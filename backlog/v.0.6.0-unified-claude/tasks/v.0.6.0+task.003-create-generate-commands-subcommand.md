---
id: v.0.6.0+task.003
status: pending
priority: high
estimate: 6h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Create generate-commands subcommand

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
- [ ] **Template Variables**: What variables should templates support?
- [ ] **Naming Conflicts**: How to handle workflows with similar names?
- [ ] **Generation Rules**: Should some workflows never have commands?

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
- Template-based generation with ERB
- Command registry integration for tracking

### Technology Stack
- Ruby File/Dir for filesystem scanning
- ERB for template processing
- JSON for command registry updates

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Dir.glob | Workflow scanning | Built-in, efficient pattern matching |
| ERB | Template processing | Standard Ruby templating |
| FileUtils | File operations | Standard library reliability |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/generate_commands.rb` - Command implementation
- `dev-tools/lib/coding_agent_tools/organisms/claude_command_generator.rb` - Business logic
- `dev-tools/spec/coding_agent_tools/organisms/claude_command_generator_spec.rb` - Tests

### Modify
- `dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl` - Ensure template exists

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

* [ ] Analyze workflow naming patterns in dev-handbook
* [ ] Define template variable requirements
* [ ] Design command detection logic (custom vs missing)
* [ ] Plan dry-run implementation approach

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
          @custom_dir = "dev-handbook/.integrations/claude/commands/_custom"
          @generated_dir = "dev-handbook/.integrations/claude/commands/_generated"
          @template_path = "dev-handbook/.integrations/claude/templates/workflow-command.md.tmpl"
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
    template = ERB.new(File.read(@template_path))
    
    workflows.each do |workflow|
      output_path = File.join(@generated_dir, "#{workflow}.md")
      
      if File.exist?(output_path) && !force
        puts "⚠ Skipped: #{workflow}.md (already exists)"
        next
      end
      
      content = template.result_with_hash(workflow_name: workflow)
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