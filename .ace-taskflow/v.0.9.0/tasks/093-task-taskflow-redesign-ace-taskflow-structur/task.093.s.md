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
- **File Extension-Based Discovery**: Replace pattern matching with extension detection (`.t.md`, `.i.md`)
- **Hierarchical Slug Generation**: Two-level context (folder = general, file = specific)

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
  - Update `load_tasks_from_release`: Change glob pattern from `*.s.md` to `*.t.md`
  - Update `has_task_frontmatter?`: Support both `.s.md` (old) and `.t.md` (new) during transition
  - Update `find_task_directory`: Search for both old and new directory naming patterns
- **Impact:** Task discovery now uses extension-based filtering
- **Integration:** All commands that list/find tasks will automatically use new discovery

**ace-taskflow/lib/ace/taskflow/molecules/idea_loader.rb**
- **Changes:**
  - Update `load_all_with_glob`: Change glob pattern from `*.s.md` to `*.i.md`
  - Update file detection logic: Check for `.i.md` extension
  - Add support for hierarchical folder structure with thematic grouping
  - Update `load_idea_file`: Extract folder slug for grouping
- **Impact:** Idea discovery uses extension and hierarchical folders
- **Integration:** All idea commands automatically use new structure

#### Modify - Path Building

**ace-taskflow/lib/ace/taskflow/atoms/path_builder.rb**
- **Changes:**
  - Update `extract_task_number`: Parse task numbers from new format (e.g., `085-search-fix`)
  - Add `extract_sub_task_number`: Handle sub-task notation (085.1, 085.2)
  - Update `build_task_file_path`: Generate `.t.md` filenames instead of `task.*.s.md`
  - Add `build_idea_folder_path`: Generate hierarchical idea folder paths
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
  - Add `generate_folder_slug`: Generate thematic folder slugs for ideas
  - Add `generate_file_slug`: Generate specific idea file slugs
  - Update `generate`: Support hierarchical folder/file structure
  - Update extension: Change from `.s.md` to `.i.md`
- **Impact:** Ideas created with hierarchical structure
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
  - Update `generate_path`: Use hierarchical folder structure
  - Add `generate_folder_slug`: Create thematic folder from content
  - Add `generate_file_slug`: Create specific filename slug
  - Update file extension: `.s.md` → `.i.md`
- **Impact:** Ideas created with folder grouping
- **Integration:** All idea creation uses new structure

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
  - Update `move_to_subdirectory`: Move to `done/{folder}/` (preserve theme)
  - Add folder structure preservation logic
  - Update path resolution for hierarchical folders
- **Impact:** Done ideas maintain thematic grouping
- **Integration:** Used by idea done operations

#### Create - Migration Support

**ace-taskflow/lib/ace/taskflow/molecules/format_detector.rb**
- **Purpose:** Detect old vs new format for tasks and ideas
- **Key components:**
  - `detect_task_format(path)`: Returns `:legacy` or `:hierarchical`
  - `detect_idea_format(path)`: Returns `:flat` or `:hierarchical`
  - `is_task_file?(path)`: Check for `.t.md` or legacy `task.*.md`
  - `is_idea_file?(path)`: Check for `.i.md` or legacy flat `.md`
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
  - Add `task_file_extension`: Configure task extension (`.t.md`)
  - Add `idea_file_extension`: Configure idea extension (`.i.md`)
  - Add `support_legacy_format`: Toggle for backward compatibility (default: true)
  - Add `slug_max_folder_words`: Max words in folder slug (default: 4)
  - Add `slug_max_file_words`: Max words in file slug (default: 5)
- **Impact:** Configurable format support
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

  - [ ] Enhance FileNamer for idea hierarchical structure
    - Add `generate_folder_slug` for thematic grouping
    - Add `generate_file_slug` for specific ideas
    - Update extension to `.i.md`
    > TEST: Idea File Naming
    > Type: Unit Test
    > Assert: Folder and file slugs generated correctly, extension is .i.md
    > Command: bundle exec ruby -I test test/molecules/file_namer_test.rb

- [ ] **Phase 2: Path and Discovery (Week 1)**
  - [ ] Update PathBuilder for new format
    - Modify `extract_task_number` to parse from hierarchical names
    - Add `extract_sub_task_number` for decimal notation (085.1)
    - Update `build_task_file_path` to use `.t.md` extension
    - Add `build_idea_folder_path` for hierarchical ideas
    > TEST: Path Building
    > Type: Unit Test
    > Assert: Paths built correctly for both old and new formats, sub-tasks supported
    > Command: bundle exec ruby -I test test/atoms/path_builder_test.rb

  - [ ] Update TaskLoader for extension-based discovery
    - Change glob pattern from `*.s.md` to `*.t.md`
    - Add backward compatibility for `task.*.s.md` pattern
    - Update `find_task_directory` for hierarchical folders
    - Enhance `has_task_frontmatter?` to check both extensions
    > TEST: Task Loading
    > Type: Integration Test
    > Assert: Loads both old and new format tasks, finds tasks in hierarchical folders
    > Command: bundle exec ruby -I test test/molecules/task_loader_test.rb

  - [ ] Update IdeaLoader for hierarchical structure
    - Change glob pattern from `*.s.md` to `*.i.md`
    - Add folder-based grouping logic
    - Update `load_idea_file` to extract folder slug
    - Support both flat and hierarchical formats
    > TEST: Idea Loading
    > Type: Integration Test
    > Assert: Loads both old and new format ideas, groups by folder correctly
    > Command: bundle exec ruby -I test test/molecules/idea_loader_test.rb

- [ ] **Phase 3: Creation Logic (Week 2)**
  - [ ] Update TaskManager.create_task
    - Integrate hierarchical slug generation
    - Add sub-task detection (check folder existence)
    - Assign sub-numbers (085.1, 085.2) for related tasks
    - Generate `.t.md` files in hierarchical folders
    > TEST: Task Creation
    > Type: Integration Test
    > Assert: Tasks created with correct folder/file structure, sub-tasks assigned correctly
    > Command: bundle exec ruby -I test test/organisms/task_manager_test.rb

  - [ ] Update IdeaWriter.write
    - Integrate hierarchical folder slug generation
    - Generate thematic folders from content
    - Create `.i.md` files with specific slugs
    - Maintain timestamp-based IDs
    > TEST: Idea Creation
    > Type: Integration Test
    > Assert: Ideas created in correct thematic folders with .i.md extension
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
