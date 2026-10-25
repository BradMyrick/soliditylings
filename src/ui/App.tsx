import React, { useEffect, useMemo, useRef, useState } from "react";
import { useInput, useStdout } from "ink";
import { Box, Text } from "ink";
import {
    Exercise,
    getExercises,
    getState,
    markSolved,
    readExerciseSource,
} from "../state.js";
import { RunResult, runExerciseAsync } from "../runner.js";
import { bus } from "./bus.js";
import { ExercisePane } from "./ExercisePane.js";
import { OutputPane } from "./OutputPane.js";
import { ListView } from "./ListView.js";
import { Footer } from "./Footer.js";

type Overlay = "none" | "list";

export function App() {
    const { stdout: stdoutRaw } = useStdout();
    const stdout = stdoutRaw as NodeJS.WriteStream;

    const exercises = useMemo<Exercise[]>(() => getExercises(), []);
    const [solved, setSolved] = useState<Set<string>>(() => new Set(getState().solved));
    const firstPending = exercises.findIndex((e) => !solved.has(e.name));
    const [idx, setIdx] = useState(firstPending === -1 ? 0 : firstPending);
    const [runSeq, setRunSeq] = useState(0);

    const [result, setResult] = useState<RunResult | null>(null);
    const [running, setRunning] = useState(false);
    const [source, setSource] = useState<string>(() => readExerciseSource(exercises[0] ?? ({} as Exercise)));
    const [showHint, setShowHint] = useState(false);
    const [overlay, setOverlay] = useState<Overlay>("none");
    const [scrollFromBottom, setScrollFromBottom] = useState(0);
    const [newlySolvedFlash, setNewlySolvedFlash] = useState<string | null>(null);

    const current = exercises[Math.min(idx, exercises.length - 1)];
    const runIdRef = useRef(0);

    // ---- run the current exercise whenever it changes / is retried ----
    useEffect(() => {
        if (!current) return;
        const runId = ++runIdRef.current;
        setSource(readExerciseSource(current));
        setRunning(true);
        setScrollFromBottom(0);

        let cancelled = false;
        runExerciseAsync(current).then((res) => {
            if (cancelled || runId !== runIdRef.current) return;
            setRunning(false);
            setResult(res);
            if (res.ok) {
                const before = solved.has(current.name);
                if (!before) {
                    markSolved(current);
                    setSolved((prev) => new Set(prev).add(current.name));
                    setNewlySolvedFlash(current.name);
                }
            }
        });
        return () => {
            cancelled = true;
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [idx, runSeq]);

    // auto-advance shortly after a fresh solve — keep the flow moving
    useEffect(() => {
        if (!newlySolvedFlash) return;
        const t = setTimeout(() => {
            setNewlySolvedFlash(null);
            setIdx((i) => {
                const next = exercises.findIndex((e, j) => j > i && !solved.has(e.name));
                return next === -1 ? i : next;
            });
        }, 1200);
        return () => clearTimeout(t);
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [newlySolvedFlash]);

    // ---- focus + re-run the exercise whose file was just edited ----
    useEffect(() => {
        return bus.subscribe((name) => {
            const i = exercises.findIndex((e) => e.name === name);
            if (i === -1) return;
            setIdx((cur) => {
                if (cur !== i) setSource(readExerciseSource(exercises[i]));
                return i;
            });
            setRunSeq((s) => s + 1);
        });
    }, [exercises]);

    // ---- re-render on terminal resize ----
    const [, forceResize] = useState(0);
    useEffect(() => {
        const onResize = () => forceResize((n) => n + 1);
        stdout.on("resize", onResize);
        return () => {
            stdout.off("resize", onResize);
        };
    }, [stdout]);

    const goto = (i: number) => {
        if (i < 0 || i >= exercises.length || i === idx) return;
        setOverlay("none");
        setIdx(i);
    };

    // ---- key routing ----
    useInput((input, key) => {
        if (overlay === "list") {
            if (key.escape) setOverlay("none");
            return; // ListView owns arrows/enter via isActive
        }
        if (key.escape) {
            setShowHint(false);
            setScrollFromBottom(0);
            return;
        }
        switch (input) {
            case "n":
                goto(idx + 1);
                break;
            case "p":
                goto(idx - 1);
                break;
            case "r":
                setRunSeq((s) => s + 1);
                break;
            case "h":
                setShowHint((v) => !v);
                break;
            case "l":
                setOverlay("list");
                break;
            case "q":
                process.exit(0);
                break;
            case "j":
                setScrollFromBottom((b) => b + 1);
                break;
            case "k":
                setScrollFromBottom((b) => Math.max(0, b - 1));
                break;
        }
    });

    if (!current) {
        return (
            <Box justifyContent="center" alignItems="center" flexGrow={1}>
                <Text color="green">🎉 All exercises completed! You are done with soliditylings!</Text>
            </Box>
        );
    }

    const cols = stdout.columns || 100;
    const rows = stdout.rows || 40;
    const sideBySide = cols >= 120;

    const hintLines = showHint && current.hint ? current.hint.trim().split("\n") : [];
    const hintH = hintLines.length > 0 ? Math.min(hintLines.length + 2, 8) : 0;
    const footerH = 2;
    const bodyRows = Math.max(10, rows - footerH - hintH);

    const codeH = sideBySide ? bodyRows - 2 : Math.max(8, Math.floor(bodyRows * 0.4)) - 2;
    const outH = bodyRows - (sideBySide ? 2 : codeH + 2) - 2;

    const codeW = sideBySide ? Math.floor(cols / 2) - 3 : cols - 4;
    const outW = sideBySide ? cols - Math.floor(cols / 2) - 3 : cols - 4;

    const status: "running" | "pass" | "fail" = running ? "running" : result ? (result.ok ? "pass" : "fail") : "running";
    const solvedCount = exercises.filter((e) => solved.has(e.name)).length;

    const title = `Exercise ${idx + 1}/${exercises.length} · ${current.name} · ${current.path}`;

    return (
        <Box flexDirection="column" height={rows}>
            <Box flexDirection={sideBySide ? "row" : "column"} flexGrow={1}>
                <ExercisePane
                    title={title}
                    source={source}
                    width={codeW}
                    height={codeH}
                    flash={newlySolvedFlash === current.name}
                />
                <OutputPane
                    output={result?.output ?? ""}
                    status={status}
                    timedOut={result?.timedOut ?? false}
                    width={outW}
                    height={outH}
                    scrollFromBottom={scrollFromBottom}
                />
            </Box>

            {hintLines.length > 0 && (
                <Box borderStyle="round" borderColor="yellow" flexDirection="column" height={hintH} paddingLeft={1}>
                    <Text bold color="yellow">hint (h to hide)</Text>
                    {hintLines.slice(0, hintH - 2).map((l, i) => (
                        <Text key={i} color="yellow">{l}</Text>
                    ))}
                </Box>
            )}

            <Footer
                solved={solvedCount}
                total={exercises.length}
                status={status}
                width={cols}
            />

            {overlay === "list" && (
                <ListView
                    exercises={exercises}
                    solved={solved}
                    currentIdx={idx}
                    onSelect={(i) => goto(i)}
                    onClose={() => setOverlay("none")}
                />
            )}
        </Box>
    );
}
