---
id: v.0.9.0+task.182
status: pending
priority: high
estimate: 3h
dependencies: []
---

# Fix task create command with nested dry-cli subcommands

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-taskflow task create --title "Fix task extensions" --status draft --estimate 2h`
- **Process**: dry-cli parses the command, routes to nested subcommand, creates task with provided options
- **Output**: Task created successfully, confirmation message with path

### Expected Behavior

The system should accept nested subcommand syntax for task operations:

1. **Primary command**: `ace-taskflow task` is the namespace
2. **Subcommands**: `create`, `show`, `start`, `done`, `move`, `update`, etc.
3. **Options**: Each subcommand defines its own specific options

When user runs:
```bash
ace-taskflow task create --title "Task title" --status draft --estimate 2h
```

The system should:
- Route `task create` to the dedicated Create command class
- Parse `--title`, `--status`, `--estimate` options defined in that class
- Execute the create operation with provided parameters
- Return success confirmation with task path

### Interface Contract

```bash
# Primary syntax
ace-taskflow task create [TITLE] [options]

# Options
--title TITLE       Task title (alternative to positional)
--status STATUS     Initial status (pending, draft, in-progress, done, blocked)
--estimate EST      Effort estimate (e.g., 2h, 1d, TBD)
--dependencies DEPS Comma-separated dependency list (e.g., 018,019)
--child-of REF      Create as subtask under parent task (-p short form)
--backlog           Create task in backlog
--release VER       Create in specific release
--dry-run, -n       Preview what would be created without creating
--help, -h          Show create command help

# Examples
ace-taskflow task create --title "Fix bug" --status draft --estimate 2h
ace-taskflow task create "Add caching layer"
ace-taskflow task create "Write tests" --dependencies 041,042
ace-taskflow task create "Archive output" --child-of 121
```

**Error Handling:**
- Missing title: Error message with usage hint
- Invalid status: Error with valid status values
- Invalid parent reference: Error with finding parent task
- Missing required metadata: Clear error messages

**Edge Cases:**
- Title with spaces: Handle quoted strings properly
- Multiple dependencies: Parse comma-separated list
- Subtask creation: Validate parent exists and supports subtasks
- Dry-run mode: Show preview without creating files

### Success Criteria

- [ ] **Command Execution**: `ace-taskflow task create --title "Test" --status draft` creates task successfully
- [ ] **Option Parsing**: All defined options (--title, --status, --estimate, etc.) are parsed correctly
- [ ] **Help Display**: `ace-taskflow task create --help` shows create-specific help
- [ ] **Backward Compatibility**: `ace-taskflow task create "Title"` positional argument still works
- [ ] **No Unknown Option Errors**: No "was called with arguments" errors for valid options
- [ ] **Exit Codes**: Returns 0 on success, non-zero on failure

### Validation Questions

- [ ] **Scope**: Should we migrate ALL task subcommands (start, done, move, etc.) or just fix create first?
- [ ] **Breaking Changes**: Are there any existing scripts/users relying on current behavior?
- [ ] **Testing**: How to ensure existing tests still pass after refactoring?

## Objective

Fix the broken `ace-taskflow task create` command by refactoring from wrapper pattern to dry-cli's native nested subcommand support, enabling proper option parsing and help display.

## Scope of Work

- **User Experience Scope**: Task creation workflow with all options working correctly
- **System Behavior Scope**: dry-cli command registration and option parsing for task subcommands
- **Interface Scope**: `ace-taskflow task create` command and its options

### Deliverables

#### Behavioral Specifications
- Nested subcommand registration for `task create`
- Option definitions for create-specific flags
- Help text for create command

#### Validation Artifacts
- Test scenarios for option parsing
- Command execution verification
- Help display validation

## Out of Scope

- ❌ **Other Subcommands**: Focus on create only, other subcommands (move, start, done) can be migrated separately if needed
- ❌ **Task Manager Logic**: No changes to TaskCommand organism or TaskManager
- ❌ **OptionParser Migration**: Can keep using OptionParser internally, just expose via dry-cli options

## Implementation Plan

### Technical Approach

**Architecture Pattern**: dry-cli nested subcommand registration
- Follow the pattern from `ace-llm-models-dev` which successfully uses space-separated command registration
- Each subcommand is a dedicated `Dry::CLI::Command` subclass
- Commands delegate to existing `TaskCommand` organism for business logic

**Technology Stack**:
- dry-cli (already in use)
- Existing `TaskCommand` and `TaskManager` organisms
- No new dependencies required

**Implementation Strategy**:
1. Create new command class for `task create` with proper option definitions
2. Register as nested subcommand `"task create"`
3. Keep existing `TaskCommand#create_task` method for business logic
4. Update CLI registration to use new pattern
5. Leave existing wrapper in place for backward compatibility during transition

