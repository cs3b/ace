---
test-id: MT-COMMIT-004c
title: Split Commit - Scope Cascade
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

# Split Commit - Scope Cascade

## Objective

Verify that files within a single config scope commit together without splitting, and that config cascade with `.ace-defaults` derives correct scope names from the primary source path.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-commit"
SHORT_ID="mt004c"
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
# Create initial structure
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

### TC-005: Single Config Scope Does Not Split

**Objective:** Verify that files within a single config scope are committed together without splitting.

**Steps:**
1. Create additional file in pkg-a and commit it
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > pkg-a/helper.rb << 'EOF'
# frozen_string_literal: true

class HelperA
  def assist
    "Helper in package A"
  end
end
EOF
   git add pkg-a/helper.rb
   git commit -m "Add helper file"
SANDBOX
   ```

2. Modify multiple files in the same package and commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> pkg-a/service.rb << 'EOF'

  def single_scope_method
    "Same scope test"
  end
EOF

   cat >> pkg-a/helper.rb << 'EOF'

  def additional_help
    "More help"
  end
EOF

   ace-git-commit pkg-a/service.rb pkg-a/helper.rb -m "Update pkg-a files"
SANDBOX
   ```

3. Verify single commit with both files
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git log --oneline -1
   git show --stat HEAD
   FILE_COUNT=$(git show --name-only --format="" HEAD | wc -l | tr -d ' ')
   [ "$FILE_COUNT" -eq 2 ] && echo "PASS: Both files in single commit" || echo "FAIL: Expected 2 files, got $FILE_COUNT"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Single commit created (no splitting)
- Both pkg-a files in the same commit

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Config Cascade with Gem Defaults (Compound Source Path)

**Objective:** Verify that scope derivation works correctly when config sources include cascade paths (e.g., `pkg/.ace/git/commit.yml -> .ace-defaults/git/commit.yml`). The scope derivation must extract only the PRIMARY source to determine the package name.

**Steps:**
1. Create .ace-defaults and two packages with cascade configs
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace-defaults/git
   cat > .ace-defaults/git/commit.yml << 'EOF'
# Gem defaults - simulates ace-git-commit/.ace-defaults
model: glite
conventions:
  format: conventional
EOF

   mkdir -p pkg-alpha/.ace/git pkg-beta/.ace/git

   cat > pkg-alpha/.ace/git/commit.yml << 'EOF'
model: gflash
EOF

   cat > pkg-beta/.ace/git/commit.yml << 'EOF'
model: gpro
EOF

   cat > pkg-alpha/main.rb << 'EOF'
# frozen_string_literal: true

class AlphaMain
  def run
    "Alpha package"
  end
end
EOF

   cat > pkg-beta/main.rb << 'EOF'
# frozen_string_literal: true

class BetaMain
  def run
    "Beta package"
  end
end
EOF

   git add .
   git commit -m "Add packages with cascade configs"
SANDBOX
   ```

2. Modify files in both packages and run ace-git-commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> pkg-alpha/main.rb << 'EOF'

  def cascade_test
    "Testing config cascade"
  end
EOF

   cat >> pkg-beta/main.rb << 'EOF'

  def cascade_test
    "Testing config cascade"
  end
EOF

   ace-git-commit pkg-alpha/main.rb pkg-beta/main.rb -m "Test cascade config"
SANDBOX
   ```

3. Verify two separate commits with correct scope derivation
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Commit 1 (HEAD) scope check ==="
   git show --stat HEAD
   git show --name-only --format="" HEAD | head -1

   echo "=== Commit 2 (HEAD~1) scope check ==="
   git show --stat HEAD~1
   git show --name-only --format="" HEAD~1 | head -1
SANDBOX
   ```

4. Verify scope names are package names (not "project default")
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   COMMIT1_FILE=$(git show --name-only --format="" HEAD | head -1)
   COMMIT2_FILE=$(git show --name-only --format="" HEAD~1 | head -1)

   echo "Commit 1 contains: $COMMIT1_FILE"
   echo "Commit 2 contains: $COMMIT2_FILE"

   [ "$COMMIT1_FILE" != "$COMMIT2_FILE" ] && echo "PASS: Files in separate commits" || echo "FAIL: Same file in both"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Two commits created (one per package)
- Each commit contains only files from one package (pkg-alpha or pkg-beta)
- Scope names derived from package path, NOT "project default"
- Config cascade with .ace-defaults does not interfere with scope derivation

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

- [ ] TC-005: Single scope files commit together without splitting
- [ ] TC-006: Config cascade with .ace-defaults derives correct scope names
