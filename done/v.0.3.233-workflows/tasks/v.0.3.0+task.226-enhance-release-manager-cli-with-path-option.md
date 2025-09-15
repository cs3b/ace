---
id: v.0.3.0+task.226
status: done
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.225]
---

# Enhance release-manager CLI with --path Option

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools/cli/commands/release | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools/lib/coding_agent_tools/cli/commands/release
    ├── all.rb
    ├── current.rb
    ├── generate_id.rb
    ├── next.rb
    └── validate.rb
```

## Objective

Add a `--path` option to the `release-manager current` command that uses the new ReleaseManager resolve_path method to return resolved paths. This provides CLI access to path resolution functionality for scripts and other tools.

## Scope of Work

- Add `--path` option to release current command
- When --path is provided, return the resolved path instead of release info
- Support both text and JSON output formats for path results
- Handle error cases gracefully
- Update command help and examples

### Deliverables

#### Create

- None

#### Modify

- .ace/tools/lib/coding_agent_tools/cli/commands/release/current.rb

#### Delete

- None

## Phases

1. Review current CLI command structure
2. Add --path option handling
3. Implement path resolution output
4. Handle JSON format output
5. Update documentation

## Implementation Plan

### Planning Steps

* [x] Review current release current command implementation
* [x] Study dry-cli option handling patterns
* [x] Design output format for path results
* [x] Plan integration with ReleaseManager.resolve_path

### Execution Steps

- [x] Add --path option to command definition
  ```ruby
  option :path, type: :string, desc: "Resolve path within current release"
  ```
- [x] Modify call method to handle --path option
- [x] When --path provided, call release_manager.resolve_path
- [x] Format output appropriately (text shows just path, JSON includes metadata)
- [x] Update command examples to show --path usage
- [x] Handle errors when path resolution fails

## Acceptance Criteria

- [x] `release-manager current --path reflections` returns full path
- [x] `release-manager current --path reflections/synthesis` works correctly
- [x] JSON format includes path in structured output
- [x] Errors are handled gracefully (no current release, invalid path)
- [x] Command help shows --path option with examples
- [x] Works with all common subdirectories

## Out of Scope

- ❌ Modifying other release-manager commands
- ❌ Adding path resolution to release next/all commands
- ❌ Complex path patterns or wildcards
- ❌ Changing existing command behavior

## References

- Release current command: .ace/tools/lib/coding_agent_tools/cli/commands/release/current.rb
- Depends on: v.0.3.0+task.225 (Add Path Resolution to ReleaseManager)
- Example usage: `release-manager current --path reflections/synthesis`