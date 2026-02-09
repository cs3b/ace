---
test-id: MT-WORKTREE-001
title: Basic Worktree Lifecycle
area: git-worktree
package: ace-git-worktree
priority: high
duration: ~15min
automation-candidate: true
requires:
  tools: [git, ace-git-worktree]
last-verified: null
verified-by: null
---

# Basic Worktree Lifecycle

## Objective

Verify core git worktree operations (list, create, switch, remove, prune) work correctly through the ace-git-worktree CLI. Tests use a temporary isolated git repository.

## Prerequisites

- Git installed
- ace-git-worktree package available in PATH
- Write access to .cache directory

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-worktree"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
WORKTREES_ROOT="$TEST_DIR/worktrees"
mkdir -p "$TEST_DIR" "$WORKTREES_ROOT"

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Create an isolated git repository for testing
REPO_DIR="$TEST_DIR/test-repo"
mkdir -p "$REPO_DIR"
cd "$REPO_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Create initial commit on main branch
echo "# Test Repository" > README.md
git add README.md
git commit -m "Initial commit" --quiet

echo "=== Environment Setup Complete ==="
echo "Test directory: $TEST_DIR"
echo "Repository: $REPO_DIR"
echo "Worktrees root: $WORKTREES_ROOT"
pwd
git branch -a
echo "=================================="

# === SANDBOX ISOLATION CHECKPOINT ===
echo "=== SANDBOX ISOLATION CHECK ==="
CURRENT_DIR="$(pwd)"
if [[ "$CURRENT_DIR" == *".cache/ace-test-e2e/"* ]]; then
  echo "PASS: Working directory is inside sandbox"
else
  echo "FAIL: NOT in sandbox! Current: $CURRENT_DIR"
  exit 1
fi
if git rev-parse --git-dir >/dev/null 2>&1; then
  REMOTES=$(git remote -v 2>/dev/null)
  if [ -z "$REMOTES" ]; then
    echo "PASS: No git remotes (isolated repo)"
  else
    echo "FAIL: Git remotes found - NOT isolated!"
    exit 1
  fi
else
  echo "PASS: No git repo in sandbox (tools use PROJECT_ROOT_PATH)"
fi
if [ -f "CLAUDE.md" ] || [ -f "Gemfile" ] || [ -d ".ace-taskflow" ]; then
  echo "FAIL: Main project markers found!"
  exit 1
else
  echo "PASS: No main project markers"
fi
echo "=== ISOLATION VERIFIED ==="
```

## Test Data

```bash
ace-test-e2e-sh "$REPO_DIR" bash << 'SANDBOX'
# Create a feature branch for worktree testing
git checkout -b feature/test-worktree --quiet
echo "Feature content" > feature.txt
git add feature.txt
git commit -m "Add feature content" --quiet

# Return to main branch
git checkout main --quiet

# Create another branch for multi-worktree testing
git checkout -b bugfix/test-fix --quiet
echo "Bugfix content" > bugfix.txt
git add bugfix.txt
git commit -m "Add bugfix content" --quiet

# Return to main
git checkout main --quiet

echo "=== Test Branches Created ==="
git branch -a
echo "============================="
SANDBOX
```

## Test Cases

### TC-001: List Existing Worktrees

**Objective:** Verify that `ace-git-worktree list` shows the main worktree.

**Steps:**
1. List worktrees in a fresh repository
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree list
   ```

**Expected:**
- Exit code: 0
- Output shows the main worktree (current directory)
- Shows branch name (main)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Create Worktree from Branch

**Objective:** Verify worktree creation from an existing branch.

**Steps:**
1. Create worktree from the feature branch
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree create feature/test-worktree --path "$WORKTREES_ROOT/feature-wt"
   ```

2. Verify worktree was created
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   test -d "$WORKTREES_ROOT/feature-wt" && echo "Directory exists - PASS"
   test -f "$WORKTREES_ROOT/feature-wt/feature.txt" && echo "Feature file exists - PASS"
   SANDBOX
   ```

3. List worktrees to confirm
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree list
   ```

**Expected:**
- Exit code: 0
- Worktree directory created at specified path
- Feature file present in worktree
- List shows both main and feature worktrees

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Create Worktree with New Branch

**Objective:** Verify worktree creation with a new branch using --from.

**Steps:**
1. Create worktree with new branch from main
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree create new-feature --from main --path "$WORKTREES_ROOT/new-feature-wt"
   ```

2. Verify worktree and branch
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   test -d "$WORKTREES_ROOT/new-feature-wt" && echo "Directory exists - PASS"
   cd "$WORKTREES_ROOT/new-feature-wt"
   git branch --show-current
   SANDBOX
   ```

3. Confirm branch tracks from main
   ```bash
   ace-test-e2e-sh "$WORKTREES_ROOT/new-feature-wt" git log --oneline -1
   ```

**Expected:**
- Exit code: 0
- Worktree directory created
- New branch "new-feature" exists
- Branch started from main's commit

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Switch to Worktree

**Objective:** Verify switching to a worktree returns its path.

**Steps:**
1. Get worktree path for feature branch
   ```bash
   ace-test-e2e-sh "$REPO_DIR" bash << 'SANDBOX'
   SWITCH_PATH=$(ace-git-worktree switch feature/test-worktree)
   echo "Switch path: $SWITCH_PATH"
   SANDBOX
   ```

2. Verify path is correct
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   test "$SWITCH_PATH" = "$WORKTREES_ROOT/feature-wt" && echo "Path matches - PASS"
   SANDBOX
   ```

