# reflect-and-refactor-internal

## Purpose

Run architecture reflection and bounded refactoring before release/closeout.

## Steps

1. Validate implementation/demo state.
2. Run architecture-focused review on the active diff.
3. Categorize findings (refactor/accept/skip).
4. Execute bounded refactoring for selected findings only.
5. Commit refactor changes separately.
6. If a replan trigger is hit, inject follow-up implementation steps and rerun once.
