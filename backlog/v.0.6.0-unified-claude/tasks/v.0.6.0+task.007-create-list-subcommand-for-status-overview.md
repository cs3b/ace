---
id: v.0.6.0+task.007
status: pending
priority: medium
estimate: 2h
dependencies: [v.0.6.0+task.002]
release: v.0.6.0-unified-claude
---

# Create list subcommand for status overview

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
  "custom": ["commit", "draft-tasks", ...],
  "generated": ["capture-idea", ...],
  "missing": ["fix-linting-issue-from", ...]
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
- [ ] **Filtering**: Should we support filtering by pattern?
- [ ] **Status Icons**: What symbols for different states?
- [ ] **Performance**: Should we cache results for large projects?

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

### Technology Stack
- Ruby Dir/File for scanning
- JSON for structured output
- String formatting for display

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

* [ ] Design output format variations
* [ ] Define status determination logic
* [ ] Plan JSON schema for structured output
* [ ] Consider color output for terminals

### Execution Steps

- [ ] Implement list command class
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

- [ ] Create command lister organism
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
    {
      custom: scan_directory(@custom_dir),
      generated: scan_directory(@generated_dir),
      missing: find_missing_workflows
    }
  end
  ```
  > TEST: Inventory Building
  > Type: Unit Test
  > Assert: Correctly categorizes all commands
  > Command: bundle exec rspec -e "builds complete inventory"

- [ ] Implement formatted output
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

- [ ] Add test coverage
  > TEST: Output Formats
  > Type: Integration Test
  > Assert: All formats produce valid output
  > Command: bundle exec rspec -e "outputs in all formats"

## Acceptance Criteria

- [ ] Lists all commands from both directories
- [ ] Identifies missing commands correctly
- [ ] Supports verbose mode with file details
- [ ] Filters by command type
- [ ] Outputs valid JSON when requested
- [ ] Provides accurate summary counts

## References

- Current command organization structure
- Standard CLI list command patterns
- JSON output format standards