# Goal 3 - Update and Archive Movement

## Goal

Update a real task status to done, move it to archive, and verify on-disk relocation.

## Workspace

Save only real command captures to `results/tc/03/`.

## Constraints

- Reuse the task created in Goal 2 by resolving its full short ref from prior real command captures when available.
- Do not depend on any helper ref-tracking file.
- Capture command outputs only; the verifier will inspect the archive tree directly.
- Mention the resolved task ref in final runner observations if it was reused.

## Steps

1. Resolve the target task ref from Goal 2 command captures when available; otherwise create a fallback task and use that ref.
2. Run `ace-task update <ref> --set status=done --move-to archive` and save `update.*`.
3. Run `ace-task show <ref>` and save `show-after-update.*`.
