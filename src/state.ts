import * as fs from "node:fs";
import * as path from "node:path";
import * as crypto from "node:crypto";
import { parse as parseToml } from "smol-toml";

export interface Exercise {
    name: string;
    path: string;
    mode: "test";
    hint: string;
}

export interface State {
    solved: string[];
    hashes: Record<string, string>;
}

export const STATE_FILE = ".soliditylings-state";
export const INFO_FILE = "info.toml";

export function findRoot(dir: string): string {
    if (fs.existsSync(path.join(dir, INFO_FILE))) {
        return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) return process.cwd();
    return findRoot(parent);
}

export const PROJECT_ROOT = findRoot(process.cwd());

export function getFileHash(relPath: string): string {
    const fullPath = path.resolve(PROJECT_ROOT, relPath);
    if (!fs.existsSync(fullPath)) return "";
    return crypto.createHash("md5").update(fs.readFileSync(fullPath, "utf-8")).digest("hex");
}

export function getExercises(): Exercise[] {
    const data = fs.readFileSync(path.resolve(PROJECT_ROOT, INFO_FILE), "utf-8");
    const parsed = parseToml(data) as unknown as { exercises: Exercise[] };
    return parsed.exercises;
}

export function getState(): State {
    const statePath = path.resolve(PROJECT_ROOT, STATE_FILE);
    if (!fs.existsSync(statePath)) {
        return { solved: [], hashes: {} };
    }
    try {
        return JSON.parse(fs.readFileSync(statePath, "utf-8")) as State;
    } catch {
        return { solved: [], hashes: {} };
    }
}

export function saveState(state: State): void {
    fs.writeFileSync(path.resolve(PROJECT_ROOT, STATE_FILE), JSON.stringify(state, null, 2));
}

export function markSolved(exercise: Exercise): State {
    const state = getState();
    if (!state.solved.includes(exercise.name)) {
        state.solved.push(exercise.name);
        state.hashes[exercise.name] = getFileHash(exercise.path);
        saveState(state);
    }
    return state;
}

export function readExerciseSource(exercise: Exercise): string {
    const full = path.resolve(PROJECT_ROOT, exercise.path);
    if (!fs.existsSync(full)) return `// file not found: ${exercise.path}`;
    return fs.readFileSync(full, "utf-8");
}
