---
id: 8o5000
title: Bypassing domain tools causes task renumbering chaos
type: conversation-analysis
tags: []
created_at: '2026-01-06 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8o5000-task-renumbering-failure-avoid-domain-tools.md"
---

# Reflection: Bypassing domain tools causes task renumbering chaos

**Date**: 2026-01-06
**Context**: Task 179 code review feedback implementation - attempted to add 4 new subtasks
**Author**: Claude Code Agent
**Type**: Conversation Analysis

## What Went Well

- User quickly identified the root cause (bypassing ace-taskflow tool)
- Clear explanation of why the approach was wrong
- User stopped the cascade of errors before more damage

## What Could Be Improved

- Created invalid task ID format (`179.00.1` with triple decimals)
- Multiple failed renumbering attempts creating duplicates and gaps
- Lost 30+ minutes in file renaming chaos
- Required manual intervention to identify the problem

## Key Learnings

- **ALWAYS use domain-specific tools** (`ace-taskflow`) instead of manual file manipulation
- Domain tools enforce schema, prevent invalid formats, maintain consistency
- Manual `Write` tool bypasses all safeguards and creates maintenance burden
- When tool exists for the job, use it - don't treat domain files as generic text files

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Bypassing domain tools**: Used `Write` tool instead of `ace-taskflow task create`
  - Occurrences: 4 new task files created manually
  - Impact: Created invalid task IDs, required 3 commit attempts, created file chaos
  - Root Cause: Treated task files as regular text files instead of domain-managed entities

- **Invalid task ID format**: Created `v.0.9.0+task.179.00.1` (triple-decimal)
  - Occurrences: 1 invalid ID propagated across 4 files
  - Impact: System couldn't parse ID, required complete renumbering
  - Root Cause: Didn't understand ACE task ID schema (NNN.SS pattern only)

#### Medium Impact Issues

- **Wrong renumbering approach**: Appended instead of inserting at position 01
  - Occurrences: 2 attempted fixes
  - Impact: Created wrong ordering (179.01-179.13, then 179.14-179.17)
  - Root Cause: Misunderstood requirement as "append" not "insert + shift"

- **Partial file renames**: Multi-rename operations failed partway through
  - Occurrences: 1 failed bash command
  - Impact: Created duplicate 179.14 files, missing 179.03
  - Root Cause: Complex multi-file operations without atomic transaction

#### Low Impact Issues

- **sed replacement before file renames**: Updated IDs before files were renamed
  - Occurrences: 1 global replacement
  - Impact: Metadata and filenames got out of sync
  - Root Cause: Wrong order of operations (should rename files first, then update IDs)

### Improvement Proposals

#### Process Improvements

- **Mandatory domain tool usage**: When `ace-*` tool exists for a task, ALWAYS use it
- **Validation step before file operations**: Check format validity with existing tools first
- **Atomic operations**: Use tools that handle entire operations atomically

#### Tool Enhancements

- **Write tool validation**: If writing to `.ace-taskflow/` paths, validate against task schema
- **ID format checking**: Warn when task ID doesn't match expected `NNN.SS` pattern
- **Pre-flight checks**: Suggest using `ace-taskflow task create` when task file patterns detected

#### Communication Protocols

- **Ask before bypassing tools**: "Should I use ace-taskflow for this?"
- **Confirm format understanding**: "Task ID format is NNN.SS - correct?"

### Token Limit & Truncation Issues

- **Large Output Instances**: 2 (bash mv command output, file listings)
- **Truncation Impact**: Had to run multiple ls commands to see state
- **Mitigation Applied**: Used targeted ls with head instead of full listings
- **Prevention Strategy**: Use targeted queries, avoid broad operations

## Action Items

### Stop Doing

- Creating task files manually with `Write` tool
- Editing task frontmatter without using `ace-taskflow` commands
- Treating domain-managed files as generic text files
- Using `sed` to update task IDs manually

### Continue Doing

- Using `ace-taskflow task create` for new tasks
- Relying on domain tools to enforce schema and validation
- Asking user when uncertain about tool choice

### Start Doing

- **MANDATORY**: Check if `ace-*` tool exists before manual file operations
- Validate task ID format (`NNN.SS` only, no triple decimals)
- Use atomic operations instead of multi-step file renames
- Document domain tool patterns in CLAUDE.md for reference

## Technical Details

**Invalid ID Created**: `v.0.9.0+task.179.00.1`
**Correct Pattern**: `v.0.9.0+task.NNN.SS` (e.g., `v.0.9.0+task.179.14`)

**Correct Approach**:
```bash
# This would have auto-assigned valid IDs
ace-taskflow task create "Create shared Ace::Core::CLI::Command base class" --parent 179
ace-taskflow task create "Update ADR-018 and ace-gems.g.md" --parent 179
ace-taskflow task create "Security audit of dry-cli" --parent 179
ace-taskflow task create "Performance baseline testing" --parent 179
```

**What Happened Instead**:
1. Used `Write` tool → Created invalid ID `179.00.1`
2. First "fix": Renamed to `179.14`, left `179.01-179.13` untouched → Wrong order
3. Second "fix": Tried shuffling from wrong end → Duplicates, gaps, partial completion

## Additional Context

- **Commits Created**: 2 (both need to be reset)
- **Files Affected**: 18 task files (4 new, 14 dependency updates)
- **Time Lost**: ~30 minutes in renumbering attempts
- **User Correction**: "How is it possible to have wrong id - if you use ace-taskflow task for everything (and do not edit manually) it is almost impossible?"

**Key Quote**: "The lesson: Always use the domain-specific tools (ace-taskflow) instead of manual file manipulation for core operations."