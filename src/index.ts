#!/usr/bin/env node

import { Command } from "commander";
import * as chokidar from "chokidar";
import * as fs from "fs";
import * as path from "path";
import * as toml from "toml";
import { execSync } from "child_process";
import chalk from "chalk";
import * as readline from "readline";

const program = new Command();
const STATE_FILE = ".soliditylings-state";
const INFO_FILE = "info.toml";
const RUN_TIMEOUT_MS = 120_000;

// Every exercise runs in an isolated throwaway Foundry project: a broken
// exercise must never block another (forge compiles the whole source tree
// when run in-repo, so one missing brace would sink every --match-path).
// The staging dir persists between runs so forge's cache warms up.
const STAGE_DIR = path.join(require("os").tmpdir(), "soliditylings-stage");

interface Exercise {
    name: string;
    path: string;
    mode: "compile" | "test";
    hint: string;
}

interface State {
    solved: string[];
    hashes: Record<string, string>;
}

function findRoot(dir: string): string {
    if (fs.existsSync(path.join(dir, INFO_FILE))) {
        return dir;
    }
    const parent = path.dirname(dir);
    if (parent === dir) return process.cwd();
    return findRoot(parent);
}

const PROJECT_ROOT = findRoot(process.cwd());

function getFileHash(filePath: string): string {
    const fullPath = path.resolve(PROJECT_ROOT, filePath);
    if (!fs.existsSync(fullPath)) return "";
    const content = fs.readFileSync(fullPath, "utf-8");
    return require("crypto").createHash("md5").update(content).digest("hex");
}

function getExercises(): Exercise[] {
    const data = fs.readFileSync(path.resolve(PROJECT_ROOT, INFO_FILE), "utf-8");
    const parsed = toml.parse(data);
    return parsed.exercises as Exercise[];
}

/**
 * Copy one exercise into the staging Foundry project and return the path
 * to the staged file. `lib` is symlinked so forge-std resolves.
 */
