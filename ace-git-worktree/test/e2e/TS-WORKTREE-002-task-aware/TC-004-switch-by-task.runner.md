# Goal 4 — Switch by Task ID

## Goal

Switch to task 8pp.t.q7w's worktree using the task ID (not the branch name). Verify the returned path is correct, exists as a real directory immediately after the switch, and appears in the public `switch --list` output.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/switch-task.stdout`, `.stderr`, `.exit` — switch by task ID output
- `results/tc/04/switch-list.stdout`, `.stderr`, `.exit` — public list output after the switch
- `results/tc/04/path-check.txt` — verification that the returned path exists as a directory and appears in `switch --list`

## Constraints

- Use explicit public commands:
  1. `ace-git-worktree switch 8pp.t.q7w`
  2. `ace-git-worktree switch --list`
- Verify the returned path is a real directory immediately after the switch command completes.
- Use `switch --list` as the public confirmation oracle that the returned path is one of the current worktrees.
- Do not require deeper task-layout checks here; task-aware directory structure is already covered by Goal 2.
- All artifacts must come from real tool execution, not fabricated.

## Steps

1. Run the public switch command and capture the returned path:

   ```bash
   ace-git-worktree switch 8pp.t.q7w > results/tc/04/switch-task.stdout 2> results/tc/04/switch-task.stderr
   echo $? > results/tc/04/switch-task.exit
   ```

2. Capture the public list output after the switch:

   ```bash
   ace-git-worktree switch --list > results/tc/04/switch-list.stdout 2> results/tc/04/switch-list.stderr
   echo $? > results/tc/04/switch-list.exit
   ```

3. Confirm the returned path exists and is listed publicly:

   ```bash
   switch_path="$(tr -d '\r\n' < results/tc/04/switch-task.stdout)"
   {
     if [ -d "$switch_path" ]; then
       printf 'exists: %s\n' "$switch_path"
     else
       printf 'missing: %s\n' "$switch_path"
     fi

     if grep -Fq "$switch_path" results/tc/04/switch-list.stdout; then
       echo 'listed: yes'
     else
       echo 'listed: no'
     fi
   } > results/tc/04/path-check.txt
   ```
