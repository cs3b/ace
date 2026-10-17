# Retrospective — L1.3 unify active documentation and configuration

## What went well

- One canonical flow/owner document (`docs/lab-flow.md`) is now loaded into the
  project bundle, and every package README states its state owner.
- Later-wave features are explicitly marked "planned — not available yet", so
  the docs no longer claim the old lab or unimplemented L2–L10 behavior.
- The rewrite covered the whole active surface found by the audit (35+ files),
  including project guides, configs and integration docs, not just package
  READMEs.
- Docs were produced from the post-removal command surface, so no active
  instruction points at deleted commands or a cancelled task as owner.

## What could improve

- Docs work started before the code removal finished; a late re-check was needed
  for the surviving CLI surface. Sequencing docs after the removal commit (or
  freezing the command list first) would remove that risk.
- Some stale `.ace-task` references remain in handbook workflow files owned by
  the flow worker; they should be swept in a follow-up lint pass.
- `ace-bundle project` with the default agent compressor hangs when no provider
  is available; validation needed the `--compressor off` equivalent. That is an
  environment issue, not a docs issue, but it should fail fast instead of hang.

## Action items

- Add a docs lint/grep gate for old owner IDs and `.ace-task` references in
  active docs (excluding `.ace-tasks/` history and CHANGELOG).
- L5/L6/L7 doc updates should be derived from the shipped command surface at the
  time of writing, using the same "planned" marker convention.
