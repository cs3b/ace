---
name: reflection
description: Architecture reflection focus for pre-PR self-assessment
last-updated: '2026-02-19'
---

# Architecture Reflection Focus

## Purpose

Self-assessment of implementation before PR creation. Categorize findings into actionable refactoring items vs. acceptable trade-offs.

## Review Requirements

### Over-Engineering Detection
- Unnecessary abstractions (helpers/utilities for one-time operations)
- Premature generalization (configurability nobody asked for)
- Feature flags or backward-compatibility shims when direct changes suffice
- Extra error handling for impossible scenarios
- Layers of indirection that add complexity without value

### Missing Abstractions
- Repeated patterns across 3+ locations that should be extracted
- Inline logic that belongs in a dedicated atom or molecule
- Configuration values hardcoded in multiple places
- Shared behavior duplicated instead of composed

### ATOM Layer Compliance
- Atoms must be pure, stateless, single-responsibility
- Molecules compose atoms with controlled side effects
- Organisms orchestrate molecules for business logic
- No layer-skipping (organisms should not directly use atoms)
- No circular dependencies between layers

### Scope Discipline
- Changes stay within the task scope (no drive-by refactoring)
- No unrelated "improvements" bundled with the implementation
- Comments and docstrings only where logic is non-obvious

## Output Format

Categorize each finding as one of:

### Refactor (actionable, bounded)
Items that should be fixed before shipping. Each must be:
- Concrete (specific file and location)
- Bounded (completable in a single pass)
- Testable (won't break existing tests, or test changes are clear)

### Accept (correct as-is)
Items reviewed and confirmed appropriate:
- Intentional trade-offs with clear reasoning
- Patterns that match project conventions
- Complexity justified by requirements

### Skip (out of scope or too risky)
Items identified but deferred:
- Would require significant rework beyond task scope
- Risk of introducing regressions outweighs benefit
- Better addressed in a dedicated follow-up task
