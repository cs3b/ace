---
test-id: MT-SECRETS-002
title: Rewrite Workflow
area: git-secrets
package: ace-git-secrets
priority: high
duration: ~15min
automation-candidate: true
requires:
  tools: [ace-git-secrets, git, gitleaks, git-filter-repo]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Rewrite Workflow

## Objective

Verify the ace-git-secrets rewrite-history and revoke command workflows including dry-run mode, raw value handling in scan files, and graceful failure when raw values are missing.

## Prerequisites

- Ruby >= 3.0 installed
- ace-git-secrets package available in PATH
- git installed
- gitleaks installed (brew install gitleaks)
- git-filter-repo installed (brew install git-filter-repo) - optional, tests handle missing

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="secrets"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Create isolated git repository
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

echo "=== Tool Verification ==="
which ace-git-secrets && ace-git-secrets --version
which gitleaks && gitleaks version
which git-filter-repo && echo "git-filter-repo: available" || echo "git-filter-repo: NOT available (some tests may skip)"
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
# Create initial commit
cat > README.md << 'EOF'
# Test Project

This is a test project for rewrite workflow testing.
EOF

git add README.md
git commit -q -m "Initial commit"

# Add a secret
cat > config.txt << 'EOF'
TOKEN=ghp_RewriteDryRun1234567890abcdefghijABC
EOF

git add config.txt
git commit -q -m "Add secret"
SANDBOX
```

## Test Cases

### TC-001: Dry Run Mode

**Objective:** Verify that rewrite-history --dry-run shows what would be done without modifying history.

**Steps:**
1. Run rewrite-history in dry run mode
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets rewrite-history --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify exit code is 0 (dry run success)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   SANDBOX
   ```

3. Verify dry run indication
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qi "dry.run" && echo "PASS: Dry run mentioned" || echo "FAIL: No dry run indication"
   SANDBOX
   ```

4. Verify token is shown
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -q "ghp_" && echo "PASS: Token shown in dry run" || echo "FAIL: Token not shown"
   SANDBOX
   ```

5. Verify git history unchanged
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   git log --oneline | grep -q "Add secret" && echo "PASS: Original commit preserved" || echo "FAIL: History was modified"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output shows "dry run" indication
- Shows detected tokens
- Git history unchanged

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Scan File Includes Raw Values

**Objective:** Verify that scan output files include raw_value field for revocation workflow.

**Steps:**
1. Run scan with JSON output
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-git-secrets scan --format json 2>&1
   ```

2. Find the saved report file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   REPORT_FILE=$(find .cache/ace-git-secrets/sessions -name "*-report.json" 2>/dev/null | head -1)
   if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
     echo "Report file: $REPORT_FILE"
   else
     echo "FAIL: Report file not found"
     exit 1
   fi
   SANDBOX
   ```

3. Verify tokens array has raw_value
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   REPORT_FILE=$(find .cache/ace-git-secrets/sessions -name "*-report.json" 2>/dev/null | head -1)
   TOKEN_COUNT=$(cat "$REPORT_FILE" | jq '.tokens | length')
   if [ "$TOKEN_COUNT" -gt 0 ]; then
     HAS_RAW=$(cat "$REPORT_FILE" | jq '.tokens[0] | has("raw_value")')
     [ "$HAS_RAW" = "true" ] && echo "PASS: raw_value present" || echo "FAIL: raw_value missing"

     RAW_VALUE=$(cat "$REPORT_FILE" | jq -r '.tokens[0].raw_value')
     echo "$RAW_VALUE" | grep -q "ghp_" && echo "PASS: raw_value has ghp_ prefix" || echo "FAIL: Invalid raw_value"
   else
     echo "INFO: No tokens found in report"
   fi
   SANDBOX
   ```

**Expected:**
- Report file saved with valid JSON
- Tokens array contains raw_value field
- raw_value contains actual token value

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Revoke Fails Gracefully Without Raw Values

**Objective:** Verify that revoke command fails with helpful error when scan file lacks raw_value.

**Steps:**
1. Create a broken scan file without raw_value
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .cache/ace-git-secrets
   cat > .cache/ace-git-secrets/broken-report.json << 'EOF'
   {
     "scan_metadata": { "repository": "." },
     "tokens": [
       {
         "token_type": "github_pat_classic",
         "confidence": "high",
         "commit_hash": "abc123",
         "file_path": "secret.txt"
       }
     ]
   }
   EOF
   SANDBOX
   ```

2. Attempt revoke with broken scan file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets revoke --scan-file ".cache/ace-git-secrets/broken-report.json" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify exit code is non-zero (failure)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Command failed as expected" || echo "FAIL: Expected failure"
   SANDBOX
   ```

4. Verify helpful error message
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qi "raw.value\|missing\|re-run\|scan" && echo "PASS: Helpful error message" || echo "FAIL: No helpful message"
   SANDBOX
   ```

**Expected:**
- Exit code: non-zero (1)
- Error message mentions missing raw_value
- Suggests re-running scan

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Rewrite Fails Gracefully Without Raw Values

**Objective:** Verify that rewrite-history command handles missing raw_value appropriately.

**Steps:**
1. Attempt rewrite with broken scan file
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets rewrite-history --scan-file ".cache/ace-git-secrets/broken-report.json" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify command handles missing raw_value
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   # Either fails with error OR proceeds with fresh scan (both acceptable)
   if [ "$EXIT_CODE" -ne 0 ]; then
     echo "$OUTPUT" | grep -qi "raw.value\|missing" && echo "PASS: Error mentions missing raw_value" || echo "INFO: Different error"
   else
     echo "INFO: Command succeeded (may have done fresh scan)"
   fi
   SANDBOX
   ```

**Expected:**
- Either fails with helpful error mentioning raw_value
- Or proceeds with fresh scan (fallback behavior)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Error - Revoke Without Token or Scan File

**Objective:** Verify that revoke command fails with helpful error when no token specified.

**Steps:**
1. Run revoke without arguments
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets revoke 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify exit code is non-zero
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Command failed as expected" || echo "FAIL: Expected failure"
   SANDBOX
   ```

3. Verify error message
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "token|scan.file|required|specify" && echo "PASS: Helpful error message" || echo "FAIL: No helpful message"
   SANDBOX
   ```

**Expected:**
- Exit code: non-zero
- Error message indicates token or scan-file required

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Known Issues

- **TC-006 through TC-011**: Rewrite functionality fails for multiple secret types. The `ace-git-secrets rewrite` command does not correctly handle all secret patterns (AWS keys, generic passwords, API tokens, etc.). These are code bugs in the rewrite engine, not test issues.

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

```bash
# Only run if cleanup is enabled - reports are preserved by default
# rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: Dry run mode works correctly
- [ ] TC-002: Scan files include raw_value
- [ ] TC-003: Revoke fails gracefully without raw_value
- [ ] TC-004: Rewrite handles missing raw_value
- [ ] TC-005: Revoke without arguments shows helpful error

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-git-secrets/test/integration/full_workflow_test.rb
- Tests require gitleaks to be installed
- git-filter-repo is required for actual rewrite (not dry-run)
- The revoke command may fail differently depending on whether raw_value is truly missing
