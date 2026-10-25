#!/usr/bin/env node

import { Command } from "commander";
import chalk from "chalk";
import * as fs from "node:fs";
import * as path from "node:path";
import { execSync, spawnSync } from "node:child_process";
import {
    Exercise,
    PROJECT_ROOT,
    getExercises,
    getState,
    getFileHash,
    saveState,
    markSolved,
} from "./state.js";
import { runExerciseAsync, summarizeForgeOutput } from "./runner.js";

const program = new Command();

function nextPending(exercises: Exercise[], solved: string[]): Exercise | undefined {
    return exercises.find((e) => !solved.includes(e.name));
}

function programHeader() {
    console.log(chalk.bold.blue(`\n  Soliditylings \n`));
}

program
    .name("soliditylings")
    .description("A learning tool for Solidity")
    .version("2.0.0");

program
    .command("list")
    .description("Show the progress on the exercises")
    .action(() => {
        const exercises = getExercises();
        const state = getState();

        programHeader();
        console.log(chalk.bold.underline("Progress:\n"));
        exercises.forEach((ex) => {
            const isSolved = state.solved.includes(ex.name);
            const status = isSolved ? chalk.green("✔ done") : chalk.yellow("○ pending");
            console.log(`${chalk.cyan(ex.name.padEnd(25))} ${ex.path.padEnd(45)} ${status}`);
        });

        const solvedCount = exercises.filter((e) => state.solved.includes(e.name)).length;
        console.log(`\nProgress: ${solvedCount}/${exercises.length} (${Math.round((solvedCount / exercises.length) * 100)}%)\n`);
    });

program
    .command("run")
    .description("Executes the next pending exercise")
    .argument("[name]", "Name of the exercise to run")
    .action(async (name: string | undefined) => {
        const exercises = getExercises();
        const state = getState();

        const target = name
            ? exercises.find((e) => e.name === name)
            : nextPending(exercises, state.solved);

        if (!target) {
            console.log(chalk.green("🎉 All exercises completed!"));
            return;
        }

        console.log(chalk.blue(`\nTesting ${target.path}...`));
        const result = await runExerciseAsync(target);
        if (result.ok) {
            console.log(chalk.green(`✓ Successfully ran ${target.path}!\n`));
            markSolved(target);
        } else {
            console.log(chalk.red(`✗ Testing of ${target.path} failed! Here is the output:\n`));
            console.log(result.output);
            if (result.timedOut) {
                console.log(chalk.yellow(`⚠ Timed out after ${result.durationMs / 1000 | 0}s — check for an infinite loop or blocking call.`));
            }
            process.exitCode = 1;
        }
    });

program
    .command("reset")
    .description("Reset completed exercises")
    .action(() => {
        saveState({ solved: [], hashes: {} });
        try {
            execSync("git checkout HEAD -- exercises", { stdio: "pipe", cwd: PROJECT_ROOT });
            console.log(chalk.green("✓ Progress and files successfully reset to original state!"));
        } catch {
            console.log(chalk.yellow("⚠ Progress reset, but could not restore files via git. You may need to revert changes manually."));
        }
    });

program
    .command("hint")
    .description("Show a hint for the current exercise")
    .argument("[name]", "Name of the exercise to get hint for")
    .action((name: string | undefined) => {
        const exercises = getExercises();
        const state = getState();

        const target = name
            ? exercises.find((e) => e.name === name)
            : nextPending(exercises, state.solved);

        if (!target) {
            console.log(chalk.green("🎉 All exercises completed! No hints needed."));
            return;
        }

        console.log(chalk.bold.yellow(`\nHint for ${target.name}:`));
        console.log(target.hint || chalk.gray("No hint available for this exercise."));
        console.log("");
    });

program
    .command("edit")
    .description("Open an exercise in $EDITOR (defaults to vi) — pairs with `watch` in another pane")
    .argument("[name]", "Name of the exercise to edit (default: next pending)")
    .action((name: string | undefined) => {
        const exercises = getExercises();
        const state = getState();

        const target = name
            ? exercises.find((e) => e.name === name)
            : nextPending(exercises, state.solved);

        if (!target) {
            console.log(chalk.green("🎉 All exercises completed! Nothing to edit."));
            return;
        }

        const editor = process.env.EDITOR || process.env.VISUAL || "vi";
        const file = path.resolve(PROJECT_ROOT, target.path);
        console.log(chalk.blue(`Opening ${target.path} in ${editor}...`));
        const { status } = spawnSync(editor, [file], { stdio: "inherit" });
        if (status !== 0 && status !== null) process.exitCode = status;
    });

program
    .command("path")
    .description("Print an exercise's file path — e.g. nvim $(soliditylings path)")
    .argument("[name]", "Name of the exercise (default: next pending)")
    .action((name: string | undefined) => {
        const exercises = getExercises();
        const state = getState();

        const target = name
            ? exercises.find((e) => e.name === name)
            : nextPending(exercises, state.solved);

        if (!target) {
            console.log(chalk.green("🎉 All exercises completed!"));
            return;
        }
        console.log(path.resolve(PROJECT_ROOT, target.path));
    });

program
    .command("watch")
    .description("Watch exercises and automatically run when files change (the recommended way to practice)")
    .action(async () => {
        const { runWatch } = await import("./ui/watch.js");
        await runWatch();
    });

program
    .command("verify")
    .description("Verify all exercises according to the sequence")
    .action(async () => {
        const exercises = getExercises();

        programHeader();
        for (const exercise of exercises) {
            process.stdout.write(chalk.blue(`Testing ${exercise.path}... `));
            const result = await runExerciseAsync(exercise);
            if (!result.ok) {
                console.log(chalk.red("FAIL"));
                console.log(chalk.red(`\nVerification failed for ${exercise.path}.`));
                console.log(result.output.split("\n").slice(0, 25).join("\n"));
                console.log(chalk.gray(`\n(run: soliditylings run ${exercise.name})`));
                process.exit(1);
            }
            console.log(chalk.green("PASS") + chalk.gray(`  (${summarizeForgeOutput(result.output)})`));
            markSolved(exercise); // persists incrementally — progress survives Ctrl-C
        }
        console.log(chalk.green(`\n🎉 All ${exercises.length} exercises verified and completed!`));
    });

program
    .command("lsp")
    .description("Generate remappings.txt for Language Server")
    .action(() => {
        const remappings = ["forge-std/=lib/forge-std/src/"];
        fs.writeFileSync(path.resolve(PROJECT_ROOT, "remappings.txt"), remappings.join("\n"));
        console.log(chalk.green("✓ Successfully generated remappings.txt"));
    });

program.parseAsync(process.argv);
