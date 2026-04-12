---
id: 8quwjc
title: monorepo-e2e-quickstart-verification
type: standard
tags: [e2e, monorepo, quickstart, rubygems]
created_at: "2026-03-31 21:41:30"
status: active
---

# Monorepo E2E Quick-Start Verification

Context: Converted the `rubygems-verify-install` workflow to an E2E scenario, created a new quick-start doc validation scenario, and established `ace-monorepo-e2e/` as the home for cross-cutting monorepo-level E2E tests.

## What Went Well

- **Auto-discovery works out of the box.** `TestDiscoverer#list_packages` uses a generic `*/test/e2e/TS-*/scenario.yml` glob — no framework changes were needed to add `ace-monorepo-e2e` as a new "package" for E2E purposes.
- **TS-MONO-001 fully replaces the workflow.** The RubyGems install verification E2E scenario produces the same SAFE/LAG_DETECTED/METADATA_BROKEN classification as the old workflow, but with deterministic runner/verifier separation and repeatable execution via `ace-test-e2e`.
- **TS-MONO-002 caught a real setup gap.** The quick-start doc validation revealed that `ace-nav` and `ace-bundle project` require `ace-config init` + `ace-handbook sync` to work in a fresh project — a prerequisite that was documented in quick-start.md but not enforced by the test setup. Adding those steps to `scenario.yml` setup fixed all 4 TCs.
- **Classification result confirmed SAFE.** The 37-gem install from RubyGems.org succeeded on both normal and `--full-index` paths, producing a valid proof artifact with Ruby 3.4.8.

## What Could Be Improved

- **First runs used wrong provider flags.** Running with `--provider claude:sonnet` without `--cli-args dangerously-skip-permissions` caused the runner agent to be blocked on every command. The default `claude:haiku@yolo` already includes permission bypass via `@yolo`. This cost two full timeout cycles (~20 min) before the root cause was identified from the runner output file.
- **TS-MONO-001 needs a higher timeout.** The default 600s is too short for `bundle install` with 37 gems from RubyGems.org. The successful run used `--timeout 1200`. The scenario should document the recommended timeout or the E2E framework should support a `timeout:` field in `scenario.yml`.
- **Over-scoped initial delivery.** The first iteration included a per-package getting-started scenario for `ace-b36ts` (TS-B36TS-002) that was out of scope for the ask. It was created and then removed after user feedback. Should have started with just the two monorepo-level scenarios.
- **Runner output diagnosis was slow.** When the runner produced zero artifacts, the root cause wasn't immediately obvious from the summary report. Had to dig into `.ace-local/e2e/runner-output.md` to find the permission-blocked explanation. The report could surface runner-side errors more prominently.

## Key Learnings

- **Verification workflows vs operational workflows:** The distinction rule is clean — "does X work?" maps to E2E, "do X" stays as workflow. Only `rubygems-verify-install` was a verification concern; the other 4 release workflows (`publish`, `bump-version`, `rubygems-publish`, `update-changelog`) are operational and correctly remain as workflows.
- **Sandbox setup must mirror the real user path.** TC-003 failed because the sandbox skipped `ace-config init` and `ace-handbook sync` — steps that a real user would run before `ace-nav`. E2E tests that validate documentation must follow the documented prerequisite chain, not shortcut past it.
- **`@yolo` suffix on provider names is the E2E permission mechanism.** The `claude:haiku@yolo` default handles permission bypass for the runner agent subprocess. Using a bare provider name (e.g., `claude:sonnet`) requires explicit `--cli-args dangerously-skip-permissions`.

## Action Items

- **Continue:** Using `ace-monorepo-e2e/` for cross-cutting E2E scenarios that don't belong to any single package.
- **Start:** Adding `timeout:` to `scenario.yml` for TS-MONO-001 so the E2E runner can automatically use a higher timeout for network-dependent scenarios.
- **Start:** Documenting the `@yolo` provider suffix requirement in the E2E testing guide so future scenario authors don't hit the same permission issue.
- **Stop:** Creating per-package getting-started scenarios without explicit user request — keep scope tight to the monorepo-level ask.
