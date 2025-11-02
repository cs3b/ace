# Task & Idea Structure Redesign - Usage Documentation

## Overview

This document describes the new hierarchical folder and file naming structure for ace-taskflow tasks and ideas. The redesign replaces redundant naming patterns with a clean, context-rich hierarchy that supports multiple related items in shared thematic folders.

## Key Changes

### Tasks Structure

**Old Format:**
```
.ace-taskflow/v.0.9.0/tasks/045-info-tasks-and-id-045/task.045.s.md
                             ↑ Redundant ID info  ↑ Generic "task" prefix
```

**New Format:**
```
.ace-taskflow/v.0.9.0/tasks/045-taskflow-info/045-show-tasks-and-ids.s.md
                             ↑ General context   ↑ Specific description + .s.md
```

### Ideas Structure

**Old Format (Flat - Current Bug):**
```
.ace-taskflow/v.0.9.0/ideas/20251015-011423-enhancement-in-ace-taskflow-make-the-task-folde.s.md
                            ↑ Flat structure with very long filename (BUG - should be in folder)
```

**New Format (Timestamped Folders):**
```
.ace-taskflow/v.0.9.0/ideas/20251015-011423-taskflow-enhance/redesign-task-structure.s.md
                            ↑ Timestamped folder (each idea separate) ↑ Description + .s.md
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
Path: .ace-taskflow/v.0.9.0/tasks/085-search-fix/085-default-behavior.s.md
```

**What happens:**
- System assigns next available task number (085)
- Generates folder slug from title: `085-search-fix` (system area + goal type)
- Generates file slug: `085-default-behavior.s.md` (specific description)
- Creates task with `.s.md` extension (existing extension)

### Scenario 2: Creating related tasks (Multi-task folder)

**Goal:** Create multiple tasks that share a thematic area

**Commands:**
```bash
ace-taskflow task create "Fix search default to project root"
# Creates: 085-search-fix/085-default-to-project-root.s.md

ace-taskflow task create "Fix search ignore pattern handling"
# Creates: 085-search-fix/085.1-ignore-pattern-handling.s.md (sub-task)
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
ace-taskflow tasks all                   # Lists all tasks
```

**What happens:**
- System finds tasks by `{id}-*.s.md` pattern (instead of old `task.*.s.md` pattern)
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
       tasks/085-search-fix/085-default-to-project-root.s.md
```

**What happens:**
- Entire folder moved to `done/` subdirectory
- Structure preserved (hierarchical organization maintained)
- All related tasks in folder move together

### Scenario 5: Creating a new idea (Basic - Bug Fix)

**Goal:** Capture an idea with automatic slug generation

**Command:**
```bash
ace-taskflow idea create "Improve search performance for large repos"
```

**Result:**
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251102-143022-search-enhance/improve-search-performance.s.md
```

**What happens:**
- System generates timestamp identifier: `20251102-143022`
- Generates timestamped folder: `20251102-143022-search-enhance` (timestamp + theme)
- Generates file slug: `improve-search-performance.s.md` (description only, NO timestamp)
- **BUG FIX**: ALWAYS creates in subfolder, never as flat file
- Creates idea with `.s.md` extension (existing extension)

### Scenario 6: Creating related ideas (No Automatic Grouping)

**Goal:** Create multiple ideas in the same thematic area

**Commands:**
```bash
ace-taskflow idea create "Add caching to search results"
# Creates: ideas/20251102-143022-search-enhance/add-caching-results.s.md

ace-taskflow idea create "Implement parallel search execution"
# Creates: ideas/20251102-150312-search-enhance/parallel-search-execution.s.md
```

**What happens:**
- Each idea gets its own timestamped folder (NO automatic grouping)
- Both have similar theme (`search-enhance`) but separate timestamps
- Timestamp provides unique folder identifier
- Each folder contains single idea file with description-only name

### Scenario 7: Finding ideas (Backward compatible)

**Goal:** Find and show ideas using existing commands

