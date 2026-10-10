# Proposed usage contract

These are acceptance scenarios for the draft, not claims of current functionality. Commands use the installed executable spelling; inside ACE use `bin/ace-*`.

## Local diff

Input: `ace-review --preset scoped --subject diff:HEAD --dry-run`

Expected: A scoped preset excluding excluded.rb produces a prompt without that diff and an explicit exclusion manifest.

## PR scope

Input: `ace-review --preset scoped --pr 42 --dry-run`

Expected: The same selection semantics apply to the PR inventory.

## Unsupported strategy

Input: `ace-review --preset invalid-strategy --subject diff:HEAD --dry-run`

Expected: Nonzero actionable configuration error; no dispatch.

