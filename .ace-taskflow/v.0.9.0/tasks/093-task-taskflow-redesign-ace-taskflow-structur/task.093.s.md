---
id: v.0.9.0+task.093
status: pending
priority: medium
estimate: 2-3 weeks
dependencies: []
sort: 996
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
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085-always-use-project-root.s.md
.ace-taskflow/v.0.9.0/tasks/090-taskflow-enhance/090-implement-update-command.s.md
.ace-taskflow/v.0.9.0/tasks/092-docs-add/092-add-timestamp-frontmatter.s.md
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085.1-update-search-docs.s.md  # Sub-task

# Ideas (each in separate timestamped folder - NO automatic grouping):
.ace-taskflow/v.0.9.0/ideas/20251015-011423-taskflow-enhance/redesign-task-structure.s.md
.ace-taskflow/v.0.9.0/ideas/20251016-094512-taskflow-enhance/add-task-templates.s.md
.ace-taskflow/v.0.9.0/ideas/20251020-143022-search-fix/default-to-project-root.s.md
.ace-taskflow/v.0.9.0/ideas/20251022-091534-docs-add/add-usage-examples.s.md
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
- Format: `{id}-{precise-description}.s.md`
- More specific description of the task
- Continues/completes context from folder name
- Extension: `.s.md` (spec) - existing extension preserved
- Examples:
  - `085-always-use-project-root.s.md`
  - `090-implement-update-command.s.md`
  - `092-add-timestamp-frontmatter.s.md`

**Multi-task Support:**
```bash
# Multiple related tasks can share a folder:
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085-always-use-project-root.s.md
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085.1-update-search-docs.s.md
.ace-taskflow/v.0.9.0/tasks/085-search-fix/085.2-add-integration-tests.s.md
```

#### Ideas Structure

**Folder Naming Convention:**
- Format: `{timestamp}-{system-area}-{goal-type}`
- Timestamp first (format: YYYYMMDD-HHMMSS) - acts as unique identifier
- System area and goal type provide thematic context
- Goal types: `add`, `enhance`, `fix`, `refactor`
- Each idea gets its own timestamped folder (NO automatic grouping)
- Examples:
  - `20251015-011423-taskflow-enhance` (idea for enhancing taskflow)
  - `20251020-143022-search-fix` (idea for fixing search)
  - `20251022-091534-docs-add` (idea for adding docs)

**File Naming Convention (5±2 words):**
- Format: `{precise-description}.s.md`
- NO timestamp in filename (timestamp is in folder name)
- Precise description of the idea (approximately 5 words, range 3-7)
- Extension: `.s.md` (spec) - existing extension preserved
- Examples:
  - `redesign-task-structure.s.md`
  - `default-to-project-root.s.md`
  - `add-usage-examples.s.md`

**Multiple Ideas (Each in Separate Folder):**
```bash
# Each idea gets its own timestamped folder, even if same theme:
.ace-taskflow/v.0.9.0/ideas/20251015-011423-taskflow-enhance/redesign-task-structure.s.md
.ace-taskflow/v.0.9.0/ideas/20251016-094512-taskflow-enhance/add-task-templates.s.md
.ace-taskflow/v.0.9.0/ideas/20251020-143022-search-fix/default-to-project-root.s.md
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
# Creates: tasks/{id}-{auto-slug}/{id}-{auto-slug}.s.md

# Task completion (moves to done/ with same structure)
ace-taskflow task done 085
# Moves: tasks/085-search-fix/ → done/085-search-fix/

# Task listing (adapts to new filename pattern)
ace-taskflow tasks all                   # Lists all tasks
ace-taskflow tasks next                  # Shows actionable tasks

# Idea commands (NOW creates in subfolder - fixing current bug):
ace-taskflow idea create "Improve search performance"
# Creates: ideas/{timestamp}-{auto-slug}/{description}.s.md
# Example: ideas/20251102-104523-search-enhance/improve-performance.s.md

ace-taskflow idea show 20251015-011423
# Shows idea by timestamp (finds in timestamped folder)

ace-taskflow idea done 20251015-011423
# Moves: ideas/{timestamp}-{folder}/ → ideas/done/{timestamp}-{folder}/

# Idea listing
ace-taskflow ideas all                   # Lists all ideas
ace-taskflow ideas active                # Shows active ideas
```

