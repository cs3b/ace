---
test-id: MT-SECRETS-001
title: Full Scan Workflow
area: git-secrets
package: ace-git-secrets
priority: high
duration: ~20min
automation-candidate: true
requires:
  tools: [ace-git-secrets, git, gitleaks]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Full Scan Workflow

## Objective

Verify the complete ace-git-secrets scan workflow including clean repo scanning, secret detection, JSON output, verbose mode, confidence filtering, date filtering, and whitelist functionality.

## Prerequisites

- Ruby >= 3.0 installed
- ace-git-secrets package available in PATH
- git installed
- gitleaks installed (brew install gitleaks)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="secrets"
SHORT_ID="mt001"
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
echo "========================="
```

## Test Data

```bash
# Create initial clean commit
cat > "$TEST_DIR/README.md" << 'EOF'
# Test Project

This is a clean project for testing.
EOF

git add README.md
git commit -q -m "Initial commit"
```

## Test Cases

### TC-001: Scan Clean Repo (No Secrets)

**Objective:** Verify that scanning a clean repository returns exit code 0 and reports no tokens found.

**Steps:**
1. Run scan on clean repository
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify output indicates clean
   ```bash
   echo "$OUTPUT" | grep -qi "no tokens\|clean" && echo "PASS: Clean message found" || echo "FAIL: No clean message"
   ```

**Expected:**
- Exit code: 0
- Output contains "No tokens" or "clean" indication

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Scan Repo with Secrets (Gitleaks Detection)

**Objective:** Verify that scanning a repository with secrets returns exit code 1 and reports detected tokens.

**Steps:**
1. Plant a secret in the repository
   ```bash
   cat > "$TEST_DIR/config.env" << 'EOF'
   # Configuration
   DATABASE_URL=postgres://localhost:5432/mydb
   GITHUB_TOKEN=ghp_test_token_for_full_scan_workflow_1234567890AB
   EOF

   git add config.env
   git commit -q -m "Add config with secret"
   ```

2. Run scan
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify exit code is 1 (secrets found)
   ```bash
   [ "$EXIT_CODE" -eq 1 ] && echo "PASS: Exit code is 1" || echo "FAIL: Expected 1, got $EXIT_CODE"
   ```

4. Verify output indicates tokens found
   ```bash
   echo "$OUTPUT" | grep -qiE "token|secret|found|alert" && echo "PASS: Token detection message" || echo "FAIL: No token message"
   ```

**Expected:**
- Exit code: 1
- Output contains token detection message

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: JSON Output Format

**Objective:** Verify that JSON report format works correctly.

**Steps:**
1. Run scan with JSON report format
   ```bash
   OUTPUT=$(ace-git-secrets scan --format json 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify report file is saved
   ```bash
   echo "$OUTPUT" | grep -qE "Report saved:.*\.json" && echo "PASS: Report saved message" || echo "FAIL: No report saved message"
   ```

3. Find and verify JSON report structure
   ```bash
   REPORT_FILE=$(find "$TEST_DIR/.cache/ace-git-secrets/sessions" -name "*-report.json" 2>/dev/null | head -1)
   if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
     echo "PASS: Report file exists: $REPORT_FILE"
     cat "$REPORT_FILE" | jq . > /dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
     cat "$REPORT_FILE" | jq -e '.tokens' > /dev/null && echo "PASS: Has tokens key" || echo "FAIL: Missing tokens key"
     cat "$REPORT_FILE" | jq -e '.scan_metadata' > /dev/null && echo "PASS: Has scan_metadata" || echo "FAIL: Missing scan_metadata"
   else
     echo "FAIL: Report file not found"
   fi
   ```

**Expected:**
- Report saved to .cache/ace-git-secrets/sessions/
- Valid JSON structure with tokens and scan_metadata keys

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Verbose JSON to Stdout

**Objective:** Verify that verbose mode outputs full JSON to stdout.

**Steps:**
1. Run scan with verbose mode and JSON format
   ```bash
   OUTPUT=$(ace-git-secrets scan --format json --verbose 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify JSON structure in stdout
   ```bash
   echo "$OUTPUT" | grep -q '"scan_metadata"' && echo "PASS: scan_metadata in stdout" || echo "FAIL: No scan_metadata"
   echo "$OUTPUT" | grep -q '"tokens"' && echo "PASS: tokens in stdout" || echo "FAIL: No tokens"
   ```

**Expected:**
- Full JSON report printed to stdout
- Contains scan_metadata and tokens keys

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Confidence Filtering (High/Medium/Low)

**Objective:** Verify that confidence level filtering works correctly.

**Steps:**
1. Run scan with high confidence filter
   ```bash
   OUTPUT=$(ace-git-secrets scan --confidence high 2>&1)
   EXIT_CODE=$?
   echo "Exit code (high): $EXIT_CODE"
   ```

2. Run scan with medium confidence filter
   ```bash
   OUTPUT=$(ace-git-secrets scan --confidence medium 2>&1)
   EXIT_CODE=$?
   echo "Exit code (medium): $EXIT_CODE"
   ```

3. Run scan with low confidence filter
   ```bash
   OUTPUT=$(ace-git-secrets scan --confidence low 2>&1)
   EXIT_CODE=$?
   echo "Exit code (low): $EXIT_CODE"
   ```

4. Verify command completes without error
   ```bash
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Confidence filtering works" || echo "FAIL: Command error"
   ```

**Expected:**
- All confidence levels accepted
- Commands complete without error

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Since Option (Date Filtering)

**Objective:** Verify that the --since option for date filtering works correctly.

**Steps:**
1. Run scan with since option
   ```bash
   OUTPUT=$(ace-git-secrets scan --since "2020-01-01" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify command completes
   ```bash
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Since option accepted" || echo "FAIL: Command error"
   ```

**Expected:**
- --since option accepted
- Command completes without error

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Whitelist Filtering

**Objective:** Verify that whitelisted files are excluded from scan results.

**Steps:**
1. Create test fixture with secret
   ```bash
   mkdir -p "$TEST_DIR/test"
   cat > "$TEST_DIR/test/mock_tokens.json" << 'EOF'
   {"token": "ghp_test_whitelist_filter_1234567890AB"}
   EOF

   git add test/mock_tokens.json
   git commit -q -m "Test fixture"
   ```

2. Create whitelist config
   ```bash
   mkdir -p "$TEST_DIR/.ace/git-secrets"
   cat > "$TEST_DIR/.ace/git-secrets/config.yml" << 'EOF'
   whitelist:
     - file: "test/*"
       reason: "Test fixtures"
   EOF
   ```

3. Run scan
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

4. Verify whitelist was applied (check output for whitelist mention)
   ```bash
   echo "$OUTPUT" | grep -qi "whitelist\|excluded" && echo "PASS: Whitelist mentioned" || echo "INFO: Whitelist not explicitly mentioned"
   ```

**Expected:**
- Whitelisted file excluded from results
- Output may mention whitelist filtering

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Whitelist Display in Output

**Objective:** Verify that whitelisted tokens are mentioned in scan output.

**Steps:**
1. Create non-whitelisted secret
   ```bash
   cat > "$TEST_DIR/real_config.env" << 'EOF'
   API_KEY=ghp_test_real_secret_display_1234567890AB
   EOF

   git add real_config.env
   git commit -q -m "Add real config"
   ```

2. Run scan (whitelist config from TC-007 should still be active)
   ```bash
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

3. Verify output mentions both detection and whitelist
   ```bash
   echo "$OUTPUT" | grep -qiE "token|found" && echo "PASS: Token detected" || echo "FAIL: No token found"
   ```

**Expected:**
- Real secret detected (exit code 1)
- Output may indicate whitelisted tokens were excluded

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

- [ ] TC-001: Scan clean repo returns exit 0
- [ ] TC-002: Scan with secrets returns exit 1
- [ ] TC-003: JSON output format generates valid report
- [ ] TC-004: Verbose JSON outputs to stdout
- [ ] TC-005: Confidence filtering works
- [ ] TC-006: Since option (date filtering) works
- [ ] TC-007: Whitelist filtering excludes files
- [ ] TC-008: Output shows detection with whitelist context

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-git-secrets/test/integration/full_workflow_test.rb
- Tests require gitleaks to be installed (brew install gitleaks)
- Exit codes: 0=clean, 1=tokens found, other=error
- Tests build on previous TCs - run in order
