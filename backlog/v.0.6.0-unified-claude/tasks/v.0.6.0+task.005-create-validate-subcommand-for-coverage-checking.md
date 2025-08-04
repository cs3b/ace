---
id: v.0.6.0+task.005
status: pending
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
needs_review: true
---

# Create validate subcommand for coverage checking

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Should the validate command be integrated with the ClaudeCommandsInstaller class or be completely separate?
  - **Research conducted**: ClaudeCommandsInstaller handles installation but doesn't have validation logic
  - **Current structure**: Installer scans workflows and generates/copies commands
  - **Suggested default**: Separate ClaudeValidator class for single responsibility principle
  - **Why needs human input**: Architecture decision - could extend installer or keep separate

> keep the ATOM architecture, and if there is need to refactor, let it go, but do not overload the class

- [ ] How should we handle the directory structure difference between custom and generated commands?
  - **Research conducted**: Custom commands in dev-handbook/.integrations/claude/commands/, installed to .claude/commands/
  - **Current pattern**: ClaudeCommandsInstaller copies from both custom and generates from workflows
  - **Suggested default**: Check both _custom/ and _generated/ subdirectories if they exist
  - **Why needs human input**: Directory structure is evolving with task.003 adding _generated/

> we should work on command / agent names (in dev-handbook they structure is different, but the names should be the same))

### [MEDIUM] Enhancement Questions
- [ ] Should validation report format support JSON output for CI/CD integration?
  - **Research conducted**: release validate command supports --format json option
  - **Pattern found**: JSON output used for programmatic consumption in CI pipelines
  - **Suggested default**: Support both text (default) and JSON formats
  - **Why needs human input**: Feature scope and CI/CD requirements

> yes

- [ ] What constitutes "outdated" - file timestamp or content hash comparison?
  - **Research conducted**: ClaudeCommandsInstaller uses File.mtime for comparison
  - **Current approach**: Timestamp-based comparison is simpler and faster
  - **Suggested default**: Use mtime (consistent with installer), add --deep flag for content comparison later
  - **Why needs human input**: Trade-off between accuracy and performance

> content hash

### [LOW] Future Enhancement Questions
- [ ] Should validation results be cacheable to speed up repeated runs?
  - **Research conducted**: No caching patterns found in existing validation commands
  - **Suggested default**: No caching initially, add if performance becomes an issue
  - **Why needs human input**: Premature optimization vs future needs

> no - we are working on less then 100 files

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
  - **[Research conducted]**: No existing whitelist patterns found in codebase
  - **[Pattern analysis]**: All workflows appear to be command-eligible
  - **[Suggested approach]**: Add .claudeignore file or comment directive in workflow files
- [ ] **Staleness Definition**: How old before a command is "outdated"?
  - **[Resolved through research]**: Any workflow newer than its command file (mtime comparison)
  - **[Consistent with]**: ClaudeCommandsInstaller already uses this approach
- [ ] **Validation Levels**: Should there be warning vs error severity?
  - **[Research conducted]**: Release validate uses simple pass/fail with exit codes
  - **[Suggested default]**: Missing = error, outdated = warning, duplicate = warning
- [ ] **Custom Rules**: Should validation be configurable?
  - **[Research conducted]**: No config files found for Claude commands
  - **[Suggested default]**: Start with hardcoded rules, add config file if needed

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
  - Missing command: ERROR (affects exit code)
  - Outdated command: WARNING (informational)
  - Duplicate command: WARNING (informational)
  - Orphaned command: INFO (command without workflow)
* [ ] Design report format for different output modes
  - Text format: Human-readable with symbols (✓, ✗, ⚠)
  - JSON format: Structured for CI consumption (following release validate pattern)
