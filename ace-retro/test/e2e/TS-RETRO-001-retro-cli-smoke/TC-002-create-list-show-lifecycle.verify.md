# Goal 2 - Create/List/Show Lifecycle Verification

## Expectations

Validation order (impact-first):
1. Confirm a retro markdown file exists on disk and was captured.
2. Confirm explicit artifacts under `results/tc/02/`.
3. Use debug captures as fallback.

1. `create.exit`, `list.exit`, `show.exit`, and `show-path.exit` are `0`.
2. `create.stdout` includes `Retro created:` and `Path:`.
3. `retro-id.txt` contains a non-empty retro ID.
4. `list.stdout` includes the created retro title.
5. `show.stdout` includes the same retro ID and title.
6. `retro-file.md` contains YAML frontmatter with `id:`, `title:`, and `status:`.

## Verdict

- **PASS**: End-to-end create/list/show flow works with persisted retro evidence.
- **FAIL**: Missing file evidence, inconsistent IDs/titles, or non-zero exit codes.
