---
test-id: MT-COMMIT-003
title: Deleted and Renamed File Handling
area: git-commit
package: ace-git-commit
priority: critical
duration: ~10min
automation-candidate: true
requires:
  tools: [git, ace-git-commit]
  ruby: ">= 3.0"
related-task: 220
last-verified: null
verified-by: null
---

# Deleted and Renamed File Handling

## Objective

Verify that ace-git-commit correctly handles deleted and renamed files. This test validates the Task 220 fix for path validation issues when files no longer exist at their original location.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-commit"
SHORT_ID="mt003"
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
# Create initial structure and commit
cat > README.md << 'EOF'
# Test Repository
EOF

cat > old_name.rb << 'EOF'
# frozen_string_literal: true

class OldName
  def hello
    "Hello from old name"
  end
end
EOF

cat > to_delete.rb << 'EOF'
# frozen_string_literal: true

class ToDelete
  def goodbye
    "This file will be deleted"
  end
end
EOF

cat > keeper.rb << 'EOF'
# frozen_string_literal: true

class Keeper
  def stay
    "This file stays and gets modified"
  end
end
EOF

# Initial commit
git add .
git commit -m "Initial commit with test files"
SANDBOX
```

## Test Cases

### TC-001: Commit Deleted File

**Objective:** Verify that ace-git-commit correctly handles committing a deleted file.

**Steps:**
1. Delete the file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" rm to_delete.rb
   ```

2. Verify git shows deletion
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
   ```

3. Commit the deletion
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit to_delete.rb -m "Remove deprecated ToDelete class"
   ```

4. Verify commit contains deletion
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git show --stat HEAD
   git log --oneline -1
SANDBOX
   ```

5. Verify file no longer exists and is not tracked
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ ! -f to_delete.rb ] && echo "PASS: File deleted" || echo "FAIL: File exists"
   git ls-files | grep -q "to_delete.rb" && echo "FAIL: Still tracked" || echo "PASS: Not tracked"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Commit shows deletion of to_delete.rb
- File no longer exists in working directory
- File no longer tracked by git

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Commit Renamed File

**Objective:** Verify that ace-git-commit correctly handles committing a renamed file.

**Steps:**
1. Rename the file using git mv
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git mv old_name.rb new_name.rb
   ```

2. Verify git shows rename
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
   ```

3. Commit the rename (both paths are staged after git mv)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit --only-staged -m "Rename OldName to NewName"
   ```

4. Verify commit contains rename
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git show --stat HEAD
   git log --oneline -1
SANDBOX
   ```

5. Verify rename completed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f new_name.rb ] && echo "PASS: New file exists" || echo "FAIL: New file missing"
   [ ! -f old_name.rb ] && echo "PASS: Old file removed" || echo "FAIL: Old file exists"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Commit shows rename from old_name.rb to new_name.rb
- new_name.rb exists
- old_name.rb no longer exists

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Commit Mixed Changes (Deleted + Modified)

**Objective:** Verify that ace-git-commit correctly handles a mix of deleted and modified files in one commit.

**Steps:**
1. Create a new file and delete another
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > new_file.rb << 'EOF'
# frozen_string_literal: true

class NewFile
  def created
    "This is a new file"
  end
end
EOF

   # Modify existing file
   cat >> keeper.rb << 'EOF'

  def also_stay
    "Added method"
  end
EOF

   # Create another file to delete later
   cat > temporary.rb << 'EOF'
# frozen_string_literal: true

class Temporary
  def temp
    "Temporary file"
  end
end
EOF
SANDBOX
   ```

2. Stage and commit setup files
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git add new_file.rb keeper.rb temporary.rb
   git commit -m "Add files for mixed test"
SANDBOX
   ```

3. Delete temporary.rb and modify keeper.rb
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   rm temporary.rb
   cat >> keeper.rb << 'EOF'

  def final_method
    "Final addition"
  end
EOF
SANDBOX
   ```

4. Verify git status shows both changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
   ```

5. Commit both changes together
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit temporary.rb keeper.rb -m "Remove temporary file and update keeper"
   ```

6. Verify commit contains both changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git show --stat HEAD
   ```

7. Verify final state
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ ! -f temporary.rb ] && echo "PASS: Temp file deleted" || echo "FAIL: Temp file exists"
   grep -q "final_method" keeper.rb && echo "PASS: Keeper modified" || echo "FAIL: Keeper not modified"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Commit contains deletion of temporary.rb AND modification of keeper.rb
- temporary.rb no longer exists
- keeper.rb contains the new method

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Commit Using --only-staged with Deleted File

**Objective:** Verify that --only-staged flag works correctly with deleted files.

**Steps:**
1. Create and commit a file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > staged_delete.rb << 'EOF'
# frozen_string_literal: true

class StagedDelete
  def hello
    "To be staged and deleted"
  end
end
EOF
   git add staged_delete.rb
   git commit -m "Add file for staged delete test"
SANDBOX
   ```

2. Delete and stage the deletion
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   rm staged_delete.rb
   git add staged_delete.rb
SANDBOX
   ```

3. Create an unstaged change
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash -c 'echo "# Unstaged comment" >> keeper.rb'
   ```

4. Verify staged vs unstaged
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git status --porcelain
   ```

5. Commit only staged changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -s -m "Remove staged_delete.rb"
   ```

6. Verify only staged change was committed
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git show --stat HEAD
   ```

7. Verify unstaged change remains
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git diff --name-only
   ```

**Expected:**
- Exit code: 0
- Commit contains only staged_delete.rb deletion
- keeper.rb modification remains as unstaged change

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

- [ ] TC-001: Deleted file commits successfully
- [ ] TC-002: Renamed file commits successfully
- [ ] TC-003: Mixed deleted and modified files commit together
- [ ] TC-004: --only-staged works with deleted files

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Task 220 fixed path validation that incorrectly required files to exist on disk
- Deleted files should be validated against git status, not filesystem
- Renamed files may appear as delete + add or as a rename depending on similarity
- The -s/--only-staged flag should respect staged deletions
