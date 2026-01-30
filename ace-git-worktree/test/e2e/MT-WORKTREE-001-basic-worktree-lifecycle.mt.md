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

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="git-worktree"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
WORKTREES_ROOT="$TEST_DIR/worktrees"
mkdir -p "$TEST_DIR" "$WORKTREES_ROOT"

# Create an isolated git repository for testing
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

echo "=== Environment Setup Complete ==="
echo "Test directory: $TEST_DIR"
echo "Repository: $REPO_DIR"
echo "Worktrees root: $WORKTREES_ROOT"
pwd
git branch -a
echo "=================================="
```

## Test Data

```bash
# Create a feature branch for worktree testing
cd "$REPO_DIR"
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
```

## Test Cases

### TC-001: List Existing Worktrees

**Objective:** Verify that `ace-git-worktree list` shows the main worktree.

**Steps:**
1. List worktrees in a fresh repository
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree list
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
   cd "$REPO_DIR"
   ace-git-worktree create feature/test-worktree --path "$WORKTREES_ROOT/feature-wt"
   ```

2. Verify worktree was created
   ```bash
   test -d "$WORKTREES_ROOT/feature-wt" && echo "Directory exists - PASS"
   test -f "$WORKTREES_ROOT/feature-wt/feature.txt" && echo "Feature file exists - PASS"
   ```

3. List worktrees to confirm
   ```bash
   ace-git-worktree list
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
   cd "$REPO_DIR"
   ace-git-worktree create new-feature --from main --path "$WORKTREES_ROOT/new-feature-wt"
   ```

2. Verify worktree and branch
   ```bash
   test -d "$WORKTREES_ROOT/new-feature-wt" && echo "Directory exists - PASS"
   cd "$WORKTREES_ROOT/new-feature-wt"
   git branch --show-current
   ```

3. Confirm branch tracks from main
   ```bash
   git log --oneline -1
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
   cd "$REPO_DIR"
   SWITCH_PATH=$(ace-git-worktree switch feature/test-worktree)
   echo "Switch path: $SWITCH_PATH"
   ```

2. Verify path is correct
   ```bash
   test "$SWITCH_PATH" = "$WORKTREES_ROOT/feature-wt" && echo "Path matches - PASS"
   ```

3. Verify we can use the path to navigate
   ```bash
   cd "$SWITCH_PATH"
   git branch --show-current
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
   cd "$REPO_DIR"
   ace-git-worktree list --format table
   ```

2. List worktrees in JSON format
   ```bash
   ace-git-worktree list --format json
   ```

3. List worktrees in simple format
   ```bash
   ace-git-worktree list --format simple
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
   cd "$REPO_DIR"
   ace-git-worktree list | grep feature/test-worktree
   ```

2. Remove the feature worktree
   ```bash
   ace-git-worktree remove feature/test-worktree
   ```

3. Verify worktree was removed
   ```bash
   test ! -d "$WORKTREES_ROOT/feature-wt" && echo "Directory removed - PASS"
   ace-git-worktree list | grep -v feature/test-worktree && echo "Not in list - PASS"
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
   cd "$REPO_DIR"
   ace-git-worktree remove new-feature --dry-run
   ```

2. Verify worktree still exists
   ```bash
   test -d "$WORKTREES_ROOT/new-feature-wt" && echo "Directory still exists - PASS"
   ace-git-worktree list | grep new-feature && echo "Still in list - PASS"
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

**Objective:** Verify prune command identifies orphaned worktrees.

**Steps:**
1. Create an orphaned worktree scenario
   ```bash
   cd "$REPO_DIR"
   # Manually delete a worktree directory (simulating orphaned state)
   rm -rf "$WORKTREES_ROOT/new-feature-wt"
   ```

2. Run prune with dry-run
   ```bash
   ace-git-worktree prune --dry-run
   ```

3. Verify orphaned worktree detected
   ```bash
   # Output should mention the orphaned worktree
   ```

**Expected:**
- Exit code: 0
- Output identifies orphaned worktree entries
- No actual pruning occurs

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-009: Prune Cleanup

**Objective:** Verify prune command cleans up orphaned entries.

**Steps:**
1. Run prune to clean up
   ```bash
   cd "$REPO_DIR"
   ace-git-worktree prune
   ```

2. Verify cleanup
   ```bash
   ace-git-worktree list
   # Orphaned entry should be removed from list
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
   cd "$REPO_DIR"
   ace-git-worktree create bugfix/test-fix --path "$WORKTREES_ROOT/bugfix-wt" --dry-run
   ```

2. Verify nothing was created
   ```bash
   test ! -d "$WORKTREES_ROOT/bugfix-wt" && echo "Directory not created - PASS"
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
