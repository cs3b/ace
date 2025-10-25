---
id: v.0.9.0+task.089
status: pending
priority: medium
estimate: 3-4 weeks
dependencies: []
sort: 998
---

# Create ace-git-worktree gem with task integration

## Behavioral Specification

### User Experience

**Primary Use Case: Task-Aware Worktree Creation with Status Tracking**

- **Input**: Task ID (e.g., `081`, `task.081`, `v.0.9.0+081`)
- **Process**:
  1. User runs `ace-git-worktree create --task 081`
  2. Gem queries ace-taskflow for task metadata (title, slug, current status)
  3. Updates task status to `in-progress` if not already (via `ace-taskflow task start`)
  4. Adds worktree metadata to task frontmatter:
     ```yaml
     worktree:
       branch: "081-fix-authentication-bug"
       path: ".ace-wt/task.081"
       created_at: "2025-10-25 14:30:00"
     ```
  5. Commits task changes to main branch with message: `chore(task-081): mark as in-progress, creating worktree`
  6. Creates worktree directory based on configured format (default: `.ace-wt/task.081/`)
  7. Creates branch with task-based naming (default: `081-slug-of-the-task`)
  8. Automatically trusts mise.toml if present
  9. Displays confirmation with paths and status
- **Output**: Working worktree ready for task development with mise environment trusted, task marked as in-progress on main branch

**Secondary Use Case: Traditional Worktree Creation**

- **Input**: Branch name for non-task work
- **Process**: Standard git worktree creation with mise trust automation
- **Output**: Worktree at configured location

**Additional Operations:**

- List all worktrees with task associations
- Switch/navigate to worktree by task ID or name
- Remove worktrees with cleanup
- Prune deleted worktrees

### Expected Behavior

The system provides a seamless workflow for creating isolated development environments for tasks with integrated status tracking:

1. **Task Status Management**: Automatically mark tasks as in-progress when creating worktrees, maintaining accurate task state in the main branch
2. **Task Integration**: When given a task ID, automatically fetch task metadata from ace-taskflow and use it to generate consistent directory and branch names
3. **Worktree Metadata Tracking**: Add worktree information (branch, path, creation time) to task frontmatter for clear association between tasks and worktrees
4. **Atomic Updates**: Commit task status and worktree metadata changes to main branch before creating worktree, ensuring consistent state
5. **Configuration-Driven**: All naming conventions, paths, and workflow behaviors driven by `.ace/git/worktree.yml` configuration using ace-core cascade
6. **Mise Automation**: Detect mise.toml files in worktrees and automatically run `mise trust` to avoid manual trust steps
7. **Deterministic Output**: Provide parseable output for AI agents to use worktree paths programmatically
8. **ACE Integration**: Follow ACE gem patterns with ATOM architecture, custom CLI router, and handbook integration

### Interface Contract

**CLI Interface:**

```bash
# Task-aware creation (PRIMARY)
ace-git-worktree create --task <task-id>
  --task 081              # Short task number
  --task task.081         # Task with prefix
  --task v.0.9.0+081      # Fully qualified task ID

# Options
  --path <custom-path>    # Override default root path
  --no-mise-trust         # Skip automatic mise trust
  --dry-run               # Show what would be created
  --no-status-update      # Skip marking task as in-progress
  --no-commit             # Skip committing task changes
  --commit-message <msg>  # Custom commit message for task update

# Traditional creation
ace-git-worktree create <branch-name>
  [--path <custom-path>]
  [--no-mise-trust]

# Management commands
ace-git-worktree list
  [--format json|table]   # Output format
  [--show-tasks]          # Show associated task IDs

ace-git-worktree switch <worktree-identifier>
  # Identifier can be: task.081, 081, branch-name, directory-name

ace-git-worktree remove <worktree-identifier>
  [--force]               # Remove even if changes present

ace-git-worktree prune
  # Clean up deleted worktrees from git metadata

# Configuration
ace-git-worktree config
  [--show]                # Display current configuration
```

**Configuration Interface (.ace/git/worktree.yml):**

```yaml
git:
  worktree:
    # Root directory for all worktrees (relative to project root)
    root_path: ".ace-wt"

    # Mise integration
    mise_trust_auto: true

    # Task-based naming conventions
    task:
      # Directory naming: {id}, {task_id}, {release}, {slug}
      directory_format: "task.{id}"        # Results in: task.081

      # Branch naming: {id}, {task_id}, {release}, {slug}
      branch_format: "{id}-{slug}"         # Results in: 081-slug-of-task

      # Alternative examples:
      # branch_format: "task-{id}-{slug}" # task-081-slug-of-task
      # directory_format: "{id}"          # 081

      # Workflow automation
      auto_mark_in_progress: true    # Auto-update task status to in-progress
      auto_commit_task: true          # Auto-commit task changes before creating worktree
      commit_message_format: "chore(task-{id}): mark as in-progress, creating worktree"
      add_worktree_metadata: true    # Add worktree info to task frontmatter

    # Cleanup policies
    cleanup:
      on_merge: false      # Auto-remove when branch merged
      on_delete: true      # Remove worktree when branch deleted
```

