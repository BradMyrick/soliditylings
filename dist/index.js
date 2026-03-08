#!/usr/bin/env node
"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const commander_1 = require("commander");
const chokidar = __importStar(require("chokidar"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
const toml = __importStar(require("toml"));
const child_process_1 = require("child_process");
const chalk_1 = __importDefault(require("chalk"));
const readline = __importStar(require("readline"));
const program = new commander_1.Command();
const STATE_FILE = ".soliditylings-state";
const INFO_FILE = "info.toml";
function getExercises() {
    const data = fs.readFileSync(path.resolve(INFO_FILE), "utf-8");
    const parsed = toml.parse(data);
    return parsed.exercises;
}
function getSolved() {
    const statePath = path.resolve(STATE_FILE);
    if (!fs.existsSync(statePath))
        return new Set();
    const contents = fs.readFileSync(statePath, "utf-8");
    return new Set(contents.split("\n").map(l => l.trim()).filter(l => l));
}
function markSolved(name) {
    const statePath = path.resolve(STATE_FILE);
    fs.appendFileSync(statePath, `${name}\n`);
}
function runExercise(exercise) {
    console.log(chalk_1.default.blue(`\nCompiling/Testing ${exercise.path}...`));
    const env = { ...process.env, FOUNDRY_TEST: exercise.path, FOUNDRY_SRC: exercise.path };
    try {
        if (exercise.mode === "compile") {
            (0, child_process_1.execSync)(`forge build ${exercise.path}`, { stdio: "pipe", env });
        }
        else {
            (0, child_process_1.execSync)(`forge test --match-path ${exercise.path}`, { stdio: "pipe", env });
        }
        console.log(chalk_1.default.green(`✓ Successfully ran ${exercise.path}!\n`));
        return true;
    }
    catch (error) {
        console.clear();
        console.log(chalk_1.default.red(`✗ Testing of ${exercise.path} failed! Please try again. Here is the output:\n`));
        if (error.stdout)
            console.log(error.stdout.toString());
        if (error.stderr)
            console.log(error.stderr.toString());
        return false;
    }
}
function programHeader() {
    console.log(chalk_1.default.bold.blue(`\n  Soliditylings \n`));
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
    console.log(chalk_1.default.bold.underline("Progress:\n"));
    exercises.forEach(ex => {
        const status = solved.has(ex.name) ? chalk_1.default.green("Done") : chalk_1.default.yellow("Pending");
        console.log(`${chalk_1.default.cyan(ex.name.padEnd(25))} ${ex.path.padEnd(45)} ${status}`);
    });
    const solvedCount = exercises.filter(e => solved.has(e.name)).length;
    console.log(`\nProgress: ${solvedCount}/${exercises.length} (${Math.round(solvedCount / exercises.length * 100)}%)\n`);
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
        console.log(chalk_1.default.green("🎉 All exercises completed!"));
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
        console.log(chalk_1.default.green("✓ Progress reset successfully!"));
    }
    else {
        console.log(chalk_1.default.yellow("No progress to reset."));
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
        console.log(chalk_1.default.green("🎉 All exercises completed! No hints needed."));
        return;
    }
    console.log(chalk_1.default.bold.yellow(`\nHint for ${target.name}:`));
    console.log(target.hint || chalk_1.default.gray("No hint available for this exercise."));
    console.log("");
});
program
    .command("watch")
    .description("Watch exercises and automatically run when files change")
    .action(() => {
    let isRunning = false;
    const runNext = () => {
        if (isRunning)
            return;
        isRunning = true;
        const exercises = getExercises();
        const solved = getSolved();
        const next = exercises.find(e => !solved.has(e.name));
        if (!next) {
            console.clear();
            programHeader();
            console.log(chalk_1.default.green("\n🎉 All exercises completed! You are done with soliditylings!"));
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
        }
        else {
            console.log(chalk_1.default.gray(`\nCommands: [h]int, [l]ist, [r]erun, [q]uit`));
            isRunning = false;
        }
    };
    runNext();
    chokidar.watch("exercises/**/*.sol", { ignored: /(^|[\/\\])\../ }).on("all", (event, path) => {
        if (event === 'addDir' || event === 'unlinkDir')
            return;
        if (!isRunning)
            runNext();
    });
    readline.emitKeypressEvents(process.stdin);
    if (process.stdin.isTTY) {
        process.stdin.setRawMode(true);
    }
    process.stdin.on('keypress', (str, key) => {
        if (key.ctrl && key.name === 'c') {
            process.exit();
        }
        else if (key.name === 'q') {
            process.exit();
        }
        else if (key.name === 'h') {
            if (isRunning)
                return;
            const exercises = getExercises();
            const solved = getSolved();
            const next = exercises.find(e => !solved.has(e.name));
            if (next) {
                console.log(chalk_1.default.bold.yellow(`\nHint for ${next.name}:`));
                console.log(next.hint || chalk_1.default.gray("No hint available for this exercise."));
                console.log(chalk_1.default.gray(`\nCommands: [h]int, [l]ist, [r]erun, [q]uit`));
            }
        }
        else if (key.name === 'l') {
            if (isRunning)
                return;
            console.clear();
            programHeader();
            const exercises = getExercises();
            const solved = getSolved();
            console.log(chalk_1.default.bold.underline("Progress:\n"));
            exercises.forEach(ex => {
                const status = solved.has(ex.name) ? chalk_1.default.green("Done") : chalk_1.default.yellow("Pending");
                console.log(`${chalk_1.default.cyan(ex.name.padEnd(25))} ${ex.path.padEnd(45)} ${status}`);
            });
            const solvedCount = exercises.filter(e => solved.has(e.name)).length;
            console.log(`\nProgress: ${solvedCount}/${exercises.length} (${Math.round(solvedCount / exercises.length * 100)}%)\n`);
            console.log(chalk_1.default.gray("Commands: [h]int, [l]ist, [r]erun, [q]uit"));
        }
        else if (key.name === 'r' || key.name === 'return' || key.name === 'enter') {
            if (!isRunning) {
                console.clear();
                programHeader();
                runNext();
            }
        }
    });
});
program.parse(process.argv);
