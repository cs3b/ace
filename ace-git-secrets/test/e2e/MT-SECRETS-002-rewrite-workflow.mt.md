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

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="secrets"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

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
```

## Test Data

```bash
# Create initial commit
cat > "$TEST_DIR/README.md" << 'EOF'
# Test Project

This is a test project for rewrite workflow testing.
EOF

git add README.md
git commit -q -m "Initial commit"

# Add a secret
cat > "$TEST_DIR/config.txt" << 'EOF'
TOKEN=ghp_test_rewrite_dry_run_1234567890AB
EOF

git add config.txt
git commit -q -m "Add secret"
```

## Test Cases

### TC-001: Dry Run Mode

**Objective:** Verify that rewrite-history --dry-run shows what would be done without modifying history.

**Steps:**
1. Run rewrite-history in dry run mode
   ```bash
   OUTPUT=$(ace-git-secrets rewrite-history --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0 (dry run success)
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify dry run indication
   ```bash
   echo "$OUTPUT" | grep -qi "dry.run" && echo "PASS: Dry run mentioned" || echo "FAIL: No dry run indication"
   ```

4. Verify token is shown
   ```bash
   echo "$OUTPUT" | grep -q "ghp_" && echo "PASS: Token shown in dry run" || echo "FAIL: Token not shown"
   ```

5. Verify git history unchanged
   ```bash
   git log --oneline | grep -q "Add secret" && echo "PASS: Original commit preserved" || echo "FAIL: History was modified"
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
   ace-git-secrets scan --format json 2>&1
   ```

2. Find the saved report file
   ```bash
   REPORT_FILE=$(find "$TEST_DIR/.cache/ace-git-secrets/sessions" -name "*-report.json" 2>/dev/null | head -1)
   if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
     echo "Report file: $REPORT_FILE"
   else
     echo "FAIL: Report file not found"
     exit 1
   fi
   ```

3. Verify tokens array has raw_value
   ```bash
   TOKEN_COUNT=$(cat "$REPORT_FILE" | jq '.tokens | length')
   if [ "$TOKEN_COUNT" -gt 0 ]; then
     HAS_RAW=$(cat "$REPORT_FILE" | jq '.tokens[0] | has("raw_value")')
     [ "$HAS_RAW" = "true" ] && echo "PASS: raw_value present" || echo "FAIL: raw_value missing"

     RAW_VALUE=$(cat "$REPORT_FILE" | jq -r '.tokens[0].raw_value')
     echo "$RAW_VALUE" | grep -q "ghp_" && echo "PASS: raw_value has ghp_ prefix" || echo "FAIL: Invalid raw_value"
   else
     echo "INFO: No tokens found in report"
   fi
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
   mkdir -p "$TEST_DIR/.cache/ace-git-secrets"
   cat > "$TEST_DIR/.cache/ace-git-secrets/broken-report.json" << 'EOF'
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
   ```

2. Attempt revoke with broken scan file
   ```bash
   OUTPUT=$(ace-git-secrets revoke --scan-file "$TEST_DIR/.cache/ace-git-secrets/broken-report.json" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify exit code is non-zero (failure)
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Command failed as expected" || echo "FAIL: Expected failure"
   ```

4. Verify helpful error message
   ```bash
   echo "$OUTPUT" | grep -qi "raw.value\|missing\|re-run\|scan" && echo "PASS: Helpful error message" || echo "FAIL: No helpful message"
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
   OUTPUT=$(ace-git-secrets rewrite-history --scan-file "$TEST_DIR/.cache/ace-git-secrets/broken-report.json" --dry-run 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify command handles missing raw_value
   ```bash
   # Either fails with error OR proceeds with fresh scan (both acceptable)
   if [ "$EXIT_CODE" -ne 0 ]; then
     echo "$OUTPUT" | grep -qi "raw.value\|missing" && echo "PASS: Error mentions missing raw_value" || echo "INFO: Different error"
   else
     echo "INFO: Command succeeded (may have done fresh scan)"
   fi
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
   OUTPUT=$(ace-git-secrets revoke 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is non-zero
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Command failed as expected" || echo "FAIL: Expected failure"
   ```

3. Verify error message
   ```bash
   echo "$OUTPUT" | grep -qiE "token|scan.file|required|specify" && echo "PASS: Helpful error message" || echo "FAIL: No helpful message"
   ```

**Expected:**
- Exit code: non-zero
- Error message indicates token or scan-file required

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
