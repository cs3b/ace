# Question: Constraints

## The Question

What constraints must the overseer respect (tooling, compatibility, dependencies)?

## Context

ACE emphasizes CLI-first, agent-agnostic tooling with file-based state. Constraints should be explicit up front.

## Prompts

- Is ace-taskflow integration required or optional?
- Should `ace-overseer` be its own gem or live inside an existing gem?
- Which agents/providers must be supported (Claude, Codex, Gemini)?
- Are there limits on external dependencies?
- Does the design require offline operation?

## Decision Status

- [ ] Pending discussion
- [ ] Decided: _____________
