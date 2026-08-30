---
priority: high
---

# Resolve clean-container package test failures

## Behavioral Specification

### User Experience

- **Input:** A CI workflow (Forgejo Actions on PR/push) or local containerized test runner executes the ACE test matrix across all 43 package suites inside standard clean Docker containers (e.g. `docker.io/library/ruby:3.4`).
- **Process:** The inventory and matrix runner dispatches isolated container test jobs for all packages. Each package suite executes its fast, feat, and e2e tests without depending on host workspace artifacts, non-container PID assumptions, or unhandled root/DAC permission overrides.
- **Output:** All 43 package matrix jobs complete successfully (0 failures, 0 errors), allowing the deterministic `Test Summary` gate to pass cleanly (46/46 jobs green).

### Expected Behavior

- The four failing package suites identified in W400 / Forgejo Actions Run 15 (`ace-lint`, `ace-llm-providers-cli`, `ace-support-config`, `ace-support-core`) pass deterministically inside clean containers.
- Each defect is resolved at the package source/test level by dedicated child Works (W402–W405) without weakening test assertions or altering CI workflow security constraints.
- Process group isolation and cleanup in `SafeCapture` operate safely in container PID namespaces without orphaned background processes.
- Permission edge-case tests in `ace-support-config` and `ace-support-core` handle container environments (including root UID execution) correctly.
- Linter diagnostic and configuration resolution in `ace-lint` function reliably when optional external tools are not pre-installed.
- Overseer task `8vc.t.m21` integration gates and delivery milestones are preserved.

### Interface Contract

```bash
# Matrix inventory verification
ruby .ace-bin/ci_package_inventory.rb

# Per-package test execution (runs identically on host and container)
bundle exec bin/ace-test ace-lint all
bundle exec bin/ace-test ace-llm-providers-cli all
bundle exec bin/ace-test ace-support-config all
bundle exec bin/ace-test ace-support-core all

# Full suite execution
bundle exec bin/ace-test-suite --target all
```

**Error Handling:**
- Package failures in any matrix job fail that specific job and cause `Test Summary` to fail closed.
- Subprocess timeouts and termination errors provide actionable stderr and error messages rather than hanging or leaving zombies.

**Edge Cases:**
- Execution as UID 0 (root inside Docker container) vs unprivileged host user.
- Container PID namespace where PID 1 is runner init or shell wrapper.
- Missing optional external validator binaries (standardrb/rubocop gems) in clean container.

## Success Criteria

- [ ] **Clean Container Matrix 43/43**: All 43 ACE packages pass tests in isolated `docker.io/library/ruby:3.4` container runs.
- [ ] **Four Subtasks Reviewed and Dispatched**: Subtasks `8vt.t.rtr.0`, `8vt.t.rtr.1`, `8vt.t.rtr.2`, `8vt.t.rtr.3` are decision-complete, reviewed, and usable as sources for W402–W405.
- [ ] **Zero CI Weakening**: No test checks, security boundaries, or fail-closed gates are disabled or relaxed in `.forgejo/workflows/test.yml`.
- [ ] **Deterministic Summary Gate**: Forgejo Actions PR #4 retest passes all 46 jobs (inventory + 43 packages + projection contract + test summary).

## Validation Questions

- **Q1: Should CI workflow definitions be altered to work around baseline failures?**
  - *Decision*: No. The CI workflow in PR #4 is working correctly; the failures represent legitimate baseline defects that must be resolved in package code/tests via separate builder Works.
- **Q2: How are the 4 fixes integrated?**
  - *Decision*: Each builder Work (W402–W405) branches from its reviewed ACE subtask, opens a Forgejo PR, and is reviewed before integration into `main`.

## Vertical Slice Decomposition (Task/Subtask Model)

| Slice | Subtask Ref | Target Work | Outcome | Advisory Size | Depends On |
| --- | --- | --- | --- | --- | --- |
| 1 | `8vt.t.rtr.0` | W402 | `ace-lint` clean-container diagnostics and organism test stability | Medium | — |
| 2 | `8vt.t.rtr.1` | W403 | `ace-llm-providers-cli` `SafeCapture` process group cleanup in container PID namespace | Medium | — |
| 3 | `8vt.t.rtr.2` | W404 | `ace-support-config` permission error assertions with container root compatibility | Small | — |
| 4 | `8vt.t.rtr.3` | W405 | `ace-support-core` IO error assertions with container root compatibility | Small | — |

## Concept Inventory

| Concept | Inputs | Outputs | Owner Layer |
| --- | --- | --- | --- |
| Containerized Matrix Testing | Package inventory, container runner | Per-package test status | CI / Test Runner |
| Process Tree Cleanup | Subprocess PID, PGID, timeout | Terminated process group | `ace-llm-providers-cli` (`SafeCapture`) |
| Permission Boundary Testing | File/dir modes, current UID | Exception assertions or safe skips | `ace-support-config`, `ace-support-core` |
| Validator Diagnostics | Tool availability, config paths | Diagnostic reports | `ace-lint` (`LintDoctor`) |

## Verification Plan

### Unit / Component Validation
- Run fast test suites for each of the 4 packages locally:
  - `bundle exec bin/ace-test ace-lint fast`
  - `bundle exec bin/ace-test ace-llm-providers-cli fast`
  - `bundle exec bin/ace-test ace-support-config fast`
  - `bundle exec bin/ace-test ace-support-core fast`

### Integration / E2E Validation
- Run full test suite for all 4 packages:
  - `bundle exec bin/ace-test ace-lint all`
  - `bundle exec bin/ace-test ace-llm-providers-cli all`
  - `bundle exec bin/ace-test ace-support-config all`
  - `bundle exec bin/ace-test ace-support-core all`

### Failure / Invalid-Path Validation
- Confirm invalid configuration, syntax errors, missing files, and timeouts continue to be caught and tested.

### Verification Commands
- `ruby .ace-bin/ci_package_inventory.rb`
- `bundle exec bin/ace-test ace-lint all`
- `bundle exec bin/ace-test ace-llm-providers-cli all`
- `bundle exec bin/ace-test ace-support-config all`
- `bundle exec bin/ace-test ace-support-core all`

## Objective

Coordinate the resolution of the four baseline package test defects discovered in clean-container Forgejo CI (PR #4 run 15), unblocking the integration and delivery of ACE under parent Work W401 and Overseer task `8vc.t.m21`.

## Scope of Work

- Parent coordination and vertical slice tracking for the four clean-container defect fixes.
- Definition of atomic subtask specifications (`8vt.t.rtr.0` through `8vt.t.rtr.3`) for builder assignment.
- Validation that all 4 packages pass tests on host and in clean container environments.
- Re-enabling green CI summary gating on PR #4.

## Deliverables

### Behavioral Specifications
- Orchestrator specification (`8vt.t.rtr`) and 4 atomic child subtask specifications (`8vt.t.rtr.0`..`3`).

### Validation Artifacts
- CI run evidence on Forgejo confirming green status across all 46 jobs.

## Out of Scope

- Implementing code fixes within this admin planning Work (W406 only plans and specifies; builder Works W402–W405 implement).
- Modifying Forgejo Actions workflow files (`.forgejo/workflows/test.yml`).
- Merging implementation PRs or performing GitHub synchronization.
- Publishing RubyGems releases.

## References

- Overseer meta task: `8vc.t.m21` (Work W401)
- CI Delivery Work: W400 / Forgejo PR #4 (Run 15 evidence)
- Subtasks: `8vt.t.rtr.0`, `8vt.t.rtr.1`, `8vt.t.rtr.2`, `8vt.t.rtr.3`
