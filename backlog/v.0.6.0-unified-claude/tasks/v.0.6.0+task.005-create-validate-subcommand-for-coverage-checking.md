---
id: v.0.6.0+task.005
status: pending
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Create validate subcommand for coverage checking

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude validate` to check command coverage
- **Process**: System analyzes workflows vs commands and reports gaps or issues
- **Output**: Comprehensive validation report with actionable findings

### Expected Behavior
The system should perform a comprehensive validation of Claude command coverage by comparing workflow instruction files against existing commands. It should identify missing commands, outdated commands, duplicates, and any other consistency issues. The validation should provide clear, actionable feedback to help developers maintain complete and accurate Claude integration.

### Interface Contract
```bash
# Full validation
handbook claude validate
# Output:
Validating Claude command coverage...

Workflows found: 25
Commands found: 23

✗ Missing commands:
  - capture-idea.wf.md (no command found)
  - rebase-against.wf.md (no command found)

⚠ Outdated commands (workflow modified after command):
  - draft-task.md (workflow updated 2 days ago)

⚠ Duplicate commands:
  - plan-task appears in both _custom/ and _generated/

✓ Valid commands: 20

Summary: 2 missing, 1 outdated, 1 duplicate

# Validate with specific checks
handbook claude validate --check missing
# Output:
Checking for missing commands...
✗ Missing commands:
  - capture-idea.wf.md
  - rebase-against.wf.md

# Validate with exit code
handbook claude validate --strict
# Output:
[Same validation output]
# Exit code: 1 (if any issues found)

# Validate specific workflow
handbook claude validate --workflow draft-task
# Output:
Validating draft-task workflow...
✓ Command exists: _custom/draft-task.md
✓ Command is up to date
✓ No duplicates found
```

**Error Handling:**
- Missing directories: Report what's missing
- Permission issues: Clear error about access
- Malformed files: Report and continue validation

**Edge Cases:**
- Workflows without commands needed: Whitelist support
- Commands without workflows: Report as orphaned
- Symbolic links: Follow and validate
- Case sensitivity: Handle gracefully

### Success Criteria
- [ ] **Coverage Analysis**: All workflows checked for commands
- [ ] **Duplicate Detection**: Same-named commands identified
- [ ] **Freshness Check**: Outdated commands detected
- [ ] **Clear Reporting**: Issues presented actionably
- [ ] **Exit Codes**: Proper codes for CI integration

### Validation Questions
- [ ] **Whitelist Support**: How to mark workflows that don't need commands?
- [ ] **Staleness Definition**: How old before a command is "outdated"?
- [ ] **Validation Levels**: Should there be warning vs error severity?
- [ ] **Custom Rules**: Should validation be configurable?

## Objective

Provide comprehensive validation of Claude command coverage to ensure all workflows have appropriate commands and maintain integration quality.

## Scope of Work

- **User Experience Scope**: Validation workflow and reporting
- **System Behavior Scope**: Coverage analysis and issue detection
- **Interface Scope**: CLI options and report formats

### Deliverables

#### Behavioral Specifications
- Validation rule documentation
- Report format specifications
- Exit code conventions

#### Validation Artifacts
- Coverage calculation tests
- Issue detection accuracy tests
- Report format validation

## Out of Scope
- ❌ **Implementation Details**: File comparison algorithms
- ❌ **Technology Decisions**: Diff libraries or tools
- ❌ **Performance Optimization**: Caching validation results
- ❌ **Future Enhancements**: Auto-fixing issues, IDE integration

## References

- Workflow instruction conventions
- Command file standards
- CI/CD best practices for validation tools

## Technical Approach

### Architecture Pattern
- Validation engine pattern with pluggable checks
- Report builder for different output formats
- Exit code management for CI integration

### Technology Stack
- Ruby for validation logic
- File comparison utilities
- Structured reporting system

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| File.mtime | Freshness checking | Built-in, reliable timestamps |
| Set | Duplicate detection | Efficient set operations |
| StringIO | Report building | In-memory report generation |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/validate.rb` - Command implementation
- `dev-tools/lib/coding_agent_tools/organisms/claude_validator.rb` - Validation logic
- `dev-tools/spec/coding_agent_tools/organisms/claude_validator_spec.rb` - Tests

### Modify
- None required

### Delete
- None required

## Risk Assessment

### Technical Risks
- **Performance on Large Projects**: Many workflows could slow validation
  - Mitigation: Implement caching for repeated validations
- **File System Race Conditions**: Files changing during validation
  - Mitigation: Single pass snapshot approach

### Integration Risks
- **CI/CD Exit Codes**: Non-standard codes might break pipelines
  - Mitigation: Use standard 0/1 exit codes
- **Whitelist Management**: Complex exclusion rules
  - Mitigation: Simple pattern-based whitelist file

## Implementation Plan

### Planning Steps

* [ ] Define validation rules and severity levels
* [ ] Design report format for different output modes
* [ ] Plan whitelist/ignore file format
* [ ] Define exit code strategy for CI

### Execution Steps

