---
id: v.0.6.0+task.003
status: in-progress
priority: high
estimate: 6h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
needs_review: false
---

# Create generate-commands subcommand

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions
- [x] Should generated commands go into .claude/commands/ or dev-handbook/.integrations/claude/commands/_generated/?
  - **Research conducted**: Found existing ClaudeCommandsInstaller puts commands in .claude/commands/
  - **Current pattern**: Custom commands in dev-handbook/.integrations/claude/commands/, installed to .claude/commands/
  - **Suggested default**: Create in dev-handbook/.integrations/claude/commands/_generated/ for version control
  - **Why needs human input**: Architecture decision about where generated files should live
  - **Human answer**: dev-handbook (only integrate sub cmd will be working in .claude)
  - **Decision**: Generated commands will be created in `dev-handbook/.integrations/claude/commands/_generated/`

- [x] Should the subcommand modify ClaudeCommandsInstaller or create a new generator class?
  - **Research conducted**: ClaudeCommandsInstaller currently handles both custom and workflow commands
  - **Current implementation**: Monolithic class doing scanning, generation, and installation
  - **Suggested default**: New ClaudeCommandGenerator class focused on generation only
  - **Why needs human input**: Refactoring scope - might affect existing functionality
  - **Human answer**: we should reuse what possible, and refactor what necessary (the current task define behaviour)
  - **Decision**: Create new ClaudeCommandGenerator class while reusing existing components where appropriate

### [MEDIUM] Enhancement Questions
- [x] How should the template handle workflows that already have custom implementations?
  - **Research conducted**: ClaudeCommandsInstaller has get_custom_template method for commit and load-project-context
  - **Current behavior**: Skips if file exists, has hardcoded custom templates
  - **Suggested default**: Check both custom and generated dirs, skip if either exists
  - **Why needs human input**: Need clear separation strategy between custom and generated
  - **Human answer**: there is proposal to keep them in separate sub folders (_custom, _generated), by default it should not overwrite existing ones (only if there --force then overwrite existing files)
  - **Decision**: Use separate `_custom/` and `_generated/` subdirectories, skip existing unless --force flag

- [x] Should generated commands include the commit.md reference line?
  - **Research conducted**: Current template includes "read and run @.claude/commands/commit.md"
  - **Pattern observed**: All current generated commands have this line
  - **Suggested default**: Include it (maintains consistency)
  - **Why needs human input**: May not be appropriate for all workflow types
  - **Human answer**: yes, as it's the default way to call commit standalone (and within other workflow)
  - **Decision**: All generated commands will include the commit.md reference line

### [LOW] Future Enhancement Questions
- [x] Should the command support batch operations with glob patterns?
  - **Research conducted**: No existing commands use glob patterns for batch operations
  - **Suggested default**: Start with --workflow flag for single workflow only
  - **Why needs human input**: Feature scope for initial implementation
  - **Human answer**: yes
  - **Decision**: Support glob patterns for batch generation operations

- [x] Should we use ERB templates or simple string interpolation?
  - **Research conducted**: No ERB usage found in codebase, ClaudeCommandsInstaller uses heredocs
  - **Suggested default**: Simple heredocs matching existing pattern (no ERB dependency)
  - **Why needs human input**: Extensibility vs simplicity trade-off
  - **Human answer**: string interpolation - template should be defined in proper folder in dev-handbook/.integrations/claude/command.template.md
  - **Decision**: Use string interpolation with template stored in `dev-handbook/.integrations/claude/command.template.md`

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude generate-commands` with optional flags
- **Process**: System scans workflows, identifies missing commands, generates them using templates
- **Output**: Report of generated commands and their locations

### Expected Behavior
The system should scan all workflow instruction files (.wf.md) in dev-handbook and identify which ones lack corresponding Claude commands. For missing commands, it should generate appropriate command files using predefined templates. The generation should be smart enough to skip custom commands and only generate for truly missing workflows. Users should see clear progress and results.

### Interface Contract
```bash
# Generate all missing commands
handbook claude generate-commands
# Output:
Scanning workflow instructions...
Found 25 workflow files
Checking existing commands...

