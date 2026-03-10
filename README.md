# Soliditylings

Greetings and welcome to `soliditylings`. This project contains small exercises to get you used to writing and reading Solidity code! It is the spiritual clone of Rustlings, tailored entirely for Ethereum smart contract developers.

## Usage

### Getting Started

Install `soliditylings` globally so you can use it anywhere:

```shell
npm install -g .
```

To run the `soliditylings` application, just use the command:

```shell
soliditylings watch
```

### Commands

There are several options you can use:

- `watch`: Watches for file changes and automatically compiles/tests the current exercise. This is the recommended way to use `soliditylings`.
- `verify`: Verifies all exercises by running them in sequence. It will stop at the first failure.
- `run [name]`: Runs the next pending exercise, or a specific exercise if a name is provided.
- `list`: Lists all exercises and their current completion status.
- `hint`: Provides a hint for the current exercise.
- `reset`: Resets all of your completion progress so you can start from scratch.
- `lsp`: Generates a `remappings.txt` file which enables LSP (Language Server Protocol) support for Solidity in your code editor.
- `init-docs`: Initializes a `docs.json` file to easily enable `docs.page` documentation compatibility.

### Doing Exercises

1. The exercises sort themselves by difficulty and topic.
2. Every exercise is broken until you fix it! Look at the compiler and test output for clues.
3. Fix the exercises! When it passes its tests/compiles without errors, `soliditylings` will track it as done.

## Documentation (docs.page)

This repository is compatible with `docs.page`. You can initialize the documentation sidebar by running:

```shell
soliditylings init-docs
```

This will create a `docs.json` file which `docs.page` uses to understand the layout of your site.
