---

title: Integrate Native Client Review for ace-assign Subtree Pre-Commit
filename_suggestion: feat-assign-subtree-review
enhanced_at: 2026-02-26 03:59:07.000000000 +00:00
location: active
llm_model: pi:glm
id: 8pp5z7
status: pending
tags: []
created_at: '2026-02-26 03:59:06'
source: "user"
---


# Integrate Native Client Review for ace-assign Subtree Pre-Commit

## What I Hope to Accomplish
Integrate fast native client review capabilities (Claude Code's review command or Codex's equivalent) into the `ace-assign work-on subtree` workflow to provide automated review before committing changes. This leverages the deterministic CLI surface that both providers offer, ensuring consistent review quality without additional LLM calls.

## What "Complete" Looks Like
`ace-assign work-on subtree` automatically invokes the appropriate native review command (after identifying available provider capability), reviews the subtree changes, and presents findings before the commit step. The integration uses ace-llm's CLI provider abstraction pattern for seamless switching between Claude Code and Codex.

## Success Criteria
- `ace-assign work-on subtree` detects available native review capability in current CLI provider
- Review runs automatically before commit with configurable skip option
- Review findings presented in structured format compatible with ace-review output
- Configuration cascade (ADR-022) allows per-project review presets
- Tests verify review invocation across both Claude Code and Codex providers

---

## Original Idea

```
ace-assing - work-on subtree should use the /review work in progress before commiting as fast native client review codex / claude have it - we  need check which one have it and use it
```