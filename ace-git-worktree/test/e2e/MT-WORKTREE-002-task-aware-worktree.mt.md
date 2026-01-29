---
test-id: MT-WORKTREE-002
title: Task-Aware Worktree Creation
area: git-worktree
package: ace-git-worktree
priority: high
duration: ~20min
automation-candidate: false
requires:
  tools: [git, ace-git-worktree, ace-taskflow]
  files: [.ace-taskflow/]
last-verified: null
verified-by: null
---

# Task-Aware Worktree Creation

## Objective

Verify task-integrated worktree creation works correctly with ace-taskflow integration. Tests include creating worktrees for tasks, task status updates, and task association tracking.

## Prerequisites

- Git installed
- ace-git-worktree package available in PATH
- ace-taskflow package available in PATH
- ace-timestamp tool available
- Write access to .cache directory

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-ace-git-worktree-MT-WORKTREE-002"
WORKTREES_ROOT="$TEST_DIR/worktrees"
mkdir -p "$TEST_DIR" "$WORKTREES_ROOT"

# Create an isolated git repository with taskflow structure
REPO_DIR="$TEST_DIR/test-repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR"

git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Create initial commit on main branch
echo "# Test Repository" > README.md
git add README.md
git commit -m "Initial commit" --quiet

# Create worktree root directory (required by ace-git-worktree)
mkdir -p .ace-wt

echo "=== Environment Setup Complete ==="
echo "Test directory: $TEST_DIR"
echo "Repository: $REPO_DIR"
echo "Worktrees root: $WORKTREES_ROOT"
echo "=================================="
```

## Test Data

```bash
cd "$REPO_DIR"

# Create .ace-taskflow directory structure with release directory
mkdir -p .ace-taskflow/v.test/tasks/999-test-feature
mkdir -p .ace-taskflow/v.test/tasks/888-second-task

# Create task 999 with proper .s.md format and YAML frontmatter
cat > .ace-taskflow/v.test/tasks/999-test-feature/999-test-feature.s.md << 'EOF'
---
id: v.test+task.999
status: draft
priority: medium
estimate: 2h
---

# Test Feature Implementation

A test feature for E2E testing of task-aware worktrees.

## Acceptance Criteria

- [ ] Test worktree creation works
- [ ] Test status updates work
EOF

# Create task 888 with proper .s.md format
cat > .ace-taskflow/v.test/tasks/888-second-task/888-second-task.s.md << 'EOF'
---
id: v.test+task.888
status: draft
priority: high
estimate: 1h
---

# Second Test Task

A second test task for multi-task scenarios.
EOF

# Add and commit the taskflow structure
git add .ace-taskflow/
git commit -m "Add ace-taskflow structure with test tasks" --quiet

# Create taskflow config (required: default task_dir is "t", we use "tasks")
mkdir -p .ace/taskflow
cat > .ace/taskflow/config.yml << 'EOF'
taskflow:
  root: ".ace-taskflow"
  directories:
    tasks: "tasks"
EOF
git add .ace/
git commit -m "Add taskflow config" --quiet

# IMPORTANT: Set PROJECT_ROOT_PATH for isolated testing
# This ensures ace-* commands use the isolated repo, not the main project
export PROJECT_ROOT_PATH="$REPO_DIR"

echo "=== Test Tasks Created ==="
find .ace-taskflow -name "*.s.md" -type f
echo "=========================="
```

## Test Cases

### TC-001: Create Worktree for Task (Dry Run)

**Objective:** Verify task-aware worktree creation shows correct plan in dry-run mode.

**Steps:**
1. Run task worktree creation with dry-run
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree create --task 999 --dry-run --no-push --no-pr --no-commit
   ```

**Expected:**
- Exit code: 0
- Output shows planned branch name (includes task ID)
- Output shows planned worktree path
- No actual worktree created

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Create Worktree for Task

**Objective:** Verify worktree creation for a task ID creates correct structure.

