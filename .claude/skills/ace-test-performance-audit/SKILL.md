---
name: ace-test-performance-audit
description: Profile tests and document slow cases with actionable fixes
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Bash(ace-nav:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [package | path]
last_modified: 2026-01-31
source: ace-test
---

## Test Performance Audit Workflow

### Step 1: Profile Tests

Run test profiling to identify slow tests:

```bash
ace-test --profile 20 [package]
```

### Step 2: Load Audit Template

Use the performance audit template to document findings:

```bash
ace-bundle tmpl://test-performance-audit
```

### Step 3: Reference Performance Guide

Review the test performance guide for optimization strategies:

```bash
ace-bundle guide://test-performance
```

### Step 4: Document and Track

For each slow test identified:
1. Document current runtime
2. Identify root cause (I/O, fixtures, unnecessary setup)
3. Propose fix with estimated improvement
4. Track in audit report

### Performance Budgets

| Test Layer | Budget | Action |
|------------|--------|--------|
| Atom | <100ms | Mandatory fix if exceeded |
| Molecule | <500ms | Review and optimize |
| Organism | <2s | Consider moving to E2E |