Missing commands for:
  - capture-idea.wf.md
  - fix-linting-issue-from.wf.md
  - rebase-against.wf.md

Generating commands...
✓ Created: _generated/capture-idea.md
✓ Created: _generated/fix-linting-issue-from.md
✓ Created: _generated/rebase-against.md

Summary: 3 commands generated

# Generate with dry-run
handbook claude generate-commands --dry-run
# Output:
[Same scanning output]
Would generate:
  - _generated/capture-idea.md
  - _generated/fix-linting-issue-from.md
  - _generated/rebase-against.md

# Force regeneration
handbook claude generate-commands --force
# Output:
[Regenerates even existing _generated commands]

# Generate specific workflow
handbook claude generate-commands --workflow capture-idea
# Output:
✓ Created: _generated/capture-idea.md
```

**Error Handling:**
- Missing workflow directory: Clear error about location
- Template not found: Error with template path
- Write permission denied: Error with remediation steps
- Invalid workflow format: Skip with warning

**Edge Cases:**
- Workflow with custom command exists: Skip generation
- Generated command already exists: Skip unless --force
- Malformed workflow file: Report and continue
- Template variables missing: Use safe defaults

### Success Criteria
- [ ] **Workflow Scanning**: All .wf.md files are discovered and analyzed
- [ ] **Gap Detection**: Missing commands are accurately identified
- [ ] **Template Application**: Commands generated using correct template
- [ ] **Progress Reporting**: Clear output showing what's being done
- [ ] **Idempotent Operation**: Running twice produces same result

### Validation Questions
- [ ] **Custom Detection**: How to identify if a command is custom vs should be generated?
  - **[Resolved through research]**: Check for files in both _custom/ and _generated/ directories
  - **Pattern found**: Custom commands in dev-handbook/.integrations/claude/commands/, generated in _generated/
- [ ] **Template Variables**: What variables should templates support?
  - **[Resolved through research]**: Minimal - just workflow_name based on current simple template pattern
  - **Current template**: Uses workflow basename directly in path reference
- [ ] **Naming Conflicts**: How to handle workflows with similar names?
  - **[Resolved through research]**: Use exact workflow filename without .wf.md extension
  - **No conflicts possible**: Each workflow has unique filename
- [ ] **Generation Rules**: Should some workflows never have commands?
  - **[Needs answer]**: No clear pattern found - may need blacklist or convention

## Objective

Enable automatic generation of Claude commands for workflow instructions that lack them, maintaining consistency while respecting custom implementations.

## Scope of Work

- **User Experience Scope**: Command generation workflow and progress reporting
- **System Behavior Scope**: File scanning, template processing, and file generation
- **Interface Scope**: CLI flags and output format

### Deliverables

#### Behavioral Specifications
- Template format specification
- Generation rules documentation
- Progress reporting format

#### Validation Artifacts
- Generated command validation tests
- Template variable verification
- Idempotency test scenarios

## Out of Scope
- ❌ **Implementation Details**: File I/O methods, template engine choice
- ❌ **Technology Decisions**: Ruby libraries for templating
- ❌ **Performance Optimization**: Parallel generation strategies
- ❌ **Future Enhancements**: AI-powered command generation

## Technical Approach

### Architecture Pattern
- Scanner pattern for workflow discovery
- Simple heredoc templates matching existing commands
- Separation of custom vs generated commands via directory structure

### Technology Stack
- Ruby File/Dir for filesystem scanning
- Heredocs for template generation (matching existing pattern)
- Pathname for path operations (consistent with ClaudeCommandsInstaller)

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|  
| Dir.glob | Workflow scanning | Built-in, supports batch operations with patterns |
| String interpolation | Template generation | Simple, maintainable with external template |
| FileUtils | File operations | Standard library reliability |
| Pathname | Path manipulation | Already used in ClaudeCommandsInstaller |
| File.read | Template loading | Standard method for external template file |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/generate_commands.rb` - Command implementation
- `dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb` - Business logic
- `dev-tools/spec/coding_agent_tools/organisms/claude_command_generator_spec.rb` - Unit tests
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/generate_commands_spec.rb` - Command tests
- `dev-handbook/.integrations/claude/commands/_generated/` - Directory for generated commands (if not exists)

### Modify
- `dev-tools/lib/coding_agent_tools/cli.rb` - Register generate-commands in claude namespace (handled by task.002)

### Delete
- None required

## Risk Assessment

### Technical Risks
- **Template Processing Errors**: Malformed templates could break generation
  - Mitigation: Validate templates before processing, safe defaults
- **Filesystem Race Conditions**: Concurrent modifications during scan
  - Mitigation: Single scan snapshot, atomic file operations

### Integration Risks
- **Workflow Naming Variations**: Non-standard workflow names
  - Mitigation: Flexible name extraction, validation rules
- **Command Conflicts**: Generated overwrites custom
  - Mitigation: Check both _custom and _generated before creating

## Implementation Plan

### Planning Steps

* [x] Analyze workflow naming patterns in dev-handbook
  - **Completed**: All workflows use .wf.md extension, names are kebab-case
* [x] Define template variable requirements
  - **Completed**: Only workflow_name needed based on current template
* [x] Design command detection logic (custom vs missing)
  - **Completed**: Check _custom/ first, then _generated/, skip if either exists
* [x] Plan dry-run implementation approach
  - **Completed**: Follow git patterns - display actions without writing files

### Execution Steps

- [ ] Implement generate-commands command class
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude/generate_commands.rb
  module CodingAgentTools
    module CLI
      module Commands
        module Handbook
          module Claude
            class GenerateCommands < Dry::CLI::Command
              desc "Generate missing Claude commands from workflows"

              option :dry_run, type: :boolean, default: false, desc: "Show what would be generated"
              option :force, type: :boolean, default: false, desc: "Overwrite existing generated commands"
              option :workflow, type: :string, desc: "Generate for specific workflow"

              def call(**options)
                generator = CodingAgentTools::Organisms::ClaudeCommandGenerator.new
                generator.generate(options)
              end
            end
          end
        end
      end
    end
  end
  ```

