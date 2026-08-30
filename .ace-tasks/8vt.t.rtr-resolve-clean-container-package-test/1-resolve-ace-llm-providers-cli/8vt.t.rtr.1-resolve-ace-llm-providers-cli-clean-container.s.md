---
id: 8vt.t.rtr.1
status: pending
priority: high
created_at: "2026-08-30 18:33:07"
estimate: TBD
dependencies: []
tags: [ace-llm-providers-cli, ci, testing, containers, process]
parent: 8vt.t.rtr
coordination:
  work: W403
  project: ace
  parent_task: 8vt.t.rtr
bundle:
  presets: [project]
  files: [ace-llm-providers-cli/lib/ace/llm/providers/cli/molecules/safe_capture.rb, ace-llm-providers-cli/test/fast/molecules/safe_capture_test.rb]
  commands: [bundle exec bin/ace-test ace-llm-providers-cli fast, bundle exec bin/ace-test ace-llm-providers-cli all]
needs_review: false
---

# Resolve ace-llm-providers-cli clean-container failure

## Behavioral Specification

### User Experience

- **Input:** A CLI client (Claude, Codex, Gemini, OpenCode, Pi) executes an external CLI provider command wrapped by `SafeCapture` inside a clean container environment with its own PID namespace (where PID 1 is the container entrypoint and background subshells may exit or reparent rapidly).
- **Process:** `SafeCapture` spawns the subprocess in an isolated process group, captures stdout/stderr with stream safety, handles process timeouts cleanly, and terminates the entire subprocess tree (including background descendants) without hanging, crashing, or leaving orphan processes.
- **Output:** Command output and status are returned reliably on success; timeouts raise `Ace::LLM::ProviderError` with descriptive messages and clean up all child processes.

### Expected Behavior

- `SafeCapture.call` reliably tracks process group IDs even when parent shells exit quickly or when running inside container PID namespaces.
- `test_success_cleanup_terminates_background_descendants` and `test_timeout_cleanup_terminates_background_descendants` pass deterministically without race conditions or `ESRCH` failures.
- Process group termination uses reliable group killing (`Process.kill(signal, -pgid)`) with proper fallback when `pgid` cannot be retrieved.
- All CLI provider clients (Claude, Codex, Gemini, OpenCode, Pi) maintain thread-safe execution without pipe stream deadlocks.

### Interface Contract

```ruby
# SafeCapture invocation
stdout, stderr, status = Ace::LLM::Providers::CLI::Molecules::SafeCapture.call(
  cmd,
  timeout: 30,
  stdin_data: nil,
  chdir: nil,
  env: nil,
  provider_name: "CLI",
  isolate_process_group: true,
  cleanup_group_on_exit: true
)
```

**Error Handling:**
- Subprocess timeout raises `Ace::LLM::ProviderError` with formatted elapsed seconds.
- Broken pipe (`Errno::EPIPE`) on stdin is rescued to allow stderr capture of early crashes.
- Process termination catches `Errno::ESRCH` and `Errno::EPERM` cleanly.

**Edge Cases:**
- Background descendant spawned in subshell (`sleep 5 &`) terminates on parent exit or timeout.
- Container PID namespace with PID 1 init process.
- Subprocess exits before `Process.getpgid` is called.

## Success Criteria

- [ ] **Exact Reproduction Resolved**: The two `SafeCapture` child-process termination failures in `test/fast/molecules/safe_capture_test.rb` on Actions Run 15 are resolved.
- [ ] **Clean Container Verification**: `bundle exec bin/ace-test ace-llm-providers-cli all` passes with 0 failures and 0 errors inside an isolated container.
- [ ] **No Process Leakage**: Descendant subprocesses are guaranteed to be terminated on both success cleanup and timeout cleanup.
- [ ] **No Flakiness**: Process termination tests run stably across varying container runner loads.

## Exact Reproduction Evidence

- **Forgejo CI Run**: Actions Run 15 (DB ID 17) on PR #4 (`admin/W400-forgejo-ci`).
- **Failing Job**: `test (ace-llm-providers-cli)`.
- **Symptom**: 2 test failures in `test/fast/molecules/safe_capture_test.rb`:
  - `test_success_cleanup_terminates_background_descendants`
  - `test_timeout_cleanup_terminates_background_descendants`
- **Root Cause**: In container PID namespaces, process group resolution (`Process.getpgid(pid)`) after spawn or during rapid subshell exit encounters timing races where `pgid` is lost or group killing does not reach reparented background children.

## Required Package Tests

- `ace-test ace-llm-providers-cli fast`
- `ace-test ace-llm-providers-cli feat`
- `ace-test ace-llm-providers-cli all`

## Clean-Container Verification

- Run `bundle exec bin/ace-test ace-llm-providers-cli all` in a clean container.

## Assignment and Review Expectations

- **Assignee / Work**: Assigned to builder Work `W403` under parent `W401`.
- **Workflow**: Builder adopts task spec via `ace-task:ace/8vt.t.rtr.1`, uses `/as-assign-drive`, scopes changes strictly to `ace-llm-providers-cli`, validates subprocess lifecycle, passes clean-context review, and opens a Forgejo PR.

## Relationship to Parent

- Vertical slice 2 of 4 under orchestrator `8vt.t.rtr` (Work W401).

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator subtask (Slice 2 of 4)
- **Slice Outcome**: `SafeCapture` process tree termination is robust in container PID namespaces
- **Advisory Size**: Medium
- **Context Dependencies**: `ace-llm-providers-cli` `SafeCapture` molecule

## Verification Plan

### Unit / Component Validation
- Run `bundle exec bin/ace-test ace-llm-providers-cli fast`

### Integration / E2E Validation
- Run `bundle exec bin/ace-test ace-llm-providers-cli all`

### Failure / Invalid-Path Validation
- Exercise command timeouts, invalid timeout inputs, and broken pipe scenarios.

### Verification Commands
- `bundle exec bin/ace-test ace-llm-providers-cli all`

## Objective

Harden `SafeCapture` subprocess group management and descendant cleanup to pass cleanly in container PID namespaces on Forgejo CI.

## Scope of Work

- Fix `SafeCapture` process group discovery and termination logic in `ace-llm-providers-cli`.
- Ensure tests verify descendant termination deterministically across all environments.

## Deliverables

### Behavioral Specifications
- Robust process termination contract in `SafeCapture`.

### Validation Artifacts
- Test execution output showing 0 failures, 0 errors.

## Out of Scope

- Changes to other ACE packages.
- Changes to LLM client network protocols.

## References

- Parent task: `8vt.t.rtr`
- W400 report: `/lab/state/admin/tasks/W400/report.md`
- Forgejo PR #4 Run 15
