---
name: correctness
description: Correctness-focused review - logic errors, missing functionality, and bugs
last-updated: '2026-02-16'
---

# Correctness Focus

## What to Review

### Logic Errors & Bugs
- Off-by-one errors, boundary conditions, nil/null handling
- Incorrect boolean logic, missing negations, wrong operators
- Race conditions and concurrency issues
- Infinite loops or unreachable code paths
- Type mismatches and coercion errors

### Missing Functionality
- Unhandled edge cases specified in requirements
- Missing return values or incomplete branches
- Required validations that are absent
- Promised behavior not implemented

### Error Handling
- Exceptions that are swallowed silently
- Missing error handling for I/O, network, or system calls
- Error messages that leak internal details
- Recovery paths that leave state inconsistent

### Security-Affecting Issues
- Input that reaches dangerous operations unsanitized
- Path traversal or injection vectors
- Secrets or credentials exposed in code or logs
- Missing authentication or authorization checks

### Contract Violations
- Method signatures that don't match their callers
- API responses that deviate from documented contracts
- Broken invariants or preconditions
- Interface implementations that violate expectations

## DO NOT Review

The following are explicitly out of scope for this review phase:

- **Style & Formatting** — indentation, whitespace, brace placement
- **Performance Optimization** — algorithm efficiency, caching, query tuning
- **Naming Conventions** — variable names, method names, class names
- **Documentation Completeness** — missing docs, comment quality, README updates
- **Refactoring Suggestions** — alternative designs, DRY improvements, simplification
- **Alternative Approaches** — different libraries, patterns, or architectures
