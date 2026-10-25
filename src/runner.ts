import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { spawn } from "node:child_process";
import { Exercise, PROJECT_ROOT } from "./state.js";

export const RUN_TIMEOUT_MS = 120_000;

/**
 * Every exercise runs in an isolated throwaway Foundry project: a broken
 * exercise must never block another (forge compiles the whole source tree
 * when run in-repo, so one missing brace would sink every --match-path).
 * The staging dir persists between runs so forge's cache warms up.
 */
export const STAGE_DIR = path.join(os.tmpdir(), "soliditylings-stage");

export interface RunResult {
    ok: boolean;
    output: string;
    timedOut: boolean;
    durationMs: number;
}

/** The solc version the curriculum pins (read from foundry.toml). */
function getPinnedSolc(): string {
    try {
        const raw = fs.readFileSync(path.resolve(PROJECT_ROOT, "foundry.toml"), "utf-8");
        const m = raw.match(/^solc\s*=\s*"([^"]+)"/m);
        if (m) return m[1];
    } catch {
        /* fall through */
    }
    return "0.8.38"; // keep in sync with foundry.toml
}

/** Copy one exercise into the staging Foundry project; return staged path. */
export function stageExercise(exercise: Exercise): string {
    const srcDir = path.join(STAGE_DIR, "src");
    fs.rmSync(srcDir, { recursive: true, force: true });
    fs.mkdirSync(srcDir, { recursive: true });

    fs.writeFileSync(
        path.join(STAGE_DIR, "foundry.toml"),
        [
            "[profile.default]",
            'src = "src"',
            'out = "out"',
            'libs = ["lib"]',
            'test = "src"',
            `solc = "${getPinnedSolc()}"`,
            "",
        ].join("\n")
    );

    const libLink = path.join(STAGE_DIR, "lib");
    fs.rmSync(libLink, { recursive: true, force: true });
    fs.symlinkSync(path.resolve(PROJECT_ROOT, "lib"), libLink, "dir");

    const staged = path.join(srcDir, path.basename(exercise.path));
    fs.copyFileSync(path.resolve(PROJECT_ROOT, exercise.path), staged);
    return staged;
}

/**
 * Run one exercise asynchronously (never execSync — that would freeze the
 * TUI render loop). The child is killed hard after RUN_TIMEOUT_MS.
 */
export function runExerciseAsync(exercise: Exercise): Promise<RunResult> {
    let staged: string;
    try {
        staged = stageExercise(exercise);
    } catch (err: any) {
        return Promise.resolve({
            ok: false,
            output: `Failed to stage exercise: ${err?.message ?? err}`,
            timedOut: false,
            durationMs: 0,
        });
    }

    return new Promise((resolve) => {
        const start = Date.now();
        const child = spawn("forge", ["test", "--match-path", staged], {
            cwd: STAGE_DIR,
            env: process.env,
            stdio: ["ignore", "pipe", "pipe"],
        });

        let output = "";
        let timedOut = false;
        const append = (d: Buffer) => {
            output += d.toString();
        };
        child.stdout.on("data", append);
        child.stderr.on("data", append);

        const timer = setTimeout(() => {
            timedOut = true;
            child.kill("SIGKILL");
        }, RUN_TIMEOUT_MS);

        const finish = (ok: boolean, extra?: string) => {
            clearTimeout(timer);
            if (extra) output += extra;
            resolve({ ok, output, timedOut, durationMs: Date.now() - start });
        };

        child.on("error", (err) => finish(false, `\nFailed to run forge: ${err.message}`));
        child.on("close", (code) => finish(code === 0 && !timedOut));
    });
}

/** Extract the meaningful test summary from forge output, for status lines. */
export function summarizeForgeOutput(output: string): string {
    const lines = output.split("\n").filter(Boolean);
    for (let i = lines.length - 1; i >= 0; i--) {
        const l = lines[i];
        if (l.includes("tests passed") || l.includes("tests succeeded") || l.includes("tests failed")) {
            return l.trim();
        }
    }
    return "compiler error";
}