**Error Handling:**

- **Task not found**: Display error with suggestion to verify task ID via `ace-taskflow tasks`
- **ace-taskflow not available**: Fall back to manual entry or error message
- **Invalid path**: Validate worktree root exists and is writable
- **Mise trust fails**: Log warning but continue (non-fatal)
- **Worktree already exists**: Prompt for confirmation or error with --force flag
- **Git worktree command fails**: Display git error and suggest fixes

**Edge Cases:**

- **Multiple worktrees for same task**: Append counter (task.081-2)
- **Task with no slug**: Use task ID only for branch name
- **Long task titles**: Truncate slug to reasonable length (configurable)
- **Special characters in task title**: Sanitize for valid git branch names
- **Worktree in subdirectory**: Support nested paths in configuration

### Success Criteria

**Gem Structure & Architecture:**
- [ ] Full gem structure following docs/ace-gems.g.md guide
- [ ] ATOM architecture with atoms/, molecules/, organisms/, models/ directories
- [ ] Flat test structure: test/atoms/, test/molecules/, test/organisms/, test/models/
- [ ] Thor CLI commands in lib/ace/git/worktree/commands/
- [ ] Configuration cascade via ace-core integration

**Core Functionality:**
- [ ] Task-aware worktree creation with `--task` flag
- [ ] Integration with ace-taskflow for metadata lookup
- [ ] Automatic task status update to in-progress (configurable)
- [ ] Add worktree metadata to task frontmatter (branch, path, created_at)
- [ ] Commit task changes before creating worktree (configurable)
- [ ] Configurable naming conventions (directory_format, branch_format)
- [ ] Automatic mise trust execution when mise.toml detected
- [ ] Traditional branch-based worktree creation
- [ ] List command showing all worktrees with task associations
- [ ] Switch command for navigation by task ID or name
- [ ] Remove command with cleanup
- [ ] Prune command for deleted worktrees

**Configuration:**
- [ ] Example config in .ace.example/git/worktree.yml
- [ ] Configuration loaded via Ace::Core.config.get('ace', 'git', 'worktree')
- [ ] Support for custom root paths
- [ ] Configurable task naming formats
- [ ] Configurable mise trust behavior
- [ ] Configurable workflow automation (auto_mark_in_progress, auto_commit_task)
- [ ] Configurable commit message format for task updates
- [ ] Configurable worktree metadata addition to tasks

**Documentation & Integration:**
- [ ] README.md with overview and quick start
- [ ] CHANGELOG.md in Keep a Changelog format
- [ ] Handbook with workflow-instructions/worktree-create.wf.md
- [ ] Gemspec with ace-core dependency
- [ ] Rakefile with standard test task
- [ ] VERSION file with semantic versioning

**Testing:**
- [ ] Unit tests for all ATOM layers
- [ ] Integration tests for CLI commands
- [ ] Test coverage for task metadata fetching
- [ ] Test coverage for configuration loading
- [ ] Test coverage for error conditions

### Validation Questions

- [ ] **Task ID Formats**: Should we support all task reference formats (081, task.081, v.0.9.0+081) or just a subset?
- [ ] **Configuration Scope**: Should worktree config be under `git.worktree` or separate `worktree` top-level namespace?
- [ ] **Mise Trust**: Should mise trust be synchronous or asynchronous? What if it takes long time?
- [ ] **Navigation**: Should `switch` command just output path or actually attempt shell navigation (cd command)?
- [ ] **Task Metadata**: What fields from ace-taskflow tasks do we need beyond ID, title, release?
- [ ] **Error Recovery**: If ace-taskflow fails, should we prompt user for manual input or just error out?
- [ ] **Worktree Cleanup**: Should we track worktree-to-task associations for automated cleanup on task completion?

## Objective

Enable seamless, task-focused development workflows by providing deterministic CLI tools for managing git worktrees integrated with ACE's task management system. This allows both human developers and AI agents to efficiently work on multiple tasks concurrently without context switching overhead, while maintaining consistent project structure and automation (mise trust).

## Scope of Work

### User Experience Scope
- Task-aware worktree creation with automatic metadata lookup
- Traditional git worktree operations (create, list, remove, prune)
- Navigation and discovery of existing worktrees
- Configuration-driven naming conventions
- Automated environment setup (mise trust)

### System Behavior Scope
- Integration with ace-taskflow for task metadata
- Configuration management via ace-core cascade
- Git worktree CLI command execution
- Mise environment trust automation
- Deterministic, parseable output for AI agents

### Interface Scope
- Thor CLI commands for all operations
- YAML configuration via .ace/ hierarchy
- Integration with ace-taskflow CLI
- Integration with git and mise CLIs

### Deliverables

#### Behavioral Specifications
- Complete gem structure following ACE standards
- ATOM architecture implementation
- Thor CLI command suite
- Configuration cascade integration

#### User Experience Artifacts
- README with quick start guide
- Workflow instruction for worktree creation
- Example configuration files
- CLI help documentation

