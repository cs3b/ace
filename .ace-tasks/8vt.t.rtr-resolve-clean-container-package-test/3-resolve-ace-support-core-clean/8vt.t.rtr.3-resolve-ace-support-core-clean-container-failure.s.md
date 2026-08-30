---
id: 8vt.t.rtr.3
status: done
priority: high
created_at: "2026-08-30 18:33:07"
estimate: TBD
dependencies: []
tags: [ace-support-core, ci, testing, containers, io]
parent: 8vt.t.rtr
coordination:
  work: W405
  project: ace
  parent_task: 8vt.t.rtr
bundle:
  presets: [project]
  files: [ace-support-core/lib/ace/core.rb, ace-support-core/lib/ace/core/atoms/file_reader.rb, ace-support-core/test/fast/molecules/yaml_loader_test.rb, ace-support-core/test/fast/atoms/file_reader_test.rb]
  commands: [bundle exec bin/ace-test ace-support-core fast, bundle exec bin/ace-test ace-support-core all]
needs_review: false
---

# Resolve ace-support-core clean-container failure

## Behavioral Specification

### User Experience

- **Input:** A test suite or application performs file writing or YAML saving in an environment where filesystem operations may encounter write errors or where the process runs with root privileges (UID 0 inside Docker container).
- **Process:** `Ace::Support::Core` / `YamlLoader` attempts to write files, handling IO errors appropriately, while test assertions verify write-failure error handling without assuming unprivileged UID behavior.
- **Output:** File operations succeed or fail with clear `IOError` / `SystemCallError` exceptions, and test suites pass across all environments.

### Expected Behavior

- `test_handles_io_errors_on_save` in `test/fast/molecules/yaml_loader_test.rb` handles execution under root (UID 0 in Docker container) where `FileUtils.chmod(0o444, "readonly")` does not prevent root from creating files/directories.
- In unprivileged environments or when simulated, IO errors on file save continue to raise `IOError` and be handled safely.
- Core file reading, YAML loading, and environment management functions remain robust and backward-compatible.

### Interface Contract

```ruby
# YamlLoader save operation
Ace::Support::Config::Molecules::YamlLoader.save_file(config, file_path)
```

**Error Handling:**
- File write failures raise `IOError` with actionable details.
- Tests testing write-failure error handling guard against root bypass (`Process.uid.zero?` or simulated write failure).

**Edge Cases:**
- Execution as root (UID 0) in Docker container.
- Read-only directory permissions vs read-only filesystem mounts.
- Invalid YAML syntax and non-existent parent paths.

## Success Criteria

- [ ] **Exact Reproduction Resolved**: The `IOError` expected but not raised failure in `test/fast/molecules/yaml_loader_test.rb` on Actions Run 15 is resolved.
- [ ] **Clean Container Verification**: `bundle exec bin/ace-test ace-support-core all` passes with 0 failures and 0 errors inside an isolated container.
- [ ] **IO Error Handling Preserved**: Core file writing error handling remains robust and thoroughly tested.

## Exact Reproduction Evidence

- **Forgejo CI Run**: Actions Run 15 (DB ID 17) on PR #4 (`admin/W400-forgejo-ci`).
- **Failing Job**: `test (ace-support-core)`.
- **Symptom**: `IOError` expected but nothing was raised in `test_handles_io_errors_on_save` (`test/fast/molecules/yaml_loader_test.rb:163`).
- **Root Cause**: The test creates a directory with `FileUtils.chmod(0o444, "readonly")` expecting subdirectory creation/write to fail. Running as root (UID 0) in the Docker container, root overrides `0o444` directory permissions and writes successfully.

## Required Package Tests

- `ace-test ace-support-core fast`
- `ace-test ace-support-core feat`
- `ace-test ace-support-core all`

## Clean-Container Verification

- Run `bundle exec bin/ace-test ace-support-core all` in a root container.

## Assignment and Review Expectations

- **Assignee / Work**: Assigned to builder Work `W405` under parent `W401`.
- **Workflow**: Builder adopts task spec via `ace-task:ace/8vt.t.rtr.3`, uses `/as-assign-drive`, scopes changes strictly to `ace-support-core`, provides root and non-root verification proofs, passes clean-context review, and opens a Forgejo PR.

## Relationship to Parent

- Vertical slice 4 of 4 under orchestrator `8vt.t.rtr` (Work W401).

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator subtask (Slice 4 of 4)
- **Slice Outcome**: `ace-support-core` IO error tests pass in container root environments
- **Advisory Size**: Small
- **Context Dependencies**: `ace-support-core` `YamlLoader` tests

## Verification Plan

### Unit / Component Validation
- Run `bundle exec bin/ace-test ace-support-core fast`

### Integration / E2E Validation
- Run `bundle exec bin/ace-test ace-support-core all`

### Failure / Invalid-Path Validation
- Verify invalid YAML, missing file, and write error handling.

### Verification Commands
- `bundle exec bin/ace-test ace-support-core all`

## Objective

Fix the IO error handling test in `ace-support-core` to account for container root execution, achieving 100% green tests on Forgejo CI.

## Scope of Work

- Update `yaml_loader_test.rb` to handle root UID / container permission characteristics safely.
- Verify all 18 test files in `ace-support-core` pass cleanly.

## Deliverables

### Behavioral Specifications
- Container-compatible IO error test coverage for `ace-support-core`.

### Validation Artifacts
- Test execution output showing 0 failures, 0 errors.

## Out of Scope

- Changes to other ACE packages.
- Changes to core models or interfaces.

## References

- Parent task: `8vt.t.rtr`
- W400 report: `/lab/state/admin/tasks/W400/report.md`
- Forgejo PR #4 Run 15
