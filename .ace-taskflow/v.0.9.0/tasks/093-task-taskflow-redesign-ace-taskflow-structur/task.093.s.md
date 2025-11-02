---
id: v.0.9.0+task.093
status: pending
priority: medium
estimate: 2-3 weeks
dependencies: []
---

# Redesign ace-taskflow task structure with hierarchical slug naming

## Behavioral Specification

### User Experience

**Input**: Users create and manage tasks and ideas using existing ace-taskflow commands
**Process**: System organizes tasks and ideas in hierarchical folder structures with meaningful slugs
**Output**: Clean, readable organization with folder/file naming that conveys context for both tasks and ideas

**Current Structure (Problem):**
```bash
# Tasks:
.ace-taskflow/v.0.9.0/tasks/045-info-tasks-and-id-045/task.045.md

# Ideas:
.ace-taskflow/v.0.9.0/ideas/20251015-011423-enhancement-in-ace-taskflow-make-the-task-folde.md

# Issues:
# - Tasks: Redundant information in folder slug, generic "task" prefix
# - Ideas: Flat structure with long filenames, no thematic grouping
# - Both: No clear hierarchy between general context and specific description
```

**Proposed Structure (Solution):**
```bash
# Tasks (with numeric IDs):
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085-always-use-project-root.t.md
.ace-taskflow/v.0.9.0/tasks/090-taskflow-enhance/090-implement-update-command.t.md
.ace-taskflow/v.0.9.0/tasks/092-docs-add/092-add-timestamp-frontmatter.t.md
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085.1-update-search-docs.t.md  # Sub-task

# Ideas (with timestamps as identifiers):
.ace-taskflow/v.0.9.0/ideas/taskflow-enhance/20251015-011423-redesign-task-structure.i.md
.ace-taskflow/v.0.9.0/ideas/search-fix/20251020-143022-default-to-project-root.i.md
.ace-taskflow/v.0.9.0/ideas/docs-add/20251022-091534-add-usage-examples.i.md
```

### Expected Behavior

#### Tasks Structure

**Folder Naming Convention (2-4 words):**
- Format: `{id}-{system-area}-{goal-type}`
- Describes what part of the system and type of work
- Goal types: `add`, `enhance`, `fix`, `refactor`
- Examples:
  - `085-search-fix` (fixing search functionality)
  - `090-taskflow-enhance` (enhancing taskflow features)
  - `092-docs-add` (adding documentation)
  - `093-taskflow-refactor` (refactoring taskflow structure)

**File Naming Convention (3-5 words):**
- Format: `{id}-{precise-description}.t.md`
- More specific description of the task
- Continues/completes context from folder name
- Extension: `.t.md` indicates task markdown file
- Examples:
  - `085-always-use-project-root.t.md`
  - `090-implement-update-command.t.md`
  - `092-add-timestamp-frontmatter.t.md`

**Multi-task Support:**
```bash
# Multiple related tasks can share a folder:
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085-always-use-project-root.t.md
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085.1-update-search-docs.t.md
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085.2-add-integration-tests.t.md
```

#### Ideas Structure

**Folder Naming Convention (2-4 words):**
- Format: `{system-area}-{goal-type}` (no numeric ID)
- Same pattern as tasks but without the ID prefix
- Describes thematic area for grouping related ideas
- Goal types: `add`, `enhance`, `fix`, `refactor`
- Examples:
  - `taskflow-enhance` (ideas for enhancing taskflow)
  - `search-fix` (ideas for fixing search issues)
  - `docs-add` (ideas for adding documentation)

**File Naming Convention (3-5 words):**
- Format: `{timestamp}-{precise-description}.i.md`
- Timestamp acts as unique identifier (format: YYYYMMDD-HHMMSS)
- Precise description of the idea (3-5 words)
- Extension: `.i.md` indicates idea markdown file
- Examples:
  - `20251015-011423-redesign-task-structure.i.md`
  - `20251020-143022-default-to-project-root.i.md`
  - `20251022-091534-add-usage-examples.i.md`

**Multi-idea Support:**
```bash
# Multiple related ideas can share a thematic folder:
.ace-taskflow/v.0.9.0/ideas/taskflow-enhance/20251015-011423-redesign-task-structure.i.md
.ace-taskflow/v.0.9.0/ideas/taskflow-enhance/20251016-094512-add-task-templates.i.md
.ace-taskflow/v.0.9.0/ideas/taskflow-enhance/20251017-151033-improve-search-filters.i.md
```

### Interface Contract

