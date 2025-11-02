# Task & Idea Structure Redesign - Usage Documentation

## Overview

This document describes the new hierarchical folder and file naming structure for ace-taskflow tasks and ideas. The redesign replaces redundant naming patterns with a clean, context-rich hierarchy that supports multiple related items in shared thematic folders.

## Key Changes

### Tasks Structure

**Old Format:**
```
.ace-taskflow/v.0.9.0/tasks/045-info-tasks-and-id-045/task.045.md
                             ↑ Redundant ID info  ↑ Generic "task" prefix
```

**New Format:**
```
.ace-taskflow/v.0.9.0/tasks/045-taskflow-info/045-show-tasks-and-ids.t.md
                             ↑ General context   ↑ Specific description + .t.md
```

### Ideas Structure

**Old Format:**
```
.ace-taskflow/v.0.9.0/ideas/20251015-011423-enhancement-in-ace-taskflow-make-the-task-folde.md
                            ↑ Flat structure with very long filename
```

**New Format:**
```
.ace-taskflow/v.0.9.0/ideas/taskflow-enhance/20251015-011423-redesign-task-structure.i.md
                            ↑ Thematic folder   ↑ Timestamp ID + description + .i.md
```

## Usage Scenarios

### Scenario 1: Creating a new task (Basic)

**Goal:** Create a new task with automatic slug generation

**Command:**
```bash
ace-taskflow task create "Fix search default behavior"
```

**Result:**
```
Created task v.0.9.0+085
Path: .ace-taskflow/v.0.9.0/tasks/085-search-fix/085-default-behavior.t.md
```

**What happens:**
- System assigns next available task number (085)
- Generates folder slug from title: `085-search-fix` (system area + goal type)
- Generates file slug: `085-default-behavior.t.md` (specific description)
- Creates task with `.t.md` extension

### Scenario 2: Creating related tasks (Multi-task folder)

**Goal:** Create multiple tasks that share a thematic area

**Commands:**
```bash
ace-taskflow task create "Fix search default to project root"
# Creates: 085-search-fix/085-default-to-project-root.t.md

ace-taskflow task create "Fix search ignore pattern handling"
# Creates: 085-search-fix/085.1-ignore-pattern-handling.t.md (sub-task)
```

**What happens:**
- Both tasks use the same thematic folder `085-search-fix`
- Second task gets sub-number `085.1` since folder already exists
- Each file has distinct specific slug

### Scenario 3: Finding tasks (Backward compatible)

**Goal:** Find tasks using existing commands

**Commands:**
```bash
# All existing formats still work:
ace-taskflow task 085                    # Find by number
ace-taskflow task show 085               # Show task details
ace-taskflow task v.0.9.0+085           # Find by full reference
ace-taskflow tasks all                   # Lists all tasks (adapts to .t.md)
```

**What happens:**
- System finds tasks by `.t.md` extension (instead of old `task.*.md` pattern)
- All existing command syntax works without changes
- Display formats remain the same

### Scenario 4: Completing tasks (Structure preserved)

**Goal:** Mark task as done and move to done/ directory

**Command:**
```bash
ace-taskflow task done 085
```

**Result:**
```
Moved: tasks/085-search-fix/ → done/085-search-fix/
       tasks/085-search-fix/085-default-to-project-root.t.md
```

**What happens:**
- Entire folder moved to `done/` subdirectory
- Structure preserved (hierarchical organization maintained)
- All related tasks in folder move together

### Scenario 5: Creating a new idea (Basic)

**Goal:** Capture an idea with automatic slug generation

**Command:**
```bash
ace-taskflow idea create "Improve search performance for large repos"
```

**Result:**
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/search-enhance/20251102-143022-improve-search-performance.i.md
```

**What happens:**
- System generates timestamp identifier: `20251102-143022`
- Generates folder slug from content: `search-enhance` (system area + goal type)
- Generates file slug: `improve-search-performance` (specific description)
- Creates idea with `.i.md` extension

### Scenario 6: Creating related ideas (Multi-idea folder)

**Goal:** Create multiple ideas in the same thematic area

**Commands:**
```bash
ace-taskflow idea create "Add caching to search results"
# Creates: ideas/search-enhance/20251102-143022-add-caching-results.i.md

