---
id: 8xf.t.g9s
status: done
priority: medium
created_at: "2026-10-16 10:50:52"
estimate: 
dependencies: []
tags: [design, cli]
---

# Run preset-driven design agents with targeted revisions

## Approved behavior

Implement the user's accepted preset-driven design runner plan: generate runnable site/app mockups from a brief and small shared context through ace-llm coding agents; three default independently configurable variants with extra caller prompts; immutable fixture snapshot; variable-count gallery; dry-run/status/resume/revise/select; failed revisions preserve published artifacts; exact selection hashes; skill and installed CLI adoption. Reuse ACE config and ace-bundle. Exploration remains lightweight. Add owner-level cancellation cleanup if required by the existing provider boundary rather than duplicate subprocess supervision in design.

## Acceptance

- [x] Defaults, custom slots and per-variant caller guidance work through the CLI.
- [x] Shared inputs are frozen once; partial workers and targeted revisions preserve other artifacts.
- [x] Resume, status and explicit hash-bound selection work.
- [x] Provider interruption/timeout cleanup is tested at its owner.
- [x] Updated skills, docs and installed-package checks pass.
- [x] Real three-worker and B-only feedback smoke recorded.
- [x] Independent review, package checks and full suite results recorded; PR updated.
