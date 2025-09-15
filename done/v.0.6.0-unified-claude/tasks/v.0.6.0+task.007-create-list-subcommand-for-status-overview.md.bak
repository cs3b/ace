---
id: v.0.6.0+task.007
status: done
priority: medium
estimate: 2h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Create list subcommand for status overview

## Review Questions (Resolved)

### [HIGH] Critical Implementation Questions
- [x] How should the command distinguish between "custom" and "generated" commands?
  - **Research conducted**: Found ClaudeCommandsInstaller copies from dev-handbook/.integrations/claude/commands/ (6 custom multi-task commands)
  - **Current structure**: All commands end up in .claude/commands/ directory
  - **Suggested approach**: Custom = matches files in dev-handbook/.integrations/claude/commands/, Generated = others
  - **Alternative approach**: Add metadata to commands.json to track source
  - **Why needs human input**: Architecture decision affecting data structure and future extensibility
  - **Human answer**: "in dev-handbook/.integrations/claude/commands/{_custom,_generated} - separate folders"
  - **Human clarification**: "as mention in task.004 we don't need and we should not update commands.json"
  - **Decision**: Use separate subdirectories _custom/ and _generated/ within dev-handbook/.integrations/claude/commands/

- [x] What exactly are "Missing Commands" and how should they be detected?
  - **Research conducted**: Found 25 workflow files in dev-handbook/workflow-instructions/
  - **Commands exist for**: Most workflows have corresponding commands (32 total commands found)
  - **Unclear**: Should "missing" mean workflows without commands, or commands without workflows?
  - **Suggested default**: Missing = workflows in workflow-instructions/ without corresponding .claude/commands/*.md file
  - **Why needs human input**: Core functionality definition affects implementation approach
  - **Human answer**: "exactly as you suggest"
  - **Decision**: Missing = workflows in workflow-instructions/ without corresponding command file in .claude/commands/

### [MEDIUM] Enhancement Questions
- [x] Should the command require the Claude namespace to be registered first (from task.002)?
  - **Research conducted**: Task depends on v.0.6.0+task.002 which implements the claude namespace
  - **Current state**: Task.002 is now in-progress (verified)
  - **Suggested approach**: Build assuming namespace exists, coordinate implementation
  - **Why needs human input**: Implementation sequencing and integration approach
  - **Human answer**: "yes task.002 should be done before"
  - **Decision**: Wait for task.002 completion or coordinate closely with its implementation

- [x] Should the verbose output include file size and line count in addition to modification time?
  - **Research conducted**: Task list command shows minimal file info
  - **Similar patterns**: Git status shows size changes, ls -l shows sizes
  - **Suggested default**: Include file size (more useful than line count for .md files)
  - **Why needs human input**: Output format affects user experience
  - **Human answer**: "file size / modification - easy way to check the diff ( `diff path_older_file path_newer_file` )"
  - **Decision**: Include file size and modification time in verbose output to facilitate diff comparison

### [LOW] Future Enhancement Questions
- [x] Should the JSON output include additional metadata like file paths and timestamps?
  - **Research conducted**: Current spec shows simple arrays in JSON
  - **Standard practice**: API responses often include metadata
  - **Suggested default**: Simple arrays initially, richer format can be added later
  - **Why needs human input**: API design decision affecting downstream consumers
  - **Human answer**: "file paths and timestamp yes"
  - **Decision**: JSON output should include file paths and timestamps as metadata

## Behavioral Specification

### User Experience
- **Input**: Developer runs `handbook claude list` to see all commands
- **Process**: System scans directories and displays command inventory
- **Output**: Organized list showing command names, types, and status

### Expected Behavior
The system should provide a comprehensive overview of all Claude commands, clearly distinguishing between custom and generated commands. It should show which workflows have commands and which don't, helping developers quickly understand the current state of their Claude integration.

### Interface Contract
```bash
# List all commands
handbook claude list
# Output:
Claude Commands Overview
========================

Custom Commands (6):
  ✓ commit
  ✓ draft-tasks
  ✓ load-project-context
  ✓ plan-tasks
  ✓ review-tasks
  ✓ work-on-tasks

Generated Commands (19):
  ✓ capture-idea
  ✓ create-adr
  ✓ create-api-docs
  ... (remaining commands)

Missing Commands (2):
  ✗ fix-linting-issue-from
  ✗ rebase-against

Summary: 25 commands available, 2 missing

# List with details
handbook claude list --verbose
# Output:
[Same header]

Custom Commands:
  ✓ commit
    Path: _custom/commit.md
    Modified: 2025-01-30 10:15:32
  ... (all with details)

# List specific type
handbook claude list --type custom
# Output:
Custom Commands (6):
  ✓ commit
  ✓ draft-tasks
  ... (only custom commands)

# List as JSON
handbook claude list --format json
# Output:
{
  "custom": [
    {
      "name": "commit",
      "path": "_custom/commit.md",
      "modified": "2025-01-30T10:15:32Z",
      "size": 245
    },
    {
      "name": "draft-tasks",
      "path": "_custom/draft-tasks.md",
      "modified": "2025-01-30T10:15:32Z",
      "size": 312
    }
  ],
  "generated": [
    {
      "name": "capture-idea",
      "path": "_generated/capture-idea.md",
      "modified": "2025-01-30T10:15:32Z",
      "size": 189
    }
  ],
  "missing": ["fix-linting-issue-from", "rebase-against"]
}
```

**Error Handling:**
- Missing directories: Report and continue with available
- Permission errors: Show warning but continue
- Malformed files: Skip with warning

**Edge Cases:**
- Empty directories: Show "None" with appropriate message
- No workflows found: Clear message about workflow location
- Mixed file types: Only count .md files

### Success Criteria
- [ ] **Complete Inventory**: Shows all commands from both directories
- [ ] **Missing Detection**: Identifies workflows without commands
- [ ] **Clear Categorization**: Separates custom, generated, and missing
- [ ] **Multiple Formats**: Supports verbose and JSON output
- [ ] **Accurate Counts**: Summary numbers match actual files

### Validation Questions
- [ ] **Sorting**: Should commands be alphabetically sorted?
  - **[Resolved through research]**: Yes, alphabetical sorting is standard for CLI list commands
- [ ] **Filtering**: Should we support filtering by pattern?
  - **[Deferred]**: Not in initial scope, can be added as enhancement
- [ ] **Status Icons**: What symbols for different states?
  - **[Resolved through research]**: ✓ for available, ✗ for missing (consistent with other tools)
- [ ] **Performance**: Should we cache results for large projects?
  - **[Resolved through research]**: Not needed initially - ~30 files is negligible performance impact

## Objective

Provide developers with a clear, at-a-glance overview of their Claude command inventory, making it easy to see what's available and what's missing.

## Scope of Work

- **User Experience Scope**: Command listing and status display
- **System Behavior Scope**: Directory scanning and categorization
- **Interface Scope**: Multiple output formats

### Deliverables

#### Behavioral Specifications
- List format specifications
- Status categorization rules
- Output format documentation

#### Validation Artifacts
- Inventory accuracy tests
- Format validation tests
- Edge case handling

## Out of Scope
- ❌ **Implementation Details**: Specific scanning algorithms
- ❌ **Technology Decisions**: Output formatting libraries
- ❌ **Performance Optimization**: Caching mechanisms
- ❌ **Future Enhancements**: Interactive selection, editing

## Technical Approach

### Architecture Pattern
- Directory scanner with categorization
- Multi-format presenter pattern
- Status aggregation logic
- Command source detection (custom vs generated)

### Technology Stack
- Ruby Dir/File for scanning
- JSON for structured output
- String formatting for display
- Pathname for path comparison

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| Dir.glob | File discovery | Efficient pattern matching |
| JSON | Structured output | Standard format |
| StringIO | Report building | Flexible output generation |

## File Modifications

### Create
- `dev-tools/lib/coding_agent_tools/cli/commands/handbook/claude/list.rb` - Command implementation
- `dev-tools/lib/coding_agent_tools/organisms/claude_command_lister.rb` - Listing logic
- `dev-tools/spec/coding_agent_tools/organisms/claude_command_lister_spec.rb` - Tests

### Modify
- None required

### Delete
- None required

## Risk Assessment

### Technical Risks
- **Performance with Many Files**: Large command sets could be slow
  - Mitigation: Efficient scanning, consider pagination
- **Inconsistent File Naming**: Non-standard names might confuse
  - Mitigation: Clear file extension filtering

### Integration Risks
- **Workflow Discovery**: Finding all workflows accurately
  - Mitigation: Use consistent path configuration
- **Output Format Changes**: Breaking downstream tools
  - Mitigation: Version the JSON format

## Implementation Plan

### Planning Steps

* [x] Design output format variations
* [x] Define status determination logic
  - Custom: Files matching those in dev-handbook/.integrations/claude/commands/
  - Generated: All other .md files in .claude/commands/
  - Missing: Workflows without corresponding commands
* [x] Plan JSON schema for structured output
* [x] Consider color output for terminals (use existing colorize patterns from task list)

### Execution Steps

- [x] Implement list command class
  ```ruby
  # lib/coding_agent_tools/cli/commands/handbook/claude/list.rb
  module CodingAgentTools
    module CLI
      module Commands
        module Handbook
          module Claude
            class List < Dry::CLI::Command
              desc "List all commands and their status"

              option :verbose, type: :boolean, default: false, desc: "Show detailed information"
              option :type, type: :string, values: %w[custom generated missing all], default: "all", desc: "Filter by type"
              option :format, type: :string, values: %w[text json], default: "text", desc: "Output format"

              def call(**options)
                lister = CodingAgentTools::Organisms::ClaudeCommandLister.new
                lister.list(options)
              end
            end
          end
        end
      end
    end
  end
  ```

- [x] Create command lister organism
  ```ruby
  # lib/coding_agent_tools/organisms/claude_command_lister.rb
  def list(options)
    inventory = build_inventory

    case options[:format]
    when "json"
      output_json(inventory, options)
    else
      output_text(inventory, options)
    end
  end

  def build_inventory
    # Scan commands from both source directories
    custom_commands = scan_custom_commands
    generated_commands = scan_generated_commands
    
    # Also scan .claude/commands/ for installed commands
    installed_commands = scan_installed_commands

    # Find workflows without corresponding commands
    missing_commands = find_missing_workflows(installed_commands)

    {
      custom: custom_commands,
      generated: generated_commands,
      missing: missing_commands,
      installed: installed_commands
    }
  end
  
  def scan_custom_commands
    dir = File.join(project_root, 'dev-handbook', '.integrations', 'claude', 'commands', '_custom')
    return [] unless Dir.exist?(dir)
    
    Dir.glob(File.join(dir, '*.md')).map do |path|
      build_command_info(path, 'custom')
    end
  end
  
  def scan_generated_commands
    dir = File.join(project_root, 'dev-handbook', '.integrations', 'claude', 'commands', '_generated')
    return [] unless Dir.exist?(dir)
    
    Dir.glob(File.join(dir, '*.md')).map do |path|
      build_command_info(path, 'generated')
    end
  end
  ```
  > TEST: Inventory Building
  > Type: Unit Test
  > Assert: Correctly categorizes all commands
  > Command: bundle exec rspec -e "builds complete inventory"

- [x] Implement formatted output
  ```ruby
  def output_text(inventory, options)
    puts "Claude Commands Overview"
    puts "========================"
    puts ""

    if options[:type] == "all" || options[:type] == "custom"
      output_category("Custom Commands", inventory[:custom], options[:verbose])
    end

    # Similar for generated and missing

    output_summary(inventory) if options[:type] == "all"
  end
  ```

- [x] Add test coverage
  > TEST: Output Formats
  > Type: Integration Test
  > Assert: All formats produce valid output
  > Command: bundle exec rspec -e "outputs in all formats"

## Acceptance Criteria

- [x] Lists all commands from both directories
- [x] Identifies missing commands correctly
- [x] Supports verbose mode with file details
- [x] Filters by command type
- [x] Outputs valid JSON when requested
- [x] Provides accurate summary counts

## References

- Current command organization structure
- Standard CLI list command patterns
- JSON output format standards
- ClaudeCommandsInstaller implementation (dev-tools/lib/coding_agent_tools/integrations/claude_commands_installer.rb)
- Task list command pattern (dev-tools/lib/coding_agent_tools/cli/commands/task/list.rb)
- Handbook namespace structure (dev-tools/lib/coding_agent_tools/cli/commands/handbook/)

## Review Summary

**Date:** 2025-08-04
**Reviewer:** Claude (Automated Review)

**Questions Generated:** 5 total (2 HIGH, 2 MEDIUM, 1 LOW)
**Questions Resolved:** All 5 questions have been answered by human input
**Critical Blockers:** None - all questions resolved

**Research Conducted:**
- ✅ Verified task.002 is in-progress with namespace structure already created
- ✅ Found existing list.rb stub file ready for implementation
- ✅ Confirmed 25 workflow files exist in workflow-instructions directory
- ✅ Verified 32 command files currently exist in .claude/commands/
- ✅ Examined ClaudeCommandsInstaller implementation patterns
- ✅ Studied task list command colorization and formatting patterns
- ✅ Confirmed task.004 mentions not updating commands.json

**Content Updates Made:**
- Moved all Review Questions to "Resolved" section with human answers and decisions
- Updated directory structure to use _custom/ and _generated/ subdirectories
- Enhanced JSON output format to include file paths, timestamps, and sizes
- Updated implementation plan to scan separate source directories
- Clarified that task.002 is now in-progress (not pending)
- Updated missing command detection to align with human confirmation
- Removed needs_review flag as all questions are resolved

**Implementation Readiness:** Ready for implementation after task.002 completion

**Recommended Next Steps:**
1. Wait for task.002 to complete the Claude namespace implementation
2. Create the ClaudeCommandLister organism with subdirectory scanning
3. Implement the list command with all output formats
4. Add colorization following the task list command pattern
5. Test with both empty and populated command directories
6. Verify JSON output includes all requested metadata
