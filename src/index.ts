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

function getExercises(): Exercise[] {
    const data = fs.readFileSync(path.resolve(INFO_FILE), "utf-8");
    const parsed = toml.parse(data);
    return parsed.exercises as Exercise[];
}

function getSolved(): Set<string> {
    const statePath = path.resolve(STATE_FILE);
    if (!fs.existsSync(statePath)) return new Set();
    const contents = fs.readFileSync(statePath, "utf-8");
    return new Set(contents.split("\n").map(l => l.trim()).filter(l => l));
}

function markSolved(name: string) {
    const statePath = path.resolve(STATE_FILE);
    fs.appendFileSync(statePath, `${name}\n`);
}

function runExercise(exercise: Exercise): boolean {
    console.log(chalk.blue(`\nCompiling/Testing ${exercise.path}...`));
    const env = { ...process.env, FOUNDRY_TEST: exercise.path, FOUNDRY_SRC: exercise.path };
    try {
        if (exercise.mode === "compile") {
            execSync(`forge build ${exercise.path}`, { stdio: "pipe", env });
        } else {
            execSync(`forge test --match-path ${exercise.path}`, { stdio: "pipe", env });
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
        const solved = getSolved();
        
        programHeader();
        console.log(chalk.bold.underline("Progress:\n"));
        exercises.forEach(ex => {
            const status = solved.has(ex.name) ? chalk.green("Done") : chalk.yellow("Pending");
            console.log(`${chalk.cyan(ex.name.padEnd(25))} ${ex.path.padEnd(45)} ${status}`);
        });
        
        const solvedCount = exercises.filter(e => solved.has(e.name)).length;
        console.log(`\nProgress: ${solvedCount}/${exercises.length} (${Math.round(solvedCount/exercises.length*100)}%)\n`);
    });

program
    .command("run")
    .description("Executes the next pending exercise")
    .argument("[name]", "Name of the exercise to run")
    .action((name) => {
        const exercises = getExercises();
        const solved = getSolved();
        
        const target = name 
            ? exercises.find(e => e.name === name) 
            : exercises.find(e => !solved.has(e.name));

        if (!target) {
            console.log(chalk.green("🎉 All exercises completed!"));
            return;
        }

        const success = runExercise(target);
        if (success && !solved.has(target.name)) {
            markSolved(target.name);
        }
    });

program
    .command("reset")
    .description("Reset completed exercises")
    .action(() => {
        const statePath = path.resolve(STATE_FILE);
        if (fs.existsSync(statePath)) {
            fs.unlinkSync(statePath);
            console.log(chalk.green("✓ Progress reset successfully!"));
        } else {
            console.log(chalk.yellow("No progress to reset."));
        }
    });

program
    .command("hint")
    .description("Show a hint for the current exercise")
    .argument("[name]", "Name of the exercise to get hint for")
    .action((name) => {
        const exercises = getExercises();
        const solved = getSolved();
        
        const target = name 
            ? exercises.find(e => e.name === name) 
            : exercises.find(e => !solved.has(e.name));

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
        
        const runNext = () => {
            if (isRunning) return;
            isRunning = true;
            
            const exercises = getExercises();
            const solved = getSolved();
            const next = exercises.find(e => !solved.has(e.name));
            
            if (!next) {
                console.clear();
                programHeader();
                console.log(chalk.green("\n🎉 All exercises completed! You are done with soliditylings!"));
                process.exit(0);
            }
            
            console.clear();
            programHeader();
            const success = runExercise(next);
            if (success) {
                markSolved(next.name);
                setTimeout(() => {
                    isRunning = false;
                    runNext();
                }, 1500); // Give user a moment to see success text before moving on
            } else {
                console.log(chalk.gray(`\nCommands: [h]int, [l]ist, [r]erun, [q]uit`));
                isRunning = false;
            }
        };

        runNext();

        chokidar.watch("exercises/**/*.sol", { ignored: /(^|[\/\\])\../ }).on("all", (event, path) => {
            if (event === 'addDir' || event === 'unlinkDir') return;
            if (!isRunning) runNext();
        });
        
        readline.emitKeypressEvents(process.stdin);
        if (process.stdin.isTTY) {
            process.stdin.setRawMode(true);
        }

        process.stdin.on('keypress', (str, key) => {
            if (key.ctrl && key.name === 'c') {
                process.exit();
            } else if (key.name === 'q') {
                process.exit();
            } else if (key.name === 'h') {
                if (isRunning) return;
                const exercises = getExercises();
                const solved = getSolved();
                const next = exercises.find(e => !solved.has(e.name));
                if (next) {
                    console.log(chalk.bold.yellow(`\nHint for ${next.name}:`));
                    console.log(next.hint || chalk.gray("No hint available for this exercise."));
                    console.log(chalk.gray(`\nCommands: [h]int, [l]ist, [r]erun, [q]uit`));
                }
            } else if (key.name === 'l') {
                if (isRunning) return;
                console.clear();
                programHeader();
                const exercises = getExercises();
                const solved = getSolved();
                console.log(chalk.bold.underline("Progress:\n"));
                exercises.forEach(ex => {
                    const status = solved.has(ex.name) ? chalk.green("Done") : chalk.yellow("Pending");
                    console.log(`${chalk.cyan(ex.name.padEnd(25))} ${ex.path.padEnd(45)} ${status}`);
                });
                
                const solvedCount = exercises.filter(e => solved.has(e.name)).length;
                console.log(`\nProgress: ${solvedCount}/${exercises.length} (${Math.round(solvedCount/exercises.length*100)}%)\n`);
                console.log(chalk.gray("Commands: [h]int, [l]ist, [r]erun, [q]uit"));
            } else if (key.name === 'r' || key.name === 'return' || key.name === 'enter') {
                if (!isRunning) {
                     console.clear();
                     programHeader();
                     runNext();
                }
            }
        });
    });

program.parse(process.argv);
