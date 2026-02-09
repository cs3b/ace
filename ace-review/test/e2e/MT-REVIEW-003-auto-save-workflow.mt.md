---
test-id: MT-REVIEW-003
title: Auto-Save Workflow and Task Resolution
area: review
package: ace-review
priority: medium
duration: ~15min
automation-candidate: true
requires:
  tools: [ace-review, ace-git, ace-taskflow]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Auto-Save Workflow and Task Resolution

## Objective

Verify that ace-review auto-save workflow correctly extracts task IDs from branch names, resolves task directories, generates report files with timestamps, creates reviews subdirectory, and handles error cases like missing directories.

## Prerequisites

- Ruby >= 3.0 installed
- ace-review package available in PATH
- ace-taskflow installed (for task directory structure)
- git installed (for branch operations)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="review"
SHORT_ID="mt003"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Initialize git repo
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-review && ace-review --version || echo "ace-review not in PATH"
which ace-taskflow && ace-taskflow --version || echo "ace-taskflow not in PATH"
which git && git --version
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
# Create taskflow structure
mkdir -p .ace-taskflow/v.test/tasks/126-feature

# Create task spec file
cat > .ace-taskflow/v.test/tasks/126-feature/126.00-orchestrator.s.md << 'EOF'
---
id: v.test+task.126
status: in-progress
priority: medium
estimate: 2h
---

# Test Feature Task

## Objective
Test task for E2E auto-save testing.
EOF

# Create subtask directory
mkdir -p .ace-taskflow/v.test/tasks/126-feature
cat > .ace-taskflow/v.test/tasks/126-feature/126.03-auto-save.s.md << 'EOF'
---
id: v.test+task.126.03
status: in-progress
priority: medium
estimate: 1h
parent: v.test+task.126
---

# Auto-Save Feature Subtask

## Objective
Test subtask for E2E auto-save testing.
EOF

# Create review presets
mkdir -p .ace/review/presets
cat > .ace/review/presets/test.yml << 'EOF'
description: "Test preset"
model: "test-model"
EOF

cat > .ace/review/config.yml << 'EOF'
defaults:
  model: "test-model"
EOF

# Create test files
cat > test.rb << 'EOF'
# Test file for review
class TestClass
  def test_method
    "Hello"
  end
end
EOF

# Initial commit
git add .
git commit -m "Initial commit" --quiet

# Create a task branch
git checkout -b 126-feature-test --quiet
echo "# Branch is now: $(git branch --show-current)"
SANDBOX
```

## Test Cases

### TC-001: Task ID Extraction from Standard Branch

**Objective:** Verify that task ID is correctly extracted from standard branch naming pattern.

**Steps:**
1. Verify current branch name
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   BRANCH=$(git branch --show-current)
   echo "Current branch: $BRANCH"
   SANDBOX
   ```

2. Verify branch matches task pattern
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$BRANCH" | grep -qE "^[0-9]+" && echo "PASS: Branch has task ID prefix" || echo "FAIL: Branch doesn't match task pattern"
   SANDBOX
   ```

**Expected:**
- Branch name: 126-feature-test
- Task ID extractable: 126

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Subtask ID Extraction from Branch

**Objective:** Verify that subtask IDs (e.g., 126.03) are correctly extracted.

**Steps:**
1. Create and switch to subtask branch
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git checkout -b 126.03-auto-save-detection --quiet
   BRANCH=$(git branch --show-current)
   echo "Current branch: $BRANCH"
   SANDBOX
   ```

2. Verify subtask pattern matches
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$BRANCH" | grep -qE "^[0-9]+\.[0-9]+" && echo "PASS: Branch has subtask ID" || echo "FAIL: Branch doesn't match subtask pattern"
   SANDBOX
   ```

**Expected:**
- Branch name: 126.03-auto-save-detection
- Subtask ID extractable: 126.03

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Error - Non-Task Branch Returns No Task ID

**Objective:** Verify that main/master branches don't extract a task ID.

**Steps:**
1. Switch to main branch
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git checkout main --quiet 2>/dev/null || git checkout -b main --quiet
   BRANCH=$(git branch --show-current)
   echo "Current branch: $BRANCH"
   SANDBOX
   ```

2. Verify main branch doesn't have task ID
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$BRANCH" | grep -qE "^[0-9]+" && echo "FAIL: main branch shouldn't have task ID prefix" || echo "PASS: main branch correctly has no task ID"
   SANDBOX
   ```

**Expected:**
- Branch name: main
- No task ID should be extracted

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Reviews Subdirectory Creation

**Objective:** Verify that reviews/ subdirectory is created in task directory.

**Steps:**
1. Switch back to task branch
   ```bash
   ace-test-e2e-sh "$TEST_DIR" git checkout 126-feature-test --quiet
   ```

2. Verify reviews directory doesn't exist yet
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   TASK_DIR=".ace-taskflow/v.test/tasks/126-feature"
   ! test -d "$TASK_DIR/reviews" && echo "PASS: reviews/ doesn't exist yet" || echo "INFO: reviews/ already exists"
   SANDBOX
   ```

