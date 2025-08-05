---
id: v.0.6.0+task.017
status: completed
priority: high
estimate: 3h
dependencies: []
---

# Enhance handbook claude list readability with table format

## Behavioral Specification

### User Experience
- **Input**: Users execute `handbook claude list` command with optional flags (--type, --format, --verbose)
- **Process**: Users see a clean, concise table view of commands with status indicators and essential information
- **Output**: Users receive a tabular display showing command status at a glance, with columns for installed status, command type, validation status, and command name

### Expected Behavior
The system should display Claude commands in a compact, readable table format instead of the current verbose sectioned output. Users should be able to quickly scan and understand:
- Which commands are installed in .claude/commands
- Whether commands are custom or generated
- Command validation status (everything OK in dev-handbook)
- Command names

The table should be shorter and easier to read than the current multi-section output, allowing users to see all command statuses at once without scrolling.

### Interface Contract
```bash
# CLI Interface
handbook claude list [OPTIONS]

# Expected table output format (text mode):
Claude Commands Overview
========================

Installed | Type      | Valid | Command Name
----------|-----------|-------|------------------
    ✓     | custom    |   ✓   | commit
    ✓     | custom    |   ✓   | draft-tasks
    ✓     | generated |   ✓   | capture-idea
    ✗     | generated |   ✓   | create-adr
    ✓     | custom    |   ✓   | load-project-context

Summary: 4 commands installed, 1 missing

# JSON output format:
{
  "commands": [
    {
      "name": "commit",
      "installed": true,
      "type": "custom",
      "valid": true
    },
    ...
  ],
  "summary": {
    "installed": 4,
    "missing": 1,
    "total": 5
  }
}
```

**Error Handling:**
- Missing .claude/commands directory: Display empty table with appropriate message
- Invalid command files: Mark as invalid in the Valid column
- Permission errors: Display error message and exit gracefully

**Edge Cases:**
- No commands found: Display empty table with "No commands found" message
- Mixed installation states: Clearly show which commands are installed vs missing
- Type filtering: Only show commands matching the specified type filter

### Success Criteria
- [ ] **Behavioral Outcome 1**: Users can view all command statuses in a single, compact table without scrolling
- [ ] **User Experience Goal 2**: Table format reduces vertical space usage by at least 50% compared to current sectioned output
- [ ] **System Performance 3**: Command status information loads and displays within 200ms

### Validation Questions
- [ ] **Requirement Clarity**: Should the table include file size and modification time, or just the essential columns?
- [ ] **Edge Case Handling**: How should we handle commands that exist in .claude but not in dev-handbook (orphaned commands)?
- [ ] **User Experience**: Should we support sorting the table by different columns (name, type, status)?
- [ ] **Success Definition**: What constitutes a "valid" command - just file existence or content validation too?

## Objective

Improve the readability and usability of the `handbook claude list` command by implementing a concise table format that allows users to quickly assess command installation status and types at a glance. This addresses user feedback about the current verbose output being difficult to scan.

## Scope of Work

- **User Experience Scope**: Command line interface output formatting for the list subcommand
- **System Behavior Scope**: Scanning and categorizing Claude commands from multiple sources, presenting data in table format
- **Interface Scope**: Text and JSON output formats with consistent data structure

### Deliverables

#### Behavioral Specifications
- Table-based display format for command listings
- Consistent status indicators across all command types
- Summary information for quick overview

#### Validation Artifacts
- Test cases for table formatting with various command states
- JSON output format validation
- Performance benchmarks for command scanning

## Out of Scope
- ❌ **Implementation Details**: Specific Ruby code organization or ATOM architecture decisions
- ❌ **Technology Decisions**: Choice of table formatting libraries or output colorization methods
- ❌ **Performance Optimization**: Caching strategies or parallel scanning implementations
- ❌ **Future Enhancements**: Column sorting, filtering beyond current --type flag, or interactive table features

## References

- Feedback item #4 from dev-taskflow/current/v.0.6.0-unified-claude/ideas/feedback-for-1-10.md
- Related to feedback #5 about .claude/commands location (flattened structure)
- Current implementation in dev-tools/lib/coding_agent_tools/organisms/claude_command_lister.rb

## Technical Approach

### Architecture Pattern
- Use the ATOM architecture pattern with a clear separation of concerns
- Enhance existing ClaudeCommandLister organism to support table formatting
- Create new atom components for table rendering and column alignment
- Leverage existing molecules for command scanning and status detection

### Technology Stack
- Ruby standard library for string formatting and padding
- No external table formatting libraries needed (keep dependencies minimal)
- ANSI color codes for status indicators (already in use)
- Existing filesystem and path handling utilities

### Implementation Strategy
- Refactor output methods to support table format as primary display mode
- Create reusable table rendering atom for potential future use
- Maintain backward compatibility with JSON output format
- Keep verbose mode for detailed information when needed

## Tool Selection

| Criteria | Custom Table Implementation | Terminal-table gem | TTY-table gem | Selected |
|----------|----------------------------|-------------------|---------------|-----------|
| Performance | Excellent | Good | Good | Custom |
| Integration | Native | External dependency | External dependency | Custom |
| Maintenance | Direct control | Community maintained | Community maintained | Custom |
| Security | No external deps | Additional dep | Additional dep | Custom |
| Learning Curve | None (standard Ruby) | Small | Small | Custom |

