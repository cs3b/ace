---
id: v.0.6.0+task.031
status: done
priority: high
estimate: 30m
dependencies: [v.0.6.0+task.006]
---

# Fix command count display in handbook claude integrate summary

## Behavioral Context

**Issue**: The `handbook claude integrate` command was showing "Commands: 0" in its summary even though commands were successfully installed.

**Key Behavioral Requirements**:
- The summary should accurately reflect the number of commands installed
- Command counts should be tracked by type (custom, generated)
- The installation process should continue working as before

## Objective

Fix the statistics tracking in CommandInstaller to properly count installed commands in the summary display.

## Scope of Work

- Fixed CommandInstaller to use specific command types when recording statistics
- Added mapping from source types to statistics types
- Ensured backward compatibility with existing functionality

### Deliverables

#### Create
- Added `map_source_type_to_stat_type` method to map source types to statistics types

#### Modify
- Modified `install_single_command` method to use specific command types
- Changed statistics recording from generic `:command` to specific types (`:custom_command`, `:generated_command`)

#### Delete
- None

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported that `handbook claude integrate` showed "Commands: 0" even when successfully installing commands
- **Investigation**: Found that CommandInstaller was using generic `:command` type but StatisticsCollector only recognized specific types
- **Solution**: Added proper type mapping based on source directory structure
- **Validation**: Tested with `handbook claude integrate --force` and verified correct counts

### Technical Details

The issue was in `dev-tools/lib/coding_agent_tools/organisms/command_installer.rb`:

1. CommandInstaller was recording operations with type `:command`
2. StatisticsCollector's `record_by_type` method only recognized:
   - `:custom_command`
   - `:generated_command`
   - `:workflow_command`
   - `:agent`

3. Added mapping function to convert source types:
   - 'custom' → `:custom_command`
   - 'generated' → `:generated_command`
   - 'flat' → `:custom_command`

### Testing/Validation

```bash
# Test with full installation
handbook claude integrate --force
# Result: "Commands: 37" (correct count)

# Test with single command
rm .claude/commands/document-unplanned-work.md
handbook claude integrate
# Result: "Commands: 1" (correct count)
```

**Results**: Command counts now display correctly in the installation summary.

## References

- Commit: cb663c5 "fix(stats): use specific command types for tracking"
- Related to task v.0.6.0+task.006 (implement integrate subcommand)
- No follow-up needed - fix is complete and tested