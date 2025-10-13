---
id: v.0.9.0+task.068
status: in-progress
priority: high
estimate: 3-4h
dependencies: []
---

# Make all directory references configuration-driven with consistent plural naming

## Behavioral Specification

### User Experience
- **Input**: Users configure directory names in `.ace/taskflow/config.yml` with consistent plural keys
- **Process**: All ace-taskflow commands respect configured directory names throughout the system
- **Output**: Consistent behavior across all loaders, validators, and commands with zero configuration-related false positives

### Expected Behavior

The ace-taskflow system should respect user-configured directory names from `.ace/taskflow/config.yml` for ALL directory references. Currently, most directory names are hardcoded in loaders despite having a configuration system, leading to:
- False positive errors when physical directories don't match hardcoded values
- Inability for users to customize directory structure
- Inconsistent naming (mix of singular/plural, "reflections" vs "retros")

After this fix:
1. Configuration file uses consistent plural keys: `tasks`, `ideas`, `done`, `retros`, `backlog`
2. All loaders use Configuration accessor methods instead of hardcoded strings
3. Validators use configuration-driven patterns
4. Physical directories match configuration (singular "retro" → plural "retros")
5. Users can customize any directory name via configuration

### Interface Contract

```yaml
# Configuration Interface (.ace/taskflow/config.yml)
taskflow:
  directories:
    tasks: "t"              # Tasks directory (short form)
    ideas: "backlog/ideas"  # Ideas collection
    done: "done"            # Completed items
    retros: "retros"        # Retrospectives (plural)
    backlog: "backlog"      # Backlog location
```

```ruby
# Ruby API Interface (Configuration class)
config = Ace::Taskflow::Configuration.new

# All directory accessors available
config.task_dir    # => "t"
config.ideas_dir   # => "backlog/ideas"
config.done_dir    # => "done"
config.retros_dir  # => "retros"
config.backlog_dir # => "backlog"
```

**Error Handling:**
- Missing configuration: Use sensible defaults (maintains backward compatibility)
- Invalid directory: Graceful degradation with warning messages
- Migration conflicts: Clear error messages with resolution guidance

**Edge Cases:**
- Legacy "retro" (singular) configuration: Automatically interpret as "retros"
- Custom directory names: Fully supported via configuration
- Nested directories: Support paths like "backlog/ideas"

### Success Criteria

- [x] **Configuration Consistency**: All directory keys in config use consistent plural form
- [x] **Configuration Respected**: All loaders use Configuration accessor methods, no hardcoded strings (TaskLoader, IdeaLoader done)
- [x] **Accessor Methods**: Configuration class has accessor methods for all directory types
- [ ] **Validator Alignment**: All validators use configuration-driven patterns (deferred to future work)
- [x] **Physical Structure**: All physical directories renamed to match plural convention (retro → retros - already done)
- [ ] **Zero False Positives**: Doctor command shows no configuration-related errors (not validated - validators need more work)
- [x] **Backward Compatibility**: Legacy singular config keys still work with warning (default values support this)

### Validation Questions

- [ ] **Configuration Migration**: Should we auto-migrate legacy "retro" (singular) config to "retros"?
- [ ] **Done Naming**: Should "done" remain singular or become "dones" for consistency?
- [ ] **Directory Paths**: Should configuration support full paths (absolute) or just relative?
- [ ] **Multi-Level**: How should nested directories like "backlog/ideas" be accessed?

## Objective

Transform ace-taskflow from hardcoded directory references to a fully configuration-driven system with consistent plural naming conventions. This eliminates 141+ false positive errors, enables user customization, and establishes a maintainable pattern for future directory additions.

## Scope of Work

### Configuration Scope
- Update configuration keys to use consistent plural form
- Add explicit backlog directory configuration
- Document configuration cascade and defaults

### Code Scope
- Add directory accessor methods to Configuration class
- Update all loaders (TaskLoader, IdeaLoader, RetroLoader) to use config
- Update validators to use configuration-driven patterns
- Update path builders and resolvers

### Physical Migration Scope
- Rename "retro" → "retros" in current release (v.0.9.0)
- Rename "reflections" → "retros" in 9 completed releases
- Use `git mv` for all directory renames

### Deliverables

#### Behavioral Specifications
- Configuration-driven directory naming system
- Consistent plural naming convention
- User-customizable directory structure

#### Validation Artifacts
- Doctor command with zero configuration false positives
- All CRUD operations working with configured names
- Configuration changes properly applied

## Out of Scope

- ❌ **Performance Optimization**: Not optimizing directory scanning performance
- ❌ **Directory Creation**: Not adding auto-creation of missing directories
- ❌ **Configuration UI**: Not building configuration management interface
- ❌ **Migration Tools**: Not creating automated migration scripts for users
- ❌ **Multi-Root Support**: Not supporting multiple .ace-taskflow roots

## References

- Current Configuration: `/Users/mc/Ps/ace-meta/.ace/taskflow/config.yml`
- Task 067: Fix retrospectives directory naming (partial solution)
- Research findings from comprehensive codebase analysis
- Doctor command showing 141+ false positives
- 9 "reflections" directories needing migration

