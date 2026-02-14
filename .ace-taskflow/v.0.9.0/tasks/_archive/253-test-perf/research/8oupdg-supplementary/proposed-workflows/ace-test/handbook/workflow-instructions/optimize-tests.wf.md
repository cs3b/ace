---
name: optimize-tests
description: Refactor slow tests to restore fast-loop performance
allowed-tools: Read, Write, Edit, Bash
argument-hint: [package | path]
doc-type: workflow
purpose: Test performance optimization
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Optimize Tests Workflow Instruction

## Goal

Reduce test runtime by removing IO leaks, eliminating zombie mocks, and moving real IO to E2E tests.

## Steps

1. **Profile**: `ace-test --profile 10` and capture slow tests
2. **Identify IO leaks**:
   - subprocess calls (Open3/system)
   - filesystem IO
   - network calls
   - sleeps in retries
3. **Fix patterns**:
   - Stub outer boundary (`available?`, guard checks)
   - Pre-warm caches in test helper
   - Replace mock expectations with behavior assertions
   - Build composite helpers for nested stubs
4. **Migrate to E2E**:
   - Keep one E2E per critical workflow
   - Move CLI/integration permutations to unit tests
5. **Verify**: re-run `ace-test --profile 10` and confirm <100ms rule

## Output

Document changes and performance improvement in the task or audit report.
