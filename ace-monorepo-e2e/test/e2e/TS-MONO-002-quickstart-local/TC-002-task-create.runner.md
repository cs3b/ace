# Goal 2 — Task Creation

## Goal

Follow quick-start section 2 ("Draft a task from the idea") and verify that `ace-task`
creates a task spec, returns success, and can be shown by its resolved ID.

## Workspace

Save all output to `results/tc/02/`.

## Steps

1. Run task create and capture execution evidence:
   ```bash
   ace-task create "Implement webhook retry with exponential backoff" \
     --tags reliability,webhooks \
     --priority high \
     > results/tc/02/create.stdout 2> results/tc/02/create.stderr
   echo $? > results/tc/02/create.exit
   ```
2. Enumerate task specs and resolve the newest path:
   ```bash
   find .ace-tasks -type f -name '*.s.md' | sort > results/tc/02/tasks.txt
   tail -n 1 results/tc/02/tasks.txt > results/tc/02/spec-path.txt
   ```
3. Derive task ID from the spec filename and save it:
   ```bash
   spec_path="$(cat results/tc/02/spec-path.txt)"
   task_id="$(basename "$spec_path")"
   task_id="${task_id%%.*}"
   printf '%s\n' "$task_id" > results/tc/02/task-id.txt
   ```
4. Show the created task with full output capture:
   ```bash
   ace-task show "$task_id" --format full \
     > results/tc/02/show.stdout 2> results/tc/02/show.stderr
   echo $? > results/tc/02/show.exit
   ```
5. Capture normalized task tree snapshot:
   ```bash
   find .ace-tasks -type f -name '*.s.md' | sort > results/tc/02/tree.stdout
   ```

## Constraints

- Use only `ace-task` commands as documented in quick-start.md.
- Do not create files manually.
- Keep all output under `results/tc/02/`.
