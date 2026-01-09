---
id: v.0.6.0+task.005
status: done
priority: high
estimate: 4h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
needs_review: false
---

# Create validate subcommand for coverage checking

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions
- [x] Should the validate command be integrated with the ClaudeCommandsInstaller class or be completely separate?
  - **Research conducted**: ClaudeCommandsInstaller handles installation but doesn't have validation logic
  - **Current structure**: Installer scans workflows and generates/copies commands
  - **Suggested default**: Separate ClaudeValidator class for single responsibility principle
  - **Why needs human input**: Architecture decision - could extend installer or keep separate
  - **Human answer**: keep the ATOM architecture, and if there is need to refactor, let it go, but do not overload the class
  - **Decision**: Create separate ClaudeValidator organism following ATOM architecture

- [x] How should we handle the directory structure difference between custom and generated commands?
  - **Research conducted**: Custom commands in .ace/handbook/.integrations/claude/commands/, installed to .claude/commands/
  - **Current pattern**: ClaudeCommandsInstaller copies from both custom and generates from workflows
  - **Suggested default**: Check both _custom/ and _generated/ subdirectories if they exist
  - **Why needs human input**: Directory structure is evolving with task.003 adding _generated/
  - **Human answer**: we should work on command / agent names (in .ace/handbook they structure is different, but the names should be the same)
  - **Decision**: Check both _custom/ and _generated/ subdirectories, focus on matching command names

### [MEDIUM] Enhancement Questions
- [x] Should validation report format support JSON output for CI/CD integration?
  - **Research conducted**: release validate command supports --format json option
  - **Pattern found**: JSON output used for programmatic consumption in CI pipelines
  - **Suggested default**: Support both text (default) and JSON formats
  - **Why needs human input**: Feature scope and CI/CD requirements
  - **Human answer**: yes
  - **Decision**: Support both text and JSON output formats

- [x] What constitutes "outdated" - file timestamp or content hash comparison?
  - **Research conducted**: ClaudeCommandsInstaller uses File.mtime for comparison
  - **Current approach**: Timestamp-based comparison is simpler and faster
  - **Suggested default**: Use mtime (consistent with installer), add --deep flag for content comparison later
  - **Why needs human input**: Trade-off between accuracy and performance
  - **Human answer**: content hash
  - **Decision**: Use content hash comparison for accuracy

### [LOW] Future Enhancement Questions
- [x] Should validation results be cacheable to speed up repeated runs?
  - **Research conducted**: No caching patterns found in existing validation commands
  - **Suggested default**: No caching initially, add if performance becomes an issue
  - **Why needs human input**: Premature optimization vs future needs
  - **Human answer**: no - we are working on less than 100 files
  - **Decision**: No caching needed for current scale

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
- Separate ClaudeValidator organism following ATOM architecture
- Reuse path resolution and workflow scanning logic from ClaudeCommandsInstaller where appropriate

### Technology Stack
- Ruby for validation logic
- File comparison utilities
- Structured reporting system

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Digest::SHA256 | Content comparison | Accurate change detection via content hash |
| Set | Duplicate detection | Efficient set operations |
| StringIO | Report building | In-memory report generation |

## File Modifications

### Create
- `.ace/tools/lib/coding_agent_tools/cli/commands/handbook/claude/validate.rb` - Command implementation
- `.ace/tools/lib/coding_agent_tools/cli/commands/handbook/claude.rb` - Namespace registration (if not exists)
- `.ace/tools/lib/coding_agent_tools/organisms/claude_validator.rb` - Validation organism
- `.ace/tools/lib/coding_agent_tools/molecules/claude_command_content_generator.rb` - Content generation molecule (shared with installer)
- `.ace/tools/spec/coding_agent_tools/organisms/claude_validator_spec.rb` - Organism tests
- `.ace/tools/spec/coding_agent_tools/molecules/claude_command_content_generator_spec.rb` - Molecule tests

### Modify
- `.ace/tools/lib/coding_agent_tools/cli.rb` - Add claude subcommand registration to handbook namespace:
  ```ruby
  def self.register_handbook_commands
    return if @handbook_commands_registered

    require_relative "cli/commands/handbook/sync_templates"
    require_relative "cli/commands/handbook/claude/validate"

    register "handbook", aliases: [] do |prefix|
      prefix.register "sync-templates", Commands::Handbook::SyncTemplates
      
      # Register claude subcommands
      prefix.register "claude", aliases: [] do |claude|
        claude.register "validate", Commands::Handbook::Claude::Validate
      end
    end

    @handbook_commands_registered = true
  end
  ```
- `.ace/tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb` - Extract content generation to shared molecule (optional refactor)

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

* [x] Define validation rules and severity levels
  - Missing command: ERROR (affects exit code)
  - Outdated command: WARNING (informational) - based on content hash mismatch
  - Duplicate command: WARNING (informational)
  - Orphaned command: INFO (command without workflow)
* [x] Design report format for different output modes
  - Text format: Human-readable with symbols (✓, ✗, ⚠)
  - JSON format: Structured for CI consumption (following release validate pattern)
