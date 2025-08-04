---
id: v.0.6.0+task.002
status: pending
priority: high
estimate: 4h
dependencies: []
release: v.0.6.0-unified-claude
---

# Implement Claude CLI namespace in handbook

## Behavioral Specification

### User Experience
- **Input**: Developer types `handbook claude` or `handbook claude --help`
- **Process**: System displays available Claude-related subcommands with descriptions
- **Output**: Clear command listing with usage examples and descriptions

### Expected Behavior
When developers invoke `handbook claude`, they should see a helpful overview of all available Claude integration commands. Each subcommand should be clearly described with its purpose. The command structure should follow the established patterns of other handbook subcommands, providing a consistent and intuitive experience.

### Interface Contract
```bash
# Main command
handbook claude
# Output:
Usage: handbook claude [SUBCOMMAND]

Subcommands:
  generate-commands  Generate missing Claude commands from workflows
  update-registry    Update commands.json registry
  integrate          Copy commands to .claude/ directory
  validate           Validate command coverage
  list               List all commands and their status

# Help command
handbook claude --help
# Same output as above

# Invalid subcommand
handbook claude invalid-command
# Output:
Error: Unknown subcommand 'invalid-command'
Usage: handbook claude [SUBCOMMAND]
[... rest of help output ...]
```

**Error Handling:**
- Unknown subcommand: Display error and show help
- No subcommand provided: Display help information
- Missing dependencies: Clear error about what's missing

**Edge Cases:**
- Called from non-project directory: Graceful error with guidance
- Incomplete installation: Detect and report missing components

### Success Criteria
- [ ] **Command Registration**: `handbook claude` is recognized and executable
- [ ] **Help System**: Help information displays correctly
- [ ] **Subcommand Structure**: All planned subcommands are registered
- [ ] **Error Messages**: Clear, actionable error messages for common issues

### Validation Questions
- [ ] **Command Aliases**: Should we support short aliases like `handbook cl`?
- [ ] **Output Format**: Should help output be colorized or plain text?
- [ ] **Subcommand Loading**: Should subcommands be lazy-loaded or eager-loaded?
- [ ] **Backward Compatibility**: How to handle users expecting old claude-integrate script?

## Objective

Establish the Claude namespace within the handbook CLI to provide a unified, discoverable interface for all Claude Code integration operations.

## Scope of Work

- **User Experience Scope**: Command discovery and help system
- **System Behavior Scope**: Command registration and routing
- **Interface Scope**: CLI command structure and output format

### Deliverables

#### Behavioral Specifications
- Command hierarchy documentation
- Help text specifications
- Error message catalog

#### Validation Artifacts
- Command registration tests
- Help output validation
- Subcommand routing tests

## Out of Scope
- ❌ **Implementation Details**: Ruby class structure, dry-cli specifics
- ❌ **Technology Decisions**: Command parsing library choices
- ❌ **Performance Optimization**: Command loading optimization
- ❌ **Future Enhancements**: Additional namespaces or command restructuring

## Technical Approach

### Architecture Pattern
- Command namespace pattern using dry-cli's subcommand registration
- Lazy loading of subcommands for performance
- Consistent with existing handbook CLI patterns

### Technology Stack
- Ruby with dry-cli for command parsing
- Standard Ruby patterns for command organization
- Existing handbook CLI infrastructure

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| dry-cli | Command parsing | Already used in project |
| Ruby modules | Command organization | Standard Ruby patterns |
| YAML | Help text storage | Human-readable configuration |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude.rb` - Main Claude command class
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/` - Subcommand directory
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude_spec.rb` - Tests

### Modify
- `dev-tools/lib/coding_agent_tools/cli.rb` - Register Claude namespace
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook.rb` - Add Claude subcommand

### Delete
- None required

## Risk Assessment

### Technical Risks
- **Command Conflicts**: Existing scripts might conflict
  - Mitigation: Check for naming conflicts before implementation
- **Loading Performance**: Too many subcommands might slow startup
  - Mitigation: Use lazy loading pattern