- [ ] Implement validate command class
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude/validate.rb
  module CodingAgentTools
    module CLI
      module Commands
        module Handbook
          module Claude
            class Validate < Dry::CLI::Command
              desc "Validate Claude command coverage"
              
              option :check, type: :string, desc: "Specific check to run (missing, outdated, duplicates)"
              option :strict, type: :boolean, default: false, desc: "Exit with code 1 if issues found"
              option :workflow, type: :string, desc: "Validate specific workflow"
              
              def call(**options)
                validator = CodingAgentTools::Organisms::ClaudeValidator.new
                result = validator.validate(options)
                
                exit(1) if options[:strict] && result.has_issues?
              end
            end
          end
        end
      end
    end
  end
  ```

- [ ] Create validator organism
  ```ruby
  # lib/coding_agent_tools/organisms/claude_validator.rb
  module CodingAgentTools
    module Organisms
      class ClaudeValidator
        def initialize
          @workflow_dir = "dev-handbook/workflow-instructions"
          @custom_dir = "dev-handbook/.integrations/claude/commands/_custom"
          @generated_dir = "dev-handbook/.integrations/claude/commands/_generated"
        end
        
        def validate(options)
          if options[:workflow]
            validate_single_workflow(options[:workflow])
          elsif options[:check]
            run_specific_check(options[:check])
          else
            run_all_validations
          end
        end
      end
    end
  end
  ```
  > TEST: Validator Initialization
  > Type: Unit Test
  > Assert: Validator initializes with correct paths
  > Command: bundle exec rspec -e "initializes with paths"

- [ ] Implement missing command detection
  ```ruby
  def find_missing_commands
    workflows = Dir.glob(File.join(@workflow_dir, "*.wf.md"))
    missing = []
    
    workflows.each do |workflow_path|
      name = File.basename(workflow_path, ".wf.md")
      unless command_exists?(name)
        missing << name
      end
    end
    
    missing
  end
  
  def command_exists?(name)
    File.exist?(File.join(@custom_dir, "#{name}.md")) ||
    File.exist?(File.join(@generated_dir, "#{name}.md"))
  end
  ```
  > TEST: Missing Command Detection
  > Type: Integration Test
  > Assert: Finds workflows without commands
  > Command: bundle exec rspec -e "detects missing commands"

- [ ] Implement outdated command detection
  ```ruby
  def find_outdated_commands
    outdated = []
    
    all_commands.each do |cmd_path|
      workflow_name = File.basename(cmd_path, ".md")
      workflow_path = File.join(@workflow_dir, "#{workflow_name}.wf.md")
      
      if File.exist?(workflow_path)
        if File.mtime(workflow_path) > File.mtime(cmd_path)
          outdated << {
            command: File.basename(cmd_path),
            workflow_updated: File.mtime(workflow_path),
            command_updated: File.mtime(cmd_path)
          }
        end
      end
    end
    
    outdated
  end
  ```

- [ ] Implement duplicate detection
  ```ruby
  def find_duplicate_commands
    custom_commands = Dir.glob(File.join(@custom_dir, "*.md")).map { |p| File.basename(p, ".md") }
    generated_commands = Dir.glob(File.join(@generated_dir, "*.md")).map { |p| File.basename(p, ".md") }
    
    duplicates = custom_commands & generated_commands
    duplicates.map { |name| "#{name} appears in both _custom/ and _generated/" }
  end
  ```
  > TEST: Duplicate Detection
  > Type: Unit Test
  > Assert: Finds commands in both directories
  > Command: bundle exec rspec -e "detects duplicates"

- [ ] Implement report generation
  ```ruby
  def generate_report(validation_results)
    report = StringIO.new
    
    report.puts "Validating Claude command coverage..."
    report.puts ""
    report.puts "Workflows found: #{validation_results[:workflow_count]}"
    report.puts "Commands found: #{validation_results[:command_count]}"
    report.puts ""
    
    if validation_results[:missing].any?
      report.puts "✗ Missing commands:"
      validation_results[:missing].each do |name|
        report.puts "  - #{name}.wf.md (no command found)"
      end
      report.puts ""
    end
    
    # ... similar for outdated and duplicates
    
    report.string
  end
  ```

- [ ] Add comprehensive test coverage
  ```ruby
  # spec/coding_agent_tools/organisms/claude_validator_spec.rb
  RSpec.describe CodingAgentTools::Organisms::ClaudeValidator do
    describe "#validate" do
      it "runs all validations by default" do
        # Test implementation
      end
      
      it "validates single workflow when specified" do
        # Test implementation
      end
      
      it "runs specific check when requested" do
        # Test implementation
      end
    end
  end
  ```

- [ ] Test CI integration
  > TEST: Exit Code Behavior
  > Type: Integration Test
  > Assert: Returns 1 with --strict and issues
  > Command: handbook claude validate --strict; echo $?

## Acceptance Criteria

- [ ] Detects all missing commands accurately
- [ ] Identifies outdated commands based on timestamps
- [ ] Finds duplicate commands across directories
- [ ] Generates clear, actionable reports
- [ ] Supports specific workflow validation
- [ ] Provides proper exit codes for CI
- [ ] Handles edge cases gracefully