#### Validation Artifacts
- Comprehensive test suite (unit + integration)
- Error handling for all edge cases
- Configuration validation
- CLI output format specifications

## Out of Scope

- ❌ **GitHub PR Integration**: Creating or managing pull requests (deferred to future enhancement)
- ❌ **Worktree Merging**: Automated merge workflows (use existing git/GitHub workflows)
- ❌ **Multi-Project Support**: Managing worktrees across multiple repositories simultaneously
- ❌ **GUI Interface**: Command-line only, no graphical interface
- ❌ **Performance Optimization**: Advanced caching or performance tuning (implement if needed)
- ❌ **Cloud Integration**: Remote worktree hosting or synchronization

## References

- Source Idea 1: `.ace-taskflow/v.0.9.0/ideas/done/20251024-211928-ace-git-worktree-1-create-a-workree-2-mise-tr.md`
- Source Idea 2: `.ace-taskflow/v.0.9.0/ideas/done/20250926-152156-feat-git-worktree-pr-management.md`
- ACE Gem Guide: `docs/ace-gems.g.md`
- ATOM Architecture: `docs/architecture.md` (ADR-011)
- Configuration: `docs/decisions.md` (ADR-019)
- Similar gems: ace-git-commit, ace-taskflow, ace-search

---

## Technical Approach

### Architecture Pattern

**ATOM Pattern Implementation:**
- **Atoms**: Pure functions for git command execution, path manipulation, string slugification
- **Molecules**: Worktree operations (create, list, remove), task metadata fetching, task status updating, task frontmatter updating, mise trust execution
- **Organisms**: Orchestration of complete task-worktree workflow (status update, metadata tracking, commit, worktree creation), configuration-driven operations
- **Models**: Data structures for WorktreeConfig, WorktreeInfo, TaskMetadata, WorktreeMetadata

**Integration Points:**
- ace-core: Configuration cascade via `Ace::Core.config.get('ace', 'git', 'worktree')`
- ace-taskflow: Task metadata lookup via CLI integration
- ace-git-diff: Reuse CommandExecutor atom for safe git command execution
- git: Standard git worktree commands executed via Open3.capture3

### Technology Stack

**Core Dependencies:**
- Ruby >= 3.0.0 (project standard)
- ace-core ~> 0.9.0 (configuration management)
- ace-git-diff ~> 0.1.0 (git command execution)
- ace-taskflow ~> 0.9.0 (task metadata lookup) - runtime dependency for task integration
- Standard library: Open3, FileUtils, YAML, Timeout

**CLI Framework:**
- Custom CLI router (following ace-taskflow pattern, not Thor)
- Command pattern with explicit routing in CLI class
- Returns exit codes (0/1) from commands

**Testing:**
- Minitest (project standard)
- ace-test-support for test infrastructure
- Flat test structure: test/{atoms,molecules,organisms,models,commands}/

### Implementation Strategy

**Phase 1: Core Infrastructure**
1. Create gem structure following ACE standards
2. Implement ATOM architecture with atoms for git commands
3. Set up configuration cascade integration
4. Create basic CLI routing

**Phase 2: Git Operations**
1. Implement git worktree command wrappers (atoms)
2. Build worktree creation molecule with mise integration
3. Implement list, remove, prune operations
4. Add error handling for git failures

**Phase 3: Task Integration**
1. Build task metadata fetcher molecule
2. Implement naming convention formatter (atoms for slugification)
3. Create task-aware worktree orchestrator
4. Add task ID resolution logic

**Phase 4: CLI and Configuration**
1. Implement all CLI commands
2. Create example configuration files
3. Add configuration validation
4. Implement dry-run mode

**Phase 5: Documentation and Testing**
1. Write comprehensive test suite
2. Create README and CHANGELOG
3. Write workflow instructions
4. Create usage documentation

## Tool Selection

| Criteria | ace-git-diff | ace-taskflow | Custom Implementation | Selected |
|----------|--------------|--------------|----------------------|----------|
| **Git Command Execution** | ||||
| Safety (injection prevention) | Excellent | N/A | Good | ace-git-diff |
| Error handling | Excellent | N/A | Good | ace-git-diff |
| Timeout support | Yes | N/A | Manual | ace-git-diff |
| **Task Metadata** | ||||
| Integration | N/A | Excellent | Manual parsing | ace-taskflow |
| Reliability | N/A | Excellent | Manual parsing | ace-taskflow |
| Maintenance | N/A | Excellent | Manual effort | ace-taskflow |
| **CLI Framework** | ||||
| Flexibility | N/A | Custom router | Thor library | Custom router |
| ACE patterns | N/A | Yes | Requires learning | Custom router |
| Exit codes | N/A | Yes | Yes | Custom router |

**Selection Rationale:**

**ace-git-diff for Git Commands:**
- Proven safety with command injection prevention
- Built-in timeout handling (30s)
- Consistent error handling
- Already used by ace-git-commit successfully
- Eliminates need to reimplement git safety measures

