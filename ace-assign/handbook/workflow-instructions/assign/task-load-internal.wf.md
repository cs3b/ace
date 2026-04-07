# task-load-internal

## Purpose

Load task behavioral specification and dependency context for assignment execution.

## Steps

1. Run `ace-bundle task://<taskref>` for the target task reference.
2. If task dependencies are declared, run `ace-bundle task://<dep-ref>` for each dependency.
3. Review relevant dependency reports under `.ace-local/assign/` so the plan/work steps build on prior implementation.
4. Confirm context is loaded before proceeding.
