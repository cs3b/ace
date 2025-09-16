---
id: v.0.5.0+task.056
status: done
priority: high
estimate: 3h
dependencies: []
---

# Flatten Claude command integration structure

## Behavioral Specification

### User Experience
- **Input**: Developer runs `coding-agent-tools integrate claude` or `handbook claude integrate`
- **Process**: Integration installs all Claude commands directly into `.claude/commands/` without creating subdirectory symlinks
- **Output**: All commands are immediately accessible at `.claude/commands/*.md` with no navigation through `_custom` or `_generated` folders

### Expected Behavior

The integration command should create a flat command structure where all Claude commands (both custom and generated) are directly available in the `.claude/commands/` directory. This eliminates the need for AI agents to understand or navigate through subdirectory structures like `_custom` and `_generated`.

**Current problematic behavior:**
```
.claude/commands/
├── _custom -> ../../.ace/handbook/.integrations/claude/commands/_custom
├── _generated -> ../../.ace/handbook/.integrations/claude/commands/_generated
└── *.md (actual command files)
```

**Desired behavior:**
```
.claude/commands/
├── capture-idea.md
├── commit.md
├── create-adr.md
├── draft-task.md
└── ... (all other commands directly here)
```

### Interface Contract

```bash
# CLI Interface remains unchanged
coding-agent-tools integrate claude [OPTIONS]
handbook claude integrate [OPTIONS]

# Expected file structure after integration
.claude/
├── agents/
│   └── *.ag.md (agent files)
└── commands/
    └── *.md (all command files flat, no subdirectories)

# Command access pattern for AI agents
# Before: May need to check .claude/commands/_custom/commit.md or .claude/commands/_generated/commit.md
# After: Always check .claude/commands/commit.md
```

**Conflict Resolution:**
- When same command exists in both `_custom` and `_generated`: Custom version takes precedence
- Integration reports which version was used if conflicts detected
- No error thrown for conflicts, just informational output

**Error Handling:**
- Missing source directories: Continue with available commands
- Permission errors: Report and skip problematic files
- Existing files without --force: Skip and report

### Success Criteria

- [x] **No Subdirectory Symlinks**: The `.claude/commands/` directory contains NO symlinks to `_custom` or `_generated` folders
- [x] **Direct Command Access**: All commands are directly accessible as `.claude/commands/[command-name].md`
- [x] **Conflict Resolution Works**: When same command exists in both sources, custom version is installed
- [x] **Backward Compatible**: Existing installations work after update without breaking changes
- [x] **Clear Reporting**: Integration output clearly shows what was installed/skipped/conflicted

### Validation Questions

- [x] **README Handling**: Should README.md files be copied to `.claude/commands/` or excluded entirely? → Currently excluded by orchestrator
- [x] **Symlink vs Copy**: Should we continue copying files or could we symlink individual files instead of directories? → Using copy for individual files
- [x] **Metadata Preservation**: Does the current metadata injection system work correctly with the flattened structure? → Yes, metadata is injected during copy
- [x] **Testing Coverage**: Are there existing tests that expect the subdirectory structure that need updating? → No specific tests found for integrate.rb

## Objective

Simplify Claude command access for AI agents by eliminating unnecessary directory navigation. AI agents should be able to directly access any command at a predictable path without needing to understand the internal organization of custom vs generated commands.

## Scope of Work

- **User Experience Scope**: Integration command behavior and output, AI agent command discovery
- **System Behavior Scope**: File installation logic, conflict resolution, progress reporting
- **Interface Scope**: Maintaining existing CLI interface while changing output structure

### Deliverables

#### Behavioral Specifications
- Flat command structure specification
- Conflict resolution behavior definition
- Integration output format specification

#### Validation Artifacts
- Test cases for conflict scenarios
- Validation of flat structure creation
- Backward compatibility verification

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby code changes, file operation methods
- ❌ **Technology Decisions**: Whether to use symlinks vs copies for individual files
- ❌ **Performance Optimization**: Speed improvements to the integration process
- ❌ **Future Enhancements**: Command categorization, command discovery improvements

## Implementation Plan

### Technical Research

**Current Architecture:**
- The integration uses `ClaudeCommandsOrchestrator` to coordinate command installation
- Commands are discovered in `_custom` and `_generated` subdirectories
- The `integrate.rb` creates symlinks to these subdirectories (lines showing symlink creation)
- Individual command files are already being copied flat to `.claude/commands/`

**Key Finding:**
- Commands are ALREADY being copied flat! The symlinks to subdirectories are redundant
- The issue is that symlinks to `_custom` and `_generated` folders are being created unnecessarily

### File Modifications

#### Files to Modify
1. **.ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb**
   - Remove code that creates symlinks to `_custom` and `_generated` directories
   - Ensure only individual command files are handled

2. **.ace/tools/lib/coding_agent_tools/organisms/claude_commands_orchestrator.rb**
   - Verify flat installation is working correctly
   - Add conflict reporting when custom overrides generated

3. **.ace/tools/lib/coding_agent_tools/organisms/command_installer.rb**
   - Add logic to detect and report conflicts
   - Ensure custom commands take precedence

### Implementation Steps

1. **Analyze Current Symlink Creation**
   - Search for code creating the problematic symlinks
   - Identify exact location in `integrate.rb`

2. **Remove Subdirectory Symlinks**
   - Comment out or remove symlink creation for `_custom` and `_generated`
   - Keep individual file copying logic intact

3. **Add Conflict Detection**
   - Track which commands exist in both sources
   - Report conflicts in integration output
   - Ensure custom version wins

4. **Test Integration**
   - Run integration on test project
   - Verify flat structure created
   - Check conflict resolution works

5. **Update Tests**
   - Find tests expecting subdirectory structure
   - Update to expect flat structure

### Test Planning

#### Integration Tests
- Verify no subdirectory symlinks created
- Test conflict resolution (custom overrides generated)
- Ensure backward compatibility

#### Manual Testing
- Run `handbook claude integrate` on fresh project
- Verify `.claude/commands/` has no subdirectory symlinks
- Test AI agent command access

## References

- Original idea: .ace/taskflow/current/v.0.5.0-insights/docs/ideas/056-20250824-2300-claude-command-flattening.md
- Current integration implementation: .ace/tools/lib/coding_agent_tools/cli/commands/integrate.rb
- Command orchestrator: .ace/tools/lib/coding_agent_tools/organisms/claude_commands_orchestrator.rb
- Recent integration enhancements: v.0.5.0+task.055