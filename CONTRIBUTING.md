# Contributing to soliditylings

## Curriculum philosophy

The exercise list is a **single, flat, linear progression from easiest
to hardest**. There are no "beginner / intermediate / advanced" labels:
difficulty is expressed only by position in `info.toml`. Topic
directories are numbered (`00_intro`, `01_variables`, …) to match.

## Adding an exercise

An exercise has **three required parts**:

1. **The broken exercise** at `exercises/<NN_topic>/<name>.sol`.
2. **A solved copy** at `solutions/<NN_topic>/<name>.sol` (same relative path).
3. **A metadata entry** in `info.toml`, at the correct difficulty position.

```toml
[[exercises]]
name = "myexercise"
path = "exercises/NN_topic/myexercise.sol"
mode = "test"
hint = "a nudge that teaches the concept, never the answer"
```

### Exercise conventions

- Every file starts with `// SPDX-License-Identifier: MIT` and
  `pragma solidity ^0.8.38;` — no exceptions, including intro files.
- **Every exercise is `mode = "test"`**: the file contains a Foundry
  test contract (`import "forge-std/Test.sol"`) and the learner must
  make it pass. "Compiles" is never enough — tests make exercises
  un-gameable.
- The test contract lives in the same file as the target contract, so
  the runner can stage one file per run.
- Lead the learner with comments: a short concept intro, then numbered
  TODOs. **Hints in `info.toml` teach the concept — never paste the
  solution.**
- Broken files must **fail fast**. Never ship an exercise whose broken
  state hangs (infinite loop, blocking call) — the runner kills runs at
  120s, but a learner should see a crisp failure.

### The solved copy

`solutions/<NN_topic>/<name>.sol` must be the **complete working**
version of the exercise, with the SAME test contract. CI verifies all
of them (`make verify-solutions`), which guarantees the curriculum is
solvable and solutions never drift.

## Validating your work

From the repository root:

```sh
make check-solved      # exercises/ <-> info.toml <-> solutions/ agree
make verify-solutions  # every solved copy compiles and passes on pinned solc
npm run build          # the CLI itself compiles
```

All three must pass before a pull request can merge.

## Toolchain

Foundry (`forge`) and Node ≥ 22. The compiler is pinned in
`foundry.toml` (`solc = "0.8.38"`); forge downloads it automatically.
The runner stages each exercise into an isolated throwaway Foundry
project under `$TMPDIR/soliditylings-stage`, so a broken exercise never
blocks another (forge otherwise compiles the whole source tree).
