---
id: v.0.6.0+task.002
status: pending
priority: high
estimate: 4h
dependencies: []
release: v.0.6.0-unified-claude
needs_review: false
---

# Implement Claude CLI namespace in handbook

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions
- [x] Should the `integrate` subcommand directly call the existing `ClaudeCommandsInstaller` class?
  - **Research conducted**: Found existing `CodingAgentTools::Integrations::ClaudeCommandsInstaller` class
  - **Current implementation**: Standalone class with `run` method, handles all Claude command installation
  - **Human answer**: refactor existing code and tests
  - **Decision**: Will refactor ClaudeCommandsInstaller to better integrate with CLI patterns while maintaining backward compatibility

- [x] Should `handbook claude` without subcommand show help or execute a default action?
  - **Research conducted**: Checked dry-cli documentation and existing patterns in codebase
  - **Similar implementations**: Most namespaces show help when called without subcommand (e.g., task, release, code)
  - **Human answer**: show help
  - **Decision**: Use dry-cli default behavior (shows available subcommands)

### [MEDIUM] Enhancement Questions
- [x] Should the claude namespace be eager-loaded or lazy-loaded?
  - **Research conducted**: Reviewed cli.rb loading patterns
  - **Current pattern**: All namespaces use lazy loading through `register_*_commands` methods
  - **Human answer**: lazy loaded
  - **Decision**: Follow existing pattern with lazy loading

- [x] What should be the exact help text description for each subcommand?
  - **Research conducted**: Reviewed existing command descriptions
  - **Pattern found**: Short, action-oriented descriptions (10-15 words)
  - **Decision**: Use suggested defaults as they align with existing patterns

### [LOW] Future Enhancement Questions
- [x] Should we support command aliases (e.g., `handbook cl` for `handbook claude`)?
  - **Research conducted**: Other namespaces don't use short aliases (except individual commands)
  - **Human answer**: no
  - **Decision**: No aliases for now

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
- **[Added on review]** Nested namespace help: `handbook claude` shows subcommands (handled by dry-cli)
- **[Added on review]** Missing .claude directory: ClaudeCommandsInstaller creates it automatically
- **[Added on review]** Conflicting command files: ClaudeCommandsInstaller skips existing files

### Success Criteria
- [ ] **Command Registration**: `handbook claude` is recognized and executable
- [ ] **Help System**: Help information displays correctly
- [ ] **Subcommand Structure**: All planned subcommands are registered
- [ ] **Error Messages**: Clear, actionable error messages for common issues

### Validation Questions
- [ ] **Command Aliases**: Should we support short aliases like `handbook cl`?
  - **[Resolved through research]**: No aliases needed - consistent with other namespaces
- [ ] **Output Format**: Should help output be colorized or plain text?
  - **[Resolved through research]**: dry-cli handles this automatically, no custom implementation needed
- [ ] **Subcommand Loading**: Should subcommands be lazy-loaded or eager-loaded?
  - **[Resolved through research]**: Lazy-loaded via nested registration block pattern
- [ ] **Backward Compatibility**: How to handle users expecting old claude-integrate script?
  - **[Added on review]** No existing claude-integrate script found in exe/ directory

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
- Command namespace pattern using dry-cli's subcommand registration via block syntax
- Lazy loading through modification of existing `register_handbook_commands` method in cli.rb
- Consistent with existing handbook CLI patterns (follows task, release, code namespace patterns)
- Refactor existing `ClaudeCommandsInstaller` class for better CLI integration (per human decision)

### Technology Stack
- Ruby with dry-cli gem (already in project dependencies, version in Gemfile)
- Standard Ruby module/class patterns for command organization
- Existing handbook CLI infrastructure in `CodingAgentTools::Cli::Commands` namespace
- Refactored `CodingAgentTools::Integrations::ClaudeCommandsInstaller` for CLI integration

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| dry-cli | Command parsing | Already used in project |
| Ruby modules | Command organization | Standard Ruby patterns |
| YAML | Help text storage | Human-readable configuration |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/` - Subcommand directory
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/generate_commands.rb` - Generate commands subcommand
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/update_registry.rb` - Update registry subcommand
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/integrate.rb` - Integrate subcommand (wraps existing installer)
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/validate.rb` - Validate subcommand
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/list.rb` - List subcommand
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/` - Test directory
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/integrate_spec.rb` - Integration tests
- `dev-tools/spec/integration/handbook_claude_cli_spec.rb` - CLI integration tests

