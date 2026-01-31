---
name: test-layer-decision
description: Decision matrix for choosing unit vs integration vs E2E tests
doc-type: guide
purpose: Test layer selection
search_keywords:
  - test layer decision
  - unit vs integration vs e2e
  - test pyramid
  - layer matrix
update:
  frequency: on-change
  last-updated: '2026-01-31'
---

# Test Layer Decision Guide

Use this guide to choose the lowest test layer that can validate a behavior.

## Core Rule

**Start with unit tests** and only move up layers when the lower layer cannot prove the behavior.

## Decision Matrix

| Question | Unit | Integration | E2E |
|----------|------|-------------|-----|
| Needs real filesystem? | No (mock) | Sometimes (temp dir) | Yes |
| Needs real git? | No (MockGitRepo) | Rarely | Yes |
| Needs subprocess? | Never | Stub | Yes |
| External API? | WebMock | WebMock | Yes (safe) |
| CLI parity? | No | One per file | Yes |

## What to Test Where

### Unit (atoms/molecules)
- Pure logic, parsing, transformations
- Edge cases and error handling
- Configuration parsing
- **No IO**

### Integration (organisms)
- Component orchestration
- Error propagation
- One CLI parity test per file
- **Stub external dependencies**

### E2E
- Critical user workflows
- Tool availability validation
- Real external APIs (sandboxed)
- Complex environment setup

## E2E Reduction Rule

Keep **one E2E per critical workflow**. Do not test flag permutations or edge cases in E2E.

## See Also

- Test Responsibility Map
- Test Review Checklist
- E2E Testing Guide
