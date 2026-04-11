---
name: as-test-verify-suite
description: Run modified-package deterministic verification plus the default fast monorepo suite
# bundle: wfi://test/verify-suite
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
argument-hint: [package | path | mode:quick|standard|deep]
last_modified: 2026-01-31
source: ace-test
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
assign:
  steps:
    - name: verify-test-suite
      description: Run modified-package deterministic verification plus the default fast monorepo suite
      intent:
        phrases:
          - "run tests"
          - "run test suite"
          - "verify tests"
          - "test changes"
          - "check tests"
      prerequisites:
        - name: work-on-task
          strength: recommended
          reason: "Should have code changes to verify"
      produces: [test-results]
      consumes: [code-changes]
      context:
        default: null
        reason: "Test execution needs access to project environment"
      when_to_skip:
        - "No code changes that could affect tests (documentation-only)"
        - "Tests were already run and profiled in a previous step"
      effort: light
      tags: [testing, verification, performance]
skill:
  kind: workflow
  execution:
    workflow: wfi://test/verify-suite
---

Load and run `ace-bundle wfi://test/verify-suite` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
