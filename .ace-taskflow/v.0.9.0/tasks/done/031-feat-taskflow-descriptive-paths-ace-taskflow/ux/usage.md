# Task 031: Descriptive Task Paths - Usage Examples

## Current Behavior (Before)

```bash
$ ls .ace-taskflow/v.0.9.0/t/
025/  026/  027/  028/  029/  030/  031/

$ ls .ace-taskflow/v.0.9.0/t/025/
add-git-commit-and-llm-enhance-flags-to-idea-comma.md
docs/
qa/

# Users must open files to understand what each task is about
```

## New Behavior (After)

```bash
$ ls .ace-taskflow/v.0.9.0/t/
025-feat-taskflow-idea-gc-llm/
026-fix-context-loader-crash/
027-docs-taskflow-readme/
028-test-nav-integration/
029-refactor-core-config/
030-feat-llm-anthropic/
031-feat-taskflow-paths/

$ ls .ace-taskflow/v.0.9.0/t/025-feat-taskflow-idea-gc-llm/
task.025.md
docs/
qa/

# Task purpose is immediately clear from directory names
```

## Usage Scenarios

### Scenario 1: Creating a New Task

```bash
$ ace-taskflow task create "Add support for GitHub issues import"

# System generates descriptive path automatically
Created task v.0.9.0+task.035
Path: .ace-taskflow/v.0.9.0/t/035-feat-taskflow-github-import/task.035.md
```

### Scenario 2: Browsing Tasks in File Explorer

```bash
# Before: Meaningless numbers
/t/025/
/t/026/
/t/027/

# After: Self-documenting structure
/t/025-feat-taskflow-idea-gc-llm/      # Feature: idea git commit & LLM
/t/026-fix-context-loader-crash/        # Bug fix: context loader crash
/t/027-docs-taskflow-readme/            # Documentation: taskflow readme
```

### Scenario 3: AI Agent Navigation

```bash
# AI agent using ace-nav can understand task context from paths
$ ace-nav 'wfi://*taskflow*' --list

# Results now include semantic information in paths
/t/025-feat-taskflow-idea-gc-llm/task.025.md
/t/031-feat-taskflow-paths/task.031.md
/t/032-feat-taskflow-presets/task.032.md
```

### Scenario 4: Quick Task Discovery

```bash
# Find all feature tasks
$ ls .ace-taskflow/v.*/t/ | grep feat-
025-feat-taskflow-idea-gc-llm/
030-feat-llm-anthropic/
031-feat-taskflow-paths/

# Find all bug fixes
$ ls .ace-taskflow/v.*/t/ | grep fix-
026-fix-context-loader-crash/
```

### Scenario 5: Migration of Existing Tasks

```bash
$ ace-taskflow migrate-paths

Migrating task paths to new format...
  025 -> 025-feat-taskflow-idea-gc-llm
  026 -> 026-fix-core-config-resolver
  027 -> 027-docs-handbook-guides
Migration complete: 27 tasks updated
```

## Benefits

1. **Instant Context**: No need to open files to understand task purpose
2. **Better Organization**: Tasks naturally group by type and component
3. **Improved Search**: Can use standard file tools to filter by type/component
4. **AI-Friendly**: Agents can understand project structure without parsing files
5. **Human-Friendly**: Developers can navigate tasks more efficiently