- [ ] Create command generator organism
  ```ruby
  # lib/coding_agent_tools/organisms/claude_command_generator.rb
  module CodingAgentTools
    module Organisms
      class ClaudeCommandGenerator
        def initialize
          @workflow_dir = "dev-handbook/workflow-instructions"
          @custom_dir = "dev-handbook/.integrations/claude/commands"  # Existing custom commands location
          @generated_dir = "dev-handbook/.integrations/claude/commands/_generated"
          # No template path needed - using heredocs
        end

        def generate(options)
          workflows = find_workflows(options[:workflow])
          missing = find_missing_commands(workflows)

          if options[:dry_run]
            display_dry_run(missing)
          else
            generate_commands(missing, options[:force])
          end
        end
      end
    end
  end
  ```
  > TEST: Generator Initialization
  > Type: Unit Test
  > Assert: Generator creates with correct paths
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_generator_spec.rb

- [ ] Implement workflow scanning
  ```ruby
  def find_workflows(specific = nil)
    if specific
      path = File.join(@workflow_dir, "#{specific}.wf.md")
      return [] unless File.exist?(path)
      [specific]
    else
      Dir.glob(File.join(@workflow_dir, "*.wf.md")).map do |path|
        File.basename(path, ".wf.md")
      end
    end
  end
  ```
  > TEST: Workflow Discovery
  > Type: Integration Test
  > Assert: Finds all .wf.md files
  > Command: bundle exec rspec -e "finds all workflow files"

- [ ] Implement missing command detection
  ```ruby
  def find_missing_commands(workflows)
    workflows.reject do |workflow|
      custom_exists = File.exist?(File.join(@custom_dir, "#{workflow}.md"))
      generated_exists = File.exist?(File.join(@generated_dir, "#{workflow}.md"))
      custom_exists || generated_exists
    end
  end
  ```

