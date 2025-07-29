---
id: v.0.3.0+task.226
status: pending
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.225]
---

# Enhance release-manager CLI with --path Option

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/cli/commands/release | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/cli/commands/release
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

- dev-tools/lib/coding_agent_tools/cli/commands/release/current.rb

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

* [ ] Review current release current command implementation
* [ ] Study dry-cli option handling patterns
* [ ] Design output format for path results
* [ ] Plan integration with ReleaseManager.resolve_path

### Execution Steps

- [ ] Add --path option to command definition
  ```ruby
  option :path, type: :string, desc: "Resolve path within current release"
  ```
- [ ] Modify call method to handle --path option
- [ ] When --path provided, call release_manager.resolve_path
- [ ] Format output appropriately (text shows just path, JSON includes metadata)
- [ ] Update command examples to show --path usage
- [ ] Handle errors when path resolution fails

## Acceptance Criteria

- [ ] `release-manager current --path reflections` returns full path
- [ ] `release-manager current --path reflections/synthesis` works correctly
- [ ] JSON format includes path in structured output
- [ ] Errors are handled gracefully (no current release, invalid path)
- [ ] Command help shows --path option with examples
- [ ] Works with all common subdirectories

## Out of Scope

- ❌ Modifying other release-manager commands
- ❌ Adding path resolution to release next/all commands
- ❌ Complex path patterns or wildcards
- ❌ Changing existing command behavior

## References

- Release current command: dev-tools/lib/coding_agent_tools/cli/commands/release/current.rb
- Depends on: v.0.3.0+task.225 (Add Path Resolution to ReleaseManager)
- Example usage: `release-manager current --path reflections/synthesis`