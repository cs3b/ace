---
id: v.0.9.0+task.057
status: draft
priority: high
estimate: 4-6 hours
dependencies: []
---

# Fix ace-taskflow Project Root Detection

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow` commands from any subdirectory within an ACE project
- **Process**: Tool automatically discovers project root using `ace-core` and locates `.ace-taskflow/` directory at project root
- **Output**: Commands execute successfully regardless of current working directory

### Expected Behavior

Currently, `ace-taskflow` only works when invoked from the project root directory. When run from a subdirectory, it incorrectly looks for `.ace-taskflow/` in the current directory instead of the project root, resulting in "No tasks found" errors.

This task will fix the root detection by:
1. Using `Ace::Core::ConfigDiscovery.project_root` to reliably locate the project root
2. Joining the configured taskflow root directory name (`.ace-taskflow`) with the discovered project root
3. Restructuring the configuration to be clearer about directory relationships

### Interface Contract

```bash
# Should work from project root
cd /Users/mc/Ps/ace-meta
ace-taskflow tasks           # ✓ Lists tasks

# Should work from subdirectory (currently fails)
cd /Users/mc/Ps/ace-meta/ace-git-commit
ace-taskflow tasks           # ✓ Should list SAME tasks

# Should work from nested subdirectory (currently fails)
cd /Users/mc/Ps/ace-meta/ace-taskflow/lib/ace
ace-taskflow tasks           # ✓ Should list SAME tasks
```

**Error Handling:**
- Not in ACE project: `Error: Not in an ACE project (no .git or .ace found)`
- No .ace-taskflow found at project root: `Error: Taskflow not initialized at {project_root}. Run: ace-taskflow init`

**Edge Cases:**
- Running from outside project: Clear error message
- .ace-taskflow exists but is empty: Normal behavior
- Multiple nested git repositories: Uses nearest project root

### Success Criteria

- [ ] **Root Detection**: `ace-taskflow` commands work from any subdirectory within project
- [ ] **ace-core Integration**: Tool uses `Ace::Core::ConfigDiscovery.project_root` for detection
- [ ] **Config Restructuring**: Configuration clearly separates taskflow root from subdirectories
- [ ] **Backward Compatibility**: Old configuration format still works during transition
- [ ] **Clear Error Messages**: Helpful errors when not in project or taskflow not found
- [ ] **Test Coverage**: Tests verify behavior from subdirectories
- [ ] **All Organisms Updated**: TaskManager, ReleaseManager, IdeaScheduler etc. all get correct root path

### Validation Questions

- [ ] **Requirement Clarity**: Should we support running from outside project with explicit --root flag?
- [ ] **Edge Case Handling**: What if user has multiple .ace-taskflow directories in nested projects?
- [ ] **Migration Strategy**: Should we provide automatic migration from old to new config format?
- [ ] **Success Definition**: How do we validate this works across all ace-taskflow commands?

## Objective

Enable reliable `ace-taskflow` operation from any directory within an ACE project by implementing proper project root detection using `ace-core` infrastructure. This improves developer experience and aligns with ACE's design principle that tools should work from any location within the project.

## Scope of Work

- **User Experience Scope**: All `ace-taskflow` CLI commands must work identically regardless of current working directory
- **System Behavior Scope**: Project root detection, configuration loading, path resolution for all taskflow operations
- **Interface Scope**: All `ace-taskflow` commands (tasks, task, release, releases, idea, ideas)

### Deliverables

#### Behavioral Specifications
- Project root detection behavior using ace-core
- Error handling for edge cases (not in project, taskflow not found)
- Path resolution behavior from any directory level

#### Implementation Artifacts
- Updated `ConfigLoader.find_root` implementation
- Restructured configuration format with backward compatibility
- Comprehensive tests for subdirectory execution
- Updated documentation

#### Validation Artifacts
- Test suite covering subdirectory execution
- Integration tests for all organisms
- Error message validation

## Out of Scope

- ❌ **Multi-Project Support**: Supporting multiple .ace-taskflow directories in nested projects
- ❌ **Remote Taskflow**: Accessing taskflow from remote repositories
- ❌ **Migration Tooling**: Automatic migration tool for old configs (manual migration acceptable)
- ❌ **Performance Optimization**: Caching project root detection results

## Implementation Plan

### 1. Configuration Restructuring

**Current structure** (confusing):
```yaml
taskflow:
  directories:
    root: ".ace-taskflow"      # Misleading - this IS the root, not a subdirectory