3. Verify we can use the path to navigate
   ```bash
   ace-test-e2e-sh "$WORKTREES_ROOT/feature-wt" git branch --show-current
   ```

**Expected:**
- Exit code: 0
- Returns full path to the worktree
- Path is the feature worktree location
- Can navigate to returned path

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: List with Format Options

**Objective:** Verify list command format options work correctly.

**Steps:**
1. List worktrees in table format (default)
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree list --format table
   ```

2. List worktrees in JSON format
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree list --format json
   ```

3. List worktrees in simple format
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree list --format simple
   ```

**Expected:**
- Table format: Shows columns with branch, path, status
- JSON format: Valid JSON array with worktree objects
- Simple format: One path per line

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Remove Worktree

**Objective:** Verify worktree removal works correctly.

**Steps:**
1. First confirm the worktree exists
   ```bash
   ace-test-e2e-sh "$REPO_DIR" bash << 'SANDBOX'
   ace-git-worktree list | grep feature/test-worktree
   SANDBOX
   ```

2. Remove the feature worktree
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree remove feature/test-worktree
   ```

3. Verify worktree was removed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   test ! -d "$WORKTREES_ROOT/feature-wt" && echo "Directory removed - PASS"
   ace-git-worktree list | grep -v feature/test-worktree && echo "Not in list - PASS"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Worktree directory removed
- No longer appears in worktree list

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Remove with --dry-run

**Objective:** Verify --dry-run shows what would be removed without removing.

**Steps:**
1. Dry-run removal of the new-feature worktree
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree remove new-feature --dry-run
   ```

2. Verify worktree still exists
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   test -d "$WORKTREES_ROOT/new-feature-wt" && echo "Directory still exists - PASS"
   ace-git-worktree list | grep new-feature && echo "Still in list - PASS"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output indicates what would be removed
- Worktree directory still exists
- Still appears in worktree list

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Prune Orphaned Worktrees (Dry Run)

**Objective:** Verify prune command runs successfully in dry-run mode.

**Steps:**
1. Create an orphaned worktree scenario
   ```bash
   ace-test-e2e-sh "$REPO_DIR" bash << 'SANDBOX'
   # Manually delete a worktree directory (simulating orphaned state)
   rm -rf "$WORKTREES_ROOT/new-feature-wt"
   SANDBOX
   ```

2. Run prune with dry-run
   ```bash
   ace-test-e2e-sh "$REPO_DIR" bash << 'SANDBOX'
   ace-git-worktree prune --dry-run
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   SANDBOX
   ```

3. Verify command completed
   ```bash
   ace-test-e2e-sh "$REPO_DIR" bash << 'SANDBOX'
   # Note: Git 2.50+ auto-cleans metadata on directory deletion, so prune may find no orphans
   # The important thing is the command runs successfully
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Prune dry-run completed" || echo "FAIL: Prune failed"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Prune command completes successfully
- No actual pruning occurs (dry-run mode)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Prune Cleanup

**Objective:** Verify prune command cleans up orphaned entries.

**Steps:**
1. Run prune to clean up
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree prune
   ```

2. Verify cleanup
   ```bash
   ace-test-e2e-sh "$REPO_DIR" bash << 'SANDBOX'
   ace-git-worktree list
   # Orphaned entry should be removed from list
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Orphaned worktree entry removed from git metadata
- List shows only valid worktrees

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-010: Create with --dry-run

**Objective:** Verify create --dry-run shows what would be created without creating.

**Steps:**
1. Dry-run worktree creation
   ```bash
   ace-test-e2e-sh "$REPO_DIR" ace-git-worktree create bugfix/test-fix --path "$WORKTREES_ROOT/bugfix-wt" --dry-run
   ```

2. Verify nothing was created
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   test ! -d "$WORKTREES_ROOT/bugfix-wt" && echo "Directory not created - PASS"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output shows what would be created
- No directory actually created

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: List shows main worktree in fresh repository
- [ ] TC-002: Create worktree from existing branch works
- [ ] TC-003: Create worktree with new branch from --from works
- [ ] TC-004: Switch returns correct worktree path
- [ ] TC-005: List format options (table, json, simple) all work
- [ ] TC-006: Remove worktree deletes directory and metadata
- [ ] TC-007: Remove --dry-run shows but doesn't delete
- [ ] TC-008: Prune --dry-run identifies orphaned worktrees
- [ ] TC-009: Prune cleans up orphaned entries
- [ ] TC-010: Create --dry-run shows but doesn't create

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Tests use an isolated git repository to avoid affecting real projects
- Each test case is designed to be run sequentially (some depend on previous setup)
- The worktrees root directory keeps worktrees separate from the main repo
- Prune tests require manually creating orphaned state by deleting directories