**System Behavior:**

**Tasks:**
1. **File Discovery**: System finds tasks by pattern `{id}-*.s.md` instead of `task.*.s.md` pattern
2. **ID Extraction**: Parse task ID from both folder name and filename
3. **Sub-task Support**: Handle decimal notation (085.1, 085.2) for related tasks
4. **Slug Generation**: Auto-generate meaningful slugs from task titles and context

**Ideas:**
1. **File Discovery**: System finds ideas in timestamped folders by `.s.md` extension
2. **Timestamp Extraction**: Parse timestamp identifier from folder name (NOT filename)
3. **Folder Structure**: Each idea in separate `{timestamp}-{theme}/` folder (no automatic grouping)
4. **Slug Generation**: Auto-generate folder slug (timestamp + theme) and file slug (description only)
5. **Bug Fix**: ALWAYS create ideas in subfolder, never as flat files

**Error Handling:**

**Tasks:**
- **Duplicate IDs**: Error if task ID already exists in release
- **Invalid slug format**: Warn if slug doesn't follow conventions
- **Wrong file pattern**: Warn if task files don't match `{id}-*.s.md` pattern
- **Orphaned folders**: Detect folders without task files

**Ideas:**
- **Duplicate timestamps**: Error if idea folder with same timestamp already exists
- **Invalid slug format**: Warn if slug doesn't follow conventions
- **Flat file creation**: ERROR if idea created as flat file instead of in subfolder
- **Wrong file pattern**: Warn if idea files don't match `{description}.s.md` pattern (no timestamp)
- **Orphaned folders**: Detect folders without idea files

**Edge Cases:**

**Tasks:**
- **Legacy format**: Support reading existing `task.*.s.md` files during migration
- **Sub-task creation**: Allow creating 085.1 when 085 exists
- **Folder reuse**: Allow multiple tasks in same thematic folder if IDs differ

**Ideas:**
- **Legacy format**: Support reading existing flat `.s.md` files during migration
- **Legacy directory format**: Support reading existing `{timestamp}-description/idea.s.md` pattern
- **Flat file bug**: Existing flat idea files should be detected and migrated to subfolder structure
- **No folder reuse**: Each idea gets unique timestamped folder (no grouping, no reuse)
- **Done ideas**: Maintain folder structure when moving to `done/{timestamp}-{theme}/` subdirectory

### Success Criteria

**Tasks:**
- [ ] **Folder Convention**: Folders use `{id}-{general-slug}` format (2-4 words)
- [ ] **File Convention**: Files use `{id}-{specific-slug}.s.md` format (3-5 words)
- [ ] **General Slug**: Indicates system area and goal type (add/enhance/fix/refactor)
- [ ] **Specific Slug**: Provides precise task description completing folder context
- [ ] **Multi-task Support**: Multiple related tasks can exist in same folder
- [ ] **Extension Preserved**: All task files use `.s.md` extension (existing)
- [ ] **Command Compatibility**: All ace-taskflow task commands work with new structure
- [ ] **Migration Path**: Clear strategy for migrating existing tasks