```

**New structure** (clear):
```yaml
taskflow:
  root: ".ace-taskflow"         # The taskflow root directory name

  directories:                  # Top-level directories within taskflow root
    backlog: "backlog"
    done: "done"
    active_pattern: "v.%{version}"

  release:                      # Directories within each release
    tasks: "t"
    ideas: "ideas"
    docs: "docs"
    retro: "retro"
```

### 2. Core Implementation Changes

**A. ConfigLoader.find_root (ace-taskflow/lib/ace/taskflow/molecules/config_loader.rb)**

Current buggy implementation:
```ruby
def self.find_root
  config = load
  root = config["root"] || DEFAULT_CONFIG["root"]

  # BUG: Uses Dir.pwd instead of project root!
  File.join(Dir.pwd, root)  # ❌ Wrong!
end
```

Fixed implementation:
```ruby
def self.find_root
  # 1. Find project root using ace-core
  require 'ace/core/config_discovery'
  project_root = Ace::Core::ConfigDiscovery.project_root

  unless project_root
    raise "Not in an ACE project. No project root found from #{Dir.pwd}"
  end

  # 2. Get configured taskflow root directory name
  config = load
  root_dir = config["root"] || DEFAULT_CONFIG["root"]

  # 3. Build absolute path: project_root + taskflow_root
  taskflow_root = File.join(project_root, root_dir)

  # 4. Validate it exists
  unless Dir.exist?(taskflow_root)
    raise "Taskflow directory not found: #{taskflow_root}. Run 'ace-taskflow init' to create it."
  end

  taskflow_root
end
```

**B. Update extract_taskflow_config for backward compatibility**

```ruby
# Map both old and new configuration formats
config["root"] = if taskflow_section["root"]
  # New format: taskflow.root
  taskflow_section["root"]
elsif taskflow_section["directories"] && taskflow_section["directories"]["root"]
  # Old format: taskflow.directories.root (deprecated)
  taskflow_section["directories"]["root"]
else
  nil
end
```

### 3. Files to Modify

1. **ace-taskflow/ace-taskflow.gemspec** - Ensure ace-core dependency
2. **ace-taskflow/lib/ace/taskflow/molecules/config_loader.rb** - Fix find_root + config mapping
3. **.ace/taskflow/config.yml** - Restructure to new format
4. **ace-taskflow/test/molecules/config_loader_test.rb** - Add subdirectory tests

### 4. Testing Strategy

**Unit Tests:**
- ConfigLoader.find_root from subdirectories
- Config extraction for both old and new formats
- Error handling when not in project

**Integration Tests:**
- Run `ace-taskflow tasks` from project root
- Run `ace-taskflow tasks` from subdirectories
- Run from nested subdirectories
- Verify all organisms get correct root path

### 5. Rollout Plan

1. Add ace-core dependency to gemspec
2. Update ConfigLoader with new find_root implementation
3. Update config extraction for backward compatibility
4. Restructure .ace/taskflow/config.yml
5. Add comprehensive tests
6. Test all commands from various directories
7. Update documentation

## References

- Source idea file: `.ace-taskflow/v.0.9.0/docs/ideas/057-20251001-182923-fix-taskflow-root-detection.md`
- ace-core ConfigDiscovery API: `ace-core/lib/ace/core/config_discovery.rb`
- Current ConfigLoader: `ace-taskflow/lib/ace/taskflow/molecules/config_loader.rb:73-85`
- ACE architecture principles: `docs/architecture.md`
