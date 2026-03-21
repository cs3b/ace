# Goal 3 - Update and Archive Movement

## Goal

Update a real task status to done, move it to archive, and verify on-disk relocation.

## Workspace

Save all artifacts to `results/tc/03/`.

## Constraints

- Reuse the task ref from Goal 2 if available; otherwise create a fallback task and document it.
- Capture command outputs and filesystem evidence.

## Steps

1. Read ref from `results/tc/02/task-ref.txt` when present.
2. Run `mise exec -- ace-task update <ref> --set status=done --move-to archive` and save `update.*`.
3. Run `mise exec -- ace-task show <ref>` and save `show-after-update.*`.
4. Capture archived files with `find .ace-tasks/_archive -maxdepth 4 -type f -name '*.s.md' | sort > results/tc/03/archive-files.txt`.
