# Retro: Configuration-Driven Directory Paths Implementation

**Date**: 2025-10-13
**Context**: Fixed hardcoded directory references throughout ace-taskflow, eliminated "t/" hardcoding
**Author**: Claude Code + User
**Type**: Conversation Analysis

## What Went Well

- **Systematic approach**: Comprehensive search identified all 10 files needing updates
- **Clean commit history**: Single atomic commit captured all related changes
- **Immediate validation**: Task 070 moved to correct location and verified working
- **Configuration already existed**: `task_dir` getter was already implemented correctly
- **Plan-first approach**: Clear plan approved before execution minimized rework
- **Testing validated**: `ace-taskflow doctor` confirmed all changes work correctly

## What Could Be Improved

- **Root cause discovery timing**: Discovered task.070 in wrong directory only after investigating why it was created there
- **Pattern recognition**: Should have anticipated that task creation uses same PathBuilder functions
- **Proactive search**: Could have searched for hardcoded directories earlier in development cycle

## Key Learnings

- **Configuration cascade works well**: Reading from `.ace/taskflow/config.yml` with fallback defaults is reliable
- **PathBuilder is central**: Core path building affects all operations (create, move, validate, migrate)
- **Backward compatibility matters**: Supporting legacy `/t/` patterns in regex ensures smooth migration
- **Configuration in initialization**: Even `initialize_structure!` needs to use configured directory names
- **Test fixtures affected**: Many test files have hardcoded paths that will need updating separately

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Hardcoded directory names**: All core components had "t/" hardcoded instead of reading configuration
  - Occurrences: 10 files across atoms, molecules, organisms, and configuration
  - Impact: Tasks created in wrong directory despite configuration specifying "tasks/"
  - Root Cause: PathBuilder line 20 hardcoded "t" instead of using config.task_dir
  - Resolution: Added optional config parameter to PathBuilder methods, used throughout codebase

#### Medium Impact Issues

- **Initialization hardcoding**: Configuration initialization used hardcoded "backlog", "done", "t" directories
  - Occurrences: 1 file (configuration.rb lines 115-117)
  - Impact: New project initialization would ignore configured directory names
  - Root Cause: `initialize_structure!` created directories with hardcoded strings
  - Resolution: Create config object and use config.backlog_dir, config.task_dir, config.done_dir

- **Test directory patterns**: taskflow_doctor.rb used hardcoded glob patterns for scanning
  - Occurrences: 1 file, 2 glob patterns
  - Impact: Doctor command wouldn't find tasks in non-standard directories
  - Root Cause: Glob pattern used `"**/t/**/"` instead of configured directory name
  - Resolution: Read config, interpolate task_dir into glob patterns

#### Low Impact Issues

- **Empty directory cleanup**: After moving task.070, empty `t/` directory remained
  - Occurrences: Single directory
  - Impact: Minor - just an empty directory
  - Resolution: Removed with `rmdir`

### Improvement Proposals

#### Process Improvements

- **Configuration audit**: Add workflow step to verify all hardcoded paths before creating tasks
- **PathBuilder first**: When implementing directory features, always update PathBuilder first
- **Test suite validation**: Run full test suite after directory-related changes
- **Documentation update**: Update developer documentation to emphasize configuration usage

#### Tool Enhancements

- **ace-taskflow lint**: Create command to detect hardcoded directory references in codebase
- **Configuration validator**: Add validation that checks configured directories actually exist
- **Migration tool enhancement**: Update task migrator to handle both "t/" and "tasks/" directories

#### Communication Protocols

- **Earlier search**: When investigating wrong directory, search for all hardcoded references immediately
- **Plan confirmation**: Current "exit plan mode" approach works well - continue using
- **Progress tracking**: TodoWrite tool usage was effective for tracking 12 steps

### Token Limit & Truncation Issues

- **Large Output Instances**: 1 instance - grep search for "done" directories returned 50+ matches
- **Truncation Impact**: No information lost - output was sufficient to understand pattern
- **Mitigation Applied**: Used head_limit parameter to control grep output size
- **Prevention Strategy**: Always use output_mode and head_limit for exploratory searches

## Action Items

### Stop Doing

- **Assuming configuration is used**: Always verify by searching for hardcoded strings
- **Fixing only immediate issue**: Search comprehensively for related problems

### Continue Doing

- **Plan-first approach**: Exit plan mode workflow prevented premature execution
- **Systematic search**: Using grep to find all instances before fixing ensured completeness
- **TodoWrite tracking**: Clear todo list kept 12-step process organized
- **Testing after changes**: Running `ace-taskflow doctor` validated all changes

### Start Doing

- **Proactive linting**: Create automated check for hardcoded directory references
- **Test fixture updates**: Schedule task to update test files with hardcoded paths
- **Configuration documentation**: Document which settings affect which components
- **Pattern library**: Document common "configuration-driven" patterns for future reference

## Technical Details

### Files Modified (10)

1. `lib/ace/taskflow/atoms/path_builder.rb` - Added config parameter to 3 methods
2. `lib/ace/taskflow/organisms/task_manager.rb` - Line 471: task_id_exists?
3. `lib/ace/taskflow/organisms/task_migrator.rb` - Lines 45, 89, 100
4. `lib/ace/taskflow/molecules/release_resolver.rb` - Line 112: get_statistics
5. `lib/ace/taskflow/molecules/structure_validator.rb` - Lines 67, 70, 155
6. `lib/ace/taskflow/molecules/release_validator.rb` - Line 161: task_done_dir
7. `lib/ace/taskflow/organisms/taskflow_doctor.rb` - Lines 258-259, 357, 361
8. `lib/ace/taskflow/configuration.rb` - Lines 115-117: initialize_structure!
9. Task.070 moved from `t/` to `tasks/`
10. Empty `t/` directory removed

### Pattern Applied

```ruby
# Before
File.join(path, "t", task_dir_name)

# After
config ||= Ace::Taskflow.configuration
task_dir = config.task_dir
File.join(path, task_dir, task_dir_name)
```

### Backward Compatibility

PathBuilder now supports both legacy and configured paths:
```ruby
pattern = %r{/(?:#{Regexp.escape(task_dir)}|t)/(\d+)(?:-[^/]+)?(?:/|$)}
```

### Commit Details

- **Hash**: 394dd30b
- **Message**: `refactor(taskflow): Use configuration for task directory paths`
- **Stats**: 10 files changed, 53 insertions(+), 30 deletions(-)
- **Type**: Conventional commit (refactor)

## Additional Context

- Related to configuration system introduced in v0.9.0
- Task 070 ("Add support for pending/ release directory") now in correct location
- Configuration file: `.ace/taskflow/config.yml` specifies `directories.tasks: "tasks"`
- Testing confirmed: `ace-taskflow task 070` shows correct path
