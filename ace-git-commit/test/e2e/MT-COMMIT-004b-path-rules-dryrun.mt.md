---
test-id: MT-COMMIT-004b
title: Split Commit - Path Rules and Dry-Run
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

# Split Commit - Path Rules and Dry-Run

## Objective

Verify that ace-git-commit groups files by matching path rules defined in project-level configuration, and that dry-run mode displays the planned split without committing.

## Prerequisites

- Ruby >= 3.0 installed
- Git installed and configured
- ace-git-commit package available in PATH

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="git-commit"
SHORT_ID="mt004b"
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
# Create initial structure with path rules and two packages
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

### TC-003: Path Rules in Project Config

**Objective:** Verify that files are grouped by matching path rules defined in project-level configuration.

**Steps:**
1. Create project-level config with path rules and matching files
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/git
   cat > .ace/git/commit.yml << 'EOF'
model: glite
path_rules:
  - glob: "docs/**"
    model: gflash
  - glob: "test/**"
    model: glite
EOF

   mkdir -p docs test

   cat > docs/guide.md << 'EOF'
# Guide

Documentation file.
EOF

   cat > test/service_test.rb << 'EOF'
# frozen_string_literal: true

class ServiceTest
  def test_run
    assert true
  end
end
EOF

   git add .
   git commit -m "Add config with path rules and initial files"
SANDBOX
   ```

2. Modify both files and run ace-git-commit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> docs/guide.md << 'EOF'

## Additional Section

More documentation content.
EOF

   cat >> test/service_test.rb << 'EOF'

  def test_another
    assert_equal 1, 1
  end
EOF

   ace-git-commit docs/guide.md test/service_test.rb -m "Update docs and tests"
SANDBOX
   ```

3. Verify files were grouped by path rules into separate commits
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "=== Recent commits ==="
   git log --oneline -3
   git show --stat HEAD
   git show --stat HEAD~1
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Files grouped according to path rule globs
- docs/guide.md in one commit (gflash scope)
- test/service_test.rb in another commit (glite scope)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Dry-Run Shows Split Plan

**Objective:** Verify that dry-run mode displays the planned commit groups without actually committing.

**Steps:**
1. Make changes in multiple scopes and capture initial HEAD
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat >> pkg-a/service.rb << 'EOF'

  def dry_run_method_a
    "Testing dry run"
  end
EOF

   cat >> pkg-b/service.rb << 'EOF'

  def dry_run_method_b
    "Testing dry run"
  end
EOF

   INITIAL_HEAD=$(git rev-parse HEAD)
   echo "Initial HEAD: $INITIAL_HEAD"
SANDBOX
   ```

2. Run ace-git-commit in dry-run mode
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-commit -n pkg-a/service.rb pkg-b/service.rb -m "Dry run test"
   ```

3. Verify no commits created and files remain modified
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   CURRENT_HEAD=$(git rev-parse HEAD)
   [ "$INITIAL_HEAD" = "$CURRENT_HEAD" ] && echo "PASS: No commits created" || echo "FAIL: Commits were created"
   git status --porcelain | grep -q "pkg-a/service.rb" && echo "PASS: pkg-a changes remain"
   git status --porcelain | grep -q "pkg-b/service.rb" && echo "PASS: pkg-b changes remain"
SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output shows planned commit groups
- No actual commits created (HEAD unchanged)
- Modified files remain in working directory

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

- [ ] TC-003: Path rules correctly group files by glob patterns
- [ ] TC-004: Dry-run shows split plan without committing