**Steps:**
1. Create worktree for task 999
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree create --task 999 --no-push --no-pr --no-commit --no-auto-navigate
   ```

2. Verify worktree was created
   ```bash
   ace-git-worktree list --show-tasks
   ```

3. Check branch name contains task ID
   ```bash
   ace-git-worktree list --format json | grep -o '"branch":"[^"]*999[^"]*"'
   ```

**Expected:**
- Exit code: 0
- Worktree created with branch containing task ID "999"
- Worktree appears in list with task association
- Branch name follows convention (e.g., 999-test-feature-implementation)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: List Worktrees with Task Associations

**Objective:** Verify list --show-tasks displays task information.

**Steps:**
1. List worktrees with task info
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree list --show-tasks
   ```

2. Verify task-associated filter works
   ```bash
   ace-git-worktree list --task-associated
   ```

3. Verify non-task filter works
   ```bash
   ace-git-worktree list --no-task-associated
   ```

**Expected:**
- --show-tasks: Shows task ID alongside worktree info
- --task-associated: Shows only task-linked worktrees
- --no-task-associated: Shows only non-task worktrees (main)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Switch to Task Worktree by Task ID

**Objective:** Verify switching by task ID returns correct path.

**Steps:**
1. Get worktree path by task ID
   ```bash
   cd "$REPO_DIR"
   TASK_PATH=$(ace-git-worktree switch 999)
   echo "Task worktree path: $TASK_PATH"
   ```

2. Verify path exists and contains task files
   ```bash
   test -d "$TASK_PATH" && echo "Path exists - PASS"
   test -d "$TASK_PATH/.ace-taskflow" && echo "Taskflow dir exists - PASS"
   ```

**Expected:**
- Exit code: 0
- Returns path to task 999's worktree
- Path contains .ace-taskflow directory

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Create Second Task Worktree

**Objective:** Verify multiple task worktrees can coexist.

**Steps:**
1. Create worktree for task 888
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree create --task 888 --no-push --no-pr --no-commit --no-auto-navigate
   ```

2. List all task-associated worktrees
   ```bash
   ace-git-worktree list --task-associated --format table
   ```

3. Verify both tasks have worktrees
   ```bash
   ace-git-worktree list --task-associated --format json | grep -c '"task":'
   ```

**Expected:**
- Exit code: 0
- Both task 999 and 888 have worktrees
- List shows two task-associated worktrees

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Search Worktrees by Pattern

**Objective:** Verify search filter works with task branch names.

**Steps:**
1. Search for worktrees containing "999"
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree list --search 999
   ```

2. Search for worktrees containing "test"
   ```bash
   ace-git-worktree list --search test
   ```

**Expected:**
- Search "999": Returns only task 999 worktree
- Search "test": Returns both task worktrees (both have "test" in name)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Remove Task Worktree by Task ID

**Objective:** Verify task worktree removal using --task flag.

**Steps:**
1. Remove task 888's worktree
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree remove --task 888
   ```

2. Verify removal
   ```bash
   ace-git-worktree list --task-associated | grep -v 888 && echo "Task 888 removed - PASS"
   ```

3. Verify task 999 still exists
   ```bash
   ace-git-worktree list --task-associated | grep 999 && echo "Task 999 still exists - PASS"
   ```

**Expected:**
- Exit code: 0
- Task 888 worktree removed
- Task 999 worktree unaffected

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: JSON Output Contains Task Metadata

**Objective:** Verify JSON format includes task-related fields.

**Steps:**
1. Get JSON output with task info
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree list --show-tasks --format json
   ```

2. Parse for task fields
   ```bash
   ace-git-worktree list --show-tasks --format json | python3 -c "
import sys, json
data = json.load(sys.stdin)
for wt in data:
    if wt.get('task'):
        print(f\"Task: {wt['task']}, Branch: {wt['branch']}\")
"
   ```

**Expected:**
- JSON contains task field for task-associated worktrees
- Task field contains task ID
- Non-task worktrees have null/missing task field

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Remove Task Worktree with --delete-branch

**Objective:** Verify task worktree removal also deletes branch when requested.

