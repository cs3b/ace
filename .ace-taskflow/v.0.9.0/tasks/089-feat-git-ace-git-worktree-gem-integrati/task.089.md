---
id: v.0.9.0+task.089
status: draft
priority: medium
estimate: 3-4 weeks
dependencies: []
---

# Create ace-git-worktree gem with task integration

## Behavioral Specification

### User Experience

**Primary Use Case: Task-Aware Worktree Creation**

- **Input**: Task ID (e.g., `081`, `task.081`, `v.0.9.0+081`)
- **Process**:
  1. User runs `ace-git-worktree create --task 081`
  2. Gem queries ace-taskflow for task metadata (title, slug)
  3. Creates worktree directory based on configured format (default: `.ace-wt/task.081/`)
  4. Creates branch with task-based naming (default: `081-slug-of-the-task`)
  5. Automatically trusts mise.toml if present
  6. Displays confirmation with paths
- **Output**: Working worktree ready for task development with mise environment trusted

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

The system provides a seamless workflow for creating isolated development environments for tasks:

1. **Task Integration**: When given a task ID, automatically fetch task metadata from ace-taskflow and use it to generate consistent directory and branch names
2. **Configuration-Driven**: All naming conventions and paths driven by `.ace/git/worktree.yml` configuration using ace-core cascade
3. **Mise Automation**: Detect mise.toml files in worktrees and automatically run `mise trust` to avoid manual trust steps
4. **Deterministic Output**: Provide parseable output for AI agents to use worktree paths programmatically
5. **ACE Integration**: Follow ACE gem patterns with ATOM architecture, Thor CLI, and handbook integration

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
