---
name: quality
description: Quality-focused review - structure, performance, architecture, and standards
last-updated: '2026-02-16'
---

# Quality Focus

## What to Review

### Performance Issues
- Unnecessary allocations, repeated computation, or redundant I/O
- N+1 queries, missing indexes, unoptimized database access
- Missing caching where repeated lookups occur
- Resource leaks (file handles, connections, memory)

### Architecture Compliance
- ATOM layer violations (atoms with side effects, organisms bypassing molecules)
- Circular dependencies between modules or layers
- Components exceeding their single responsibility
- Improper coupling between unrelated subsystems

### Standards Adherence
- Project coding conventions not followed
- Inconsistent patterns compared to surrounding code
- Configuration cascade (ADR-022) not used correctly
- CLI framework patterns (ADR-023) not followed

### Test Coverage Gaps
- New code paths without corresponding tests
- Edge cases exercised in code but not in tests
- Test assertions that don't verify meaningful behavior
- Missing integration tests for cross-component interactions

## DO NOT Review

The following are explicitly out of scope for this review phase:

- **Cosmetic Improvements** — whitespace, formatting, comment rewording
- **Alternative Implementations** — different algorithms or libraries that would also work
- **Polish & Simplification** — renaming for clarity, dead code removal, readability tweaks
- **Documentation Style** — prose quality, markdown formatting, doc organization