**Steps:**
1. Check branch exists before removal
   ```bash
   cd "$REPO_DIR"
   git branch -a | grep 999 && echo "Branch exists - SETUP OK"
   ```

2. Remove worktree with branch deletion
   ```bash
   ace-git-worktree remove --task 999 --delete-branch
   ```

3. Verify branch was also deleted
   ```bash
   git branch -a | grep -v 999 && echo "Branch deleted - PASS"
   ```

**Expected:**
- Exit code: 0
- Worktree removed
- Associated branch also deleted

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: Verify Clean State After Removal

**Objective:** Verify all task worktrees removed and clean state.

**Steps:**
1. List all worktrees
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree list
   ```

2. Verify no task-associated worktrees remain
   ```bash
   COUNT=$(ace-git-worktree list --task-associated --format simple | wc -l)
   test "$COUNT" -eq 0 && echo "No task worktrees remain - PASS"
   ```

3. Verify main worktree still exists
   ```bash
   ace-git-worktree list | grep main && echo "Main worktree exists - PASS"
   ```

**Expected:**
- No task-associated worktrees in list
- Main worktree still present and functional

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-011: Current Branch Fallback When Parent Has No Worktree

**Objective:** Verify target_branch uses current branch when parent task has no worktree metadata.

**Steps:**
1. Create a parent task without worktree metadata
   ```bash
   cd "$REPO_DIR"
   mkdir -p .ace-taskflow/v.test/tasks/777-parent-no-worktree

   # Create parent task 777 (orchestrator) with no worktree metadata
   cat > .ace-taskflow/v.test/tasks/777-parent-no-worktree/777.00-parent-no-worktree.s.md << 'EOF'
---
id: v.test+task.777
status: in_progress
priority: medium
---

# Parent Without Worktree

This orchestrator has no worktree metadata.
EOF

   # Create subtask 777.01
   cat > .ace-taskflow/v.test/tasks/777-parent-no-worktree/777.01-subtask.s.md << 'EOF'
---
id: v.test+task.777.01
status: draft
priority: medium
parent: v.test+task.777
---

# Subtask Under Parent Without Worktree

Feature subtask for testing current branch fallback.
EOF

   git add .ace-taskflow/
   git commit -m "Add parent task without worktree and subtask" --quiet
   ```

2. Create a feature branch to simulate current working branch
   ```bash
   git checkout -b 777-feature-branch
   echo "Feature work" >> README.md
   git add README.md
   git commit -m "Feature work on 777" --quiet
   ```

3. Create worktree for subtask from the feature branch
   ```bash
   ace-git-worktree create --task 777.01 --no-push --no-pr --no-commit --no-auto-navigate --dry-run 2>&1
   ```

**Expected:**
- Dry-run output shows target_branch as "777-feature-branch" (current branch)
- NOT "main" as fallback

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
test ! -d "$TEST_DIR" && echo "Cleanup verified - PASS" || echo "Cleanup failed - FAIL"
```

## Success Criteria

- [ ] TC-001: Dry-run shows correct task worktree plan
- [ ] TC-002: Task worktree creation with correct branch naming
- [ ] TC-003: List filtering by task association works
- [ ] TC-004: Switch by task ID returns correct path
- [ ] TC-005: Multiple task worktrees can coexist
- [ ] TC-006: Search filter works with task patterns
- [ ] TC-007: Remove by task ID works correctly
- [ ] TC-008: JSON output includes task metadata
- [ ] TC-009: Remove with --delete-branch cleans up branch
- [ ] TC-010: Clean state after all removals
- [ ] TC-011: Current branch fallback when parent has no worktree

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Tests use --no-push, --no-pr, --no-commit flags to avoid external dependencies
- Tests allow worktree metadata to be written to task files (enables --task lookups)
- Uses --no-auto-navigate to stay in the main repo for subsequent commands
- Worktree metadata in task frontmatter enables `switch --task` and `remove --task` functionality
- Branch naming convention is: {task-id}-{slugified-title}
