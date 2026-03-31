# Goal 2 — Task Creation

## Goal

Follow quick-start section 2 ("Draft a task from the idea") using the CLI path and verify that `ace-task` creates the expected file structure.

## Workspace

Save all output to `results/tc/02/`.

## Steps

1. Run `ace-task create "Implement webhook retry with exponential backoff" --tags reliability,webhooks --priority high`.
2. Save stdout to `results/tc/02/create.stdout` and exit code to `results/tc/02/create.exit`.
3. List the `.ace-tasks/` directory tree and save to `results/tc/02/tree.stdout`.
4. Find the created `.s.md` spec file and save its path to `results/tc/02/spec-path.txt`.
5. Extract the task ID from the creation output and run `ace-task show <id>`. Save to `results/tc/02/show.stdout`.

## Constraints

- Use only `ace-task` commands as documented in quick-start.md.
- Do not create files manually.
