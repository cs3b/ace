# Goal 3 - Update and Archive Movement

## Goal

Update a real task status to done, move it to archive, and verify on-disk relocation.

## Workspace

Save only real command captures to `results/tc/03/`.

## Constraints

- Reuse the task created in Goal 2 by reading `results/tc/02/resolved-ref.txt` when available.
- Capture command outputs only; the verifier will inspect the archive tree directly.
- If `resolved-ref.txt` is missing or invalid, create a fallback task in this goal and persist its ref to `results/tc/03/fallback-ref.txt`.
- Mention the resolved task ref and which path was used (reused or fallback) in final runner observations.

## Steps

1. Resolve the target task ref from `results/tc/02/resolved-ref.txt` when available.
2. If the handoff file is missing or unusable, run `ace-task create "E2E smoke fallback task" --status pending`, capture `fallback-create.*`, and use that ref.
3. Persist the selected target ref to `results/tc/03/fallback-ref.txt` (even when Goal 2 handoff was used) so verifier evidence is deterministic.
4. Run `ace-task update <ref> --set status=done --move-to archive` and save `update.*`.
5. Run `ace-task show <ref>` and save `show-after-update.*`.
