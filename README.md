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

### Commands

- `watch`: Watches for file changes and automatically tests the current exercise. Side-by-side panes, hint overlay, and a progress bar. This is the recommended way to use `soliditylings`.
- `run [name]`: Runs the next pending exercise, or a specific exercise by name.
- `list`: Lists exercises and their completion status.
- `hint`: Shows a hint for the current exercise (hints teach the concept — they never hand you the answer).
- `verify`: Runs every exercise in order; stops at the first failure.
- `reset`: Resets progress and restores the exercise files via git.
- `lsp`: Generates `remappings.txt` for editor LSP support.

In `watch` mode: `n` next · `p` previous · `h` hint · `l` list · `r` rerun · `q` quit.

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
