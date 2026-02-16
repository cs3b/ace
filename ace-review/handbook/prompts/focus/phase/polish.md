---
name: polish
description: Polish-focused review - simplification, clarity, and readability suggestions
last-updated: '2026-02-16'
---

# Polish Focus

> **ALL findings in this review are NON-BLOCKING suggestions.**
> Nothing here should prevent merge. These are opportunities to improve clarity,
> reduce complexity, or clean up after the functional work is complete.

## Suggestions for Improvement

### Simplification Opportunities
- Code that could be expressed more concisely without losing clarity
- Overly defensive checks that duplicate validations done elsewhere
- Abstractions that add indirection without adding value
- Conditional chains that could be simplified with guard clauses or early returns

### Naming Clarity
- Variables, methods, or classes whose names don't convey their purpose
- Abbreviations that reduce readability
- Boolean methods missing `?` suffix (Ruby convention)
- Names that are technically accurate but misleading in context

### Dead Code & Duplication
- Unreachable code, unused variables, or commented-out blocks
- Duplicated logic that could be extracted into a shared method
- Imports or requires that are no longer needed
- TODO/FIXME comments that refer to completed work

### Documentation Gaps
- Public methods or APIs missing documentation
- Complex logic that would benefit from an explanatory comment
- Missing or outdated inline examples
- CHANGELOG entries that should accompany the change

### Readability
- Long methods that could be broken into well-named smaller methods
- Deeply nested conditionals that obscure the main flow
- Magic numbers or strings that should be named constants
- Inconsistent ordering of method definitions (public before private)
