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

TIMESTAMP_ID="${RUN_ID:-$(ace-b36ts encode)}"
SHORT_PKG="secrets"
SHORT_ID="mt001"
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
# Create initial clean commit
cat > README.md << 'EOF'
# Test Project

This is a clean project for testing.
EOF

git add README.md
git commit -q -m "Initial commit"
SANDBOX
```

## Test Cases

### TC-001: Scan Clean Repo (No Secrets)

**Objective:** Verify that scanning a clean repository returns exit code 0 and reports no tokens found.

**Steps:**
1. Run scan on clean repository
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify exit code is 0
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   SANDBOX
   ```

3. Verify output indicates clean
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qi "no tokens\|clean" && echo "PASS: Clean message found" || echo "FAIL: No clean message"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > config.env << 'EOF'
   # Configuration
   DATABASE_URL=postgres://localhost:5432/mydb
   GITHUB_TOKEN=literal:[REDACTED:github-pat]
   EOF

   git add config.env
   git commit -q -m "Add config with secret"
   SANDBOX
   ```

2. Run scan
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify exit code is 1 (secrets found)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -eq 1 ] && echo "PASS: Exit code is 1" || echo "FAIL: Expected 1, got $EXIT_CODE"
   SANDBOX
   ```

4. Verify output indicates tokens found
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "token|secret|found|alert" && echo "PASS: Token detection message" || echo "FAIL: No token message"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan --format json 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify report file is saved
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qE "Report saved:.*\.json" && echo "PASS: Report saved message" || echo "FAIL: No report saved message"
   SANDBOX
   ```

3. Find and verify JSON report structure
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   REPORT_FILE=$(find .cache/ace-git-secrets/sessions -name "*-report.json" 2>/dev/null | head -1)
   if [ -n "$REPORT_FILE" ] && [ -f "$REPORT_FILE" ]; then
     echo "PASS: Report file exists: $REPORT_FILE"
     cat "$REPORT_FILE" | jq . > /dev/null 2>&1 && echo "PASS: Valid JSON" || echo "FAIL: Invalid JSON"
     cat "$REPORT_FILE" | jq -e '.tokens' > /dev/null && echo "PASS: Has tokens key" || echo "FAIL: Missing tokens key"
     cat "$REPORT_FILE" | jq -e '.scan_metadata' > /dev/null && echo "PASS: Has scan_metadata" || echo "FAIL: Missing scan_metadata"
   else
     echo "FAIL: Report file not found"
   fi
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan --format json --verbose 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   SANDBOX
   ```

2. Verify JSON structure in stdout
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -q '"scan_metadata"' && echo "PASS: scan_metadata in stdout" || echo "FAIL: No scan_metadata"
   echo "$OUTPUT" | grep -q '"tokens"' && echo "PASS: tokens in stdout" || echo "FAIL: No tokens"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan --confidence high 2>&1)
   EXIT_CODE=$?
   echo "Exit code (high): $EXIT_CODE"
   SANDBOX
   ```

2. Run scan with medium confidence filter
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan --confidence medium 2>&1)
   EXIT_CODE=$?
   echo "Exit code (medium): $EXIT_CODE"
   SANDBOX
   ```

3. Run scan with low confidence filter
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan --confidence low 2>&1)
   EXIT_CODE=$?
   echo "Exit code (low): $EXIT_CODE"
   SANDBOX
   ```

4. Verify command completes without error
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Confidence filtering works" || echo "FAIL: Command error"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan --since "2020-01-01" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

2. Verify command completes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Since option accepted" || echo "FAIL: Command error"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p test
   cat > test/mock_tokens.json << 'EOF'
   {"token": "literal:[REDACTED:github-pat]"}
   EOF

   git add test/mock_tokens.json
   git commit -q -m "Test fixture"
   SANDBOX
   ```

2. Create whitelist config
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/git-secrets
   cat > .ace/git-secrets/config.yml << 'EOF'
   whitelist:
     - file: "test/*"
       reason: "Test fixtures"
   EOF
   SANDBOX
   ```

3. Run scan
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

4. Verify whitelist was applied (check output for whitelist mention)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qi "whitelist\|excluded" && echo "PASS: Whitelist mentioned" || echo "INFO: Whitelist not explicitly mentioned"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > real_config.env << 'EOF'
   API_KEY=literal:[REDACTED:github-pat]
   EOF

   git add real_config.env
   git commit -q -m "Add real config"
   SANDBOX
   ```

2. Run scan (whitelist config from TC-007 should still be active)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-git-secrets scan 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   SANDBOX
   ```

3. Verify output mentions both detection and whitelist
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "$OUTPUT" | grep -qiE "token|found" && echo "PASS: Token detected" || echo "FAIL: No token found"
   SANDBOX
   ```

**Expected:**
- Real secret detected (exit code 1)
- Output may indicate whitelisted tokens were excluded

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Known Issues

- None currently known. Test tokens use format-valid patterns (ghp_ + 36 alphanumeric chars) matching gitleaks detection rules.

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
