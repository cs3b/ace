---
id: 8qp2t2
title: 8qp-t-1fn-0-markdown-fix-surgical-release
type: standard
tags: [ace-lint, assignment, retro]
created_at: "2026-03-26 01:52:18"
status: active
---

# 8qp-t-1fn-0-markdown-fix-surgical-release

## What Went Well

- The assignment loop stayed scoped to `8qp26s@010.01` and advanced cleanly through each step with explicit reports.
- The implementation split markdown fix behavior into a dedicated surgical molecule and kept kramdown formatting isolated behind guardrails, which reduced coupling and made tests straightforward.
- Quality gates were run at each stage: focused tests, full `ace-test ace-lint`, fallback pre-commit lint gate, and profile-guided verification.
- Release flow completed without manual clean-up: package changelog/version, root changelog, and lockfile updates were committed with a clean tree.

## What Could Be Improved

- The pre-commit review step landed after implementation commits, so there were no uncommitted changes to inspect with a native reviewer; this reduces the value of that gate.
- The release commit split by scope (`ace-lint` and root metadata) via `ace-git-commit`; a single coordinated commit would be clearer for traceability when required by workflow wording.
- One task verification checkbox (`ace-lint --fix ace-assign/**/*.md && git diff`) stayed intentionally unchecked to avoid large unrelated file mutations; this should be handled with a controlled fixture corpus instead.

## Key Learnings

- Surgical markdown fixes are safest when driven by explicit context boundaries (frontmatter, fenced code blocks, inline code spans) rather than parser round-trips.
- Guardrail checks (frontmatter, fence counts, table rows, HTML attribute drift) provide a practical safety boundary for optional full-format operations.
- For assignment-driven work, using path-scoped commits and frequent status checks keeps subtree execution deterministic and easier to recover.

## Action Items

### Stop

- Stop relying on broad real-repo fix commands as verification gates when they can mutate unrelated packages.

### Continue

- Continue using focused molecule/orchestrator tests plus full package suite verification before release.
- Continue writing explicit per-step assignment reports with command evidence and artifact paths.

### Start

- Start adding a dedicated markdown-fixture corpus for structural-preservation checks so the unchecked `ace-assign/**/*.md` verification can be replaced with deterministic test coverage.
- Start running a pre-commit review snapshot against staged/last-commit diffs when native `/review` is unavailable.
