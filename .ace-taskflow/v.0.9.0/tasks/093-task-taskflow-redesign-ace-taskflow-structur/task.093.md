---
id: v.0.9.0+task.093
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Redesign ace-taskflow task structure with hierarchical slug naming

## Behavioral Specification

### User Experience

**Input**: Users create and manage tasks using existing ace-taskflow commands
**Process**: System organizes tasks in hierarchical folder structure with meaningful slugs
**Output**: Clean, readable task organization with folder/file naming that conveys context

**Current Structure (Problem):**
```bash
.ace-taskflow/v.0.9.0/tasks/045-info-tasks-and-id-045/task.045.md
# Issues:
# - Redundant information in folder slug
# - Generic "task" prefix in filename
# - No clear hierarchy between folder and file context
```

**Proposed Structure (Solution):**
```bash
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085-always-use-project-root.t.md
.ace-taskflow/v.0.9.0/tasks/090-taskflow-enhance/090-implement-update-command.t.md
.ace-taskflow/v.0.9.0/tasks/092-docs-add/092-add-timestamp-frontmatter.t.md
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085.1-update-search-docs.t.md  # Sub-task
```

### Expected Behavior

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

### Interface Contract

**CLI Interface - All existing commands continue to work:**

```bash
# Task lookup (unchanged)
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
```

**System Behavior:**

1. **File Discovery**: System finds tasks by `.t.md` extension instead of `task.*.md` pattern
2. **ID Extraction**: Parse task ID from both folder name and filename
3. **Sub-task Support**: Handle decimal notation (085.1, 085.2) for related tasks
4. **Slug Generation**: Auto-generate meaningful slugs from task titles and context

**Error Handling:**

- **Duplicate IDs**: Error if task ID already exists in release
- **Invalid slug format**: Warn if slug doesn't follow conventions
- **Missing .t.md extension**: Warn if task files don't use correct extension
- **Orphaned folders**: Detect folders without task files

**Edge Cases:**

- **Legacy format**: Support reading existing `task.*.md` files during migration
- **Sub-task creation**: Allow creating 085.1 when 085 exists
- **Folder reuse**: Allow multiple tasks in same thematic folder if IDs differ

### Success Criteria

- [ ] **Folder Convention**: Folders use `{id}-{general-slug}` format (2-4 words)
- [ ] **File Convention**: Files use `{id}-{specific-slug}.t.md` format (3-5 words)
- [ ] **General Slug**: Indicates system area and goal type (add/enhance/fix/refactor)
- [ ] **Specific Slug**: Provides precise task description completing folder context
- [ ] **Multi-task Support**: Multiple related tasks can exist in same folder
- [ ] **Extension Change**: All task files use `.t.md` extension
- [ ] **Command Compatibility**: All ace-taskflow commands work with new structure
- [ ] **Migration Path**: Clear strategy for migrating existing tasks

### Validation Questions

- [ ] **Migration Strategy**: Should we migrate all existing tasks at once, or support both old and new formats during a transition period?
- [ ] **Goal Type Keywords**: Should we enforce specific keywords (add/enhance/fix/refactor) or allow flexibility in folder slugs?
- [ ] **Slug Generation**: Should slugs be auto-generated from task titles, manually specified during creation, or a hybrid approach?
- [ ] **Sub-task Format**: Is `{id}.{sub-number}` (e.g., 085.1, 085.2) the right notation for related tasks?
- [ ] **Done Structure**: Should tasks moved to done/ maintain the new structure, or use a flattened structure?
- [ ] **Folder Reuse**: What rules govern when tasks can share a folder vs. requiring separate folders?

## Objective

Transform ace-taskflow's task organization from single-purpose folders with redundant naming to a hierarchical structure that supports multiple related tasks while providing clear context through meaningful folder and file slugs.

**Why**: Current structure creates cluttered task directories with redundant information (ID appears in both folder and file, generic "task" prefix adds no value). The new structure provides:
- Better readability through meaningful slugs
- Support for related tasks in shared folders
- Clear hierarchy between general (folder) and specific (file) context
- Easier navigation and understanding of task organization

## Scope of Work

### User Experience Scope

- Task creation workflow with hierarchical slug generation
- Task lookup by ID across new structure
- Task listing with new file extension
- Task completion/movement maintaining structure
- Sub-task creation within shared folders

### System Behavior Scope

- File discovery using `.t.md` extension pattern
- Slug generation from task titles and context
- Folder sharing logic for related tasks
- Migration handling for existing task format

### Interface Scope

- All existing ace-taskflow commands maintain compatibility
- No breaking changes to command syntax
- Enhanced behavior for new structure features

### Deliverables

#### Behavioral Specifications
- User experience flow for task creation with hierarchical naming
- System behavior for file discovery and ID extraction
- Interface contract for all affected commands

#### Validation Artifacts
- Success criteria validation for new structure
- User acceptance criteria for migration
- Behavioral test scenarios for edge cases

## Out of Scope

- ❌ **Implementation Details**: Specific code changes, class structure, or technical architecture
- ❌ **Technology Decisions**: Parser library choices, regex patterns, or algorithm selection
- ❌ **Performance Optimization**: Specific performance tuning or caching strategies
- ❌ **UI Changes**: Changes to command output format or display styling
- ❌ **Related Features**: Task templates, task relationships, or task metadata enhancements beyond naming

## References

- Source Idea: `.ace-taskflow/v.0.9.0/ideas/done/20251015-011423-enhancement-in-ace-taskflow-make-the-task-folde.md`
- Current task structure: `.ace-taskflow/v.0.9.0/tasks/` (see existing examples)
- ace-taskflow commands: `ace-taskflow task --help`