function stageExercise(exercise: Exercise): string {
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

function getState(): State {
    const statePath = path.resolve(PROJECT_ROOT, STATE_FILE);
    if (!fs.existsSync(statePath)) {
        return { solved: [], hashes: {} };
    }
    try {
        return JSON.parse(fs.readFileSync(statePath, "utf-8"));
    } catch {
        return { solved: [], hashes: {} };
    }
}

function saveState(state: State) {
    const statePath = path.resolve(PROJECT_ROOT, STATE_FILE);
    fs.writeFileSync(statePath, JSON.stringify(state, null, 2));
}

function runExercise(exercise: Exercise): boolean {
    console.log(chalk.blue(`\nTesting ${exercise.path}...`));
    const staged = stageExercise(exercise);
    const env = { ...process.env };
    try {
        // A hung test must never hang the watcher — the timeout kills it.
        execSync(`forge test --match-path ${staged}`, {
            stdio: "pipe",
            env,
            timeout: RUN_TIMEOUT_MS,
            cwd: STAGE_DIR,
        });
        console.log(chalk.green(`✓ Successfully ran ${exercise.path}!\n`));
        return true;
    } catch (error: any) {
        console.clear();
        console.log(chalk.red(`✗ Testing of ${exercise.path} failed! Please try again. Here is the output:\n`));
        if (error.stdout) console.log(error.stdout.toString());
        if (error.stderr) console.log(error.stderr.toString());
        if (error.signal === "SIGTERM") {
            console.log(chalk.yellow(`\n⚠ Exercise timed out after ${RUN_TIMEOUT_MS / 1000}s — check for an infinite loop or blocking call.`));
        }
        return false;
    }
}

function programHeader() {
    console.log(chalk.bold.blue(`\n  Soliditylings \n`));
}

program
    .name("soliditylings")
    .description("A learning tool for Solidity")
    .version("1.0.0");

program
    .command("list")
    .description("Show the progress on the exercises")
    .action(() => {
        const exercises = getExercises();
        const state = getState();

        programHeader();
        console.log(chalk.bold.underline("Progress:\n"));
        exercises.forEach(ex => {
            const isSolved = state.solved.includes(ex.name);
            const status = isSolved ? chalk.green("Done") : chalk.yellow("Pending");
            console.log(`${chalk.cyan(ex.name.padEnd(25))} ${ex.path.padEnd(45)} ${status}`);
        });

        const solvedCount = exercises.filter(e => state.solved.includes(e.name)).length;
        console.log(`\nProgress: ${solvedCount}/${exercises.length} (${Math.round(solvedCount / exercises.length * 100)}%)\n`);
    });

program
    .command("run")
    .description("Executes the next pending exercise")
    .argument("[name]", "Name of the exercise to run")
    .action((name) => {
        const exercises = getExercises();
        const state = getState();

        const target = name
            ? exercises.find(e => e.name === name)
            : exercises.find(e => !state.solved.includes(e.name));

        if (!target) {
            console.log(chalk.green("🎉 All exercises completed!"));
            return;
        }

        const success = runExercise(target);
        if (success && !state.solved.includes(target.name)) {
            state.solved.push(target.name);
            state.hashes[target.name] = getFileHash(target.path);
            saveState(state);
        }
    });

program
    .command("reset")
    .description("Reset completed exercises")
    .action(() => {
        const state = getState();
        state.solved = [];
        state.hashes = {};
        saveState(state);

        try {
            execSync('git checkout HEAD -- exercises', { 
                stdio: 'pipe', 
                cwd: PROJECT_ROOT 
            });
            console.log(chalk.green("✓ Progress and files successfully reset to original state!"));
        } catch (error) {
            console.log(chalk.yellow("⚠ Progress reset, but could not restore files via git. You may need to revert changes manually."));
        }
    });

program
    .command("hint")
    .description("Show a hint for the current exercise")
    .argument("[name]", "Name of the exercise to get hint for")
    .action((name) => {
        const exercises = getExercises();
        const state = getState();

        const target = name
            ? exercises.find(e => e.name === name)
            : exercises.find(e => !state.solved.includes(e.name));

        if (!target) {
            console.log(chalk.green("🎉 All exercises completed! No hints needed."));
            return;
        }

        console.log(chalk.bold.yellow(`\nHint for ${target.name}:`));
        console.log(target.hint || chalk.gray("No hint available for this exercise."));
        console.log("");
    });

program
    .command("watch")
    .description("Watch exercises and automatically run when files change")
    .action(() => {
        let isRunning = false;
        let pendingRun = false;
        let currentExercise: Exercise | undefined;
        let isSolvedState = false;

        const runCurrent = async () => {
            if (isRunning) {
                pendingRun = true;
                return;
            }

            isRunning = true;
            pendingRun = false;

            const exercises = getExercises();
            const state = getState();

            // Only find the first unsolved if we don't have a current focus.
            if (!currentExercise) {
                currentExercise = exercises.find(e => !state.solved.includes(e.name));
            }

            if (!currentExercise) {
                console.clear();
                programHeader();
                console.log(chalk.green("\n🎉 All exercises completed! You are done with soliditylings!"));
                process.exit(0);
            }

            console.clear();
            programHeader();
            const success = runExercise(currentExercise);

            if (success) {
                const currentHash = getFileHash(currentExercise.path);
                const lastHash = state.hashes[currentExercise.name];

                if (state.solved.includes(currentExercise.name)) {
                    // Already solved. Show green solved view.
                    console.log(chalk.green(`\n✓ Exercise ${currentExercise.name} is solved!`));
                    console.log(chalk.gray(`\nCommands: [p]revious, [n]ext, [h]int, [l]ist, [r]erun, [q]uit`));
                    isSolvedState = true;
                } else if (currentHash !== lastHash) {
                    // New solve!
                    state.solved.push(currentExercise.name);
                    state.hashes[currentExercise.name] = currentHash;
                    saveState(state);
                    console.log(chalk.green(`\n✓ Exercise ${currentExercise.name} solved!`));
                    console.log(chalk.gray(`\nCommands: [p]revious, [n]ext, [h]int, [l]ist, [r]erun, [q]uit`));
                    isSolvedState = true;
                } else {
                    // Pending, passes, but no change from before reset.
                    console.log(chalk.yellow(`\n✓ This exercise is technically solved, but you already solved this version.`));
                    console.log(chalk.yellow(`  Please make a change to the file to move forward.`));
                    console.log(chalk.gray(`\nCommands: [p]revious, [n]ext, [h]int, [l]ist, [r]erun, [q]uit`));
                    isSolvedState = false;
                }
            } else {
                console.log(chalk.gray(`\nCommands: [p]revious, [n]ext, [h]int, [l]ist, [r]erun, [q]uit`));
                isSolvedState = false;
            }

            isRunning = false;
            if (pendingRun) runCurrent();
        };

        let debounceTimer: NodeJS.Timeout | null = null;
        const triggerRun = () => {
            if (debounceTimer) clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                runCurrent();
            }, 100);
        };

        triggerRun();

        chokidar.watch(path.resolve(PROJECT_ROOT, "exercises"), {
            ignored: /(^|[\/\\])\..|~$|\.swp$/,
            persistent: true,
            ignoreInitial: true,
        }).on("all", (event, filePath) => {
            if (!filePath.endsWith('.sol')) return; 
            const exercises = getExercises();
            const absoluteFilePath = path.resolve(filePath);
            const matchingExercise = exercises.find(e => path.resolve(PROJECT_ROOT, e.path) === absoluteFilePath);
            
            if (matchingExercise) {
                currentExercise = matchingExercise;
            }
            triggerRun();
        });

        readline.emitKeypressEvents(process.stdin);
        if (process.stdin.isTTY) {
            process.stdin.setRawMode(true);
        }

        process.stdin.on('keypress', (str, key) => {
            if (key.ctrl && key.name === 'c' || key.name === 'q') {
                process.exit();
            } else if (key.name === 'h') {
                if (isRunning || !currentExercise) return;
                console.log(chalk.bold.yellow(`\nHint for ${currentExercise.name}:`));
                console.log(currentExercise.hint || chalk.gray("No hint available for this exercise."));
            } else if (key.name === 'l') {
                if (isRunning) return;
                console.clear();
                programHeader();
                const exercises = getExercises();
                const state = getState();
                exercises.forEach(ex => {
                    const status = state.solved.includes(ex.name) ? chalk.green("Done") : chalk.yellow("Pending");
                    console.log(`${chalk.cyan(ex.name.padEnd(25))} ${status}`);
                });
            } else if (key.name === 'n') {
                if (isRunning) return;
                const exercises = getExercises();
                const currentIndex = currentExercise ? exercises.findIndex(e => e.name === currentExercise!.name) : -1;
                if (currentIndex >= 0 && currentIndex < exercises.length - 1) {
                    currentExercise = exercises[currentIndex + 1];
                    triggerRun();
                }
            } else if (key.name === 'p') {
                if (isRunning) return;
                const exercises = getExercises();
                const currentIndex = currentExercise ? exercises.findIndex(e => e.name === currentExercise!.name) : -1;
                if (currentIndex > 0) {
                    currentExercise = exercises[currentIndex - 1];
                    triggerRun();
                }
            } else if (key.name === 'r' || key.name === 'return' || key.name === 'enter') {
                if (!isRunning) triggerRun();
            }
        });
    });