* [x] Plan whitelist/ignore file format
  - Option 1: .claudeignore file with glob patterns
  - Option 2: Comment directive in workflow files (# claude: skip)
  - Start without whitelist, add if requested
* [x] Define exit code strategy for CI
  - 0: No issues found
  - 1: Errors found (missing commands)
  - Use --strict flag to make warnings fail (exit 1)
* [x] Implement content hash comparison logic
  - Use Digest::SHA256 for content hashing
  - Compare generated template content with actual file content
  - Handle custom commands specially (may have different content)

### Execution Steps

- [x] Implement validate command class
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

- [x] Create validator organism
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
          @workflow_dir = @project_root / ".ace/handbook" / "workflow-instructions"
          @custom_dir = @project_root / ".ace/handbook" / ".integrations" / "claude" / "commands"
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

- [x] Implement missing command detection
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
    # Check in _custom/ and _generated/ subdirectories per task.003 structure
    custom_path = @custom_dir / "_custom" / "#{name}.md"
    generated_path = @custom_dir / "_generated" / "#{name}.md"
    
    # Also check legacy locations for backward compatibility
    legacy_custom = @custom_dir / "#{name}.md"
    legacy_generated = @generated_dir / "#{name}.md" if @generated_dir.exist?
    
    custom_path.exist? || generated_path.exist? || 
    legacy_custom.exist? || (legacy_generated && legacy_generated.exist?)
  end
  ```
  > TEST: Missing Command Detection
  > Type: Integration Test
  > Assert: Finds workflows without commands
  > Command: bundle exec rspec -e "detects missing commands"

- [x] Implement outdated command detection
  ```ruby
  def find_outdated_commands
    require 'digest'
    outdated = []

    all_commands.each do |cmd_path|
      workflow_name = File.basename(cmd_path, ".md")
      workflow_path = File.join(@workflow_dir, "#{workflow_name}.wf.md")

      if File.exist?(workflow_path)
        # Generate expected command content based on workflow
        expected_content = generate_command_content(workflow_path)
        actual_content = File.read(cmd_path)
        
        # Compare content hashes
        expected_hash = Digest::SHA256.hexdigest(expected_content)
        actual_hash = Digest::SHA256.hexdigest(actual_content)
        
        if expected_hash != actual_hash
          outdated << {
            command: File.basename(cmd_path),
            workflow_path: workflow_path,
            expected_hash: expected_hash[0..7], # First 8 chars for display
            actual_hash: actual_hash[0..7]
          }
        end
      end
    end

    outdated
  end
  
  def generate_command_content(workflow_path)
    # Generate the expected command content for comparison
    workflow_name = File.basename(workflow_path)
    <<~CONTENT
      read whole file and follow @.ace/handbook/workflow-instructions/#{workflow_name}

      read and run @.claude/commands/commit.md
    CONTENT
  end
  ```

- [x] Implement duplicate detection
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

- [x] Implement orphaned command detection
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

- [x] Implement report generation
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

- [x] Add comprehensive test coverage
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

- [x] Test CI integration
  > TEST: Exit Code Behavior
  > Type: Integration Test
  > Assert: Returns 1 with --strict and issues
  > Command: handbook claude validate --strict; echo $?

- [x] Add content hash comparison tests
  > TEST: Content Hash Detection
  > Type: Unit Test
  > Assert: Detects outdated commands via content hash
  > Command: bundle exec rspec -e "detects content changes"

## Acceptance Criteria

- [x] Detects all missing commands accurately
- [x] Identifies outdated commands based on content hash
- [x] Finds duplicate commands across directories
- [x] Generates clear, actionable reports
- [x] Supports specific workflow validation
- [x] Provides proper exit codes for CI
- [x] Handles edge cases gracefully

## Review Summary

**Date:** 2025-08-04
**Reviewer:** Claude (Automated Review)

**Questions Generated:** 5 total (2 HIGH, 2 MEDIUM, 1 LOW)

**Questions Answered by User:** 5 (All questions resolved)
- Architecture: Keep ATOM architecture, separate ClaudeValidator class
- Directory structure: Check both _custom/ and _generated/ subdirectories
- JSON output: Yes, support both text and JSON formats
- Staleness detection: Use content hash comparison instead of timestamps
- Caching: Not needed for ~100 files

**Research Conducted (Current Review):**
- ✅ Deep analysis of ClaudeCommandsInstaller implementation (215 lines)
- ✅ Examined existing validator patterns in the codebase (10+ validator files found)
- ✅ Reviewed release validate command for JSON/text output patterns
- ✅ Investigated CLI registration in handbook namespace
- ✅ Checked task.003 for _generated/ directory structure details
- ✅ Analyzed ATOM architecture patterns in existing validators
- ✅ No Digest usage found - will need to add for content hashing

**Content Updates Made (Current Review):**
- Changed needs_review flag to false (all questions resolved)
- Marked all review questions as resolved with decisions
- Updated implementation to use Digest::SHA256 for content comparison
- Enhanced architecture pattern section with ATOM adherence notes
- Added shared molecule for content generation (DRY principle)
- Updated file modifications to include refactoring of installer
- Added content hash comparison tests
- Updated command_exists? to check new _custom/ and _generated/ structure
- Added generate_command_content method for hash comparison
- Updated planning steps to include content hash implementation

**Implementation Readiness:** READY - All questions resolved, clear technical approach defined

**Architecture Decisions:**
1. **ATOM Compliance**: Create ClaudeValidator as separate organism
2. **Content Generation**: Extract to shared molecule (ClaudeCommandContentGenerator)
3. **Directory Structure**: Support both _custom/ and _generated/ subdirectories
4. **Comparison Method**: Use SHA256 content hashing for accuracy
5. **Output Formats**: Support both text and JSON (following release validate pattern)

**Key Technical Details:**
- Use Digest::SHA256 for content comparison
- Generate expected command content for comparison
- Handle custom commands specially (different content expected)
- Support multi-task commands that don't map 1:1 to workflows
- Implement proper exit codes for CI integration (0=success, 1=errors)

**Next Steps:**
1. Create ClaudeValidator organism with content hash comparison
2. Extract shared content generation logic to molecule
3. Implement JSON output format support
4. Add comprehensive test coverage
5. Update CLI registration for handbook claude validate command