### Modify
- `dev-tools/lib/coding_agent_tools/cli.rb` - Update `register_handbook_commands` method to include Claude namespace
- `dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb` - Refactor for better CLI integration
- `dev-tools/spec/integrations/claude_commands_installer_spec.rb` - Update tests for refactored installer
- `dev-tools/docs/tools.md` - Add Claude commands documentation (file confirmed to exist)

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

* [x] Study existing handbook command structure in dev-tools
  - Found: handbook namespace exists with sync-templates subcommand
  - Pattern: Uses `register_handbook_commands` lazy loading method
* [x] Review dry-cli documentation for namespace patterns
  - Confirmed: Block syntax with `prefix.register` for subcommands
  - Help: Automatically generated from desc attribute
* [x] Design command hierarchy and help text
  - Finalized based on review questions and human input
* [x] Plan backward compatibility approach
  - No existing claude-integrate executable found, no compatibility needed

### Execution Steps

- [ ] Update CLI registration to add Claude as a subcommand of handbook
  ```ruby
  # In lib/coding_agent_tools/cli.rb, update register_handbook_commands method
  def self.register_handbook_commands
    return if @handbook_commands_registered

    require_relative "cli/commands/handbook/sync_templates"
    # Note: Claude subcommands will be registered within the Claude command class

    register "handbook", aliases: [] do |prefix|
      prefix.register "sync-templates", Commands::Handbook::SyncTemplates
      # Claude will be a namespace with its own subcommands
      prefix.register "claude", aliases: [] do |claude_prefix|
        require_relative "cli/commands/handbook/claude/generate_commands"
        require_relative "cli/commands/handbook/claude/update_registry"
        require_relative "cli/commands/handbook/claude/integrate"
        require_relative "cli/commands/handbook/claude/validate"
        require_relative "cli/commands/handbook/claude/list"

        claude_prefix.register "generate-commands", Commands::Handbook::Claude::GenerateCommands
        claude_prefix.register "update-registry", Commands::Handbook::Claude::UpdateRegistry
        claude_prefix.register "integrate", Commands::Handbook::Claude::Integrate
        claude_prefix.register "validate", Commands::Handbook::Claude::Validate
        claude_prefix.register "list", Commands::Handbook::Claude::List
      end
    end

    @handbook_commands_registered = true
  end
  ```
  > TEST: Command Registration
  > Type: CLI Integration Test
  > Assert: handbook claude is recognized
  > Command: bundle exec exe/handbook claude --help

- [ ] Note: Main Claude command class not needed with nested registration
  - dry-cli automatically handles help display for namespace commands
  - When `handbook claude` is called without subcommand, it will show available subcommands
  - This is consistent with how other namespaces work (e.g., `task`, `release`, `code`)

- [ ] Refactor ClaudeCommandsInstaller for better CLI integration
  ```ruby
  # Refactor lib/coding_agent_tools/integrations/claude_commands_installer.rb
  # Changes needed:
  # - Extract run method logic into smaller, testable methods
  # - Add options parameter for CLI configuration
  # - Improve error handling to return status codes instead of exit
  # - Add dry-run support for testing
  ```

- [ ] Create subcommand classes
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude/integrate.rb
  module CodingAgentTools
    module Cli  # Note: Cli not CLI based on existing pattern
      module Commands
        module Handbook
          module Claude
            class Integrate < Dry::CLI::Command
              desc "Install Claude Code commands to .claude/ directory"
              
              option :dry_run, type: :boolean, default: false,
                              desc: 'Show what would be installed without modifying files'
              option :verbose, type: :boolean, default: false,
                              desc: 'Show detailed installation information'

              def call(**options)
                # Use refactored installer with CLI options
                installer = CodingAgentTools::Integrations::ClaudeCommandsInstaller.new(
                  dry_run: options[:dry_run],
                  verbose: options[:verbose]
                )
                result = installer.run
                exit(result.exit_code) if result.exit_code != 0
              end
            end
          end
        end
      end
    end
  end
  ```

  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude/generate_commands.rb
  module CodingAgentTools
    module Cli
      module Commands
        module Handbook
          module Claude
            class GenerateCommands < Dry::CLI::Command
              desc "Generate missing Claude commands from workflow files"

              def call(*)
                puts "generate-commands: Not yet implemented"
                puts "This will scan workflow files and generate missing command files"
              end
            end
          end
        end
      end
    end
  end
  ```

  ```ruby
  # Similar structure for update_registry.rb, validate.rb, and list.rb
  ```