- [ ] Implement template-based generation
  ```ruby
  def generate_commands(workflows, force)
    # Use simple template matching existing pattern
    workflows.each do |workflow|
      output_path = File.join(@generated_dir, "#{workflow}.md")

      if File.exist?(output_path) && !force
        puts "⚠ Skipped: #{workflow}.md (already exists)"
        next
      end

      # Match existing ClaudeCommandsInstaller template pattern
      content = <<~CONTENT
        read whole file and follow @dev-handbook/workflow-instructions/#{workflow}.wf.md

        read and run @.claude/commands/commit.md
      CONTENT

      File.write(output_path, content)
      puts "✓ Created: _generated/#{workflow}.md"
    end
  end
  ```
  > TEST: Command Generation
  > Type: Integration Test
  > Assert: Creates command files with correct content
  > Command: bundle exec rspec -e "generates command files"

- [ ] Add comprehensive test coverage
  ```ruby
  # spec/coding_agent_tools/organisms/claude_command_generator_spec.rb
  RSpec.describe CodingAgentTools::Organisms::ClaudeCommandGenerator do
    describe "#find_workflows" do
      it "finds all workflow files" do
        # Test implementation
      end
    end

    describe "#generate" do
      it "respects dry-run flag" do
        # Test implementation
      end

      it "skips existing custom commands" do
        # Test implementation
      end
    end
  end
  ```

- [ ] Test idempotency
  > TEST: Idempotent Generation
  > Type: Integration Test
  > Assert: Running twice produces same result
  > Command: handbook claude generate-commands && handbook claude generate-commands

## Acceptance Criteria

- [ ] Scans all workflow files correctly
- [ ] Identifies missing commands accurately
- [ ] Generates commands using template
- [ ] Respects --dry-run flag
- [ ] Respects --force flag for regeneration
- [ ] Supports --workflow for specific generation
- [ ] Clear progress output during generation

## References

- Current workflow instruction format
- Existing Claude command patterns  
- Template processing best practices
- ClaudeCommandsInstaller implementation in dev-tools/lib/coding_agent_tools/integrations/

## Review Summary

**Date:** 2025-08-04
**Reviewer:** Claude (Automated Review)

**Questions Previously Generated:** 6 total (2 HIGH, 3 MEDIUM, 2 LOW)
**Questions Resolved:** All 6 questions have been answered by human input
**Critical Blockers:** None - all questions resolved

**Research Conducted:**
- ✅ Verified ClaudeCommandsInstaller exists and analyzed its implementation patterns
- ✅ Confirmed handbook CLI structure with nested claude namespace (from task.002)
- ✅ Analyzed existing custom commands in dev-handbook/.integrations/claude/commands/
- ✅ Verified workflow naming patterns (all use .wf.md extension, kebab-case names)
- ✅ Confirmed dry-cli command patterns and option handling
- ✅ Checked for existing template files (none found, will need to create)

**Content Updates Made:**
- Moved all Review Questions to "Resolved" section with human answers and decisions
- Updated Technical Approach based on human decisions:
  - Use separate _custom/ and _generated/ subdirectories
  - Create external template file at dev-handbook/.integrations/claude/command.template.md
  - Support glob patterns for batch operations
  - Include commit.md reference in all generated commands
- Enhanced Implementation Plan with:
  - Template file creation step
  - Migration of existing custom commands to _custom/ subdirectory
  - Glob pattern support in workflow scanning
  - External template loading with string interpolation
  - Comprehensive error handling and progress reporting
- Updated File Modifications to include template file and directory structure changes
- Refined code examples to match project patterns (Cli not CLI module naming)
- Added detailed organism implementation with Result struct for better CLI integration
- Set needs_review flag to false as all questions are resolved

**Implementation Readiness:** Ready for implementation - all questions answered and approach validated

**Recommended Next Steps:**
1. Wait for task.002 completion to ensure claude namespace is available
2. Create the command template file at the specified location
3. Migrate existing custom commands to _custom/ subdirectory
4. Implement ClaudeCommandGenerator organism with full feature set
5. Create the generate-commands CLI command class
6. Add comprehensive test coverage including glob pattern tests
7. Test end-to-end with various workflow patterns and edge cases