**Ideas:**
- [ ] **Folder Convention**: Folders use `{timestamp}-{general-slug}` format (timestamp first)
- [ ] **File Convention**: Files use `{specific-slug}.s.md` format (5±2 words, NO timestamp)
- [ ] **General Slug**: Indicates system area and goal type (add/enhance/fix/refactor)
- [ ] **Specific Slug**: Provides precise idea description (5±2 words)
- [ ] **No Grouping**: Each idea in separate timestamped folder (no automatic grouping)
- [ ] **Extension Preserved**: All idea files use `.s.md` extension (existing)
- [ ] **Bug Fixed**: Ideas ALWAYS created in subfolder, never as flat files
- [ ] **Command Compatibility**: All ace-taskflow idea commands work with new structure
- [ ] **Migration Path**: Clear strategy for migrating existing ideas and fixing flat files

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
- UX/Usage Documentation: `./ux/usage.md`

## Technical Implementation Plan

### Technical Approach

#### Architecture Pattern

The implementation follows the existing ATOM architecture pattern used throughout ace-taskflow:

- **Atoms**: Pure functions for file extension detection, slug parsing, path pattern matching
- **Molecules**: File naming logic, slug generation enhancements, path discovery updates
- **Organisms**: Coordination of task/idea creation, completion, and migration workflows
- **Commands**: CLI interface updates (minimal changes - maintain backward compatibility)

**Key Design Principles:**
- **Backward Compatibility**: Support both old and new formats during transition
- **Progressive Enhancement**: New items use new format, existing items preserved
- **Pattern-Based Discovery**: Replace `task.*.s.md` with `{id}-*.s.md` pattern for tasks
- **Hierarchical Slug Generation**: Two-level context (folder = general, file = specific)
- **Extension Preservation**: Keep `.s.md` extension for both tasks and ideas
- **Bug Fix Priority**: Fix ideas always being created in subfolders (not flat files)

#### Integration with Existing Architecture

**Current System:**
- `TaskLoader`: Uses `Dir.glob` with `*.s.md` pattern, checks for `has_task_frontmatter?`
- `IdeaLoader`: Uses `Dir.glob` with `*.s.md` pattern, extracts timestamp from filename
- `PathBuilder`: Builds paths, extracts task numbers from directory names
- `TaskSlugGenerator`: Generates descriptive slugs from titles
- `FileNamer`: Generates timestamped filenames for ideas

**Integration Points:**
1. **File Discovery**: Update glob patterns to use new extensions
2. **Path Construction**: Enhance to support hierarchical slugs
3. **Slug Generation**: Extend to generate both folder and file slugs
4. **ID Extraction**: Update to parse from both folder and file names
5. **Migration Support**: Add dual-format support during transition

### Technology Stack

#### Libraries/Frameworks
- **Existing Dependencies** (no new dependencies required):
  - Ruby stdlib: `File`, `Dir`, `FileUtils`, `Pathname`
  - `ace-support-markdown`: SafeFileWriter for atomic writes
  - YAML frontmatter parsing (existing `Atoms::YamlParser`)

#### Version Compatibility
- Ruby 2.7+ (existing requirement)
- No breaking changes to public CLI interface
- Backward compatible file format support

### File Modifications

#### Modify - Core Loading Logic

**ace-taskflow/lib/ace/taskflow/molecules/task_loader.rb**
- **Changes:**
  - Update `load_tasks_from_release`: Change file pattern from `task.*.s.md` to `*.s.md` (finds `{id}-*.s.md`)
  - Update `has_task_frontmatter?`: Support both `task.*.s.md` (old) and `{id}-*.s.md` (new) patterns
  - Update `find_task_directory`: Search for both old and new directory naming patterns
- **Impact:** Task discovery now finds tasks by new filename pattern
- **Integration:** All commands that list/find tasks will automatically use new discovery

**ace-taskflow/lib/ace/taskflow/molecules/idea_loader.rb**
- **Changes:**
  - Update `load_all_with_glob`: Look for ideas in timestamped folders `{timestamp}-*/`
  - Update file detection logic: Find `.s.md` files within timestamped folders
  - Add support for both flat files (legacy) and timestamped folders (new)
  - Update `load_idea_file`: Extract timestamp from folder name (not filename)
  - Support `{description}.s.md` filename pattern (no timestamp in filename)