ace-taskflow idea create "Implement parallel search execution"
# Creates: ideas/search-enhance/20251102-150312-parallel-search-execution.i.md
```

**What happens:**
- Both ideas use the same thematic folder `search-enhance`
- Each idea has unique timestamp identifier
- Folder groups related ideas by theme

### Scenario 7: Finding ideas (Backward compatible)

**Goal:** Find and show ideas using existing commands

**Commands:**
```bash
# All existing formats still work:
ace-taskflow idea show 20251102-143022   # By timestamp
ace-taskflow ideas all                   # Lists all (adapts to .i.md)
ace-taskflow ideas active                # Shows active ideas
```

**What happens:**
- System finds ideas by `.i.md` extension (instead of flat `.md` pattern)
- Timestamp-based identification still works
- All existing command syntax preserved

## Command Reference

### Task Commands

**Create:**
```bash
ace-taskflow task create "<title>" [--status draft|pending] [--estimate <hours>]
```
- Generates: `{id}-{system-area}-{goal-type}/{id}-{precise-description}.t.md`
- Goal types auto-detected: `add`, `enhance`, `fix`, `refactor`

**Find:**
```bash
ace-taskflow task <reference>           # By number/reference
ace-taskflow task show <reference>      # Show details
```
- Supports: `085`, `task.085`, `v.0.9.0+085`

**List:**
```bash
ace-taskflow tasks all                  # All tasks
ace-taskflow tasks next                 # Actionable tasks
ace-taskflow tasks --status pending     # By status
```

**Complete:**
```bash
ace-taskflow task done <reference>      # Move to done/
```

### Idea Commands

**Create:**
```bash
ace-taskflow idea create "<content>" [--clipboard] [--llm-enhance]
```
- Generates: `{system-area}-{goal-type}/{timestamp}-{precise-description}.i.md`
- Timestamp format: `YYYYMMDD-HHMMSS`

**Find:**
```bash
ace-taskflow idea show <timestamp>      # By timestamp
ace-taskflow idea show <partial-name>   # By partial match
```

**List:**
```bash
ace-taskflow ideas all                  # All ideas
ace-taskflow ideas active               # Active ideas only
```

**Complete:**
```bash
ace-taskflow idea done <reference>      # Move to done/ subfolder
```

## Internal Implementation Notes

### File Discovery

**Tasks:**
- Pattern: `**/*.t.md` (replaces `**/task.*.md`)
- Extension `.t.md` identifies task files
- Supports both folder and file name parsing for task numbers

**Ideas:**
- Pattern: `**/*.i.md` (replaces `**/*.md` flat files)
- Extension `.i.md` identifies idea files
- Timestamp extracted from filename

### Slug Generation

**Task Folder Naming (2-4 words):**
- Format: `{id}-{system-area}-{goal-type}`
- Example: `085-search-fix`, `090-taskflow-enhance`
- Auto-generated from title keywords

**Task File Naming (3-5 words):**
- Format: `{id}-{precise-description}.t.md`
- Example: `085-always-use-project-root.t.md`
- Completes the context from folder name

**Idea Folder Naming (2-4 words):**
- Format: `{system-area}-{goal-type}` (no ID)
- Example: `taskflow-enhance`, `search-fix`
- Thematic grouping for related ideas

**Idea File Naming (3-5 words):**
- Format: `{timestamp}-{precise-description}.i.md`
- Example: `20251015-011423-redesign-task-structure.i.md`
- Timestamp provides unique ID

## Migration Path

### Phase 1: Read Support (Backward Compatibility)
- System reads both old and new formats
- Old format: `task.*.md` files
- New format: `*.t.md` files
- Ideas: Both flat `.md` and directory-based `.i.md`

### Phase 2: Write in New Format
- All new tasks created with new structure
- All new ideas created with new structure
- Existing items preserved in old format

### Phase 3: Migration Tool (Future)
- Batch migration command for existing tasks/ideas
- Validates structure before migration
- Creates backup before changes

## Tips and Best Practices

**For Tasks:**
1. Let system auto-generate slugs (more consistent)
2. Use clear, descriptive task titles (better slugs)
3. Related tasks naturally share folders via thematic area
4. Sub-tasks get decimal notation (085.1, 085.2)

**For Ideas:**
1. Timestamp provides automatic unique ID
2. Folder grouping helps organize related ideas
3. Ideas in same theme automatically co-located
4. Done ideas moved to `done/{folder}/` preserving structure

**General:**
1. New extensions (`.t.md`, `.i.md`) clearly identify file types
2. Hierarchical structure improves readability
3. Backward compatibility maintained for all commands
4. Migration can happen gradually (no breaking changes)

## Troubleshooting

**Problem:** Task ID already exists
**Solution:** This shouldn't happen with auto-generation. Report as bug.

**Problem:** Slug doesn't match my expectations
**Solution:** Slug generation is automatic. File a feature request for custom slug support.

**Problem:** Old format tasks not appearing
**Solution:** During transition period, both formats supported. Check file extension.

**Problem:** Multiple tasks in one folder
**Solution:** This is expected behavior. Related tasks share thematic folders with sub-numbering (085.1, 085.2).