**ace-taskflow CLI Integration:**
- Programmatic API preferred but not yet available
- CLI integration via subprocess is current standard
- Reliable task lookup with all reference formats supported
- Future: migrate to programmatic API when available

**Custom CLI Router (not Thor):**
- Follows ace-taskflow pattern (most similar use case)
- Simpler implementation for focused tool
- Better exit code control
- Consistent with ACE CLI standards

### Dependencies

**Runtime Dependencies:**
- ace-core ~> 0.9.0 - Configuration cascade
- ace-git-diff ~> 0.1.0 - Safe git command execution
- ace-taskflow ~> 0.9.0 - Task metadata lookup (runtime, not development)

**Development Dependencies (managed in root Gemfile):**
- ace-test-support ~> 0.9.0 - Test infrastructure
- minitest - Testing framework
- rake - Build tasks

**Compatibility Verification:**
- All dependencies are ACE ecosystem gems with compatible versions
- No conflicting dependencies identified
- Ruby 3.0+ requirement consistent across all dependencies

## File Modifications

### Create

**Gem Structure:**

```
ace-git-worktree/
├── .ace.example/git/worktree.yml
├── lib/ace/git/worktree/
│   ├── version.rb
│   ├── configuration.rb
│   ├── cli.rb
│   ├── atoms/
│   │   ├── git_command.rb         # Delegate to ace-git-diff
│   │   ├── path_expander.rb       # Path expansion and validation
│   │   └── slug_generator.rb      # Task title to slug conversion
│   ├── molecules/
│   │   ├── task_fetcher.rb        # Fetch task metadata from ace-taskflow
│   │   ├── task_status_updater.rb # Update task status to in-progress
│   │   ├── task_metadata_writer.rb # Add worktree metadata to task frontmatter
│   │   ├── task_committer.rb      # Commit task changes via ace-git-commit
│   │   ├── worktree_creator.rb    # Core worktree creation logic
│   │   ├── worktree_lister.rb     # List worktrees with task info
│   │   ├── worktree_remover.rb    # Remove worktree operations
│   │   ├── mise_trustor.rb        # Mise trust automation
│   │   └── config_loader.rb       # Load and merge configuration
│   ├── organisms/
│   │   ├── task_worktree_orchestrator.rb  # Orchestrate task-aware creation
│   │   └── worktree_manager.rb    # Manage all worktree operations
│   ├── models/
│   │   ├── worktree_config.rb     # Configuration model
│   │   ├── worktree_info.rb       # Worktree information
│   │   ├── task_metadata.rb       # Task information
│   │   └── worktree_metadata.rb   # Worktree metadata for task frontmatter
│   └── commands/
│       ├── create_command.rb
│       ├── list_command.rb
│       ├── switch_command.rb
│       ├── remove_command.rb
│       ├── prune_command.rb
│       └── config_command.rb
├── lib/ace/git/worktree.rb         # Main entry point
├── test/
│   ├── test_helper.rb
│   ├── git_worktree_test.rb
│   ├── atoms/
│   │   ├── git_command_test.rb
│   │   ├── path_expander_test.rb
│   │   └── slug_generator_test.rb
│   ├── molecules/
│   │   ├── task_fetcher_test.rb
│   │   ├── task_status_updater_test.rb
│   │   ├── task_metadata_writer_test.rb
│   │   ├── task_committer_test.rb
│   │   ├── worktree_creator_test.rb
│   │   ├── worktree_lister_test.rb
│   │   ├── worktree_remover_test.rb
│   │   ├── mise_trustor_test.rb
│   │   └── config_loader_test.rb
│   ├── organisms/
│   │   ├── task_worktree_orchestrator_test.rb
│   │   └── worktree_manager_test.rb
│   ├── models/
│   │   ├── worktree_config_test.rb
│   │   ├── worktree_info_test.rb
│   │   ├── task_metadata_test.rb
│   │   └── worktree_metadata_test.rb
│   ├── commands/
│   │   ├── create_command_test.rb
│   │   ├── list_command_test.rb
│   │   ├── switch_command_test.rb
│   │   ├── remove_command_test.rb
│   │   ├── prune_command_test.rb
│   │   └── config_command_test.rb
│   └── integration/
│       ├── cli_integration_test.rb
│       └── task_integration_test.rb
├── exe/ace-git-worktree
├── handbook/
│   ├── agents/
│   │   └── worktree.ag.md
│   └── workflow-instructions/
│       ├── worktree-create.wf.md
│       └── worktree-manage.wf.md
├── ace-git-worktree.gemspec
├── Gemfile
├── Rakefile
├── README.md
├── CHANGELOG.md
└── LICENSE
```

**Purpose of Key Files:**