- **Impact:** Idea discovery uses timestamped folder structure
- **Integration:** All idea commands automatically use new structure

#### Modify - Path Building

**ace-taskflow/lib/ace/taskflow/atoms/path_builder.rb**
- **Changes:**
  - Update `extract_task_number`: Parse task numbers from new format (e.g., `085-search-fix`)
  - Add `extract_sub_task_number`: Handle sub-task notation (085.1, 085.2)
  - Update `build_task_file_path`: Generate `{id}-{description}.s.md` instead of `task.{id}.s.md`
  - Add `build_idea_folder_path`: Generate timestamped idea folder paths `{timestamp}-{theme}/`
  - Add helper to build idea file path: `{folder}/{description}.s.md`
- **Impact:** Path operations support both formats
- **Integration:** Used by all file creation and discovery operations

#### Modify - Slug Generation

**ace-taskflow/lib/ace/taskflow/molecules/task_slug_generator.rb**
- **Changes:**
  - Add `generate_folder_slug`: Generate general context slug (2-4 words)
  - Add `generate_file_slug`: Generate specific description slug (3-5 words)
  - Update `generate_descriptive_part`: Split into folder + file components
  - Add goal type extraction: `add`, `enhance`, `fix`, `refactor`
- **Impact:** Creates hierarchical slugs with clear context separation
- **Integration:** Used by TaskManager during task creation

**ace-taskflow/lib/ace/taskflow/molecules/file_namer.rb**
- **Changes:**
  - Add `generate_folder_slug`: Generate timestamped folder slugs `{timestamp}-{theme}`
  - Add `generate_file_slug`: Generate description-only file slugs (5±2 words, NO timestamp)
  - Update `generate`: Support timestamped folder structure (folder + file separation)
  - Keep extension: `.s.md` (no change)
- **Impact:** Ideas created with timestamped folder structure
- **Integration:** Used by IdeaWriter during idea creation

#### Modify - Task Management

**ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb**
- **Changes:**
  - Update `create_task`: Use new hierarchical slug generation
  - Add sub-task detection: Check if folder exists, assign sub-number if needed
  - Update `complete_task`: Move entire folder to done/ (preserve structure)
  - Add `generate_file_slug_from_title`: Extract specific description
- **Impact:** Task creation and completion use new structure
- **Integration:** All task lifecycle operations updated

**ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb**
- **Changes:**
  - **BUG FIX**: ALWAYS create ideas in timestamped folder, never as flat files
  - Update `generate_path`: Create `{timestamp}-{theme}/` folder structure
  - Add `generate_folder_slug`: Generate `{timestamp}-{system-area}-{goal-type}` folder name
  - Add `generate_file_slug`: Generate `{description}.s.md` filename (no timestamp)
  - Remove flat file creation logic completely
  - Keep extension: `.s.md` (no change)
- **Impact:** Ideas ALWAYS created in subfolder (fixes current bug)
- **Integration:** All idea creation uses new structure, no more flat files

#### Modify - Directory Movement

**ace-taskflow/lib/ace/taskflow/molecules/task_directory_mover.rb**
- **Changes:**
  - Update `move_to_done`: Move entire folder (not just file)
  - Add validation: Ensure all files in folder are moved together
  - Update path resolution: Handle hierarchical structure
- **Impact:** Done tasks maintain folder organization
- **Integration:** Used by complete_task operations

**ace-taskflow/lib/ace/taskflow/molecules/idea_directory_mover.rb**
- **Changes:**
  - Update `move_to_subdirectory`: Move to `done/{timestamp}-{theme}/` (preserve timestamp folder)
  - Add folder structure preservation logic
  - Update path resolution for timestamped folders
  - Handle legacy flat files during migration
- **Impact:** Done ideas maintain timestamped folder structure
- **Integration:** Used by idea done operations

#### Create - Migration Support

