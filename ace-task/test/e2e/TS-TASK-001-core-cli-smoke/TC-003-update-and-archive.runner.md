# Goal 3 - Update and Archive Movement

## Goal

Update a real task status to done, move it to archive, and verify on-disk relocation.

## Workspace

Save only real command captures to `results/tc/03/`.

## Constraints

- Create a fresh archive-specific task in this goal; do not move the Goal 2 task, because Goal 2 proves the non-archived create/list/show state.
- Capture command outputs only; the verifier will inspect the archive tree directly.
- Persist the archive-specific ref to `results/tc/03/archive-ref.txt`.
- Mention the archive-specific task ref in final runner observations.

## Steps

1. Run `ace-task create "E2E smoke archive task" --status pending` and save `archive-create.*`.
2. Resolve the created task ref from `archive-create.stdout`.
3. Persist the selected target ref to `results/tc/03/archive-ref.txt`.
4. Run `ace-task update <ref> --set status=done --move-to archive` and save `update.*`.
5. Run `ace-task show <ref>` and save `show-after-update.*`.