**Selection Rationale:** Custom implementation selected to avoid adding dependencies for a simple table format. The table requirements are straightforward (4 columns, basic alignment) and can be efficiently implemented with Ruby's string formatting capabilities.

## File Modifications

### Create
- lib/coding_agent_tools/atoms/table_renderer.rb
  - Purpose: Generic table rendering atom for formatted text output
  - Key components: Column alignment, width calculation, row formatting
  - Dependencies: None (pure Ruby)

### Modify
- lib/coding_agent_tools/organisms/claude_command_lister.rb
  - Changes: Refactor output_text method to use table format
  - Impact: Changes default display format to table view
  - Integration points: Uses new TableRenderer atom

- spec/coding_agent_tools/organisms/claude_command_lister_spec.rb
  - Changes: Update tests for new table format output
  - Impact: Ensures table format works correctly
  - Integration points: Tests table rendering behavior

### Create Tests
- spec/coding_agent_tools/atoms/table_renderer_spec.rb
  - Purpose: Unit tests for table rendering atom
  - Key components: Column alignment, width calculation, edge cases
  - Dependencies: RSpec

## Risk Assessment

### Technical Risks
- **Risk:** Terminal width constraints may affect table readability
  - **Probability:** Medium
  - **Impact:** Low
  - **Mitigation:** Implement intelligent column width calculation with minimum widths
  - **Rollback:** Fall back to list format if terminal too narrow

- **Risk:** Unicode characters (✓, ✗) may not display correctly on all terminals
  - **Probability:** Low
  - **Impact:** Low
  - **Mitigation:** Already in use in current implementation, proven to work
  - **Rollback:** Provide ASCII fallback option if needed

### Integration Risks
- **Risk:** Changes to output format may break existing scripts parsing the output
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Maintain JSON format option unchanged, document text format as human-readable only
  - **Monitoring:** Check for any automation using the text output

## Implementation Plan

### Planning Steps

* [x] Analyze current command inventory structure and data flow
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Command categories (custom, generated, installed) and their relationships are identified
  > Command: ruby -e "require './lib/coding_agent_tools/organisms/claude_command_lister'; puts CodingAgentTools::Organisms::ClaudeCommandLister.new.send(:build_inventory).keys"

* [x] Design table column layout and width calculations
  - Fixed columns: Installed (10 chars), Type (10 chars), Valid (7 chars), Command Name (variable)
  - Calculate optimal widths based on terminal size
  - Handle long command names with truncation if needed

* [x] Plan test scenarios for table rendering
  - Empty inventory
  - Single command type
  - Mixed command types
  - Long command names
  - Terminal width edge cases

### Execution Steps

- [x] Create TableRenderer atom with basic functionality
  > TEST: TableRenderer Creation
  > Type: File Creation
  > Assert: TableRenderer atom exists with proper module structure
  > Command: test -f lib/coding_agent_tools/atoms/table_renderer.rb && ruby -c lib/coding_agent_tools/atoms/table_renderer.rb

- [x] Implement table rendering logic in TableRenderer
  - Column alignment (left, center, right)
  - Width calculation and padding
  - Header and separator generation
  - Row formatting with proper spacing

- [x] Create comprehensive tests for TableRenderer
  > TEST: TableRenderer Tests
  > Type: Test Implementation
  > Assert: All table rendering scenarios are covered
  > Command: bundle exec rspec spec/coding_agent_tools/atoms/table_renderer_spec.rb

- [x] Refactor ClaudeCommandLister to detect installed vs source commands
  - Check if command exists in .claude/commands (installed)
  - Cross-reference with dev-handbook source locations
  - Determine validation status (exists in dev-handbook)

- [x] Update ClaudeCommandLister#output_text to use table format
  > TEST: Table Format Output
  > Type: Integration Test
  > Assert: Command list displays in table format
  > Command: bundle exec handbook claude list | grep -E "Installed.*Type.*Valid.*Command"

- [x] Implement summary line with counts
  - Count installed commands
  - Count missing commands
  - Display in format: "Summary: X commands installed, Y missing"

- [x] Update existing tests for new output format
  > TEST: All Tests Pass
  > Type: Test Suite
  > Assert: All ClaudeCommandLister tests pass with new format
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/claude_command_lister_spec.rb

- [x] Add integration tests for table output
  > TEST: Integration Tests
  > Type: End-to-end Test
  > Assert: handbook claude list produces expected table output
  > Command: bundle exec rspec spec/integration/handbook_claude_list_spec.rb

- [x] Test with various terminal widths and command sets
  > TEST: Terminal Compatibility
  > Type: Manual Verification
  > Assert: Table displays correctly in different terminal sizes
  > Command: COLUMNS=80 bundle exec handbook claude list && COLUMNS=120 bundle exec handbook claude list

## Acceptance Criteria

- [x] Users can view all command statuses in a single, compact table without scrolling
- [x] Table format reduces vertical space usage by at least 50% compared to current sectioned output
- [x] Command status information loads and displays within 200ms
- [x] JSON output format remains unchanged for automation compatibility
- [x] Table clearly shows installed status, command type, validation status, and command name
- [x] Summary line provides quick overview of installed vs missing commands