**ace-taskflow/lib/ace/taskflow/molecules/format_detector.rb**
- **Purpose:** Detect old vs new format for tasks and ideas
- **Key components:**
  - `detect_task_format(path)`: Returns `:legacy` (`task.*.s.md`) or `:hierarchical` (`{id}-*.s.md`)
  - `detect_idea_format(path)`: Returns `:flat` (flat `.s.md`) or `:folder` (in timestamped folder)
  - `is_task_file?(path)`: Check for both `task.*.s.md` and `{id}-*.s.md` patterns
  - `is_idea_file?(path)`: Check for `.s.md` in both flat and folder structures
  - `is_flat_idea?(path)`: Detect legacy flat idea files that need migration
- **Dependencies:** File extension checking, path pattern matching

**ace-taskflow/lib/ace/taskflow/organisms/structure_migrator.rb**
- **Purpose:** Migrate existing tasks/ideas to new format (future enhancement)
- **Key components:**
  - `migrate_task(task_path)`: Convert task to new structure
  - `migrate_idea(idea_path)`: Convert idea to new structure
  - `validate_migration(path)`: Ensure migration success
  - `create_backup(path)`: Backup before migration
- **Dependencies:** FormatDetector, TaskLoader, IdeaLoader, SafeFileWriter

#### Modify - Configuration

**ace-taskflow/lib/ace/taskflow/configuration.rb**
- **Changes:**
  - Add `task_file_pattern`: Configure task filename pattern (`{id}-*.s.md`)
  - Add `idea_require_folder`: ALWAYS true - ideas must be in folders (bug fix)
  - Add `support_legacy_format`: Toggle for backward compatibility (default: true)
  - Add `slug_max_folder_words`: Max words in folder slug (default: 4 for tasks, variable for ideas)
  - Add `slug_max_file_words`: Max words in file slug (default: 5 for tasks, 5±2 for ideas)
  - Keep `file_extension`: `.s.md` for both tasks and ideas (no change)
- **Impact:** Configurable format support, enforces subfolder creation for ideas
- **Integration:** Used by all file operations

### Implementation Plan

#### Planning Steps

* [ ] **Review and validate behavioral specification**
  - Ensure all edge cases covered in spec
  - Validate success criteria completeness
  - Confirm interface contract covers all commands

* [ ] **Analyze existing file discovery patterns**
  - Document current glob patterns across codebase
  - Identify all locations using `*.s.md` pattern
  - Map dependencies between loaders and commands

* [ ] **Design slug generation algorithm**
  - Define word extraction and filtering rules
  - Determine goal type keywords and mapping
  - Establish system area detection patterns
  - Plan folder vs file slug distribution

* [ ] **Plan migration strategy**
  - Define backward compatibility requirements
  - Design dual-format support approach
  - Plan validation and rollback procedures

#### Execution Steps

- [ ] **Phase 1: Core Infrastructure (Week 1)**
  - [ ] Create FormatDetector molecule
    > TEST: Format Detection
    > Type: Unit Test
    > Assert: Correctly identifies legacy vs new format for both tasks and ideas
    > Command: bundle exec ruby -I test test/molecules/format_detector_test.rb

  - [ ] Update Configuration with new extension settings
    > TEST: Configuration Values
    > Type: Unit Test
    > Assert: New configuration keys return expected defaults
    > Command: bundle exec ruby -I test test/configuration_test.rb

  - [ ] Enhance TaskSlugGenerator for hierarchical slugs
    - Add `generate_folder_slug` method (2-4 words, general context)
    - Add `generate_file_slug` method (3-5 words, specific description)
    - Add goal type detection (add/enhance/fix/refactor)
    - Add system area extraction logic
    > TEST: Slug Generation
    > Type: Unit Test
    > Assert: Folder slugs are 2-4 words, file slugs are 3-5 words, goal types detected correctly
    > Command: bundle exec ruby -I test test/molecules/task_slug_generator_test.rb

  - [ ] Enhance FileNamer for idea timestamped folder structure
    - Add `generate_folder_slug` for timestamped folders (`{timestamp}-{theme}`)
    - Add `generate_file_slug` for description-only filenames (5±2 words, no timestamp)
    - Keep extension `.s.md` (no change)
    > TEST: Idea File Naming
    > Type: Unit Test
    > Assert: Folder includes timestamp, file is description-only, extension is .s.md
    > Command: bundle exec ruby -I test test/molecules/file_namer_test.rb

