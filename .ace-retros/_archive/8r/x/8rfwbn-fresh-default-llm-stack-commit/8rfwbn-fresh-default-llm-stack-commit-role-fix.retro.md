---
id: 8rfwbn
title: Fresh-Default LLM Stack Commit Role Fix
type: standard
tags: [llm, release, e2e, config]
created_at: "2026-04-16 21:32:57"
status: active
---

# Fresh-Default LLM Stack Commit Role Fix

## What Went Well
- The failure was narrowed to the correct layer. `TS-COMMIT-001` looked like an `ace-git-commit` bug at first, but the evidence showed the split logic was fine and the real break was in fresh-default LLM config resolution.
- Comparing the sandbox-generated `.ace/llm/*` files with the repo's checked-in `.ace` overrides exposed the exact drift quickly. That turned a vague provider-availability failure into a concrete config/catalog mismatch.
- Fixing shipped defaults instead of weakening the scenario preserved the value of the E2E. The test still proves that a fresh `ace-config init` project can generate commit messages and execute split/no-split commit flows.
- Updating fast tests in `ace-llm` and `ace-llm-providers-cli` alongside the config changes gave fast local proof before spending time on the E2E rerun.
- The targeted rerun discipline held: one scenario rerun, `ace-test-e2e ace-git-commit TS-COMMIT-001`, was enough to confirm the fix and avoid a noisy broader suite pass.

## What Could Be Improved
- The repo's project-level `.ace` overrides had already moved ahead of the shipped `.ace-defaults`, but there was no release gate catching that divergence before it broke a fresh-sandbox path.
- The initial symptom was downstream and misleading. A commit-generation E2E failure obscured the fact that the real problem was stale provider aliases and role order in fresh defaults.
- The provider surface was split across YAML defaults and hardcoded client model lists. That means a partial update can leave the public surface internally inconsistent even when one side looks current.
- We only added the fresh-default regression assertions after the E2E failed. A dedicated default-surface check should have existed before the release path depended on it.

## Key Learnings
- Fresh-project E2Es are testing a different contract than local-repo execution. If a scenario starts from `ace-config init`, the source of truth is the shipped `.ace-defaults` tree, not the repo's checked-in `.ace` overrides.
- Project overrides can mask released-default bugs. Local development can look healthy while new sandboxes still bootstrap stale aliases, stale roles, or missing fallback targets.
- Provider metadata has to move as one surface: role order, provider YAML aliases, and client hardcoded model catalogs must stay aligned or the fallback path becomes misleading and brittle.
- When an E2E failure shows provider/model errors after setup, inspect the generated sandbox config first. That is often higher signal than changing the scenario or treating the failure as a harness problem.

## Action Items
- Add a release-time check that compares overlapping project `.ace` LLM overrides against shipped `.ace-defaults` for role order and provider alias drift.
- Keep direct fast tests that read `.ace-defaults/llm/providers/*.yml` and assert current Codex/Gemini aliases so config drift is caught before E2E.
- Keep one fresh-default scenario like `TS-COMMIT-001` exercising generated commit messages without explicit `-m`, because that is what caught the real release bug here.
- When triaging similar failures, compare sandbox `.ace` contents to repo-level overrides before changing product logic or scenario expectations.

## Technical Details
- The failing path in a fresh sandbox resolved `role:commit` through shipped defaults to `codex:mini`, which still mapped to `gpt-5-mini`. In this environment that model was rejected by Codex, and the Gemini fallback path also depended on aliases not present in the shipped defaults.
- The fix shipped as `ace-llm v0.36.1` and `ace-llm-providers-cli v0.31.2`, with `TS-COMMIT-001` rerunning cleanly at `7/7` after the default-stack update.

## Additional Context
- Release commits:
  - `5acf8a1aa fix(ace-llm): adjust commit role default fallback`
  - `2b409c9b0 fix(ace-llm-providers-cli): update model catalog and provider aliases`
  - `454118906 docs(project default): update global changelog and dependency versions`

## Action Items
