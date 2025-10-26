---
id: 088.1
status: pending
priority: high
estimate: 4h
dependencies: []
parent_task: 088
---

# Fix Config Duplication and Implement Glob-Based Presets

## Behavioral Specification

### User Experience
- **Input**: Users configure taskflow directory structure once in `.ace/taskflow/config.yml` with simple folder names (not paths)
- **Process**: Users create presets using glob patterns that work universally across all contexts (backlog, releases)
- **Output**: Consistent directory structure across all releases, self-defining presets without hardcoded mappings

### Expected Behavior

**Configuration Simplicity:**
- Main config defines folder names once: `ideas: "ideas"`, `tasks: "tasks"`
- Same folder structure in every context (backlog/, v.0.9.0/, etc.)
- No duplication of path logic between config and code

**Universal Presets:**
- Presets use glob patterns starting from ideas/ or tasks/ folders
- Same preset works for both backlog and all releases
- Globs self-define what they include (no hardcoded PRESET_TO_SCOPE mapping)
- Context determines which release root to apply globs within

**Example Directory Structure:**
```
.ace-taskflow/
├── backlog/
│   ├── ideas/         # folder name from config
│   │   ├── maybe/
│   │   ├── anyday/
│   │   └── done/
│   └── tasks/         # folder name from config
│       ├── maybe/
│       └── done/
└── v.0.9.0/
    ├── ideas/         # same folder name
    │   ├── maybe/
    │   ├── anyday/
    │   └── done/
    └── tasks/         # same folder name
        ├── maybe/
        └── done/
```

### Interface Contract

**Configuration File:**
```yaml
# .ace/taskflow/config.yml
taskflow:
  directories:
    # Folder names (NOT paths) - used in each release context
    tasks: "tasks"
    ideas: "ideas"

    # Backlog is fallback location when no release
    backlog: "backlog"
```

**Preset File:**
```yaml
# .ace/taskflow/presets/maybe.yml
description: "Maybe items (uncertain/might pursue)"
type:  # Universal (works for both ideas and tasks)
context: "current"  # or "backlog", or "v.0.9.0"
filters:
  glob:
    - "ideas/maybe/**/*.md"
    - "tasks/maybe/**/task.*.md"
sort:
  by: "created_at"
  ascending: false
```

**CLI Behavior:**
```bash
# List maybe ideas in current release
ace-taskflow ideas maybe

# List maybe tasks in backlog
ace-taskflow tasks maybe --context backlog

# List all items (ideas + tasks) in maybe scope
ace-taskflow list maybe --context current
```

**Error Handling:**
- Invalid glob pattern: Show clear error with example of valid pattern
- Missing context directory: Fall back to backlog with warning
- Empty glob results: Show "No items found matching pattern"

**Edge Cases:**
- No active release + context "current": Falls back to backlog
- Glob matches both flat files and directory-based items: Loads both
- Multiple glob patterns: Results are combined (union)

### Success Criteria

- [ ] **Config Simplification**: Main config uses `ideas: "ideas"` (not `"backlog/ideas"`)
- [ ] **Universal Globs**: Presets use glob patterns that work across all contexts
- [ ] **No Hardcoding**: PRESET_TO_SCOPE mapping removed from commands
- [ ] **Consistent Structure**: Same folder structure in backlog/ and all releases
- [ ] **Backward Compatibility**: Existing presets continue to work
- [ ] **Self-Defining**: Presets declare what they include via globs (no code mapping needed)

### Validation Questions

- [ ] **Glob Resolution**: Should globs be resolved relative to context root (backlog/ or v.0.9.0/) or relative to ideas/tasks folders?
- [ ] **Preset Type**: Should `type:` field be removed entirely or kept as optional metadata?
- [ ] **Context Default**: Should `context: "current"` remain the default when not specified?
- [ ] **Migration Path**: Do we need to migrate existing presets or just update examples?

## Objective

Eliminate configuration duplication and hardcoded mappings by implementing a glob-based preset system where:
1. Directory structure is defined once and consistently applied
2. Presets self-define their content through glob patterns
3. Same presets work universally across all contexts (backlog, releases)

This improves maintainability, extensibility, and user experience by making the system more predictable and easier to configure.

## Scope of Work

### User Experience Scope
- Configuration of taskflow directory structure
- Creation of universal presets using glob patterns
- Listing/filtering ideas and tasks across different contexts
- Understanding how context resolution works

### System Behavior Scope
- Config loading and directory name resolution
- Preset loading with glob pattern support
- Context resolution (current → active release, backlog → backlog dir)
- Glob pattern evaluation within context root

### Interface Scope
- Configuration file format (`.ace/taskflow/config.yml`)
- Preset file format (`.ace/taskflow/presets/*.yml`)
- CLI commands for listing ideas/tasks with presets

### Deliverables

#### Behavioral Specifications
- Configuration structure definition
- Preset glob pattern syntax
- Context resolution behavior
- Error handling patterns