* [ ] Plan whitelist/ignore file format
  - Option 1: .claudeignore file with glob patterns
  - Option 2: Comment directive in workflow files (# claude: skip)
  - Start without whitelist, add if requested
* [ ] Define exit code strategy for CI
  - 0: No issues found
  - 1: Errors found (missing commands)
  - Use --strict flag to make warnings fail (exit 1)

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
  require 'pathname'
  require 'json'

  module CodingAgentTools
    module Organisms
      class ClaudeValidator
        attr_reader :project_root, :validation_results

        def initialize(project_root = nil)
          @project_root = Pathname.new(project_root || find_project_root)
          @workflow_dir = @project_root / "dev-handbook" / "workflow-instructions"
          @custom_dir = @project_root / "dev-handbook" / ".integrations" / "claude" / "commands"
          @generated_dir = @custom_dir / "_generated"
          @claude_dir = @project_root / ".claude" / "commands"
          @validation_results = {
            workflow_count: 0,
            command_count: 0,
            missing: [],
            outdated: [],
            duplicates: [],
            orphaned: [],
            valid: []
          }
        end

        def validate(options = {})
          if options[:workflow]
            validate_single_workflow(options[:workflow])
          elsif options[:check]
            run_specific_check(options[:check])
          else
            run_all_validations
          end

          format_output(options[:format] || 'text')
        end

        def has_issues?
          validation_results[:missing].any? ||
          validation_results[:outdated].any? ||
          validation_results[:duplicates].any?
        end

        private

        def find_project_root
          # Reuse logic from ClaudeCommandsInstaller
          current = Pathname.pwd
          while current.parent != current
            return current if (current / '.claude' / 'commands').directory?
            current = current.parent
          end
          Pathname.pwd
        end
      end
    end
  end
  ```
  > TEST: Validator Initialization
  > Type: Unit Test
  > Assert: Validator initializes with correct paths and finds project root
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
    custom_commands = @custom_dir.glob("*.md").map { |p| p.basename(".md").to_s } if @custom_dir.exist?
    generated_commands = @generated_dir.glob("*.md").map { |p| p.basename(".md").to_s } if @generated_dir.exist?

    return [] unless custom_commands && generated_commands

    duplicates = custom_commands & generated_commands
    duplicates.map { |name| { name: name, locations: ["_custom/", "_generated/"] } }
  end
  ```
  > TEST: Duplicate Detection
  > Type: Unit Test
  > Assert: Finds commands in both directories
  > Command: bundle exec rspec -e "detects duplicates"

- [ ] Implement orphaned command detection
  ```ruby
  def find_orphaned_commands
    workflows = @workflow_dir.glob("*.wf.md").map { |p| p.basename(".wf.md").to_s }

    orphaned = []

    # Check .claude/commands directory
    if @claude_dir.exist?
      @claude_dir.glob("*.md").each do |cmd_path|
        cmd_name = cmd_path.basename(".md").to_s
        unless workflows.include?(cmd_name) || is_multi_task_command?(cmd_name)
          orphaned << { name: cmd_name, location: ".claude/commands/" }
        end
      end
    end

    orphaned
  end

  def is_multi_task_command?(name)
    # Commands that handle multiple tasks don't map 1:1 to workflows
    %w[commit handbook-review load-project-context draft-tasks plan-tasks review-tasks work-on-tasks].include?(name)
  end
  ```
  > TEST: Orphaned Command Detection
  > Type: Unit Test
  > Assert: Finds commands without corresponding workflows
  > Command: bundle exec rspec -e "detects orphaned commands"

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

## Review Summary

**Date:** 2025-08-04
**Reviewer:** Claude (Automated Review)

**Questions Generated:** 8 total (2 HIGH, 2 MEDIUM, 1 LOW, 3 validation questions)

**Questions Resolved Through Research:** 3
- Staleness definition: Use mtime comparison (consistent with ClaudeCommandsInstaller)
- Validation levels: Missing=error, outdated/duplicate=warning pattern
- Custom rules: Start without configuration, add if needed

**Critical Blockers:** 2 HIGH priority questions need human input:
1. Architecture decision on ClaudeValidator vs extending ClaudeCommandsInstaller
2. Directory structure handling for custom vs generated commands

**Research Conducted:**
- ✅ Analyzed ClaudeCommandsInstaller implementation and patterns
- ✅ Reviewed release validate command for output format patterns
- ✅ Checked for existing whitelist/configuration patterns (none found)
- ✅ Investigated project structure and command locations
- ✅ Examined CLI registration patterns in handbook namespace
- ✅ Verified no commands.json file exists currently
- ✅ Found no workflow annotations for skipping command generation

**Content Updates Made:**
- Added Review Questions section with detailed research context
- Enhanced Planning Steps with specific validation rules and severity levels
- Improved validator organism implementation with proper Pathname usage
- Added orphaned command detection logic
- Included multi-task command recognition
- Updated code examples to use Pathname API consistently
- Added JSON output format support following release validate pattern
- Clarified exit code strategy for CI integration

**Implementation Readiness:** Ready with assumptions - can proceed with suggested defaults if human input not provided

**Recommended Next Steps:**
1. Answer HIGH priority questions about architecture and directory structure
2. Consider JSON output format requirement for CI/CD
3. Decide on timestamp vs content comparison for staleness
4. Implementation can proceed with suggested defaults:
   - Separate ClaudeValidator class (single responsibility)
   - Check both _custom/ and _generated/ directories
   - Support text and JSON output formats
   - Use mtime for staleness detection

**Key Insights from Research:**
- ClaudeCommandsInstaller provides good patterns to follow but shouldn't be extended
- Release validate command provides excellent template for JSON/text output handling
- Project uses Pathname consistently for path operations
- No existing configuration infrastructure for Claude commands
- Multi-task commands need special handling as they don't map 1:1 to workflows