- [ ] Add comprehensive tests
  ```ruby
  # spec/coding_agent_tools/cli/commands/handbook/claude/integrate_spec.rb
  RSpec.describe CodingAgentTools::Cli::Commands::Handbook::Claude::Integrate do
    let(:installer_mock) { instance_double(CodingAgentTools::Integrations::ClaudeCommandsInstaller) }

    before do
      allow(CodingAgentTools::Integrations::ClaudeCommandsInstaller)
        .to receive(:new).and_return(installer_mock)
    end

    it "calls the ClaudeCommandsInstaller" do
      expect(installer_mock).to receive(:run).and_return(0)
      subject.call
    end
  end
  ```
  > TEST: Integrate Command
  > Type: Unit Test
  > Assert: Integrate command calls ClaudeCommandsInstaller
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/handbook/claude/integrate_spec.rb

  ```ruby
  # spec/integration/handbook_claude_cli_spec.rb
  RSpec.describe "handbook claude CLI" do
    it "displays help for claude namespace" do
      output = `bundle exec exe/handbook claude --help 2>&1`
      expect(output).to include("generate-commands")
      expect(output).to include("integrate")
      expect(output).to include("validate")
    end

    it "executes integrate subcommand" do
      output = `bundle exec exe/handbook claude integrate --help 2>&1`
      expect(output).to include("Install Claude Code commands")
    end
  end
  ```
  > TEST: CLI Integration
  > Type: Integration Test
  > Assert: CLI properly routes to claude subcommands
  > Command: bundle exec rspec spec/integration/handbook_claude_cli_spec.rb

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

- Existing handbook CLI structure in dev-tools/lib/coding_agent_tools/cli.rb
- dry-cli documentation for subcommand patterns (nested registration with blocks)
- Current handbook command implementations (sync-templates)
- Existing ClaudeCommandsInstaller class in dev-tools/lib/coding_agent_tools/integrations/

## Review Summary

**Date:** 2025-08-04 (Second Review)
**Reviewer:** Claude (Automated Review)

**Questions Generated Previously:** 5 total (2 HIGH, 2 MEDIUM, 1 LOW)
**Questions Resolved:** All 5 questions have been answered by human input
**Critical Blockers:** None - all questions resolved

**Research Conducted (This Review):**
- ✅ Verified ClaudeCommandsInstaller exists with `run` method at expected path
- ✅ Confirmed handbook CLI structure and sync-templates command pattern
- ✅ Verified dry-cli automatically handles namespace help display
- ✅ Found existing test patterns in cli_spec.rb for reference
- ✅ Confirmed docs/tools.md exists and needs updating
- ✅ Verified no existing claude-integrate executable (no backward compatibility needed)
- ✅ Found existing tests for ClaudeCommandsInstaller that will need updating

**Content Updates Made (This Review):**
- Moved Review Questions to "Resolved" section with human answers and decisions
- Updated Technical Approach to reflect refactoring decision for ClaudeCommandsInstaller
- Added refactoring step for ClaudeCommandsInstaller with specific requirements
- Enhanced Integrate subcommand with dry_run and verbose options
- Updated File Modifications to include refactoring of existing installer and tests
- Marked planning steps as complete based on research
- Set needs_review flag to false as all questions are resolved

**Implementation Readiness:** Ready for implementation - all questions answered and approach validated

**Recommended Next Steps:**
1. Begin implementation with ClaudeCommandsInstaller refactoring
2. Create the claude namespace and subcommands following established patterns
3. Update tests for both the refactored installer and new CLI commands
4. Update docs/tools.md with new Claude commands documentation
5. Test the complete integration flow end-to-end