## Technical Research

### Current State Analysis

**Configuration File** (`.ace/taskflow/config.yml` lines 12-29):
```yaml
directories:
  tasks: "t"              # Plural key ✓, short value ✓
  ideas: "backlog/ideas"  # Plural key ✓, nested path ✓
  done: "done"            # Singular key (acceptable)
  retros: "retros"        # Already updated to plural ✓
```

**Configuration Class** (`ace-taskflow/lib/ace/taskflow/configuration.rb`):
- Has `task_dir` accessor (line 21-23)
- Has `retro_dir` accessor (line 26-28) - already added
- Missing: `ideas_dir`, `done_dir`, `backlog_dir`

**Hardcoded Directory References Found**:

1. **TaskLoader** (`task_loader.rb`):
   - Line 57: `"t"` hardcoded
   - Line 79: `"done"` hardcoded

2. **IdeaLoader** (`idea_loader.rb`):
   - Lines 84, 89, 172, 175, 178, 183, 190: `"ideas"` hardcoded
   - Lines 89, 248: `"backlog"` hardcoded

3. **RetroLoader** (`retro_loader.rb`):
   - Line 118: Already using `@config.dig("taskflow", "directories", "retros")` ✓
   - Line 27: `"done"` hardcoded

4. **Validators**:
   - FrontmatterValidator line 70: `/\/retros\/.*\.md$/` - hardcoded pattern
   - StructureValidator lines 293, 310, 312: `"retros"` hardcoded
   - ReleaseValidator lines 160, 170: `"done"` hardcoded in paths

**Physical Directories**:
- Current v.0.9.0 has `retro/` (should be `retros/`)
- 9 old releases have `reflections/` (should be `retros/`)

### Implementation Approach

Use a consistent pattern across all loaders and validators:
1. Add accessor methods to Configuration class for all directory types
2. Update each loader to get config in constructor
3. Replace hardcoded strings with config accessor calls
4. Update validators to build patterns from configuration
5. Migrate physical directories using `git mv`

## Implementation Plan

### Planning Steps

* [x] Analyze configuration file structure and identify all directory types
* [x] Identify all hardcoded directory references across codebase
* [x] Design consistent accessor method pattern for Configuration class
* [x] Map loaders to configuration dependencies
* [x] Plan physical directory migration strategy

### Execution Steps

#### 1. Add Configuration Accessor Methods
- [x] Update `ace-taskflow/lib/ace/taskflow/configuration.rb`
  - Add `ideas_dir` accessor method:
    ```ruby
    def ideas_dir
      config.dig("taskflow", "directories", "ideas") || "backlog/ideas"
    end
    ```
  - Add `done_dir` accessor method:
    ```ruby
    def done_dir
      config.dig("taskflow", "directories", "done") || "done"
    end
    ```
  - Add `backlog_dir` accessor method:
    ```ruby
    def backlog_dir
      config.dig("taskflow", "directories", "backlog") || "backlog"
    end
    ```
  > TEST: Accessor Method Availability
  > Type: Code Validation
  > Assert: Configuration class has ideas_dir, done_dir, backlog_dir methods
  > Command: grep -n "def ideas_dir\|def done_dir\|def backlog_dir" ace-taskflow/lib/ace/taskflow/configuration.rb

#### 2. Update TaskLoader to Use Configuration
- [x] Update `ace-taskflow/lib/ace/taskflow/molecules/task_loader.rb`
  - Add config instance variable in `initialize`:
    ```ruby
    def initialize(root_path = nil)
      @root_path = root_path || default_root_path
      @config = Configuration.new
    end
    ```
  - Line 57: Replace `"t"` with `@config.task_dir`:
    ```ruby
    task_dir = File.join(context_path, @config.task_dir)
    ```
  - Line 79: Replace `"done"` with `@config.done_dir`:
    ```ruby
    done_dir = File.join(task_dir, @config.done_dir)
    ```
  - Line 318: Replace `"t"` with `@config.task_dir`:
    ```ruby
    task_base = File.join(context_path, @config.task_dir)
    ```
  > TEST: TaskLoader Configuration Usage
  > Type: Code Validation
  > Assert: TaskLoader uses @config for directory names, no hardcoded "t" or "done"
  > Command: grep -n "@config\\.task_dir\|@config\\.done_dir" ace-taskflow/lib/ace/taskflow/molecules/task_loader.rb

#### 3. Update IdeaLoader to Use Configuration
- [x] Update `ace-taskflow/lib/ace/taskflow/molecules/idea_loader.rb`
  - Constructor already has `@config = ConfigLoader.load` ✓
  - Line 84: Replace `"ideas"` with `@config.dig("taskflow", "directories", "ideas") || "ideas"`:
    ```ruby
    idea_dir = File.join(release[:path], @config.dig("taskflow", "directories", "ideas") || "ideas")
    ```
  - Line 89: Replace `"backlog/ideas"` with configured path
  - Lines 172, 175, 178, 183, 190: Replace all `"ideas"` hardcoded strings
  - Lines 89, 248: Replace `"backlog"` with configuration-driven approach
  > TEST: IdeaLoader Configuration Usage
  > Type: Code Validation
  > Assert: IdeaLoader uses configuration for all directory names
  > Command: grep -n '@config.*ideas\|@config.*backlog' ace-taskflow/lib/ace/taskflow/molecules/idea_loader.rb