### File Modifications

#### Create
- `lib/ace/taskflow/commands/task/create.rb`
  - Purpose: Dry::CLI::Command subclass for task create
  - Key components: option definitions, call method, args builder for TaskCommand
  - Dependencies: Ace::Core::CLI::DryCli::Base, existing TaskCommand

#### Modify
- `lib/ace/taskflow/cli.rb`
  - Changes: Add `register "task create", Commands::Task::Create`
  - Impact: Routes `ace-taskflow task create` to new command class
  - Integration points: Keep existing `register "task", CLI::Task.new` for direct task reference (e.g., `ace-taskflow task 114`)

#### Keep (No changes)
- `lib/ace/taskflow/commands/task_command.rb` - Business logic organism
- `lib/ace/taskflow/molecules/task_arg_parser.rb` - Argument parsing (optional, can use dry-cli options directly)

### Planning Steps

- [ ] Review ace-llm-models-dev CLI implementation for reference pattern
- [ ] Determine which options to define in Create command class
- [ ] Plan how to handle positional title argument vs --title option
- [ ] Decide whether to keep TaskArgParser or use dry-cli options directly
- [ ] Consider test impact and update requirements

### Execution Steps

- [ ] Create `lib/ace/taskflow/commands/task/` directory
- [ ] Create `lib/ace/taskflow/commands/task/create.rb` with:
  - Class definition extending `Dry::CLI::Command`
  - Include `Ace::Core::CLI::DryCli::Base`
  - Option definitions for all create flags
  - `call` method that converts options to args and delegates to TaskCommand
- [ ] Update `lib/ace/taskflow/cli.rb` to require and register the new command
- [ ] Test manually: `ace-taskflow task create --title "Test" --status draft`
- [ ] Test help: `ace-taskflow task create --help`
- [ ] Test backward compatibility: `ace-taskflow task create "Title"`
- [ ] Verify existing functionality: `ace-taskflow task 114` (should still work)
- [ ] Run existing test suite to ensure no regressions

### Risk Assessment

**Technical Risks**:
- **Risk**: Breaking existing `ace-taskflow task <ref>` direct reference functionality
  - **Probability**: Medium
  - **Impact**: High (affects common workflow)
  - **Mitigation**: Keep existing `register "task", CLI::Task.new` for direct references, only add nested `create` subcommand
  - **Rollback**: Revert CLI registration changes, restore single command pattern

**Integration Risks**:
- **Risk**: Other subcommands (move, start, done) may have same issue
  - **Mitigation**: Focus on create only, document pattern for future migrations
  - **Monitoring**: Check if other subcommands fail similarly

### Acceptance Criteria

- [ ] `ace-taskflow task create --title "Test" --status draft --estimate 2h` works without errors
- [ ] `ace-taskflow task create --help` shows create-specific help
- [ ] `ace-taskflow task create "Title"` positional argument works
- [ ] `ace-taskflow task 114` direct reference still works
- [ ] All existing tests pass
- [ ] No "was called with arguments" errors

## References

- Plan: `/Users/mc/.claude/plans/lucky-frolicking-lamport.md`
- Working example: `ace-llm-models-dev/lib/ace/llm/models_dev/cli.rb`
- Current implementation: `ace-taskflow/lib/ace/taskflow/cli/task.rb`