### Integration Risks
- **User Confusion**: Users expecting old claude-integrate script
  - Mitigation: Add deprecation notice with clear migration path
- **Subcommand Discovery**: Users might not find new commands
  - Mitigation: Clear help text and documentation

## Implementation Plan

### Planning Steps

* [ ] Study existing handbook command structure in dev-tools
* [ ] Review dry-cli documentation for namespace patterns
* [ ] Design command hierarchy and help text
* [ ] Plan backward compatibility approach

### Execution Steps

- [ ] Update CLI registration to include Claude namespace
  ```ruby
  # In lib/coding_agent_tools/cli.rb
  def self.register_handbook_commands
    return if @handbook_commands_registered

    require_relative "cli/commands/handbook/sync_templates"
    require_relative "cli/commands/handbook/claude"

    register "handbook", aliases: [] do |prefix|
      prefix.register "sync-templates", Commands::Handbook::SyncTemplates
      prefix.register "claude", Commands::Handbook::Claude
    end

    @handbook_commands_registered = true
  end
  ```
  > TEST: Command Registration
  > Type: CLI Integration Test
  > Assert: handbook claude is recognized
  > Command: bundle exec exe/handbook claude --help

- [ ] Create main Claude command class
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude.rb
  module CodingAgentTools
    module CLI
      module Commands
        module Handbook
          class Claude < Dry::CLI::Command
            desc "Manage Claude Code integration"

            def call(*)
              puts "Usage: handbook claude [SUBCOMMAND]"
              puts ""
              puts "Subcommands:"
              puts "  generate-commands  Generate missing Claude commands from workflows"
              puts "  update-registry    Update commands.json registry"
              puts "  integrate          Copy commands to .claude/ directory"
              puts "  validate           Validate command coverage"
              puts "  list               List all commands and their status"
            end
          end
        end
      end
    end
  end
  ```

- [ ] Set up subcommand registration structure
  ```ruby
  # In claude.rb, add subcommand loading
  Dir[File.join(__dir__, "claude", "*.rb")].each { |f| require f }
  
  register "generate-commands", Claude::GenerateCommands
  register "update-registry", Claude::UpdateRegistry
  register "integrate", Claude::Integrate
  register "validate", Claude::Validate
  register "list", Claude::List
  ```

- [ ] Create placeholder subcommand classes
  ```ruby
  # Example: lib/coding_agent_tools/cli/commands/handbook/claude/generate_commands.rb
  module CodingAgentTools
    module CLI
      module Commands
        module Handbook
          module Claude
            class GenerateCommands < Dry::CLI::Command
              desc "Generate missing Claude commands from workflows"
              
              def call(*)
                puts "generate-commands: Not yet implemented"
              end
            end
          end
        end
      end
    end
  end
  ```

- [ ] Add comprehensive tests
  ```ruby
  # spec/coding_agent_tools/cli/commands/handbook/claude_spec.rb
  RSpec.describe CodingAgentTools::CLI::Commands::Handbook::Claude do
    it "displays help when called without subcommand" do
      output = capture_output { subject.call }
      expect(output).to include("Usage: handbook claude [SUBCOMMAND]")
      expect(output).to include("generate-commands")
    end
  end
  ```
  > TEST: Help Display
  > Type: Unit Test
  > Assert: Help text includes all subcommands
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/handbook/claude_spec.rb

- [ ] Update documentation
  ```markdown
  # In docs/tools.md, add Claude commands section
  ### Claude Integration Commands
  - `handbook claude generate-commands` - Generate missing commands
  - `handbook claude update-registry` - Update commands.json
  ...
  ```

## Acceptance Criteria

- [ ] `handbook claude` displays help with all subcommands
- [ ] `handbook claude --help` works identically
- [ ] Invalid subcommands show error and help
- [ ] All placeholder subcommands respond with "Not yet implemented"
- [ ] Tests pass for command registration and help display

## References

- Existing handbook CLI structure
- dry-cli documentation for subcommand patterns
- Current handbook command implementations (sync-templates)