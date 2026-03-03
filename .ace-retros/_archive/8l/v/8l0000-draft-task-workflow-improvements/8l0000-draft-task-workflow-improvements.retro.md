---
id: 8l0000
title: Draft Task Workflow and ace-taskflow Root Detection Fix
type: conversation-analysis
tags: []
created_at: '2025-10-01 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8l0000-draft-task-workflow-improvements.md"
---

# Reflection: Draft Task Workflow and ace-taskflow Root Detection Fix

**Date**: 2025-10-01
**Context**: Attempted to execute draft-task workflow for taskflow root detection fix, discovered multiple system issues with task creation and ID assignment
**Author**: Claude Code (AI Agent)
**Type**: Conversation Analysis

## What Went Well

- Successfully identified and fixed critical bug in `ConfigLoader.find_root` that prevented ace-taskflow from working in subdirectories
- Discovered and fixed task ID assignment bug where IDs were being assigned based on filesystem scanning instead of global task list
- Configuration restructuring (moving `taskflow.directories.root` → `taskflow.root`) improves clarity
- Backward compatibility maintained for old configuration format during transition
- Both fixes were tested and verified to work correctly from various subdirectories

## What Could Be Improved

- Draft task workflow failed to properly execute - created wrong task ID (057 instead of expected 059)
- Idea file was manually moved with `git mv` instead of using `ace-taskflow idea done <ref>` command
- Discovered malformed tasks (057, 058) in done/ directory with broken YAML frontmatter
- Task creation process doesn't validate YAML frontmatter completeness
- Multiple test artifacts and untracked files accumulated during development session

## Key Learnings

- **Critical Bug**: `generate_task_number` was scanning only current release's filesystem instead of using `@task_loader.load_all_tasks`, causing ID reuse
- **Root Detection Issue**: `ConfigLoader.find_root` was joining configured root with `Dir.pwd` instead of project root from `Ace::Core::ConfigDiscovery`
- **Workflow Adherence**: Manual file operations bypass ace-taskflow's lifecycle management (idea tracking, status updates, statistics)
- **Task ID Assignment**: Filesystem-based scanning only sees what's in current context, not the global task list across all releases
- **YAML Validation**: Tasks with incomplete frontmatter (missing closing `---`) fail to parse but don't prevent file creation

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Task ID Assignment Logic**: Filesystem-based vs List-based Discovery
  - Occurrences: 1 (but affected all task creation attempts)
  - Impact: Created task with ID 057 when it should have been 059, causing ID conflicts
  - Root Cause: `generate_task_number` scanned only current release's `t/` and `done/` directories instead of loading all tasks globally
  - **Fix Applied**: Changed to use `@task_loader.load_all_tasks` and extract numbers from task IDs across entire project

- **Project Root Detection Failure**: ace-taskflow not working from subdirectories
  - Occurrences: Affected all subdirectory usage (discovered during testing)
  - Impact: "No tasks found" errors when running from subdirectories, forcing users to cd to project root
  - Root Cause: `ConfigLoader.find_root` used `Dir.pwd` instead of `Ace::Core::ConfigDiscovery.project_root`
  - **Fix Applied**: Updated to use ace-core's project root discovery mechanism

#### Medium Impact Issues

- **Workflow Execution Deviation**: Manual file operations instead of ace-taskflow commands
  - Occurrences: 1 (idea file movement)
  - Impact: Bypassed idea lifecycle management, lost tracking metadata
  - Root Cause: Lack of understanding of proper `ace-taskflow idea done` command usage
  - **Lesson**: Always use ace-taskflow commands for idea/task management to maintain system integrity

- **Malformed Task Files**: Tasks with incomplete YAML frontmatter
  - Occurrences: 2 tasks (057, 058 in done/ directory)
  - Impact: Tasks couldn't be parsed by TaskLoader, excluded from task list, confused ID assignment
  - Root Cause: Tasks created during testing with incomplete frontmatter (missing closing `---`)
  - **Cleanup**: Files removed in cleanup commit

#### Low Impact Issues

- **Test Artifacts Accumulation**: Untracked files and modified test files
  - Occurrences: 7 untracked files, 16 modified test files
  - Impact: Cluttered git status, requires cleanup
  - Root Cause: Development session involved refactoring that extracted new molecules from TaskManager

### Improvement Proposals

#### Process Improvements

- **Draft Task Workflow Enhancement**: Add validation step to verify task was created with correct ID before proceeding
- **Idea File Movement**: Update draft-task workflow to explicitly use `ace-taskflow idea done <ref>` instead of manual `git mv`
- **Task Creation Validation**: Add YAML frontmatter completeness check (verify closing `---` exists)
- **Pre-commit Hook**: Add validation to prevent committing tasks with malformed frontmatter