**CLI Interface - All existing commands continue to work:**

```bash
# Task commands (unchanged behavior):
ace-taskflow task 085                    # Find by number
ace-taskflow task show 085               # Show task details
ace-taskflow task v.0.9.0+085           # Find by full reference

# Task creation (system generates hierarchical structure)
ace-taskflow task create "Fix search default behavior"
# Creates: tasks/{id}-{auto-slug}/{id}-{auto-slug}.t.md

# Task completion (moves to done/ with same structure)
ace-taskflow task done 085
# Moves: tasks/085-search-fix/ → done/085-search-fix/

# Task listing (adapts to .t.md extension)
ace-taskflow tasks all                   # Lists all tasks
ace-taskflow tasks next                  # Shows actionable tasks

# Idea commands (unchanged behavior):
ace-taskflow idea create "Improve search performance"
# Creates: ideas/{auto-slug}/{timestamp}-{auto-slug}.i.md

ace-taskflow idea show 20251015-011423
# Shows idea by timestamp

ace-taskflow idea done 20251015-011423
# Moves: ideas/{folder}/ → ideas/done/{folder}/

# Idea listing (adapts to .i.md extension)
ace-taskflow ideas all                   # Lists all ideas
ace-taskflow ideas active                # Shows active ideas
```

**System Behavior:**

**Tasks:**
1. **File Discovery**: System finds tasks by `.t.md` extension instead of `task.*.md` pattern
2. **ID Extraction**: Parse task ID from both folder name and filename
3. **Sub-task Support**: Handle decimal notation (085.1, 085.2) for related tasks
4. **Slug Generation**: Auto-generate meaningful slugs from task titles and context

**Ideas:**
1. **File Discovery**: System finds ideas by `.i.md` extension instead of flat `.md` files
2. **Timestamp Extraction**: Parse timestamp identifier from filename
3. **Folder Grouping**: Group related ideas in thematic folders based on system area
4. **Slug Generation**: Auto-generate folder and file slugs from idea content and context

**Error Handling:**

**Tasks:**
- **Duplicate IDs**: Error if task ID already exists in release
- **Invalid slug format**: Warn if slug doesn't follow conventions
- **Missing .t.md extension**: Warn if task files don't use correct extension
- **Orphaned folders**: Detect folders without task files

**Ideas:**
- **Duplicate timestamps**: Error if idea with same timestamp already exists
- **Invalid slug format**: Warn if slug doesn't follow conventions
- **Missing .i.md extension**: Warn if idea files don't use correct extension
- **Orphaned folders**: Detect folders without idea files

**Edge Cases:**

**Tasks:**
- **Legacy format**: Support reading existing `task.*.md` files during migration
- **Sub-task creation**: Allow creating 085.1 when 085 exists
- **Folder reuse**: Allow multiple tasks in same thematic folder if IDs differ

**Ideas:**
- **Legacy format**: Support reading existing flat `.md` files during migration
- **Folder reuse**: Allow multiple ideas in same thematic folder (expected behavior)
- **Done ideas**: Maintain folder structure when moving to done/ subdirectory

### Success Criteria

**Tasks:**
- [ ] **Folder Convention**: Folders use `{id}-{general-slug}` format (2-4 words)
- [ ] **File Convention**: Files use `{id}-{specific-slug}.t.md` format (3-5 words)
- [ ] **General Slug**: Indicates system area and goal type (add/enhance/fix/refactor)
- [ ] **Specific Slug**: Provides precise task description completing folder context
- [ ] **Multi-task Support**: Multiple related tasks can exist in same folder
- [ ] **Extension Change**: All task files use `.t.md` extension
- [ ] **Command Compatibility**: All ace-taskflow task commands work with new structure
- [ ] **Migration Path**: Clear strategy for migrating existing tasks

**Ideas:**
- [ ] **Folder Convention**: Folders use `{general-slug}` format (2-4 words, no ID)
- [ ] **File Convention**: Files use `{timestamp}-{specific-slug}.i.md` format (3-5 words)
- [ ] **General Slug**: Indicates system area and goal type (add/enhance/fix/refactor)
- [ ] **Specific Slug**: Provides precise idea description completing folder context
- [ ] **Multi-idea Support**: Multiple related ideas can exist in same thematic folder
- [ ] **Extension Change**: All idea files use `.i.md` extension
- [ ] **Command Compatibility**: All ace-taskflow idea commands work with new structure
- [ ] **Migration Path**: Clear strategy for migrating existing ideas

### Validation Questions

