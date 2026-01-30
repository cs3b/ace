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
last-verified: null
verified-by: null
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
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="git-commit"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize test git repo
git init
git config user.email "test@example.com"
git config user.name "Test User"

# Verify tools are available
echo "=== Tool Verification ==="
which git && git --version
which ace-git-commit && ace-git-commit --version
echo "========================="
```

## Test Data

```bash
# Create initial commit to establish repo history
cat > "$TEST_DIR/README.md" << 'EOF'
# Test Repository

This is a test repository for ace-git-commit E2E tests.
EOF

git add README.md
git commit -m "Initial commit"

# Create test files for subsequent tests
cat > "$TEST_DIR/app.rb" << 'EOF'
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

cat > "$TEST_DIR/helper.rb" << 'EOF'
# frozen_string_literal: true

module Helper
  def self.format_message(msg)
    "[INFO] #{msg}"
  end
end
EOF
```

## Test Cases

### TC-001: Commit All Changes with Explicit Message

**Objective:** Verify that ace-git-commit commits all staged changes with a provided message (bypasses LLM).

**Steps:**
1. Stage all new files
   ```bash
   git add app.rb helper.rb
   ```

2. Commit with explicit message using -m flag
   ```bash
   ace-git-commit -m "Add application and helper modules"
   ```

3. Verify commit was created
   ```bash
   git log --oneline -1
   git show --stat HEAD
   ```

4. Verify working directory is clean
   ```bash
   git status --porcelain
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
   cat >> "$TEST_DIR/app.rb" << 'EOF'

  def stop
    puts "Stopping #{@name}"
  end
EOF
   ```

2. Stage changes
   ```bash
   git add app.rb
   ```

3. Commit with intention context (use -m to test the flow without actual LLM)
   ```bash
   ace-git-commit -i "add stop functionality" -m "feat(app): add stop method to Application class"
   ```

4. Verify commit
   ```bash
   git log --oneline -1
   git show --stat HEAD
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
   cat >> "$TEST_DIR/helper.rb" << 'EOF'

  def self.debug(msg)
    "[DEBUG] #{msg}"
  end
EOF
   ```

2. Stage changes
   ```bash
   git add helper.rb
   ```

3. Record current HEAD
   ```bash
   BEFORE_HEAD=$(git rev-parse HEAD)
   ```

4. Run dry-run
   ```bash
   ace-git-commit -n -m "Add debug helper method"
   ```

5. Verify HEAD unchanged
   ```bash
   AFTER_HEAD=$(git rev-parse HEAD)
   [ "$BEFORE_HEAD" = "$AFTER_HEAD" ] && echo "PASS: HEAD unchanged" || echo "FAIL: HEAD changed"
   ```

6. Verify changes still staged
   ```bash
   git diff --cached --name-only
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
   cat > "$TEST_DIR/to_move.rb" << 'EOF'
# frozen_string_literal: true

class ToMove
  def location
    "Will be moved"
  end
end
EOF

   cat > "$TEST_DIR/to_delete.rb" << 'EOF'
# frozen_string_literal: true

class ToDelete
  def status
    "Will be deleted"
  end
end
EOF
   git add .
   git commit -m "Add files for move/delete test"
   ```

2. Move one file and delete another
   ```bash
   mkdir -p "$TEST_DIR/lib"
   git mv to_move.rb lib/moved.rb
   git rm to_delete.rb
   ```

3. Verify git shows both changes
   ```bash
   git status --porcelain
   git diff --cached --name-only --no-renames
   # Should show: lib/moved.rb, to_delete.rb, to_move.rb
   ```

4. Commit with ace-git-commit
   ```bash
   ace-git-commit -m "Refactor: move file to lib and remove unused file"
   ```

5. Verify all changes were committed
   ```bash
   git log --oneline -1
   git show --stat HEAD
   ```

6. Verify files are in expected state
   ```bash
   [ ! -f "$TEST_DIR/to_move.rb" ] && echo "PASS: Source file removed" || echo "FAIL: Source still exists"
   [ ! -f "$TEST_DIR/to_delete.rb" ] && echo "PASS: Deleted file removed" || echo "FAIL: Deleted file still exists"
   [ -f "$TEST_DIR/lib/moved.rb" ] && echo "PASS: File moved to lib/" || echo "FAIL: Moved file missing"
   ```

7. Verify working directory is clean
   ```bash
   UNCOMMITTED=$(git status --porcelain)
   [ -z "$UNCOMMITTED" ] && echo "PASS: All changes committed" || echo "FAIL: Uncommitted: $UNCOMMITTED"
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