#### Validation Artifacts
- Test scenarios for glob pattern matching
- Context resolution test cases
- Backward compatibility validation

## Out of Scope

- ❌ **Migration Scripts**: Automatic migration of existing user configs (manual update documented)
- ❌ **Advanced Glob Features**: Exclusion patterns, negative globs (use simple include-only globs)
- ❌ **Performance Optimization**: Caching, indexing (future enhancement)
- ❌ **UI Changes**: No changes to display format or statistics

## Problem Analysis

### Root Cause

The configuration at `.ace/taskflow/config.yml` currently has:
```yaml
taskflow:
  directories:
    tasks: "tasks"
    ideas: "backlog/ideas"  # WRONG: This is a fallback path, not a folder name
```

This creates duplication because:
1. The config mixes folder names (`tasks: "tasks"`) with paths (`ideas: "backlog/ideas"`)
2. Code has to extract the last part: `ideas_dir_config.split("/").last → "ideas"`
3. Actual structure shows each release has its own `ideas/` folder at the same level
4. The path logic is duplicated in multiple places (idea_loader, task_manager, etc.)

### Current Issues

1. **Config Duplication**: Path construction logic duplicated across loaders
2. **Hardcoded Mappings**: PRESET_TO_SCOPE in IdeasCommand/TasksCommand
3. **Type-Specific Presets**: Can't create universal presets for both ideas and tasks
4. **Non-Extensible**: Adding new scopes requires code changes

### Solution Benefits

1. **No Duplication**: Config defines folder names once
2. **Self-Defining**: Presets declare what they include via globs
3. **Universal**: Same globs work for backlog + all releases
4. **Extensible**: Users can create custom subdirs + presets without code changes

## Implementation Plan

### Planning Steps

* [ ] **Research Current Implementation**
  - Review idea_loader.rb determine_idea_directory method (lines 180-214)
  - Review task_manager.rb for similar path construction logic
  - Document all places where `ideas_dir_config.split("/").last` is used
  - Analyze PRESET_TO_SCOPE mapping in ideas_command.rb and tasks_command.rb

* [ ] **Design Glob Resolution Strategy**
  - Decision: Should globs be resolved from context root or from ideas/tasks subdir?
  - Recommended: Resolve from context root (backlog/, v.0.9.0/) for consistency
  - Pattern: `Dir.glob(File.join(context_root, glob_pattern))`
  - Example: `context_root = "/path/to/v.0.9.0"`, `glob = "ideas/maybe/**/*.md"`
  - Result: Matches `/path/to/v.0.9.0/ideas/maybe/**/*.md`

* [ ] **Plan Backward Compatibility**
  - Existing presets without glob patterns should still work
  - Fall back to old scope-based loading if no glob present
  - Document migration path for users with custom configs

* [ ] **Design Preset Type Handling**
  - Decision: Keep `type:` field as optional metadata or remove?
  - Recommended: Make `type:` optional, determine from glob patterns
  - If glob includes "ideas/**" → ideas type
  - If glob includes "tasks/**" → tasks type
  - If both → universal type

### Execution Steps

#### Phase 1: Fix Main Configuration

- [ ] Update `.ace/taskflow/config.yml`
  - Change `ideas: "backlog/ideas"` to `ideas: "ideas"`
  - Add comment: `# Folder names (NOT paths) - used in each release context`
  - Verify `tasks: "tasks"` is already correct
  - Keep `backlog: "backlog"` as is

- [ ] Test config change doesn't break existing functionality
  - Run `ace-taskflow ideas` to verify ideas still load
  - Run `ace-taskflow tasks` to verify tasks still load
  - Check both backlog and current release contexts

#### Phase 2: Add Glob Support to Preset Loading

- [ ] Update `list_preset_manager.rb`
  - Add `glob` field loading from preset YAML
  - Support both single string and array of strings: `glob: "ideas/**/*.md"` or `glob: ["ideas/**/*.md", "tasks/**/*.md"]`
  - Pass glob patterns to loaders when present
  - Fall back to old behavior if no glob field

- [ ] Add tests for glob loading
  - Test single glob pattern loading
  - Test multiple glob patterns (array)
  - Test preset without glob (backward compatibility)
  - Test invalid glob patterns (error handling)

#### Phase 3: Implement Glob Support in IdeaLoader

- [ ] Update `idea_loader.rb` load_all method
  - Add `glob` parameter (default: nil)
  - When glob present: Use `Dir.glob(File.join(base_dir, pattern))`
  - Base dir should be context root (backlog/ or v.0.9.0/)
  - Support multiple glob patterns (union results)
  - Maintain existing behavior when glob is nil

- [ ] Refactor `determine_idea_directory` → `determine_context_root`
  - Rename method to reflect it returns context root, not ideas dir
  - Remove `ideas_dirname` extraction and joining
  - Return just the context root: backlog/, v.0.9.0/, etc.
  - Update all callers to join with folder names as needed

