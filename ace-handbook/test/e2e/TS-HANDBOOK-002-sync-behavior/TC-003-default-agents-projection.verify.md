# Goal 3 Verification - Default agents projection includes legacy workflow skills

## Expectation

Plain `ace-handbook sync` exits successfully, writes the default projection to `.agents/skills`, and makes a
legacy-targeted workflow skill available in that neutral provider tree.

## Oracle Priority

1. Filesystem state after sync (`.agents/skills/as-git-commit/SKILL.md` when the full ACE stack is present, or
   another installed common ACE workflow skill that targets `claude`, `codex`, `gemini`, `opencode`, and `pi`)
2. User-visible sync and status output (`results/tc/03/sync-agents.stdout`, `results/tc/03/status-agents.stdout`)
3. Explicit command exit artifacts (`results/tc/03/sync-agents.exit`, `results/tc/03/status-agents.exit`)
4. Debug fallback captures (`results/tc/03/sync-agents.stderr`, `results/tc/03/status-agents.stderr`) only when primary
   artifacts are ambiguous

## PASS Criteria

- `results/tc/03/sync-agents.exit` is `0`
- `results/tc/03/status-agents.exit` is `0`
- `results/tc/03/sync-agents.stdout` includes `synced agents -> .agents/skills`
- `.agents/skills/as-git-commit/SKILL.md` exists when `ace-git-commit` skills are installed in the sandbox
- If `as-git-commit` is not installed in the sandbox, at least one installed common workflow skill from the legacy
  full-provider target set exists under `.agents/skills`
- `results/tc/03/status-agents.stdout` does not report the projected legacy-targeted workflow skill as an extra entry
