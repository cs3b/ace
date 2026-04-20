---
id: 8rfnxb
title: E2E Hardening and Release Coordination
type: standard
tags:
  - e2e
  - release
  - test-harness
  - verifier
created_at: "2026-04-16 15:57:01"
status: active
---

# E2E Hardening and Release Coordination

## What Went Well
- Breaking the red suite into `runner/harness`, `test-spec`, and `product-code` issues made the fix order obvious. The highest-leverage work was in shared sandbox/runtime behavior, not in individual scenario files.
- The `ace-test-runner-e2e` sandbox fixes paid off across multiple packages at once. Syncing protocol-source manifests and tightening the shared runner contract removed a class of failures that individual packages could not solve locally.
- Hermetic validator shims for `ace-lint` turned environment-sensitive failures into deterministic coverage. That raised the value of the E2E scenario instead of weakening it.
- Targeted reruns after each fix, followed by `ace-test-e2e-suite --only-failures`, kept the session grounded in current evidence instead of assuming earlier fixes held.
- The release workflow stayed manageable because the package set was scoped to the actual modified directories, then released with coordinated version/changelog updates and path-scoped commit splitting.

## What Could Be Improved
- We still learned about missing workflow-source visibility and PATH/env drift from scenario failures instead of from an explicit E2E preflight. Those checks should fail fast before scenario execution starts.
- Several scenarios were still asserting wording details or end-of-scenario state that later cleanup steps intentionally destroy. That is low-value friction and creates avoidable red builds.
- `ace-task plan` is improved on the failure path, but the E2E still passes on actionable timeout diagnostics rather than on a deterministic success artifact. That leaves one important branch under-covered in integrated testing.
- Root release notes are accumulating repeated category headings and long unreleased sections. Release summaries are still correct, but not especially maintainable.

## Key Learnings
- E2E triage should start with classification, not code changes. If the problem is harness-level, fixing a package first is wasted motion.
- Shared runner prompts are part of the executable contract. Allowing wrapper commands, env resets, or implicit PATH assumptions creates failures that look like product bugs but are really harness defects.
- For dependency-heavy scenarios, hermetic local fixtures are usually more valuable than relying on the operator machine. Scenario-local shims make failures reproducible and make the test teach the right contract.
- Public-surface CLI bugs do show up through E2E and are worth fixing at that layer. The `ace-search --count` and `ace-task plan --timeout` work were real product improvements, not just test cleanup.
- Release prep is safer when version/changelog work is driven from the actual touched package set, not from the full branch history. That avoids accidentally re-releasing already-settled package changes.

## Action Items
- Add an explicit E2E preflight for protocol-source visibility, sandbox runtime PATH/env integrity, tmux socket health, and declared external-tool availability.
- Continue rewriting scenario verifiers toward stable end-state or artifact assertions and away from exact wording checks or post-cleanup assumptions.
- Add a deterministic success-path fixture or stub for `ace-task plan` so E2E covers both bounded success and bounded failure behavior.
- Keep using hermetic validator/provider/tool fixtures for packages that otherwise depend on ambient machine state.
- Revisit the root `CHANGELOG.md` unreleased-section hygiene so coordinated releases remain readable when many packages ship on the same day.
