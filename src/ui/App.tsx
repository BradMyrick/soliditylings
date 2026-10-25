import React, { useEffect, useMemo, useRef, useState } from "react";
import { useInput, useStdin, useStdout } from "ink";
import { Box, Text } from "ink";
import { spawnSync } from "node:child_process";
import * as path from "node:path";
import {
    Exercise,
    PROJECT_ROOT,
    getExercises,
    getState,
    markSolved,
} from "../state.js";
import { RunResult, runExerciseAsync, summarizeForgeOutput } from "../runner.js";
import { bus } from "./bus.js";
import { OutputPane } from "./OutputPane.js";
import { ListView } from "./ListView.js";
import { Footer } from "./Footer.js";

type Overlay = "none" | "list";

/**
 * Compact watch dashboard. NOT a fullscreen IDE: you edit in your
 * editor (nvim beside this in a split) — this shows status, the forge
 * output, hints, and progress, sized to whatever pane it's given.
 */
export function App() {
    const { stdout: stdoutRaw } = useStdout();
    const { stdin: stdinRaw } = useStdin();
    const stdout = stdoutRaw as NodeJS.WriteStream;
    const stdin = stdinRaw as NodeJS.ReadStream & { pause(): void; resume(): void };

    const exercises = useMemo<Exercise[]>(() => getExercises(), []);
    const [solved, setSolved] = useState<Set<string>>(() => new Set(getState().solved));
    const firstPending = exercises.findIndex((e) => !solved.has(e.name));
    const [idx, setIdx] = useState(firstPending === -1 ? 0 : firstPending);
    const [runSeq, setRunSeq] = useState(0);

    const [result, setResult] = useState<RunResult | null>(null);
    const [running, setRunning] = useState(false);
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
        setRunning(true);
        setScrollFromBottom(0);

        let cancelled = false;
        runExerciseAsync(current).then((res) => {
            if (cancelled || runId !== runIdRef.current) return;
            setRunning(false);
            setResult(res);
            if (res.ok && !solved.has(current.name)) {
                markSolved(current);
                setSolved((prev) => new Set(prev).add(current.name));
                setNewlySolvedFlash(current.name);
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
            setIdx(i);
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

    /**
     * Open the current exercise in $EDITOR (nvim, etc). Hand the
     * terminal over: raw mode off, stdin paused, screen cleared —
     * the editor gets a clean terminal. On exit, restore and re-run.
     */
    const openInEditor = () => {
        const editor = process.env.EDITOR || process.env.VISUAL || "vi";
        const file = path.resolve(PROJECT_ROOT, current.path);
        try {
            stdin.setRawMode(false);
            stdin.pause();
            process.stdout.write("\x1b[2J\x1b[H"); // clear for the editor
            spawnSync(editor, [file], { stdio: "inherit" });
        } catch {
            // editor failed to launch — restore anyway
        } finally {
            stdin.resume();
            try {
                stdin.setRawMode(true);
            } catch {
                /* already restored */
            }
            console.clear();
            setRunSeq((s) => s + 1); // re-run on return
        }
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
            case "e":
                if (!running) openInEditor();
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

    const hintLines = showHint && current.hint ? current.hint.trim().split("\n") : [];
    const hintH = hintLines.length > 0 ? Math.min(hintLines.length + 2, 8) : 0;

    // header (1) + status (1) + footer (2) + output borders (2)
    const outH = Math.max(3, rows - 6 - hintH);
    const outW = cols - 4;

    const status: "running" | "pass" | "fail" = running
        ? "running"
        : result
          ? (result.ok ? "pass" : "fail")
          : "running";
    const solvedCount = exercises.filter((e) => solved.has(e.name)).length;

    const statusColor = status === "pass" ? "green" : status === "fail" ? "red" : "yellow";
    const statusText =
        status === "running"
            ? "● running…"
            : status === "pass"
              ? `✓ PASS · ${summarizeForgeOutput(result?.output ?? "")}`
              : result?.timedOut
                ? "✗ FAIL · TIMEOUT"
                : `✗ FAIL · ${summarizeForgeOutput(result?.output ?? "")}`;

    return (
        <Box flexDirection="column" height={rows}>
            <Text bold color={newlySolvedFlash === current.name ? "green" : "cyan"}>
                {`Exercise ${idx + 1}/${exercises.length}`} · {current.name} ·{" "}
                <Text dimColor>{current.path}</Text>
            </Text>
            <Text color={statusColor} bold={status !== "running"}>
                {statusText}
                {result && !running ? (
                    <Text dimColor> ({(result.durationMs / 1000).toFixed(1)}s)</Text>
                ) : null}
            </Text>

            <OutputPane
                output={result?.output ?? ""}
                status={status}
                timedOut={result?.timedOut ?? false}
                width={outW}
                height={outH}
                scrollFromBottom={scrollFromBottom}
            />

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
