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
    console.log(chalk.blue(`\nCompiling/Testing ${exercise.path}...`));
    const fullPath = path.resolve(PROJECT_ROOT, exercise.path);
    const env = { ...process.env, FOUNDRY_TEST: fullPath, FOUNDRY_SRC: fullPath };
    try {
        if (exercise.mode === "compile") {
            execSync(`forge build ${fullPath}`, { stdio: "pipe", env });
        } else {
            execSync(`forge test --match-path ${fullPath}`, { stdio: "pipe", env });
        }
        console.log(chalk.green(`✓ Successfully ran ${exercise.path}!\n`));
        return true;
    } catch (error: any) {
        console.clear();
        console.log(chalk.red(`✗ Testing of ${exercise.path} failed! Please try again. Here is the output:\n`));
        if (error.stdout) console.log(error.stdout.toString());
        if (error.stderr) console.log(error.stderr.toString());
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
        // Keep hashes but clear solved list so users have to edit the file to re-solve
        state.solved = [];
        saveState(state);
        console.log(chalk.green("✓ Progress reset successfully! Files will be re-solved once you edit them."));
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

            // If no current exercise or current is solved, look for the first unsolved
            if (!currentExercise || state.solved.includes(currentExercise.name)) {
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

                // Rustlings logic: must have a different hash than the reset hash to move on
                if (currentHash !== lastHash) {
                    if (!state.solved.includes(currentExercise.name)) {
                        state.solved.push(currentExercise.name);
                        state.hashes[currentExercise.name] = currentHash;
                        saveState(state);
                    }
                    console.log(chalk.green(`\n✓ Exercise ${currentExercise.name} solved!`));
                    console.log(chalk.gray(`\nCommands: [n]ext, [h]int, [l]ist, [r]erun, [q]uit`));
                    isSolvedState = true;
                } else {
                    console.log(chalk.yellow(`\n✓ This exercise is technically solved, but you already solved this version.`));
                    console.log(chalk.yellow(`  Please make a change to the file to move forward.`));
                    console.log(chalk.gray(`\nCommands: [h]int, [l]ist, [r]erun, [q]uit`));
                    isSolvedState = false;
                }
            } else {
                console.log(chalk.gray(`\nCommands: [h]int, [l]ist, [r]erun, [q]uit`));
                isSolvedState = false;
            }

            isRunning = false;
            if (pendingRun) runCurrent();
        };

        runCurrent();

        chokidar.watch(path.resolve(PROJECT_ROOT, "exercises/**/*.sol"), {
            ignored: /(^|[\/\\])\../,
            persistent: true,
            ignoreInitial: true,
            awaitWriteFinish: {
                stabilityThreshold: 300,
                pollInterval: 100
            }
        }).on("all", (event) => {
            if (event === 'addDir' || event === 'unlinkDir') return;
            runCurrent();
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
                if (isRunning || !isSolvedState) return;
                // Manual progression to the next unsolved exercise
                currentExercise = undefined;
                runCurrent();
            } else if (key.name === 'r' || key.name === 'return' || key.name === 'enter') {
                if (!isRunning) runCurrent();
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
        }
        saveState(state);
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
