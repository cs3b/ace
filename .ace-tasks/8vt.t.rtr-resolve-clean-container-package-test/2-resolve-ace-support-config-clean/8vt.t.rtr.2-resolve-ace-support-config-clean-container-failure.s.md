---
id: 8vt.t.rtr.2
status: pending
priority: high
created_at: "2026-08-30 18:33:07"
estimate: TBD
dependencies: []
tags: [ace-support-config, ci, testing, containers, permissions]
parent: 8vt.t.rtr
coordination:
  work: W404
  project: ace
  parent_task: 8vt.t.rtr
bundle:
  presets: [project]
  files: [ace-support-config/lib/ace/support/config.rb, ace-support-config/lib/ace/support/config/errors.rb, ace-support-config/lib/ace/support/config/molecules/yaml_loader.rb, ace-support-config/test/feat/config_cascade_edge_test.rb]
  commands: [bundle exec bin/ace-test ace-support-config fast, bundle exec bin/ace-test ace-support-config all]
needs_review: false
---

# Resolve ace-support-config clean-container failure

## Behavioral Specification

### User Experience

- **Input:** A test suite or application executes configuration cascade resolution in an environment where file permissions may be restricted (e.g. `chmod 0000`) or where the executing user has root privileges (UID 0 inside Docker containers where `CAP_DAC_OVERRIDE` bypasses standard read permission bits).
- **Process:** `Ace::Support::Config` discovers and loads configuration files, raising `ConfigNotFoundError` when unreadable files are encountered in non-root environments, while test assertions account for root/container execution without false assertion failures.
- **Output:** Configuration resolution completes cleanly, and all feature and edge-case tests pass across both unprivileged host environments and container root environments.

### Expected Behavior

- `test_permission_denied_on_config_file` in `test/feat/config_cascade_edge_test.rb` properly handles execution as root (UID 0 in Docker container) where `File.chmod(0o000, ...)` does not trigger permission errors.
- In unprivileged environments, `ConfigNotFoundError` continues to be raised and tested when config files cannot be read.
- Configuration cascade resolution, precedence rules, and error handling remain strict and unchanged.

### Interface Contract

```ruby
# Configuration resolution
resolver = Ace::Support::Config.create
config = resolver.resolve
```

**Error Handling:**
- Unreadable configuration files raise `Ace::Support::Config::ConfigNotFoundError` with descriptive messages.
- Permission edge-case tests include root-awareness checks (`Process.uid.zero?` or equivalent DAC capability guard) to prevent false test failures in Docker containers.

**Edge Cases:**
- Execution as root (UID 0) in Docker container vs unprivileged user on host.
- Inaccessible configuration directories vs inaccessible configuration files.
- Symlink loops and invalid YAML structures.

## Success Criteria

- [ ] **Exact Reproduction Resolved**: The `ConfigNotFoundError` expected but not raised failure in `test/feat/config_cascade_edge_test.rb` on Actions Run 15 is resolved.
- [ ] **Clean Container Verification**: `bundle exec bin/ace-test ace-support-config all` passes with 0 failures and 0 errors inside an isolated container.
- [ ] **Error Handling Preserved**: `ConfigNotFoundError` behavior and cascade mechanics remain fully verified for unprivileged users.

## Exact Reproduction Evidence

- **Forgejo CI Run**: Actions Run 15 (DB ID 17) on PR #4 (`admin/W400-forgejo-ci`).
- **Failing Job**: `test (ace-support-config)`.
- **Symptom**: `ConfigNotFoundError` expected but nothing was raised in `test_permission_denied_on_config_file` (`test/feat/config_cascade_edge_test.rb:446`).
- **Root Cause**: The test uses `File.chmod(0o000, config_path)` to trigger a read permission error. When executed inside a container as root (UID 0), the Linux kernel's DAC override allows root to read mode `0000` files, so no exception is raised.

## Required Package Tests

- `ace-test ace-support-config fast`
- `ace-test ace-support-config feat`
- `ace-test ace-support-config all`

## Clean-Container Verification

- Run `bundle exec bin/ace-test ace-support-config all` in a root container.

## Assignment and Review Expectations

- **Assignee / Work**: Assigned to builder Work `W404` under parent `W401`.
- **Workflow**: Builder adopts task spec via `ace-task:ace/8vt.t.rtr.2`, uses `/as-assign-drive`, scopes changes strictly to `ace-support-config`, provides root and non-root verification proofs, passes clean-context review, and opens a Forgejo PR.

## Relationship to Parent

- Vertical slice 3 of 4 under orchestrator `8vt.t.rtr` (Work W401).

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator subtask (Slice 3 of 4)
- **Slice Outcome**: `ace-support-config` edge-case tests pass in container root environments
- **Advisory Size**: Small
- **Context Dependencies**: `ace-support-config` cascade edge tests

## Verification Plan

### Unit / Component Validation
- Run `bundle exec bin/ace-test ace-support-config fast`

### Integration / E2E Validation
- Run `bundle exec bin/ace-test ace-support-config all`

### Failure / Invalid-Path Validation
- Verify permission denial and missing file error paths.

### Verification Commands
- `bundle exec bin/ace-test ace-support-config all`

## Objective

Fix the permission denial test in `ace-support-config` to account for container root execution, achieving 100% green tests on Forgejo CI.

## Scope of Work

- Update `config_cascade_edge_test.rb` to handle root UID / container permission characteristics safely.
- Verify all 23 test files in `ace-support-config` pass cleanly.

## Deliverables

### Behavioral Specifications
- Container-compatible permission edge-case test coverage for `ace-support-config`.

### Validation Artifacts
- Test execution output showing 0 failures, 0 errors.

## Out of Scope

- Changes to other ACE packages.
- Changes to configuration schema or cascade precedence rules.

## References

- Parent task: `8vt.t.rtr`
- W400 report: `/lab/state/admin/tasks/W400/report.md`
- Forgejo PR #4 Run 15
