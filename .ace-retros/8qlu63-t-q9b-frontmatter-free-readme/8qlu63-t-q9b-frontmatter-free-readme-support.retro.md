---
id: 8qlu63
title: t-q9b-frontmatter-free-readme-support
type: standard
tags: [ace-docs, ace-lint, readme]
created_at: "2026-03-22 20:06:47"
status: active
task_ref: t.q9b
---

# t-q9b-frontmatter-free-readme-support

## What Went Well
- Implemented `frontmatter_free` behavior end-to-end across `ace-docs` and `ace-lint` without breaking existing test suites.
- Added focused atoms and tests (`FrontmatterFreeMatcher`, `ReadmeMetadataInferrer`, `GitDateResolver`) that made behavior changes explicit and reviewable.
- Validated the final state with both package tests and `ace-test-suite`, reducing uncertainty before assignment completion.
- Successfully migrated package README files off YAML frontmatter and confirmed `ace-docs status` discovers them as managed `user` docs.

## What Could Be Improved
- `ace-git-commit` failed due provider/network availability, which interrupted the intended scoped commit workflow.
- `ace-task plan t.q9b` stalled in this environment; fallback handling worked but added overhead.
- `ace-docs status` still emits noisy warnings when encountering malformed markdown fixtures in unrelated test directories.

## Key Learnings
- Frontmatter-free document support is safest when path matching is centralized; spreading basename checks across commands leads to drift.
- For README inference, explicit frontmatter precedence must be preserved to avoid backwards-compatibility regressions.
- Release steps that auto-detect from the current diff can become no-op after a clean commit; this should be expected and documented in step reports.

## Action Items
- Continue:
  - Keep behavior changes tied to targeted tests in both affected packages before broad migrations.
- Start:
  - Add resilient fallback behavior in `ace-git-commit` for provider outages (e.g., local deterministic fallback message mode).
  - Harden `ace-task plan` against hangs by surfacing progress or timeout diagnostics earlier.
- Stop:
  - Relying on command-level inference scattered across files; move all frontmatter-free matching to shared helpers.