- **atoms/git_command.rb**: Thin wrapper delegating to ace-git-diff CommandExecutor
- **atoms/slug_generator.rb**: Convert task titles to URL-safe slugs for branch names
- **molecules/task_fetcher.rb**: Execute `ace-taskflow task <id>` and parse output
- **molecules/task_status_updater.rb**: Execute `ace-taskflow task start <id>` to update status
- **molecules/task_metadata_writer.rb**: Update task file frontmatter with worktree metadata
- **molecules/task_committer.rb**: Execute `ace-git-commit` to commit task changes
- **molecules/worktree_creator.rb**: Execute git worktree add with error handling
- **molecules/mise_trustor.rb**: Detect and trust mise.toml in worktree
- **organisms/task_worktree_orchestrator.rb**: Coordinate complete workflow: status update + metadata + commit + worktree creation + mise trust
- **commands/*_command.rb**: CLI command implementations returning exit codes
- **cli.rb**: Route subcommands to command classes
- **configuration.rb**: Load config via Ace::Core.config cascade

### Modify

**Root Gemfile:**
- Add `gem 'ace-git-worktree', path: 'ace-git-worktree'` for development

**docs/tools.md:**
- Add ace-git-worktree entry with key commands

**CHANGELOG.md (root):**
- Add entry for new ace-git-worktree gem

### Delete

No files to delete.

## Test Case Planning

### Test Scenarios

#### Happy Path Scenarios

**Task-Aware Worktree Creation:**
- Given: Valid task ID (081, task.081, v.0.9.0+081)
- When: `ace-git-worktree create --task 081`
- Then: Worktree created at configured path with proper branch name, mise trusted

**Traditional Worktree Creation:**
- Given: Branch name
- When: `ace-git-worktree create feature-branch`
- Then: Worktree created at configured path with branch name

**List Worktrees:**
- Given: Multiple worktrees exist
- When: `ace-git-worktree list --show-tasks`
- Then: All worktrees displayed with task associations

**Switch Worktree:**
- Given: Worktree exists for task 081
- When: `ace-git-worktree switch 081`
- Then: Path to worktree printed to stdout

**Remove Worktree:**
- Given: Worktree exists without uncommitted changes
- When: `ace-git-worktree remove 081`
- Then: Worktree removed successfully

#### Edge Case Scenarios

**Long Task Title:**
- Given: Task with very long title (>100 characters)
- When: Create worktree
- Then: Slug truncated to reasonable length, branch name valid

**Special Characters in Title:**
- Given: Task title with /, \, :, @, etc.
- When: Create worktree
- Then: Special characters sanitized in slug

**Multiple Worktrees for Same Task:**
- Given: Worktree already exists for task 081
- When: Create another for task 081
- Then: Directory name appended with counter (task.081-2)

**Task with No Slug:**
- Given: Task title is very short or only special characters
- When: Create worktree
- Then: Use task ID as fallback for branch name

**Missing mise.toml:**
- Given: Worktree without mise.toml
- When: Create worktree
- Then: Skip mise trust, continue successfully

**Empty Worktree List:**
- Given: No worktrees exist
- When: List worktrees
- Then: Display appropriate message, exit 0

#### Error Condition Scenarios

**Task Not Found:**
- Given: Invalid task ID (999)
- When: Create with --task 999
- Then: Error message with suggestion, exit 1

**ace-taskflow Not Available:**
- Given: ace-taskflow not installed
- When: Create with --task flag
- Then: Error message suggesting gem installation, exit 1

**Not in Git Repository:**
- Given: Running outside git repo
- When: Any worktree command
- Then: Error message, exit 1

**Worktree Already Exists:**
- Given: Directory already exists at worktree path
- When: Create worktree
- Then: Error message, exit 1

**Invalid Path:**
- Given: Worktree root path not writable
- When: Create worktree
- Then: Error message with permission details, exit 1

**Git Command Failure:**
- Given: Git worktree add fails (e.g., branch exists)
- When: Create worktree
- Then: Display git error message, exit 1

**Mise Trust Failure:**
- Given: mise command fails
- When: Create worktree with mise.toml
- Then: Log warning, continue (non-fatal)

**Uncommitted Changes on Remove:**
- Given: Worktree has uncommitted changes
- When: Remove without --force
- Then: Error message, suggest --force, exit 1

#### Integration Point Scenarios

**ace-taskflow CLI Integration:**
- Test: Execute `ace-taskflow task 081` subprocess
- Assert: Correct parsing of task metadata from output
- Mock: Subprocess execution for consistent testing

**ace-git-diff CommandExecutor:**
- Test: Delegate git commands correctly
- Assert: Commands executed with proper safety
- Mock: CommandExecutor for unit tests

**Configuration Cascade:**
- Test: Load config from .ace/git/worktree.yml
- Assert: Nearest config wins, defaults applied
- Test: Project, user, and default config layers

**Mise Detection and Trust:**
- Test: Detect mise.toml in worktree directory
- Assert: Execute mise trust with correct path
- Mock: File system and mise command execution

### Test Type Categorization

**Unit Tests (High Priority):**
- SlugGenerator atom: title to slug conversion
- PathExpander atom: path expansion and validation
- TaskFetcher molecule: parse ace-taskflow output
- ConfigLoader molecule: configuration cascade
- WorktreeCreator molecule: git command execution
- All model classes: data structure integrity

**Integration Tests (Medium Priority):**
- CLI command execution end-to-end
- Task worktree orchestrator with mocked subprocess
- Configuration loading from actual .ace.example files
- Worktree lister with mocked git output

**End-to-End Tests (Low Priority - Manual):**
- Full workflow with real ace-taskflow and git
- Actual worktree creation and removal
- Real mise trust execution
- Complex scenarios with multiple worktrees

**Security Tests (High Priority):**
- Command injection prevention (inherited from ace-git-diff)
- Path traversal prevention in worktree paths
- Input sanitization for task titles and slugs
- Proper quoting in git commands

### Test Coverage Expectations

**Target Coverage:** 90%+ for atoms and molecules, 80%+ for organisms and commands

**Critical Paths (100% coverage):**
- Git command execution and error handling
- Task metadata fetching and parsing
- Configuration loading and merging
- Slug generation and sanitization

**Documentation:**
- Test case matrix in `test/TEST_PLAN.md`
- Each test file documents scenarios covered
- Integration test scenarios in `test/integration/README.md`

## Implementation Plan

### Planning Steps

* [ ] Review ACE gem patterns in ace-git-commit and ace-taskflow for reference
* [ ] Validate naming conventions for git/worktree namespace
  > TEST: Namespace Check
  > Type: Pre-condition Check
  > Assert: Namespace Ace::Git::Worktree doesn't conflict with existing gems
  > Command: grep -r "module Worktree" ace-git-*/lib/ ace-*/lib/ace/git/
