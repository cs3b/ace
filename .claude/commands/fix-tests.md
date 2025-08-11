---
description: Fix Tests
allowed-tools: Read, Write, Edit, Bash, Grep, Task, TodoWrite, MultiEdit
model: claude-4-1-sonnet-latest
last_modified: '2025-08-11 22:45:00'
source: custom
---

# Fix Test Failures

Systematically diagnose and fix failing automated tests following the fix-tests workflow.

## Process

1. **Load workflow instructions**
   - Read dev-handbook/workflow-instructions/fix-tests.wf.md
   - Follow the systematic approach defined there

2. **Analyze failures**
   - Identify test failure patterns
   - Check recent changes that might have caused failures
   - Understand the root cause

3. **Fix iteratively**
   - Fix one failure at a time
   - Verify each fix before moving to next
   - Run related tests to ensure no regressions

4. **Final verification**
   - Run full test suite
   - Ensure all tests pass
   - Commit fixes if requested

## Usage

Pass the test output or specific failure information as arguments.

Example:
```
/fix-tests "3 failures in RipgrepExecutor specs"
```
