---
test-id: MT-COMMIT-001
title: Basic Commit Workflow
area: git-commit
package: ace-git-commit
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [git, ace-git-commit]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Basic Commit Workflow

## Objective

Verify that ace-git-commit correctly executes the full commit cycle in a real git repository. Tests cover committing with explicit messages, intention context for LLM, and dry-run mode.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-commit"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Initialize test git repo
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Verify tools are available
echo "=== Tool Verification ==="
which git && git --version
which ace-git-commit && ace-git-commit --version
echo "========================="

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
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Create initial commit to establish repo history
cat > README.md << 'EOF'
# Test Repository

This is a test repository for ace-git-commit E2E tests.
EOF

git add README.md
git commit -m "Initial commit"

# Create test files for subsequent tests
cat > app.rb << 'EOF'
# frozen_string_literal: true

class Application
  def initialize(name)
    @name = name
  end

  def run
    puts "Running #{@name}"
  end
end
EOF

cat > helper.rb << 'EOF'
# frozen_string_literal: true

module Helper
  def self.format_message(msg)
    "[INFO] #{msg}"
  end
end
EOF
SANDBOX
```

## Test Cases

### TC-001: Commit All Changes with Explicit Message

**Objective:** Verify that ace-git-commit commits all staged changes with a provided message (bypasses LLM).

**Steps:**
1. Stage all new files
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git add app.rb helper.rb
   ```

2. Commit with explicit message using -m flag
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -m "Add application and helper modules"
   ```

3. Verify commit was created
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git log --oneline -1
   git show --stat HEAD
SANDBOX
   ```

4. Verify working directory is clean
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
   ```

**Expected:**
- Exit code: 0
- Commit created with message "Add application and helper modules"
- Both app.rb and helper.rb appear in commit
- Working directory shows no pending changes

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Commit with Intention Context

**Objective:** Verify that ace-git-commit uses intention context for LLM message generation.

**Steps:**
1. Modify an existing file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> app.rb << 'EOF'

  def stop
    puts "Stopping #{@name}"
  end
EOF
SANDBOX
   ```

2. Stage changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git add app.rb
   ```

3. Commit with intention context (use -m to test the flow without actual LLM)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -i "add stop functionality" -m "feat(app): add stop method to Application class"
   ```

4. Verify commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git log --oneline -1
   git show --stat HEAD
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Commit created successfully
- Only app.rb changes appear in commit
- Intention context accepted (no errors about -i flag)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Dry-Run Mode

**Objective:** Verify that dry-run mode shows planned changes without actually committing.

**Steps:**
1. Make a modification
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> helper.rb << 'EOF'

  def self.debug(msg)
    "[DEBUG] #{msg}"
  end
EOF
SANDBOX
   ```

2. Stage changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git add helper.rb
   ```

3. Record current HEAD
   ```bash
   BEFORE_HEAD=$(ace-test-e2e-sh "$TEST_DIR" git rev-parse HEAD)
   ```

4. Run dry-run
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -n -m "Add debug helper method"
   ```

5. Verify HEAD unchanged
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   AFTER_HEAD=$(git rev-parse HEAD)
   [ "$BEFORE_HEAD" = "$AFTER_HEAD" ] && echo "PASS: HEAD unchanged" || echo "FAIL: HEAD changed"
SANDBOX
   ```

6. Verify changes still staged
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git diff --cached --name-only
   ```

**Expected:**
- Exit code: 0
- Dry-run output shows what would be committed
- HEAD remains unchanged (no new commit)
- Changes remain staged

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Commit File Moves and Deletions

**Objective:** Verify that ace-git-commit correctly commits file moves (renames) and deletions, ensuring both the deleted source and added destination paths are included.

**Background:** Git's rename detection can collapse a file move into a single "rename" entry. The `--no-renames` flag ensures both the deletion and addition are tracked separately, preventing silent exclusion of deleted files.

**Steps:**
1. Create files to move and delete
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > to_move.rb << 'EOF'
# frozen_string_literal: true

class ToMove
  def location
    "Will be moved"
  end
end
EOF

   cat > to_delete.rb << 'EOF'
# frozen_string_literal: true

class ToDelete
  def status
    "Will be deleted"
  end
end
EOF
   git add .
   git commit -m "Add files for move/delete test"
SANDBOX
   ```

2. Move one file and delete another
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p lib
   git mv to_move.rb lib/moved.rb
   git rm to_delete.rb
SANDBOX
   ```

3. Verify git shows both changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git status --porcelain
   git diff --cached --name-only --no-renames
   # Should show: lib/moved.rb, to_delete.rb, to_move.rb
SANDBOX
   ```

4. Commit with ace-git-commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -m "Refactor: move file to lib and remove unused file"
   ```

5. Verify all changes were committed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git log --oneline -1
   git show --stat HEAD
SANDBOX
   ```

6. Verify files are in expected state
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ ! -f to_move.rb ] && echo "PASS: Source file removed" || echo "FAIL: Source still exists"
   [ ! -f to_delete.rb ] && echo "PASS: Deleted file removed" || echo "FAIL: Deleted file still exists"
   [ -f lib/moved.rb ] && echo "PASS: File moved to lib/" || echo "FAIL: Moved file missing"
SANDBOX
   ```

7. Verify working directory is clean
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   UNCOMMITTED=$(git status --porcelain)
   [ -z "$UNCOMMITTED" ] && echo "PASS: All changes committed" || echo "FAIL: Uncommitted: $UNCOMMITTED"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- All file changes committed:
  - to_move.rb deletion committed
  - lib/moved.rb addition committed
  - to_delete.rb deletion committed
- Working directory clean after commit

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

- [ ] TC-001: Commit all changes with explicit message succeeds
- [ ] TC-002: Commit with intention context accepted
- [ ] TC-003: Dry-run mode shows changes without committing
- [ ] TC-004: Commit file moves and deletions correctly

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Tests use -m flag to provide explicit messages and avoid LLM calls during testing
- TC-002 combines -i and -m flags; in production use, -i would influence LLM generation
- Dry-run mode is useful for CI/CD pipelines to validate commit readiness