#### Tool Enhancements

- **ace-taskflow task create**: Add `--verify` flag to check created task ID matches expected next ID
- **ace-taskflow idea done**: Enhance command to support moving idea files to current release with task number prefix
- **TaskLoader**: Add frontmatter validation that warns/errors on incomplete YAML structure
- **generate_task_number**: Consider caching global max to avoid repeated full task list loads

#### Communication Protocols

- **Task Creation Confirmation**: Workflow should verify created task ID and alert if unexpected
- **Command Usage Guidance**: Draft-task workflow should explicitly specify which ace-taskflow commands to use
- **Error Detection**: Early detection when task ID doesn't match expected value

### Token Limit & Truncation Issues

- **Large Output Instances**: None encountered in this session
- **Truncation Impact**: N/A
- **Mitigation Applied**: N/A
- **Prevention Strategy**: N/A

## Action Items

### Stop Doing

- Using manual file operations (`git mv`) instead of ace-taskflow commands
- Creating tasks without verifying the assigned ID matches expectations
- Allowing malformed YAML frontmatter in task files

### Continue Doing

- Testing fixes from multiple subdirectories to verify they work everywhere
- Maintaining backward compatibility when restructuring configuration
- Cleaning up test artifacts before committing
- Using ace-core's project root discovery for consistent behavior

### Start Doing

- Validate task IDs immediately after creation in workflows
- Use `ace-taskflow idea done <ref>` for proper idea lifecycle management
- Add YAML frontmatter validation to task creation process
- Consider pre-commit hooks for task file validation

## Technical Details

### Fix 1: ConfigLoader.find_root

**Before:**
```ruby
def self.find_root
  config = load
  root = config["root"] || DEFAULT_CONFIG["root"]
  File.join(Dir.pwd, root)  # ❌ Uses current directory
end
```

**After:**
```ruby
def self.find_root
  require "ace/core/config_discovery"
  project_root = Ace::Core::ConfigDiscovery.project_root
  raise "Not in an ACE project" unless project_root

  config = load
  root_dir = config["root"] || DEFAULT_CONFIG["root"]
  taskflow_root = File.join(project_root, root_dir)  # ✅ Uses project root

  raise "Taskflow directory not found: #{taskflow_root}" unless Dir.exist?(taskflow_root)
  taskflow_root
end
```

### Fix 2: generate_task_number

**Before:**
```ruby
def generate_task_number(context_path)
  task_dirs = [
    File.join(context_path, "t"),
    File.join(context_path, "done")
  ]
  # Only scans current context filesystem
  existing = []
  task_dirs.each do |task_dir|
    existing += Dir.glob(File.join(task_dir, "*")).map { ... }
  end
  # ❌ Returns local max + 1
end
```

**After:**
```ruby
def generate_task_number(context_path)
  # Load ALL tasks from ALL releases
  all_tasks = @task_loader.load_all_tasks

  # Extract task numbers from all tasks
  existing_numbers = all_tasks.map do |task|
    task[:task_number]&.to_i || extract_number_from_id(task[:id])
  end.compact

  # ✅ Returns global max + 1
  return "001" if existing_numbers.empty?
  next_number = existing_numbers.max + 1
  next_number.to_s.rjust(3, '0')
end

def extract_number_from_id(id)
  return nil unless id
  match = id.match(/task\.(\d+)/)
  match ? match[1].to_i : nil
end
```

### Configuration Restructuring

**Old Format (deprecated but supported):**
```yaml
taskflow:
  directories:
    root: ".ace-taskflow"  # Confusing - this IS the root
```

**New Format (preferred):**
```yaml
taskflow:
  root: ".ace-taskflow"  # Clear - the taskflow root directory name
  directories:
    # Top-level directories within taskflow root
```

## Additional Context

**Commits Created:**
1. `29f55001` - Draft task 057: Fix ace-taskflow project root detection
2. `92f02396` - Fix ace-taskflow task ID assignment to use global maximum
3. `33278be2` - Remove malformed and incorrect test tasks

**Files Modified:**
- `ace-taskflow/lib/ace/taskflow/molecules/config_loader.rb` - Root detection fix
- `ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb` - ID assignment fix
- `.ace/taskflow/config.yml` - Configuration restructuring

**Tasks Created:**
- v.0.9.0+057 (incorrect - should have been 059, but was wrong task anyway)

**Outstanding Work:**
- Properly create draft task for taskflow root detection fix
- Commit new molecule files and their tests
- Review and clean up modified test files
- Add unit tests for subdirectory execution and global ID assignment