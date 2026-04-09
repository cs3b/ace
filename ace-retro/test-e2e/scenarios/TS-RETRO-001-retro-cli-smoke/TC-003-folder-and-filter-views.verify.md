# Goal 3 - Folder and Filter Views Verification

## Expectations

Validation order (impact-first):
1. Confirm archive-targeted retro file exists under `_archive` path in sandbox tree evidence.
2. Confirm explicit artifacts under `results/tc/03/`.
3. Use debug captures as fallback.

1. `create-archive.exit`, `list-archive.exit`, `list-status.exit`, and `list-tags.exit` are `0`.
2. `create-archive.stdout` indicates `_archive` folder placement.
3. `list-archive.stdout` includes the archive-created retro title and excludes unrelated root-only entries.
4. `list-status.stdout` and `list-tags.stdout` include expected filtered entries.

## Verdict

- **PASS**: Folder routing and filter flags work against real persisted retros.
- **FAIL**: Incorrect folder placement, filter mismatch, or non-zero exit codes.
