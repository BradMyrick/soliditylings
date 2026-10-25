# Soliditylings

Greetings and welcome to `soliditylings`. This project contains small exercises to get you used to writing and reading Solidity code! It is the spiritual clone of Rustlings (and golings), tailored entirely for Ethereum smart contract developers — built on [Foundry](https://book.getfoundry.sh/).

Every exercise is a broken contract with a Foundry test contract beside it. Fix the contract until the test passes.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (`forge`)
- Node.js ≥ 22

The Solidity compiler is pinned (`solc = "0.8.38"` in `foundry.toml`) and every exercise declares `pragma solidity ^0.8.38;` — forge downloads the pinned version automatically.

## Usage

```shell
npm install
npm install -g .        # optional: run `soliditylings` from anywhere
soliditylings watch     # the recommended way to practice
```

> **Note on the global install:** `npm install -g .` links the global
> `soliditylings` binary to this repo's `dist/`. After pulling new
> changes, run `npm run build` once (or skip the build entirely with
> `npm run start -- watch`, which always runs the live source).

### Commands

- `watch`: Compact dashboard for your second pane — status, forge output, hints, and progress; every save in your editor re-runs the current exercise. This is the recommended way to use `soliditylings`.
- `run [name]`: Runs the next pending exercise, or a specific exercise by name.
- `list`: Lists exercises and their completion status.
- `hint`: Shows a hint for the current exercise (hints teach the concept — they never hand you the answer).
- `edit [name]`: Opens the next pending (or named) exercise in `$EDITOR`.
- `path [name]`: Prints an exercise's path — `nvim $(soliditylings path)`.
- `verify`: Runs every exercise in order; stops at the first failure.
- `reset`: Resets progress and restores the exercise files via git.
- `lsp`: Generates `remappings.txt` for editor LSP support.

### Working with your editor

`watch` is a read-only dashboard — **you edit the files in your editor**, and every save re-runs the current exercise automatically. Two ways to set it up:

**Two panes (recommended):** run `soliditylings watch` in one tmux/window pane and your editor in the other:

```shell
# pane 1                     # pane 2
soliditylings watch          nvim $(soliditylings path)
```

**Or press `e` inside watch** to open the current exercise in `$EDITOR` (`EDITOR=nvim` if it's not already set) — the terminal hands itself to the editor and takes over again when the editor exits.

In `watch` mode: `e` edit · `n` next · `p` previous · `h` hint · `l` list · `r` rerun · `j`/`k` scroll output · `q` quit. Solving an exercise auto-advances to the next pending one.

### Doing exercises

1. The exercises order themselves from easiest to hardest — work top to bottom.
2. Every exercise is broken until you fix it. The test output tells you what's wrong.
3. Each exercise lives in its own isolated Foundry project at run time, so breaking one never blocks another.

## The curriculum is guaranteed solvable

Every exercise has a solved twin in [`solutions/`](./solutions). CI verifies all of them:

```sh
make check-solved       # structure: exercises/ <-> info.toml <-> solutions/
make verify-solutions   # every solution compiles and passes
```

See [CONTRIBUTING.md](./CONTRIBUTING.md) to add your own exercises.
