---
id: 8qun8n
title: ace-config-migration-batch-8qu-t-jdt
type: standard
tags: [batch, config, migration]
created_at: "2026-03-31 15:29:37"
status: active
---

# Batch Retro: ace-config CLI Migration (8qu.t.jdt)

**Scope**: Tasks `8qu.t.jdt.0` (add ace-config CLI to ace-support-config) and `8qu.t.jdt.1` (remove ace-framework from ace-support-core)
**Branch**: `j24-new-project-onboarding-hardening-rollout`
**PR**: #273

## What Went Well

- **Clean two-task split**: Separating "add" (jdt.0) from "remove" (jdt.1) into sequential fork subtrees prevented conflicts and made each step's scope clear.
- **Fork agents delivered complete commits**: Both subtrees produced well-scoped conventional commits with test verification evidence; no orphaned changes found after fork-run.
- **Tests passed across both packages**: 276 tests (ace-support-config) and 192 tests (ace-support-core), 0 failures after each task — no regressions introduced.
- **Review cycles were productive**: The valid cycle caught 4 real issues (CLI flag wiring, cache isolation, bundler dep, bootstrap preset), all fixed before merge.
- **Delegation + guard loop worked smoothly**: The driver→fork-run→subtree-guard pattern with report review caught the malformed CHANGELOG entry (0.29.5 content left under [Unreleased]) before advancing.

## What Could Be Improved

- **CHANGELOG formatting in fork releases**: The 010.02.07 fork agent bumped the version number but placed release content under `[Unreleased]` instead of creating a `[0.29.5]` dated section. The driver had to patch this in step 020. Fork agents should validate CHANGELOG structure before marking release steps done.
- **verify-e2e (step 015) fork timeout**: The Codex provider timed out at 1800s on a step where the actual work was a no-op (no E2E scenarios in the modified packages). The fork agent should detect the skip condition early rather than exhausting the provider timeout.
- **ace-task plan stall**: Fork agent for jdt.0 reported that `ace-task plan` stalled and had to fall back to inline spec reading. This suggests a provider/tool reliability issue that should be investigated separately.

## Key Learnings

- **Skip-condition detection should precede fork delegation**: Before delegating a fork step that may be a no-op (like verify-e2e), the driver can pre-check the skip condition (e.g., `find <pkg>/test/e2e -name scenario.yml | wc -l`) and short-circuit without a full fork-run.
- **CHANGELOG promotion must be validated post-release**: Release steps should verify that the resulting CHANGELOG has a versioned section (not just updated [Unreleased]) before marking done. A quick `grep -m2 "## \[" CHANGELOG.md` check is sufficient.
- **Review cycle circuit breaker was not needed**: All 3 review providers succeeded in this batch. The circuit breaker logic (skip fit/shine if valid failed) was not triggered.

### Review Cycle Analysis

- **valid (040)**: 4 valid items applied (CLI flag wiring, ConfigTemplates.reset!, bundler dep, bootstrap preset self-containment), 4 low-priority skipped. ace-support-config released as v0.10.1.
- **fit (070)**: 1 valid item (Gemfile group scanning gap in rubygems-verify-install workflow), no package release needed.
- **shine (100)**: 13 items reviewed, none required new code changes. 3 packages released: ace-bundle v0.41.2, ace-llm v0.31.3, ace-support-config v0.10.2.
- **False positive rate**: Low across all cycles. Most skips were low-priority style/doc suggestions.
- **Cross-cycle pattern**: Correctness issues (valid cycle) were structural (flag wiring, test isolation). Fit/shine cycles caught workflow and documentation gaps, not code bugs.

## Action Items

- **Stop**: Accepting fork release steps as done without checking CHANGELOG section format (`## [X.Y.Z] - date` vs content under `[Unreleased]`).
- **Continue**: Pre-checking skip conditions before launching fork-runs for gate steps (e2e, test-suite).
- **Start**: Adding a CHANGELOG structure validation step to the release workflow that verifies no content remains under `[Unreleased]` after a version bump.
