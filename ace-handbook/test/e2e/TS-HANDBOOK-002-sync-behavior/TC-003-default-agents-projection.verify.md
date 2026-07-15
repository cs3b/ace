# Goal 3 Verification - Default agents projection includes legacy workflow skills

## Expectation

Plain `ace-handbook sync` exits successfully, writes the default projection to `.agents/skills`, and makes a
legacy-targeted workflow skill available in that neutral provider tree.

## Oracle Priority

1. Filesystem state after sync (`.agents/skills/as-git-commit/SKILL.md`)
2. User-visible sync and status output (`results/tc/03/sync-agents.stdout`, `results/tc/03/status-agents.stdout`)
3. Explicit command exit artifacts (`results/tc/03/sync-agents.exit`, `results/tc/03/status-agents.exit`)
4. Debug fallback captures (`results/tc/03/sync-agents.stderr`, `results/tc/03/status-agents.stderr`) only when primary
   artifacts are ambiguous

## PASS Criteria

- `results/tc/03/sync-agents.exit` is `0`
- `results/tc/03/status-agents.exit` is `0`
- `results/tc/03/sync-agents.stdout` includes `synced agents -> .agents/skills`
- `.agents/skills/as-git-commit/SKILL.md` exists
- `results/tc/03/status-codex.exit` is non-zero and its captured output reports `Unknown provider: codex`, proving the
  runtime does not know a Codex integration provider
- The `agents` row in `results/tc/03/status-agents.stdout` reports equal `EXPECTED`, `INSTALLED`, and `IN_SYNC` counts,
  with `OUTDATED=0`, `MISSING=0`, and `EXTRA=0`
- The same row reports `POLICY=complete` and `EXCLUDED=0`
