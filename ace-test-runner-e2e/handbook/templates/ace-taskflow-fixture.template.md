---
doc-type: template
title: ACE Taskflow Test Fixture Template
purpose: Documentation for ace-test-runner-e2e/handbook/templates/ace-taskflow-fixture.template.md
ace-docs:
  last-updated: 2026-02-25
  last-checked: 2026-03-21
---

# ACE Taskflow Test Fixture Template

This template provides scaffolding for E2E tests that need valid ace-taskflow structures.

## Basic Task Fixture

Create a minimal valid taskflow structure:

```bash
# Create release directory structure
mkdir -p "$REPO_DIR/.ace-taskflow/v.test/tasks/001-feature"

# Create a valid task file
cat > "$REPO_DIR/.ace-taskflow/v.test/tasks/001-feature/001-test-task.s.md" << 'EOF'
---
id: v.test+task.001
status: pending
priority: medium
estimate: 1h
dependencies: []
---

# Test Task Title

## Objective

This is a test task for E2E testing purposes.

## Implementation Plan

### Execution Steps

- [ ] Step 1: First action
- [ ] Step 2: Second action

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
EOF
```

## Task with Worktree Metadata

For tests involving ace-git-worktree:

```bash
cat > "$REPO_DIR/.ace-taskflow/v.test/tasks/001-feature/001-test-task.s.md" << 'EOF'
---
id: v.test+task.001
status: in-progress
priority: medium
estimate: 1h
dependencies: []
worktree:
  branch: 001-test-task
  path: "../project-task.001"
  created_at: '2026-01-15 10:00:00'
  updated_at: '2026-01-15 10:00:00'
  target_branch: main
---

# Test Task with Worktree

## Objective

Task with worktree metadata for worktree-related E2E tests.

## Implementation Plan

### Execution Steps

- [ ] Step 1: Work in worktree

## Acceptance Criteria

- [ ] Worktree created
EOF
```

## Parent Task with Subtasks (Orchestrator)

For tests involving task hierarchies:

```bash
# Create parent task directory
mkdir -p "$REPO_DIR/.ace-taskflow/v.test/tasks/100-parent-feature"

# Create orchestrator task
cat > "$REPO_DIR/.ace-taskflow/v.test/tasks/100-parent-feature/100-orchestrator.s.md" << 'EOF'
---
id: v.test+task.100
status: pending
priority: high
estimate: 8h
dependencies: []
subtasks:
  - 100.01
  - 100.02
---

# Parent Feature Task

## Objective

Orchestrator task that coordinates subtasks.

## Subtasks

- 100.01: First subtask
- 100.02: Second subtask

## Acceptance Criteria

- [ ] All subtasks completed
EOF

# Create first subtask
cat > "$REPO_DIR/.ace-taskflow/v.test/tasks/100-parent-feature/100.01-first-subtask.s.md" << 'EOF'
---
id: v.test+task.100.01
status: pending
priority: medium
estimate: 2h
dependencies: []
parent: 100
---

# First Subtask

## Objective

First part of the parent feature.

## Implementation Plan

- [ ] Implement first component

## Acceptance Criteria

- [ ] First component done
EOF

# Create second subtask
cat > "$REPO_DIR/.ace-taskflow/v.test/tasks/100-parent-feature/100.02-second-subtask.s.md" << 'EOF'
---
id: v.test+task.100.02
status: pending
priority: medium
estimate: 2h
dependencies:
  - 100.01
parent: 100
---

# Second Subtask

## Objective

Second part of the parent feature, depends on first.

## Implementation Plan

- [ ] Implement second component

## Acceptance Criteria

- [ ] Second component done
EOF
```

## Release Configuration

For tests that need a complete release setup:

```bash
# Create release.yml
cat > "$REPO_DIR/.ace-taskflow/v.test/release.yml" << 'EOF'
id: v.test
title: Test Release
status: active
started: 2026-01-01
EOF
```

## Complete Test Setup Example

Combining all patterns:

```bash
# Create isolated git repository
REPO_DIR="$TEST_DIR/test-repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Create taskflow structure
mkdir -p .ace-taskflow/v.test/tasks/001-feature

# Create release configuration
cat > .ace-taskflow/v.test/release.yml << 'EOF'
id: v.test
title: Test Release
status: active
started: 2026-01-01
EOF

# Create task
cat > .ace-taskflow/v.test/tasks/001-feature/001-test-task.s.md << 'EOF'
---
id: v.test+task.001
status: pending
priority: medium
estimate: 1h
dependencies: []
---

# Test Task

## Objective

Test task for E2E testing.

## Implementation Plan

- [ ] Do something

## Acceptance Criteria

- [ ] Done
EOF

# Commit the structure
git add .ace-taskflow/
git commit -m "Add taskflow structure" --quiet

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$REPO_DIR"

# Now ace-taskflow commands will use this isolated structure
# ace-task show 001  # Should find the test task
```

## YAML Frontmatter Reference

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Task ID in format `v.{version}+task.{number}` |
| `status` | enum | One of: `pending`, `in-progress`, `done`, `blocked` |
| `priority` | enum | One of: `high`, `medium`, `low` |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `estimate` | string | Time estimate (e.g., `2h`, `1d`) |
| `dependencies` | array | Task IDs this task depends on |
| `parent` | string | Parent task number for subtasks |
| `subtasks` | array | Child task numbers for orchestrators |
| `worktree` | object | Worktree metadata if task uses worktree |

### Status Values

- `pending` - Not started
- `in-progress` - Currently being worked on
- `done` - Completed
- `blocked` - Cannot proceed due to external blocker

## Common Patterns

### Testing Task Selection

```bash
# Verify ace-taskflow can find the task
ace-task show 001
# Should output task details

# Verify task file path
ace-task show 001 --path
# Should output: .ace-taskflow/v.test/tasks/001-feature/001-test-task.s.md
```

### Testing Status Updates

```bash
# Create task in pending state
# ... create task fixture ...

# Mark as in-progress
ace-task start 001
# Verify status changed

# Mark as done
ace-task done 001
# Verify status changed
```

### Testing Worktree Integration

```bash
# Create task with worktree metadata
# ... create task fixture with worktree ...

# Create corresponding worktree
git worktree add "../project-task.001" -b 001-test-task

# Verify worktree detection
ace-git-worktree list
```