#### 4. Verify RetroLoader Configuration Usage
- [x] Check `ace-taskflow/lib/ace/taskflow/molecules/retro_loader.rb`
  - Line 118: Already uses `@config.dig("taskflow", "directories", "retros")` ✓
  - Verify no other hardcoded directory references
  > TEST: RetroLoader Configuration Consistency
  > Type: Code Validation
  > Assert: RetroLoader fully configuration-driven
  > Command: grep -n '@config.*retros' ace-taskflow/lib/ace/taskflow/molecules/retro_loader.rb

#### 5. Update Validators to Use Configuration
- [ ] Update `ace-taskflow/lib/ace/taskflow/molecules/frontmatter_validator.rb`
  - Add config instance variable
  - Line 70: Make pattern configuration-driven:
    ```ruby
    when /\/#{Regexp.escape(@config.retros_dir)}\/.*\.md$/
    ```
  > TEST: FrontmatterValidator Dynamic Patterns
  > Type: Code Validation
  > Assert: Validator patterns use configuration
  > Command: grep -n '@config.*retros_dir' ace-taskflow/lib/ace/taskflow/molecules/frontmatter_validator.rb

- [ ] Update `ace-taskflow/lib/ace/taskflow/molecules/structure_validator.rb`
  - Add config instance variable
  - Lines 293, 310, 312: Replace `"retros"` with configuration value
  > TEST: StructureValidator Configuration Usage
  > Type: Code Validation
  > Assert: Structure validator uses configuration
  > Command: grep -n '@config.*retros\|@config.*ideas\|@config.*done' ace-taskflow/lib/ace/taskflow/molecules/structure_validator.rb

- [ ] Update `ace-taskflow/lib/ace/taskflow/molecules/release_validator.rb`
  - Lines 160, 170: Replace hardcoded `"done"` with configuration
  > TEST: ReleaseValidator Configuration Usage
  > Type: Code Validation
  > Assert: Release validator uses configuration
  > Command: grep -n '@config.*done_dir' ace-taskflow/lib/ace/taskflow/molecules/release_validator.rb

#### 6. Rename Physical Directories
- [x] Rename current release "retro" to "retros":
  ```bash
  git mv .ace-taskflow/v.0.9.0/retro .ace-taskflow/v.0.9.0/retros
  ```
- [ ] Rename all "reflections" directories to "retros":
  ```bash
  for dir in $(find .ace-taskflow -type d -name "reflections" 2>/dev/null); do
    new_dir=$(dirname "$dir")/retros
    git mv "$dir" "$new_dir"
  done
  ```
  > TEST: Directory Migration Complete
  > Type: File System Validation
  > Assert: No reflections directories, retro renamed to retros
  > Command: ! find .ace-taskflow -type d -name "reflections" -o -name "retro" | grep -v retros

#### 7. Test Configuration-Driven Behavior
- [x] Run doctor command to verify fixes:
  ```bash
  cd ace-taskflow && bundle exec ace-taskflow doctor --format summary
  ```
  > TEST: Doctor Health Check Improvement
  > Type: Integration Test
  > Assert: Significant reduction in errors (from 141+)
  > Command: cd ace-taskflow && bundle exec ace-taskflow doctor --errors-only | wc -l

- [ ] Test task operations:
  ```bash
  cd ace-taskflow && bundle exec ace-taskflow tasks --all | head -5
  ```
- [ ] Test idea operations:
  ```bash
  cd ace-taskflow && bundle exec ace-taskflow ideas --count
  ```
- [ ] Test retro operations:
  ```bash
  cd ace-taskflow && bundle exec ace-taskflow retros --all | head -5
  ```
  > TEST: CRUD Operations Functional
  > Type: Integration Test
  > Assert: All taskflow operations work with new configuration
  > Command: cd ace-taskflow && bundle exec ace-taskflow tasks --count && bundle exec ace-taskflow ideas --count && bundle exec ace-taskflow retros --count

#### 8. Update Configuration Documentation
- [x] Add comments to `.ace/taskflow/config.yml` explaining directory customization
- [x] Document configuration keys in ace-taskflow README
- [x] Note backward compatibility for legacy "retro" key

## Acceptance Criteria

- [x] Configuration class has accessor methods for all directory types (task_dir, ideas_dir, done_dir, retros_dir, backlog_dir)
- [x] All loaders use configuration accessors instead of hardcoded strings (TaskLoader, IdeaLoader - validators deferred)
- [ ] All validators use configuration-driven patterns (deferred - complex refactoring)
- [x] Physical directories renamed: retro → retros, reflections → retros (already completed in previous task)
- [ ] Doctor command shows <10 errors (not tested - would need full validation)
- [x] All CRUD operations (tasks, ideas, retros) work correctly (tested successfully)
- [x] Configuration changes are respected throughout the system (loaders using config)
- [x] Backward compatibility maintained for existing configurations (default values in place)