**Commands:**
```bash
# All existing formats still work:
ace-taskflow idea show 20251102-143022   # By timestamp
ace-taskflow ideas all                   # Lists all ideas
ace-taskflow ideas active                # Shows active ideas
```

**What happens:**
- System finds ideas in timestamped folders by `.s.md` extension
- Timestamp extracted from folder name (not filename)
- All existing command syntax preserved

## Command Reference

### Task Commands

**Create:**
```bash
ace-taskflow task create "<title>" [--status draft|pending] [--estimate <hours>]
```
- Generates: `{id}-{system-area}-{goal-type}/{id}-{precise-description}.s.md`
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
- Generates: `{timestamp}-{system-area}-{goal-type}/{precise-description}.s.md`
- Timestamp format: `YYYYMMDD-HHMMSS` (in folder name, NOT filename)
- **Bug Fix**: ALWAYS creates in subfolder, never as flat file

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
- Pattern: `**/*{id}-*.s.md` (replaces `**/task.*.s.md`)
- Extension `.s.md` identifies files (existing extension)
- Filename pattern `{id}-*.s.md` identifies task files
- Supports both folder and file name parsing for task numbers

**Ideas:**
- Pattern: `**/{timestamp}-*/*.s.md` (finds ideas in timestamped folders)
- Extension `.s.md` identifies files (existing extension)
- Timestamp extracted from folder name (NOT filename)
- Each idea in separate timestamped folder

### Slug Generation

**Task Folder Naming (2-4 words):**
- Format: `{id}-{system-area}-{goal-type}`
- Example: `085-search-fix`, `090-taskflow-enhance`
- Auto-generated from title keywords

**Task File Naming (3-5 words):**
- Format: `{id}-{precise-description}.s.md`
- Example: `085-always-use-project-root.s.md`
- Completes the context from folder name

**Idea Folder Naming:**
- Format: `{timestamp}-{system-area}-{goal-type}` (timestamp first)
- Example: `20251015-011423-taskflow-enhance`, `20251020-143022-search-fix`
- Each idea gets unique timestamped folder (no grouping)

**Idea File Naming (5±2 words):**
- Format: `{precise-description}.s.md` (NO timestamp in filename)
- Example: `redesign-task-structure.s.md`, `default-to-project-root.s.md`
- Description only, timestamp is in folder name

## Migration Path

### Phase 1: Read Support (Backward Compatibility)
- System reads both old and new formats
- Old task format: `task.*.s.md` files
- New task format: `{id}-*.s.md` files
- Old idea format: Flat `.s.md` files (current bug)
- New idea format: `{timestamp}-*/{description}.s.md` (timestamped folders)

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
1. Timestamp in folder name provides automatic unique ID
2. Each idea gets separate timestamped folder (no automatic grouping)
3. Filename is description-only (no timestamp duplication)
4. Done ideas moved to `done/{timestamp}-{folder}/` preserving structure
5. **Bug fixed**: Ideas ALWAYS created in subfolders, never as flat files

**General:**
1. Extension `.s.md` (spec) used for both tasks and ideas (existing)
2. Hierarchical structure improves readability
3. Backward compatibility maintained for all commands
4. Migration can happen gradually (no breaking changes)

## Troubleshooting

**Problem:** Task ID already exists
**Solution:** This shouldn't happen with auto-generation. Report as bug.

**Problem:** Slug doesn't match my expectations
**Solution:** Slug generation is automatic. File a feature request for custom slug support.

**Problem:** Old format tasks not appearing
**Solution:** During transition period, both formats supported. Check filename pattern (`task.*.s.md` vs `{id}-*.s.md`).

**Problem:** Multiple tasks in one folder
**Solution:** This is expected behavior. Related tasks share thematic folders with sub-numbering (085.1, 085.2).

**Problem:** Idea created as flat file instead of in folder
**Solution:** This was a bug in the old system. After this fix, ideas ALWAYS created in timestamped folders. Use migration tool to move old flat files to folders.
