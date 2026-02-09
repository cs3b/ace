---
test-id: MT-COMMIT-004d
title: Split Commit - Moves, Deletions, and Glob Arrays
area: git-commit
package: ace-git-commit
priority: high
duration: ~3min
automation-candidate: true
requires:
  tools: [git, ace-git-commit]
  ruby: ">= 3.0"
related-task: 228
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Split Commit - Moves, Deletions, and Glob Arrays

## Objective

Verify that ace-git-commit correctly handles file moves (renames) and deletions across config scopes, and that glob array path rules group matching files from multiple packages into a single commit.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-commit"
SHORT_ID="mt004d"
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
# Create initial structure with two packages
cat > README.md << 'EOF'
# Test Repository

Multi-package repository for testing split commits.
EOF

git add README.md
git commit -m "Initial commit"

mkdir -p pkg-a/.ace/git pkg-b/.ace/git

cat > pkg-a/.ace/git/commit.yml << 'EOF'
model: glite
EOF

cat > pkg-b/.ace/git/commit.yml << 'EOF'
model: gflash
EOF

cat > pkg-a/service.rb << 'EOF'
# frozen_string_literal: true

class ServiceA
  def run
    "Running service A"
  end
end
EOF

cat > pkg-b/service.rb << 'EOF'
# frozen_string_literal: true

class ServiceB
  def run
    "Running service B"
  end
end
EOF

git add .
git commit -m "Add package structure with configs"
SANDBOX
```

## Test Cases

### TC-007: File Moves and Deletions Across Config Scopes

**Objective:** Verify that ace-git-commit correctly picks up file moves (renames) and deletions when they span multiple config scopes.

**Steps:**
1. Create files for move/delete testing and commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > pkg-a/to_move.rb << 'EOF'
# frozen_string_literal: true

class ToMove
  def location
    "Originally in pkg-a"
  end
end
EOF

   cat > pkg-b/to_delete.rb << 'EOF'
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

2. Move file across packages, delete file, and modify existing
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git mv pkg-a/to_move.rb pkg-b/moved_file.rb
   git rm pkg-b/to_delete.rb

   cat >> pkg-a/service.rb << 'EOF'

  def move_delete_test
    "Testing move and delete"
  end
EOF
   git add pkg-a/service.rb

   echo "=== Git status ==="
   git status --porcelain
   echo "=== Staged files (no rename detection) ==="
   git diff --cached --name-only --no-renames
SANDBOX
   ```

3. Run ace-git-commit with dry-run first, then commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -n -m "Test move and delete handling"
   ```

4. Commit and verify all changes captured
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -m "Refactor: move file and clean up"
   ```

5. Verify commits, file states, and no uncommitted changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Check for deletion of pkg-a/to_move.rb ==="
   git log --all --full-history -- pkg-a/to_move.rb | head -5

   echo "=== Check for addition of pkg-b/moved_file.rb ==="
   git log --all --full-history -- pkg-b/moved_file.rb | head -5

   echo "=== Check for deletion of pkg-b/to_delete.rb ==="
   git log --all --full-history -- pkg-b/to_delete.rb | head -5

   [ ! -f pkg-a/to_move.rb ] && echo "PASS: Source file removed" || echo "FAIL: Source still exists"
   [ ! -f pkg-b/to_delete.rb ] && echo "PASS: Deleted file removed" || echo "FAIL: Deleted file still exists"
   [ -f pkg-b/moved_file.rb ] && echo "PASS: Moved file exists at destination" || echo "FAIL: Moved file missing"

   UNCOMMITTED=$(git status --porcelain)
   [ -z "$UNCOMMITTED" ] && echo "PASS: All changes committed" || echo "FAIL: Uncommitted changes: $UNCOMMITTED"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- All file changes committed (no silently dropped files)
- Changes split across config scopes appropriately
- Working directory clean after commit

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Glob Array Groups .ace Folders Across Packages

**Objective:** Verify that a path rule with glob ARRAY correctly groups all `.ace/**` files from multiple packages into a single "ace-config" commit.

