---
test-id: MT-COMMIT-004a
title: Split Commit - Auto-Split Basics
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

# Split Commit - Auto-Split Basics

## Objective

Verify that ace-git-commit automatically creates separate commits when files span multiple configuration scopes, and that --no-split forces a single commit.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-commit"
SHORT_ID="mt004a"
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
# Create initial structure with two packages having separate configs
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

### TC-001: Auto-Split When Files Span Multiple Config Scopes

**Objective:** Verify that ace-git-commit automatically creates separate commits when files span multiple configuration scopes.

**Steps:**
1. Make changes in both packages
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> pkg-a/service.rb << 'EOF'

  def new_method_a
    "Added to package A"
  end
EOF

   cat >> pkg-b/service.rb << 'EOF'

  def new_method_b
    "Added to package B"
  end
EOF

   git status --porcelain
SANDBOX
   ```

2. Run ace-git-commit and verify two separate commits created
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit pkg-a/service.rb pkg-b/service.rb -m "Add methods to services"
   ```

3. Verify each commit contains only one package's changes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Recent commits ==="
   git log --oneline -3

   echo "=== Commit 1 (HEAD) ==="
   git show --stat HEAD
   echo "=== Commit 2 (HEAD~1) ==="
   git show --stat HEAD~1
SANDBOX
   ```

4. Verify files in each commit belong to separate packages
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git show --name-only --format="" HEAD | grep -q "pkg-" && echo "PASS: HEAD has package files"
   git show --name-only --format="" HEAD~1 | grep -q "pkg-" && echo "PASS: HEAD~1 has package files"

   # Verify they are in different packages
   HEAD_PKG=$(git show --name-only --format="" HEAD | head -1 | cut -d/ -f1)
   PREV_PKG=$(git show --name-only --format="" HEAD~1 | head -1 | cut -d/ -f1)
   [ "$HEAD_PKG" != "$PREV_PKG" ] && echo "PASS: Commits contain different packages" || echo "FAIL: Same package in both commits"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Two commits created (one per config scope)
- Each commit contains only files from one package
- Commit messages reflect the scope

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Force Single Commit with --no-split

**Objective:** Verify that --no-split flag forces all changes into a single commit regardless of config scopes.

**Steps:**
1. Make changes in both packages
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> pkg-a/service.rb << 'EOF'

  def another_method_a
    "Another method in package A"
  end
EOF

   cat >> pkg-b/service.rb << 'EOF'

  def another_method_b
    "Another method in package B"
  end
EOF

   git status --porcelain
SANDBOX
   ```

2. Run ace-git-commit with --no-split
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit --no-split pkg-a/service.rb pkg-b/service.rb -m "Add methods to both services"
   ```

3. Verify single commit with both packages' files
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Latest commit ==="
   git log --oneline -1
   git show --stat HEAD

   FILE_COUNT=$(git show --name-only --format="" HEAD | grep -c "service.rb")
   [ "$FILE_COUNT" -eq 2 ] && echo "PASS: Both service.rb files in one commit" || echo "FAIL: Expected 2 files, got $FILE_COUNT"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Single commit created
- Commit contains files from both pkg-a and pkg-b

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

- [ ] TC-001: Auto-split creates separate commits for different config scopes
- [ ] TC-002: --no-split forces single commit across scopes
