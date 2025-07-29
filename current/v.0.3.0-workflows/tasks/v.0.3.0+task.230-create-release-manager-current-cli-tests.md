---
id: v.0.3.0+task.230
status: pending
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.226]
---

# Create release-manager current CLI Tests

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 3 dev-tools/spec/coding_agent_tools/cli/commands | grep -E "(release|current)" || echo "No release command tests found"
```

_Result excerpt:_

```
No release command tests found
```

## Objective

Create comprehensive test coverage for the `release-manager current` command, particularly focusing on the new `--path` option functionality. This new test file will ensure the CLI interface works correctly with path resolution.

## Scope of Work

- Create new test file for release current command
- Test basic current release functionality
- Test new --path option thoroughly
- Test JSON and text output formats
- Test error handling scenarios
- Follow existing CLI test patterns

### Deliverables

#### Create

- dev-tools/spec/coding_agent_tools/cli/commands/release/current_spec.rb

#### Modify

- None

#### Delete

- None

## Phases

1. Create test file structure
2. Add basic command tests
3. Add --path option tests
4. Add format output tests
5. Add error scenario tests

## Implementation Plan

### Planning Steps

* [ ] Study existing CLI command test patterns
* [ ] Review dry-cli testing best practices
* [ ] Plan test scenarios for --path option
* [ ] Design mock setup for ReleaseManager

### Execution Steps

- [ ] Create new spec file with proper structure
  ```ruby
  require "spec_helper"
  
  RSpec.describe CodingAgentTools::Cli::Commands::Release::Current do
    # Tests
  end
  ```
- [ ] Test basic functionality
  ```ruby
  describe "#call" do
    it "displays current release information"
    it "returns 0 on success"
    it "returns 1 on error"
  end
  ```
- [ ] Test --path option
  ```ruby
  describe "with --path option" do
    it "returns resolved path for reflections"
    it "returns resolved path for reflections/synthesis"
    it "returns resolved path for tasks"
    it "handles missing release gracefully"
  end
  ```
- [ ] Test output formats
  ```ruby
  describe "output formats" do
    it "outputs plain text path by default"
    it "outputs JSON with --format json"
    it "includes metadata in JSON output"
  end
  ```
- [ ] Test error scenarios
  ```ruby
  describe "error handling" do
    it "shows error when no current release"
    it "shows error for invalid paths"
    it "respects --debug flag"
  end
  ```

## Acceptance Criteria

- [ ] New test file follows project conventions
- [ ] All test scenarios pass
- [ ] --path option is thoroughly tested
- [ ] Both output formats are tested
- [ ] Error messages are validated
- [ ] Mock setup is clean and maintainable

## Out of Scope

- ❌ Testing other release commands (all, next, etc.)
- ❌ Integration tests with actual file system
- ❌ Performance testing
- ❌ Testing ReleaseManager internals

## References

- Command implementation: dev-tools/lib/coding_agent_tools/cli/commands/release/current.rb
- CLI test patterns: Look at other command specs in dev-tools/spec/coding_agent_tools/cli/commands/
- Depends on: v.0.3.0+task.226 (CLI implementation)