#!/usr/bin/env node

import { Command } from "commander";
import * as chokidar from "chokidar";
import * as fs from "fs";
import * as path from "path";
import * as toml from "toml";
import { execSync } from "child_process";
import chalk from "chalk";

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
    try {
        if (exercise.mode === "compile") {
            execSync(`forge build ${exercise.path}`, { stdio: "pipe" });
        } else {
            execSync(`forge test --match-path ${exercise.path}`, { stdio: "pipe" });
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
        
        console.log(chalk.bold.underline("\nSoliditylings Progress:\n"));
        exercises.forEach(ex => {
            const status = solved.has(ex.name) ? chalk.green("Done") : chalk.yellow("Pending");
            console.log(`${ex.name.padEnd(20)} ${ex.path.padEnd(40)} ${status}`);
        });
        console.log("");
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
                console.log(chalk.green("\n🎉 All exercises completed! You are done with soliditylings!"));
                process.exit(0);
            }
            
            console.clear();
            const success = runExercise(next);
            if (success) {
                markSolved(next.name);
                setTimeout(() => {
                    isRunning = false;
                    runNext();
                }, 1000); // Give user a moment to see success text
            } else {
                isRunning = false;
            }
        };

        runNext();

        chokidar.watch("exercises/**/*.sol", { ignored: /(^|[\/\\])\../ }).on("change", (path) => {
            if (!isRunning) runNext();
        });
        
        console.log(chalk.gray("\nWatching for changes to .sol files... Press Ctrl+C to exit."));
    });

program.parse(process.argv);
