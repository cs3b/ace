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

- [x] Decided: **Minimal, independent gem**

| Constraint | Decision |
|------------|----------|
| ace-taskflow integration | Optional - coworker defines its own schema/documents |
| Package | New gem: `ace-coworker` |
| Agent support | Any agent that can run CLI + read files. Thin skill layer for workflows. |
| Dependencies | Minimal (Ruby stdlib + ace-support-*) |
| Offline | Not our concern - agents use LLMs, if LLM is offline we work offline |