* [ ] Design slug generation algorithm (research branch naming best practices)
* [ ] Plan task metadata parsing format from ace-taskflow output
* [ ] Research git worktree edge cases and failure modes

### Execution Steps

**Phase 1: Gem Infrastructure (Weeks 1)**

- [ ] Create gem directory structure with all ATOM layer directories
  > TEST: Structure Validation
  > Type: Action Validation
  > Assert: All required directories exist (atoms, molecules, organisms, models, commands, test/)
  > Command: ls -la ace-git-worktree/lib/ace/git/worktree/ ace-git-worktree/test/

- [ ] Create gemspec with ace-core, ace-git-diff, ace-taskflow dependencies
  > TEST: Gemspec Validation
  > Type: Action Validation
  > Assert: Gemspec loads without errors and has correct dependencies
  > Command: cd ace-git-worktree && ruby ace-git-worktree.gemspec

- [ ] Create VERSION file and version.rb with 0.1.0
- [ ] Create Gemfile with development dependencies reference to root
- [ ] Create Rakefile with test tasks following ACE standards
- [ ] Create LICENSE (MIT) and basic README.md structure
- [ ] Create CHANGELOG.md with Keep a Changelog format
- [ ] Set up test_helper.rb with ace-test-support integration
  > TEST: Test Infrastructure
  > Type: Action Validation
  > Assert: Test helper loads without errors
  > Command: cd ace-git-worktree && ruby -Ilib:test test/test_helper.rb

**Phase 2: Atoms Layer (Week 1)**

- [ ] Create atoms/git_command.rb delegating to ace-git-diff CommandExecutor
  > TEST: Git Command Atom
  > Type: Unit Test
  > Assert: Commands delegated correctly with proper error handling
  > Command: cd ace-git-worktree && ruby -Ilib:test test/atoms/git_command_test.rb

- [ ] Create atoms/path_expander.rb for path expansion and validation
  > TEST: Path Expansion Atom
  > Type: Unit Test
  > Assert: Paths expanded correctly, ~ resolved, relative paths handled
  > Command: cd ace-git-worktree && ruby -Ilib:test test/atoms/path_expander_test.rb

- [ ] Create atoms/slug_generator.rb with title-to-slug conversion
  > TEST: Slug Generation Atom
  > Type: Unit Test
  > Assert: Special characters removed, length limits enforced, deterministic output
  > Command: cd ace-git-worktree && ruby -Ilib:test test/atoms/slug_generator_test.rb

- [ ] Write comprehensive atom unit tests (edge cases, error conditions)

**Phase 3: Models Layer (Week 1-2)**