- [ ] **Phase 2: Path and Discovery (Week 1)**
  - [ ] Update PathBuilder for new format
    - Modify `extract_task_number` to parse from hierarchical names
    - Add `extract_sub_task_number` for decimal notation (085.1)
    - Update `build_task_file_path` to generate `{id}-{description}.s.md` pattern
    - Add `build_idea_folder_path` for timestamped folders `{timestamp}-{theme}/`
    - Add `build_idea_file_path` for description-only filenames
    > TEST: Path Building
    > Type: Unit Test
    > Assert: Paths built correctly for both old and new formats, sub-tasks supported, idea timestamps in folders
    > Command: bundle exec ruby -I test test/atoms/path_builder_test.rb

  - [ ] Update TaskLoader for new filename pattern
    - Change file pattern from `task.*.s.md` to `*.s.md` (finds `{id}-*.s.md`)
    - Add backward compatibility for `task.*.s.md` pattern
    - Update `find_task_directory` for hierarchical folders
    - Enhance `has_task_frontmatter?` to check both patterns
    > TEST: Task Loading
    > Type: Integration Test
    > Assert: Loads both old and new format tasks, finds tasks in hierarchical folders
    > Command: bundle exec ruby -I test test/molecules/task_loader_test.rb

  - [ ] Update IdeaLoader for timestamped folder structure
    - Look for ideas in timestamped folders `{timestamp}-*/`
    - Find `.s.md` files within timestamped folders
    - Support both flat files (legacy) and timestamped folders (new)
    - Extract timestamp from folder name (not filename)
    > TEST: Idea Loading
    > Type: Integration Test
    > Assert: Loads both old flat and new timestamped folder ideas, timestamp from folder name
    > Command: bundle exec ruby -I test test/molecules/idea_loader_test.rb

- [ ] **Phase 3: Creation Logic (Week 2)**
  - [ ] Update TaskManager.create_task
    - Integrate hierarchical slug generation
    - Add sub-task detection (check folder existence)
    - Assign sub-numbers (085.1, 085.2) for related tasks
    - Generate `{id}-{description}.s.md` files in hierarchical folders
    > TEST: Task Creation
    > Type: Integration Test
    > Assert: Tasks created with correct folder/file structure, sub-tasks assigned correctly, .s.md extension
    > Command: bundle exec ruby -I test test/organisms/task_manager_test.rb

  - [ ] **FIX IdeaWriter.write (Bug Fix)**
    - **ALWAYS create ideas in timestamped folders, never as flat files**
    - Generate timestamped folder: `{timestamp}-{system-area}-{goal-type}/`
    - Generate description-only filename: `{description}.s.md` (no timestamp)
    - Remove any flat file creation logic
    - Maintain timestamp-based folder IDs
    > TEST: Idea Creation (Bug Fix Validation)
    > Type: Integration Test
    > Assert: Ideas ALWAYS created in subfolder, never as flat files, timestamp in folder not filename
    > Command: bundle exec ruby -I test test/organisms/idea_writer_test.rb