- [ ] Update `load_ideas_from_directory` for glob results
  - Handle glob results that may include both flat files and directories
  - Detect directory-based ideas (directories with idea.md inside)
  - Load both formats correctly
  - Skip SCOPE_SUBDIRECTORIES when scanning (already done)

- [ ] Add tests for glob-based loading
  - Test glob matching ideas in maybe/ subdirectory
  - Test glob matching both ideas and tasks
  - Test glob with multiple patterns
  - Test glob matching directory-based ideas
  - Test empty glob results

#### Phase 4: Implement Glob Support in TaskManager

- [ ] Update `task_manager.rb` with same pattern as IdeaLoader
  - Add `glob` parameter to task loading methods
  - Implement context root resolution
  - Support glob pattern evaluation
  - Maintain backward compatibility

- [ ] Add tests for task glob loading
  - Test glob matching tasks in maybe/ subdirectory
  - Test glob matching both ideas and tasks
  - Test glob with task.*.md pattern
  - Test empty glob results

#### Phase 5: Remove Hardcoded Mappings from Commands

- [ ] Update `ideas_command.rb`
  - Remove PRESET_TO_SCOPE constant
  - Pass glob from preset config to idea_loader
  - Remove scope determination logic (let globs define scope)
  - Keep context resolution (current, backlog, v.X.Y.Z)

- [ ] Update `tasks_command.rb`
  - Remove PRESET_TO_SCOPE constant (if exists)
  - Pass glob from preset to task_manager
  - Remove scope determination logic
  - Keep context resolution

- [ ] Add tests for commands with glob presets
  - Test `ace-taskflow ideas maybe` uses glob from preset
  - Test `ace-taskflow tasks done` uses glob from preset
  - Test fallback to old behavior for presets without globs

#### Phase 6: Update All Presets with Glob Patterns

- [ ] Update `.ace/taskflow/presets/maybe.yml`
  ```yaml
  filters:
    glob:
      - "ideas/maybe/**/*.md"
      - "tasks/maybe/**/task.*.md"
  ```

- [ ] Update `.ace/taskflow/presets/anyday.yml`
  ```yaml
  filters:
    glob:
      - "ideas/anyday/**/*.md"
      - "tasks/anyday/**/task.*.md"
  ```

- [ ] Update `.ace/taskflow/presets/done.yml`
  ```yaml
  filters:
    glob:
      - "ideas/done/**/*.md"
      - "tasks/done/**/task.*.md"
  ```

- [ ] Update `.ace/taskflow/presets/all.yml`
  ```yaml
  filters:
    glob:
      - "ideas/**/*.md"
      - "tasks/**/task.*.md"
  ```

- [ ] Update `.ace/taskflow/presets/pending.yml` (or `next.yml`)
  ```yaml
  filters:
    glob:
      - "ideas/*.md"              # Only top-level ideas (exclude subdirs)
      - "tasks/**/task.*.md"      # All tasks not in subdirs
  ```

- [ ] Update example configs in `ace-taskflow/.ace.example/taskflow/presets/`
  - Update maybe.yml example
  - Update anyday.yml example
  - Update other preset examples

#### Phase 7: Integration Testing

- [ ] Test full workflow with glob-based presets
  - Create ideas in maybe/ subdirectory
  - List with `ace-taskflow ideas maybe`
  - Verify correct ideas shown from current release
  - Switch context to backlog and verify

- [ ] Test backward compatibility
  - Run commands with old presets (no glob)
  - Verify they still work with fallback logic
  - Test mixed environment (some presets with glob, some without)

- [ ] Run full test suite
  - `bundle exec rake test` in ace-taskflow package
  - Verify all existing tests pass
  - Check new tests for glob functionality

### Risk Analysis and Rollback

**Technical Risks:**
- Breaking existing user configs that depend on `ideas: "backlog/ideas"`
- Glob patterns not matching expected files
- Performance issues with complex glob patterns

**Mitigation:**
- Document migration path clearly in CHANGELOG
- Add validation for glob patterns
- Keep fallback logic for presets without globs
- Comprehensive testing before release

**Rollback Strategy:**
- Config change is isolated and reversible
- Can revert to old PRESET_TO_SCOPE mapping if needed
- Glob support can be made optional feature flag

## References

- Parent task: v.0.9.0+task.088 (Maybe and Anyday Scope Support)
- Related discussion: Configuration duplication and hardcoded preset mappings
- Code locations:
  - Config: `.ace/taskflow/config.yml`
  - IdeaLoader: `ace-taskflow/lib/ace/taskflow/molecules/idea_loader.rb:180-214`
  - IdeasCommand: `ace-taskflow/lib/ace/taskflow/commands/ideas_command.rb` (PRESET_TO_SCOPE)
  - TaskManager: `ace-taskflow/lib/ace/taskflow/molecules/task_manager.rb`
  - ListPresetManager: `ace-taskflow/lib/ace/taskflow/molecules/list_preset_manager.rb`
  - Presets: `.ace/taskflow/presets/*.yml`
