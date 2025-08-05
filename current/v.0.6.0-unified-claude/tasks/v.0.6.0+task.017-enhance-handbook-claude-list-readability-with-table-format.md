---
id: v.0.6.0+task.017
status: draft
priority: high
estimate: TBD
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