**Tasks:**
- [ ] **Migration Strategy**: Should we migrate all existing tasks at once, or support both old and new formats during a transition period?
- [ ] **Goal Type Keywords**: Should we enforce specific keywords (add/enhance/fix/refactor) or allow flexibility in folder slugs?
- [ ] **Slug Generation**: Should slugs be auto-generated from task titles, manually specified during creation, or a hybrid approach?
- [ ] **Sub-task Format**: Is `{id}.{sub-number}` (e.g., 085.1, 085.2) the right notation for related tasks?
- [ ] **Done Structure**: Should tasks moved to done/ maintain the new structure, or use a flattened structure?
- [ ] **Folder Reuse**: What rules govern when tasks can share a folder vs. requiring separate folders?

**Ideas:**
- [ ] **Migration Strategy**: Should we migrate all existing ideas at once, or support both old and new formats during a transition period?
- [ ] **Goal Type Keywords**: Should we enforce the same keywords (add/enhance/fix/refactor) for idea folders?
- [ ] **Slug Generation**: Should folder and file slugs be auto-generated from idea content, manually specified, or a hybrid approach?
- [ ] **Folder Assignment**: Should the system automatically determine which folder an idea belongs to, or should users specify it?
- [ ] **Done Structure**: Should ideas moved to done/ maintain folder structure (done/{folder}/) or use a flat structure (done/)?
- [ ] **Timestamp Precision**: Is YYYYMMDD-HHMMSS sufficient granularity for idea identifiers, or do we need milliseconds?

## Objective

Transform ace-taskflow's task and idea organization from redundant/flat structures to hierarchical structures that support multiple related items while providing clear context through meaningful folder and file slugs.

**Why**: Current structures have significant limitations:
- **Tasks**: Redundant information (ID in both folder and file), generic "task" prefix adds no value
- **Ideas**: Flat structure with very long filenames, no thematic grouping

The new unified structure provides:
- Better readability through meaningful, hierarchical slugs
- Support for related items (tasks/ideas) in shared thematic folders
- Clear hierarchy between general (folder) and specific (file) context
- Consistent pattern across both tasks and ideas
- Easier navigation and understanding of project organization

## Scope of Work

### User Experience Scope

**Tasks:**
- Task creation workflow with hierarchical slug generation
- Task lookup by ID across new structure
- Task listing with new file extension (`.t.md`)
- Task completion/movement maintaining structure
- Sub-task creation within shared folders

**Ideas:**
- Idea creation workflow with hierarchical slug generation
- Idea lookup by timestamp across new structure
- Idea listing with new file extension (`.i.md`)
- Idea completion/movement maintaining folder structure
- Multiple ideas grouped in thematic folders

### System Behavior Scope

**Tasks:**
- File discovery using `.t.md` extension pattern
- Slug generation from task titles and context
- Folder sharing logic for related tasks
- Migration handling for existing task format

**Ideas:**
- File discovery using `.i.md` extension pattern
- Slug generation from idea content and context
- Folder assignment logic for thematic grouping
- Migration handling for existing flat idea format

### Interface Scope

- All existing ace-taskflow commands maintain compatibility
- No breaking changes to command syntax
- Enhanced behavior for new structure features
- Unified pattern across tasks and ideas

### Deliverables

#### Behavioral Specifications
- User experience flows for task and idea creation with hierarchical naming
- System behavior for file discovery and ID/timestamp extraction
- Interface contracts for all affected task and idea commands

#### Validation Artifacts
- Success criteria validation for new task and idea structures
- User acceptance criteria for both migration paths
- Behavioral test scenarios for edge cases in tasks and ideas

## Out of Scope

- ❌ **Implementation Details**: Specific code changes, class structure, or technical architecture
- ❌ **Technology Decisions**: Parser library choices, regex patterns, or algorithm selection
- ❌ **Performance Optimization**: Specific performance tuning or caching strategies
- ❌ **UI Changes**: Changes to command output format or display styling
- ❌ **Related Features**: Task/idea templates, relationships, or metadata enhancements beyond naming structure

## References

- Source Idea: `.ace-taskflow/v.0.9.0/ideas/done/20251015-011423-enhancement-in-ace-taskflow-make-the-task-folde.md`
- Current task structure: `.ace-taskflow/v.0.9.0/tasks/` (see existing examples)
- Current idea structure: `.ace-taskflow/v.0.9.0/ideas/` (see existing examples)
- ace-taskflow task commands: `ace-taskflow task --help`
- ace-taskflow idea commands: `ace-taskflow idea --help`
