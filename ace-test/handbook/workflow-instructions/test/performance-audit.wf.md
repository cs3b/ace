---
name: test-performance-audit
description: Profile tests and document slow cases with actionable fixes
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: "[package | path]"
doc-type: workflow
purpose: test performance audit workflow
---

# Test Performance Audit Workflow

## Instructions

1. Run `ace-test --profile 20 $ARGUMENTS`.
2. Read `tmpl://test-performance-audit` and use it to structure findings.
3. Read `guide://test-performance` for optimization guidance.
4. Document slow tests, root causes, and proposed fixes.