**Steps:**
1. Create project config with glob ARRAY and .ace folders in multiple packages
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/git
   cat > .ace/git/commit.yml << 'EOF'
model: glite
paths:
  ace-config:
    glob:
      - ".ace/**"
      - "*/.ace/**"
    type_hint: chore
    description: "All ACE configuration files"
EOF

   mkdir -p pkg-a/.ace/git pkg-b/.ace/git pkg-c/.ace/git

   cat > pkg-a/.ace/git/commit.yml << 'EOF'
model: gflash
EOF

   cat > pkg-b/.ace/git/commit.yml << 'EOF'
model: gpro
EOF

   cat > pkg-c/.ace/git/commit.yml << 'EOF'
model: glite
EOF

   cat > pkg-a/lib.rb << 'EOF'
# frozen_string_literal: true
class LibA; end
EOF

   cat > pkg-b/lib.rb << 'EOF'
# frozen_string_literal: true
class LibB; end
EOF

   git add .
   git commit -m "Add packages with .ace configs"
SANDBOX
   ```

2. Modify .ace config files in root and all packages, plus a non-.ace file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> .ace/git/commit.yml << 'EOF'

# Updated configuration
generation:
  temperature: 0.8
EOF

   cat >> pkg-a/.ace/git/commit.yml << 'EOF'

# Package A specific settings
conventions:
  format: simple
EOF

   cat >> pkg-b/.ace/git/commit.yml << 'EOF'

# Package B specific settings
conventions:
  format: conventional
EOF

   cat >> pkg-c/.ace/git/commit.yml << 'EOF'

# Package C specific settings
type_hint: docs
EOF

   cat >> pkg-a/lib.rb << 'EOF'

  def glob_array_test
    "Testing glob arrays"
  end
EOF
SANDBOX
   ```

3. Verify changes and run ace-git-commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Changed files ==="
   git status --porcelain
   echo "=== .ace files specifically ==="
   git status --porcelain | grep "\.ace/"

   ace-git-commit -m "Update configurations"
SANDBOX
   ```

4. Verify all .ace files grouped in one commit and non-.ace file separated
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Files in HEAD commit ==="
   git show --name-only --format="" HEAD

   echo "=== Files in HEAD~1 commit ==="
   git show --name-only --format="" HEAD~1

   ACE_FILES_HEAD=$(git show --name-only --format="" HEAD | grep -c "\.ace/" || echo 0)
   ACE_FILES_PREV=$(git show --name-only --format="" HEAD~1 | grep -c "\.ace/" || echo 0)

   echo "HEAD has $ACE_FILES_HEAD .ace files"
   echo "HEAD~1 has $ACE_FILES_PREV .ace files"

   if [ "$ACE_FILES_HEAD" -eq 4 ] || [ "$ACE_FILES_PREV" -eq 4 ]; then
     echo "PASS: All .ace files grouped in single commit"
   else
     echo "FAIL: .ace files split across commits"
   fi

   LIB_IN_HEAD=$(git show --name-only --format="" HEAD | grep -c "lib.rb" || echo 0)
   ACE_IN_HEAD=$(git show --name-only --format="" HEAD | grep -c "\.ace/" || echo 0)

   if [ "$LIB_IN_HEAD" -gt 0 ] && [ "$ACE_IN_HEAD" -eq 0 ]; then
     echo "PASS: lib.rb correctly separated from .ace files"
   elif [ "$LIB_IN_HEAD" -eq 0 ] && [ "$ACE_IN_HEAD" -gt 0 ]; then
     echo "PASS: .ace files correctly separated from lib.rb"
   else
     echo "FAIL: lib.rb and .ace files mixed in same commit"
   fi
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Two commits created:
  1. "ace-config" scope: Contains ALL 4 .ace files (root + pkg-a + pkg-b + pkg-c)
  2. Package scope: Contains pkg-a/lib.rb
- Glob array `[".ace/**", "*/.ace/**"]` matches all .ace folders
- No .ace files split across multiple commits

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

- [ ] TC-007: File moves and deletions correctly picked up across scopes
- [ ] TC-008: Glob array groups all .ace folders into single ace-config commit