- [ ] **Phase 4: Movement Operations (Week 2)**
  - [ ] Update TaskDirectoryMover
    - Modify `move_to_done` to move entire folder
    - Add validation for folder contents
    - Preserve hierarchical structure in done/
    > TEST: Task Movement
    > Type: Integration Test
    > Assert: Entire folder moved to done/, structure preserved
    > Command: bundle exec ruby -I test test/molecules/task_directory_mover_test.rb

  - [ ] Update IdeaDirectoryMover
    - Modify movement to preserve folder structure (`done/{folder}/`)
    - Update path resolution for hierarchical ideas
    > TEST: Idea Movement
    > Type: Integration Test
    > Assert: Ideas moved to done/{folder}/, thematic grouping preserved
    > Command: bundle exec ruby -I test test/molecules/idea_directory_mover_test.rb

- [ ] **Phase 5: Testing & Validation (Week 3)**
  - [ ] Create comprehensive integration tests
    - Full task lifecycle (create → complete → find)
    - Full idea lifecycle (create → complete → find)
    - Sub-task creation and management
    - Multi-idea folder grouping
    > TEST: End-to-End Workflows
    > Type: Integration Test
    > Assert: Complete workflows function correctly with new structure
    > Command: bundle exec rake test

  - [ ] Test backward compatibility
    - Verify old format tasks still load
    - Verify old format ideas still load
    - Test mixed environments (old + new)
    > TEST: Backward Compatibility
    > Type: Integration Test
    > Assert: Old format files work alongside new format
    > Command: bundle exec ruby -I test test/integration/backward_compatibility_test.rb

  - [ ] Manual CLI testing
    - Test all task commands with new structure
    - Test all idea commands with new structure
    - Verify display formats correct
    - Confirm error handling works

  - [ ] Update documentation
    - Update README with new structure examples
    - Update CHANGELOG with migration notes
    - Create migration guide for users

  - [ ] Create migration tool (StructureMigrator organism)
    - Implement batch migration for existing tasks
    - Implement batch migration for existing ideas
    - Add dry-run mode
    - Add backup/rollback support
    > TEST: Migration Tool
    > Type: Integration Test
    > Assert: Migrations complete successfully, backups created, rollback works
    > Command: bundle exec ruby -I test test/organisms/structure_migrator_test.rb

### Risk Assessment

#### Technical Risks

- **Risk:** File discovery breaks in edge cases (nested folders, symbolic links)
  - **Probability:** Medium
  - **Impact:** High (could break task/idea listing)
  - **Mitigation:** Comprehensive test coverage for edge cases, add validation for folder structures
  - **Rollback:** Revert glob pattern changes, maintain old format support

- **Risk:** Sub-task numbering conflicts (085.1 already exists)
  - **Probability:** Low
  - **Impact:** Medium (creation fails, user confusion)
  - **Mitigation:** Check for existing sub-numbers, increment to next available (085.2, 085.3)
  - **Rollback:** Manual renumbering if needed

- **Risk:** Slug generation produces unexpected results
  - **Probability:** Medium
  - **Impact:** Low (slugs don't match expectations but still functional)
  - **Mitigation:** Extensive testing of slug algorithm, provide clear slug examples in docs
  - **Rollback:** No rollback needed - slugs are deterministic but cosmetic

#### Integration Risks

- **Risk:** Commands assume old file patterns
  - **Probability:** Medium
  - **Impact:** High (commands fail to find files)
  - **Mitigation:** Update all glob patterns consistently, maintain backward compatibility layer
  - **Monitoring:** Test all commands in CI with both formats

- **Risk:** Third-party tools depend on old structure
  - **Probability:** Low
  - **Impact:** Medium (external integrations break)
  - **Mitigation:** Maintain dual-format support, document migration timeline
  - **Monitoring:** Provide migration guide and deprecation warnings

#### Performance Risks

- **Risk:** Hierarchical folder scanning slower than flat structure
  - **Probability:** Low
  - **Impact:** Low (slight performance degradation)
  - **Mitigation:** Glob patterns optimized, folder depth limited to 2 levels
  - **Monitoring:** Benchmark task/idea listing before and after
  - **Thresholds:** <100ms for listing 100 tasks/ideas (acceptable)