program
    .command("verify")
    .description("Verify all exercises according to the sequence")
    .action(() => {
        const exercises = getExercises();
        const state = getState();

        programHeader();
        for (const exercise of exercises) {
            const success = runExercise(exercise);
            if (!success) {
                console.log(chalk.red(`\nVerification failed for ${exercise.path}.`));
                process.exit(1);
            }
            if (!state.solved.includes(exercise.name)) {
                state.solved.push(exercise.name);
                state.hashes[exercise.name] = getFileHash(exercise.path);
            }
            // Persist after each success so a mid-run failure (or Ctrl-C)
            // never throws away progress already earned.
            saveState(state);
        }
        console.log(chalk.green(`\n🎉 All exercises verified and completed!`));
    });

program
    .command("lsp")
    .description("Generate remappings.txt for Language Server")
    .action(() => {
        const remappings = [
            "forge-std/=lib/forge-std/src/"
        ];
        fs.writeFileSync(path.resolve(PROJECT_ROOT, "remappings.txt"), remappings.join("\n"));
        console.log(chalk.green("✓ Successfully generated remappings.txt"));
    });

program
    .command("init-docs")
    .description("Initialize docs.json for docs.page setup")
    .action(() => {
        const docsJson = {
            "name": "soliditylings",
            "sidebar": [
                { "group": "Documentation", "pages": [{ "title": "Introduction", "href": "/" }] }
            ]
        };
        fs.writeFileSync(path.resolve(PROJECT_ROOT, "docs.json"), JSON.stringify(docsJson, null, 2));
        console.log(chalk.green("✓ Successfully initialized docs.json!"));
    });

program.parse(process.argv);
