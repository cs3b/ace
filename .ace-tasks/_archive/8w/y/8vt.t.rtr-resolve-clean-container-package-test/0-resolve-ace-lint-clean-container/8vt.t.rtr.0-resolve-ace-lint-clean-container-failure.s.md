---
id: 8vt.t.rtr.0
status: pending
priority: high
created_at: "2026-08-30 18:33:07"
estimate: TBD
dependencies: []
tags: [ace-lint, ci, testing, containers]
parent: 8vt.t.rtr
coordination:
  work: W402
  project: ace
  parent_task: 8vt.t.rtr
bundle:
  presets: [project]
  files: [ace-lint/lib/ace/lint/organisms/lint_doctor.rb, ace-lint/lib/ace/lint/atoms/config_locator.rb, ace-lint/lib/ace/lint/atoms/validator_registry.rb, ace-lint/lib/ace/lint/atoms/skill_schema_loader.rb, ace-lint/test/fast/organisms/lint_doctor_test.rb, ace-lint/test/fast/organisms/lint_orchestrator_test.rb]
  commands: [bundle exec bin/ace-test ace-lint fast, bundle exec bin/ace-test ace-lint all]
needs_review: false
---

# Resolve ace-lint clean-container failure

## Behavioral Specification

### User Experience

- **Input:** A developer or CI runner executes `bundle exec bin/ace-test ace-lint all` inside a clean container environment (e.g. `docker.io/library/ruby:3.4`) where optional external linting gems (such as standalone `rubocop` or `standardrb` system binaries) may not be pre-installed in the global PATH or where schema/config caches are evaluated without local project overrides.
- **Process:** `ace-lint` runs its diagnostic organisms and linters, discovering fallback configurations and validating availability through the `ValidatorRegistry` and `ConfigLocator` without unhandled errors, assertion failures, or stale cache pollution across test runs.
- **Output:** All fast and integration test suites in `ace-lint` pass cleanly (0 failures, 0 errors), reporting accurate diagnostic states.

### Expected Behavior

- `LintDoctor` diagnostics handle environments with missing or partially installed external validators gracefully, returning structured warning/info diagnostics without organism test failure.
- `ConfigLocator` and `SkillSchemaLoader` resolve gem defaults and fallback directories reliably across isolated temporary directories and clean container checkouts.
- Tests in `test/fast/organisms/lint_doctor_test.rb` and `test/fast/organisms/lint_orchestrator_test.rb` isolate setup/teardown state and stub external tools properly.
- Linting functionality for markdown, YAML, frontmatter, skills, workflows, and agents remains fully intact.

### Interface Contract

```bash
# Package test execution
bundle exec bin/ace-test ace-lint fast
bundle exec bin/ace-test ace-lint all

# CLI diagnostic interface
bundle exec bin/ace-lint doctor [--json]
```

**Error Handling:**
- Missing optional external validator tools are reported as `:unavailable` warnings in diagnostics rather than causing unhandled crashes or erroneous test assertion failures.

**Edge Cases:**
- Execution inside clean container with minimal gem set.
- Execution from arbitrary working directories (`Dir.chdir` in test temp dirs).
- Repeated test execution in same Ruby VM (cache isolation).

## Success Criteria

- [ ] **Exact Reproduction Resolved**: The organism test failure observed in Forgejo Actions Run 15 (`test (ace-lint)`) is resolved.
- [ ] **Clean Container Verification**: `bundle exec bin/ace-test ace-lint all` passes with 0 failures and 0 errors inside an isolated container.
- [ ] **No Weakened Lint Rules**: Markdown, YAML, and skill schema linting rules and contracts remain strict and unchanged.
- [ ] **Deterministic Isolation**: Tests do not leak cache state across test runs.

## Exact Reproduction Evidence

- **Forgejo CI Run**: Actions Run 15 (DB ID 17) on PR #4 (`admin/W400-forgejo-ci`).
- **Failing Job**: `test (ace-lint)`.
- **Symptom**: 1 organism test failure in `ace-lint` when executed on `docker.io/library/ruby:3.4`.
- **Root Cause**: `LintDoctorTest` / `LintOrchestrator` diagnostics and schema resolution encountering unhandled tool availability states or cache resolution issues in clean container environment without external tools pre-installed.

## Required Package Tests

- `ace-test ace-lint fast` (Atoms, Molecules, Organisms, Commands)
- `ace-test ace-lint all`

## Clean-Container Verification

- Run `bundle exec bin/ace-test ace-lint all` in a clean container without host volume mounts.

## Assignment and Review Expectations

- **Assignee / Work**: Assigned to builder Work `W402` under parent `W401`.
- **Workflow**: Builder adopts task spec via `ace-task:ace/8vt.t.rtr.0`, uses `/as-assign-drive`, scopes changes strictly to `ace-lint`, provides fast/all test proofs, passes clean-context review, and opens a Forgejo PR.

## Relationship to Parent

- Vertical slice 1 of 4 under orchestrator `8vt.t.rtr` (Work W401).

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator subtask (Slice 1 of 4)
- **Slice Outcome**: `ace-lint` passes all tests cleanly in container environments
- **Advisory Size**: Medium
- **Context Dependencies**: `ace-lint` diagnostic organisms and config locators

## Verification Plan

### Unit / Component Validation
- Run `bundle exec bin/ace-test ace-lint fast`

### Integration / E2E Validation
- Run `bundle exec bin/ace-test ace-lint all`

### Failure / Invalid-Path Validation
- Verify missing tool diagnostics correctly produce `:unavailable` warnings without crashing.

### Verification Commands
- `bundle exec bin/ace-test ace-lint all`

## Objective

Fix the `ace-lint` organism test failure in clean container environments, ensuring the package test suite is green on Forgejo Actions CI.

## Scope of Work

- Fix diagnostic / cache / availability handling in `ace-lint` organisms and tests.
- Verify all 24 test files in `ace-lint` pass cleanly.

## Deliverables

### Behavioral Specifications
- Clean container test pass for `ace-lint`.

### Validation Artifacts
- Test execution output showing 0 failures, 0 errors.

## Out of Scope

- Changes to other ACE packages.
- Changes to CI workflow configuration.

## References

- Parent task: `8vt.t.rtr`
- W400 report: `/lab/state/admin/tasks/W400/report.md`
- Forgejo PR #4 Run 15