- [ ] Create models/worktree_config.rb with configuration structure
- [ ] Create models/worktree_info.rb for worktree data
- [ ] Create models/task_metadata.rb for task information
  > TEST: Model Classes
  > Type: Unit Test
  > Assert: Models initialize correctly, validate data, provide accessors
  > Command: cd ace-git-worktree && ruby -Ilib:test test/models/*_test.rb

**Phase 4: Molecules Layer (Week 2)**

- [ ] Create molecules/config_loader.rb using Ace::Core.config cascade
  > TEST: Config Loader
  > Type: Unit Test
  > Assert: Configuration loaded from .ace/ hierarchy, defaults applied
  > Command: cd ace-git-worktree && ruby -Ilib:test test/molecules/config_loader_test.rb

- [ ] Create molecules/task_fetcher.rb executing ace-taskflow subprocess
  > TEST: Task Fetcher
  > Type: Unit Test
  > Assert: Task metadata parsed correctly from CLI output
  > Command: cd ace-git-worktree && ruby -Ilib:test test/molecules/task_fetcher_test.rb

- [ ] Create molecules/worktree_creator.rb with git worktree add logic
  > TEST: Worktree Creator
  > Type: Unit Test
  > Assert: Git commands executed correctly, errors handled properly
  > Command: cd ace-git-worktree && ruby -Ilib:test test/molecules/worktree_creator_test.rb

- [ ] Create molecules/worktree_lister.rb parsing git worktree list
  > TEST: Worktree Lister
  > Type: Unit Test
  > Assert: Worktrees parsed correctly, task associations resolved
  > Command: cd ace-git-worktree && ruby -Ilib:test test/molecules/worktree_lister_test.rb

- [ ] Create molecules/worktree_remover.rb with removal logic
- [ ] Create molecules/mise_trustor.rb detecting and trusting mise.toml
  > TEST: Mise Trustor
  > Type: Unit Test
  > Assert: mise.toml detected, trust command executed correctly
  > Command: cd ace-git-worktree && ruby -Ilib:test test/molecules/mise_trustor_test.rb

**Phase 5: Organisms Layer (Week 2-3)**

- [ ] Create organisms/task_worktree_orchestrator.rb coordinating task creation
  > TEST: Task Orchestrator
  > Type: Unit Test
  > Assert: Task fetch, naming, creation, mise trust coordinated correctly
  > Command: cd ace-git-worktree && ruby -Ilib:test test/organisms/task_worktree_orchestrator_test.rb

- [ ] Create organisms/worktree_manager.rb managing all operations
  > TEST: Worktree Manager
  > Type: Unit Test
  > Assert: All worktree operations orchestrated correctly
  > Command: cd ace-git-worktree && ruby -Ilib:test test/organisms/worktree_manager_test.rb

**Phase 6: Commands Layer (Week 3)**

- [ ] Create commands/create_command.rb with --task and traditional modes
  > TEST: Create Command
  > Type: Unit Test
  > Assert: Command executes, returns correct exit codes, handles errors
  > Command: cd ace-git-worktree && ruby -Ilib:test test/commands/create_command_test.rb

- [ ] Create commands/list_command.rb with format options
- [ ] Create commands/switch_command.rb outputting worktree path
- [ ] Create commands/remove_command.rb with --force flag
- [ ] Create commands/prune_command.rb
- [ ] Create commands/config_command.rb displaying configuration
  > TEST: All Commands
  > Type: Unit Test
  > Assert: All commands execute correctly, return proper exit codes
  > Command: cd ace-git-worktree && ruby -Ilib:test test/commands/*_test.rb

**Phase 7: CLI Integration (Week 3)**

- [ ] Create lib/ace/git/worktree/cli.rb with command routing
  > TEST: CLI Router
  > Type: Integration Test
  > Assert: Commands routed correctly, help displayed, exit codes correct
  > Command: cd ace-git-worktree && ruby -Ilib:test test/integration/cli_integration_test.rb

- [ ] Create exe/ace-git-worktree executable
- [ ] Create lib/ace/git/worktree.rb main entry point with module definitions
- [ ] Create configuration.rb with default configuration

**Phase 8: Configuration (Week 3)**

- [ ] Create .ace.example/git/worktree.yml with all options documented
  > TEST: Example Config
  > Type: Validation
  > Assert: Example config loads without errors, all options documented
  > Command: cd ace-git-worktree && ruby -e "require 'yaml'; puts YAML.load_file('.ace.example/git/worktree.yml')"

- [ ] Add configuration validation in config_loader
- [ ] Test configuration cascade (project > user > default)

**Phase 9: Documentation (Week 4)**

- [ ] Write README.md with overview, installation, quick start
- [ ] Update CHANGELOG.md with 0.1.0 release notes
- [ ] Create handbook/workflow-instructions/worktree-create.wf.md
- [ ] Create handbook/workflow-instructions/worktree-manage.wf.md
- [ ] Create handbook/agents/worktree.ag.md
- [ ] Write comprehensive usage documentation (already created in ux/usage.md)

**Phase 10: Testing and Validation (Week 4)**

- [ ] Run full test suite and achieve 90%+ coverage
  > TEST: Test Coverage
  > Type: Validation
  > Assert: Coverage >= 90% for atoms/molecules, >= 80% for organisms/commands
  > Command: cd ace-git-worktree && ace-test --coverage

- [ ] Run integration tests with mocked ace-taskflow
  > TEST: Integration Tests
  > Type: Integration Test
  > Assert: All integration scenarios pass
  > Command: cd ace-git-worktree && ruby -Ilib:test test/integration/*_test.rb

- [ ] Manual end-to-end testing with real ace-taskflow
- [ ] Test all error conditions and edge cases
- [ ] Validate security (command injection, path traversal)
  > TEST: Security Validation
  > Type: Security Test
  > Assert: No command injection vulnerabilities, path traversal prevented
  > Command: cd ace-git-worktree && ruby -Ilib:test test/security_test.rb

**Phase 11: Integration with ace-meta (Week 4)**

- [ ] Add gem to root Gemfile for development
- [ ] Update docs/tools.md with ace-git-worktree entry
- [ ] Update root CHANGELOG.md
- [ ] Create symlinks from .claude/agents/ to handbook/agents/
- [ ] Test gem in ace-meta context

**Phase 12: Final Polish (Week 4)**

- [ ] Review all code for ACE standards compliance
- [ ] Run ace-lint on all markdown files
  > TEST: Linting
  > Type: Quality Check
  > Assert: All markdown and YAML files pass linting
  > Command: cd ace-git-worktree && ace-lint "**/*.md" --fix && ace-lint "**/*.yml"

- [ ] Final test suite run
  > TEST: Final Validation
  > Type: Complete Test Suite
  > Assert: All tests pass, no failures
  > Command: cd ace-git-worktree && ace-test

- [ ] Prepare for initial release

## Risk Assessment

### Technical Risks

- **Risk:** ace-taskflow CLI output format changes
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Robust parsing with version detection, graceful degradation
  - **Rollback:** Fall back to manual task metadata input mode

- **Risk:** Git worktree command variations across git versions
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Test against multiple git versions (2.25+), use stable porcelain commands
  - **Rollback:** Document minimum git version requirement

- **Risk:** mise CLI changes or installation issues
  - **Probability:** Low
  - **Impact:** Low (non-critical feature)
  - **Mitigation:** Make mise trust optional, graceful failure
  - **Rollback:** Skip mise trust on failure

- **Risk:** Complex configuration cascade issues
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Extensive configuration testing, clear validation errors
  - **Rollback:** Fall back to hardcoded defaults

### Integration Risks

- **Risk:** ace-git-diff CommandExecutor API changes
  - **Probability:** Low
  - **Impact:** High
  - **Mitigation:** Pin version dependency, monitor ace-git-diff changes
  - **Monitoring:** Run ace-meta test suite regularly
  - **Rollback:** Vendor CommandExecutor code if needed

- **Risk:** ace-taskflow not available in environment
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Clear error messages, fallback to traditional mode
  - **Monitoring:** Check for ace-taskflow in setup/doctor command
  - **Rollback:** Traditional worktree mode works without ace-taskflow

- **Risk:** Namespace conflicts with future ace-git-* gems
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Use specific namespace Ace::Git::Worktree
  - **Rollback:** Rename if conflict detected early

### Performance Risks

- **Risk:** Slow task metadata fetching via subprocess
  - **Mitigation:** Cache task metadata, use --dry-run to preview
  - **Monitoring:** Track subprocess execution time in tests
  - **Thresholds:** < 1 second for task fetch, < 2 seconds for full worktree creation

- **Risk:** List command slow with many worktrees
  - **Mitigation:** Optimize git worktree list parsing, lazy task resolution
  - **Monitoring:** Performance tests with 50+ worktrees
  - **Thresholds:** < 2 seconds for list with 50 worktrees

## Acceptance Criteria

**Gem Structure:**
- [ ] Complete ATOM architecture implemented (atoms, molecules, organisms, models)
- [ ] Flat test structure mirrors ATOM layers
- [ ] Example configuration in .ace.example/git/worktree.yml
- [ ] Handbook with workflow instructions and agents

**Core Functionality:**
- [ ] Task-aware worktree creation via --task flag
- [ ] Traditional worktree creation with branch name
- [ ] Automatic task metadata fetching from ace-taskflow
- [ ] Configurable naming conventions (directory_format, branch_format)
- [ ] Automatic mise trust when mise.toml detected
- [ ] List command with table and JSON output formats
- [ ] Switch command outputting worktree path
- [ ] Remove command with --force option
- [ ] Prune command for cleanup
- [ ] Config command displaying current settings

**Configuration:**
- [ ] Configuration cascade working via Ace::Core.config
- [ ] All template variables supported ({id}, {task_id}, {release}, {slug})
- [ ] mise_trust_auto configurable
- [ ] root_path configurable

**Testing:**
- [ ] 90%+ test coverage for atoms and molecules
- [ ] 80%+ test coverage for organisms and commands
- [ ] All happy path scenarios tested
- [ ] All edge cases covered
- [ ] All error conditions tested
- [ ] Integration tests with mocked dependencies
- [ ] Security tests (command injection, path traversal)

**Documentation:**
- [ ] README.md with quick start guide
- [ ] CHANGELOG.md in Keep a Changelog format
- [ ] Usage documentation in ux/usage.md
- [ ] Workflow instructions for worktree creation
- [ ] Agent definition for worktree operations
- [ ] All configuration options documented

**Quality:**
- [ ] All tests pass (ace-test)
- [ ] No linting errors (ace-lint)
- [ ] No security vulnerabilities
- [ ] Proper error messages for all failure modes
- [ ] Exit codes: 0 for success, 1 for errors

**Integration:**
- [ ] Works with ace-taskflow for task metadata
- [ ] Uses ace-git-diff for git commands
- [ ] Configuration via ace-core cascade
- [ ] Installable via gem install
- [ ] Listed in docs/tools.md