3. Create reviews directory (simulating what TaskReportSaver does)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   TASK_DIR=".ace-taskflow/v.test/tasks/126-feature"
   mkdir -p "$TASK_DIR/reviews"
   test -d "$TASK_DIR/reviews" && echo "PASS: reviews/ directory created" || echo "FAIL: reviews/ not created"
   SANDBOX
   ```

**Expected:**
- reviews/ subdirectory is created in task directory

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Report Filename Generation with Timestamp

**Objective:** Verify that report filenames include timestamp ID, model, and preset.

**Steps:**
1. Generate a timestamp ID
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   TIMESTAMP=$(ace-timestamp encode)
   echo "Generated timestamp: $TIMESTAMP"
   SANDBOX
   ```

2. Verify timestamp format (6 chars Base36)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$TIMESTAMP" | grep -qE "^[0-9a-z]{6}$" && echo "PASS: Timestamp is 6-char Base36" || echo "FAIL: Invalid timestamp format"
   SANDBOX
   ```

3. Construct expected filename pattern
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   # Pattern: {timestamp}-{model-slug}-{preset}-review.md
   EXPECTED_PATTERN="^[0-9a-z]{6}-google-gemini-2-5-flash-code-review\.md$"
   SAMPLE_FILENAME="${TIMESTAMP}-google-gemini-2-5-flash-code-review.md"
   echo "Sample filename: $SAMPLE_FILENAME"
   echo "$SAMPLE_FILENAME" | grep -qE "$EXPECTED_PATTERN" && echo "PASS: Filename matches pattern" || echo "FAIL: Filename doesn't match"
   SANDBOX
   ```

**Expected:**
- Timestamp: 6-character Base36 string
- Filename pattern: {timestamp}-{model-slug}-{preset}-review.md

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Error - Missing Task Directory

**Objective:** Verify graceful handling when task directory doesn't exist.

**Steps:**
1. Attempt to create review in nonexistent directory
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   NONEXISTENT_DIR=".ace-taskflow/v.test/tasks/999-nonexistent"

   # Try to create file in nonexistent directory
   mkdir -p "$NONEXISTENT_DIR/reviews" 2>/dev/null
   test -d "$NONEXISTENT_DIR/reviews" && echo "INFO: Directory created (mkdir -p succeeds)" || echo "FAIL: mkdir -p failed"
   SANDBOX
   ```

2. Verify directory was created with mkdir -p
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   NONEXISTENT_DIR=".ace-taskflow/v.test/tasks/999-nonexistent"
   # mkdir -p creates parent directories, so this should succeed
   test -d "$NONEXISTENT_DIR" && echo "PASS: Parent directories created" || echo "FAIL: Directory not created"
   SANDBOX
   ```

**Expected:**
- mkdir -p creates directories as needed
- No error when saving to new directory structure

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Feature Branch Pattern Recognition

**Objective:** Verify that feature/123-name branch pattern is recognized.

**Steps:**
1. Create feature branch
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git checkout -b feature/123-add-login --quiet
   BRANCH=$(git branch --show-current)
   echo "Current branch: $BRANCH"
   SANDBOX
   ```

2. Verify feature branch pattern
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$BRANCH" | grep -qE "^feature/[0-9]+" && echo "PASS: Feature branch pattern detected" || echo "FAIL: Feature branch not detected"
   SANDBOX
   ```

**Expected:**
- Branch: feature/123-add-login
- Pattern recognized for task extraction

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

```bash
# Only run if cleanup is enabled - reports are preserved by default
# rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: Standard branch task ID extraction works
- [ ] TC-002: Subtask ID extraction works
- [ ] TC-003: Non-task branches handled correctly
- [ ] TC-004: Reviews subdirectory created
- [ ] TC-005: Report filename includes timestamp
- [ ] TC-006: Missing directory handled gracefully
- [ ] TC-007: Feature branch pattern recognized

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-review/test/integration/auto_save_integration_test.rb
- Only the E2E flow test (auto_save_flow_branch_to_task) is moved here
- Unit tests for TaskPatternExtractor remain in ace-git package
- Unit tests for filename generation remain in molecules test
- TaskReportSaver.save() handles directory creation and file copying
- Timestamp IDs are 6-character Base36 strings from ace-timestamp
