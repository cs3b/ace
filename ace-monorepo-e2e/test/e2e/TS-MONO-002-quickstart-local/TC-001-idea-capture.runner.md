# Goal 1 — Idea Capture

## Goal

Follow quick-start section 1 ("Capture an idea") and verify that `ace-idea` creates the expected file structure.

## Workspace

Save all output to `results/tc/01/`.

## Steps

1. Run `ace-idea create "Add retry logic to webhook delivery" --tags reliability,webhooks`.
2. Save stdout to `results/tc/01/create.stdout` and exit code to `results/tc/01/create.exit`.
3. List the `.ace-ideas/` directory tree and save to `results/tc/01/tree.stdout`.
4. Verify an `.idea.s.md` file was created — save its path to `results/tc/01/idea-path.txt`.
5. Run `ace-idea list` and save output to `results/tc/01/list.stdout`.

## Constraints

- Use only `ace-idea` commands as documented in quick-start.md.
- Do not create files manually — all artifacts must come from tool execution.
