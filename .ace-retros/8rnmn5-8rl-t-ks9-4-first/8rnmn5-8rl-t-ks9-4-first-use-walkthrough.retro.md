---
id: 8rnmn5
title: 8rl-t-ks9-4-first-use-walkthrough
type: standard
tags: []
created_at: "2026-04-24 15:05:44"
status: active
---

# 8rl-t-ks9-4-first-use-walkthrough

## What Went Well
- The task stayed focused on the public contract instead of inventing new setup behavior. Updating the shipped `AGENTS.md` and `CLAUDE.md` templates plus the bootstrap feature test closed the main acceptance gap with a small code surface.
- Existing package E2E coverage was already strong enough to reuse. Tightening the `ace-llm` provider-discovery verifier was cheaper and safer than creating a new end-to-end scenario from scratch.
- The assignment subtree structure worked cleanly once the scoped queue was restarted inline, and the release step produced a clean package-scoped commit set without dragging unrelated branch work into the release set.

## What Could Be Improved
- The task bundle still referenced renamed `config_initializer` files and the older `ace-config init` command shape. That stale context cost time during planning and made it easy to target the wrong owner files.
- The release workflow's default auto-detect rule is too broad inside a long-lived branch with earlier sibling releases already present. Explicit package selection was necessary to avoid accidental rereleases.
- The native `/review` path was unavailable in this environment, so the pre-commit review step had to fall back to linting. That kept progress moving, but it is a weaker signal than a true issue-focused review pass.

## Key Learnings
- Fresh-repo setup guidance needs two layers of protection: the visible docs and the generated bootstrap files themselves. If only the docs carry provenance/customization rules, `ace-config sync` can still emit starter files that undercut the published contract.
- Public-surface setup tasks should treat package-owned E2E verifiers as the first place to encode observable distinctions such as discovery versus readiness. That keeps the acceptance contract closer to the command users actually run.
- When a task spec names a public command that has since been renamed, the implementation plan should record that mismatch explicitly instead of silently mixing old and new command forms.

## Action Items
- Keep task bundles in sync with renamed owner files when package refactors move bootstrap logic; stale file references should be caught during task review, not implementation.
- Prefer explicit package arguments for subtree release steps when the branch already contains earlier released sibling work.
- If native pre-commit review remains unavailable in this execution path, consider adding a stronger deterministic fallback than lint-only review for docs/test-heavy tasks.
