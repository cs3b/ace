---
test-id: MT-BUNDLE-002
title: CLI Auto-Format Behavior
area: cli
package: ace-bundle
priority: high
duration: ~3min
automation-candidate: false
requires:
  tools: [ace-bundle]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# CLI Auto-Format Behavior

## Objective

Verify that ace-bundle CLI automatically chooses stdio vs cache output based on content size, and that explicit `--output` flags override this behavior. The threshold is 500 lines.

## Prerequisites

- Ruby >= 3.0 installed
- ace-bundle available in PATH
- Write access to create test directories

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="bundle"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Init git repo so ProjectRootFinder finds sandbox as root
git init "$TEST_DIR"
git -C "$TEST_DIR" config user.email "test@example.com"
git -C "$TEST_DIR" config user.name "Test User"

echo "=== Tool Verification ==="
which ace-bundle && ace-bundle --version
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
# Create minimal .ace structure
mkdir -p .ace/bundle/presets

# Create small preset (under 500 lines) - should output to stdio
cat > .ace/bundle/presets/small-test.md << 'EOF'
---
name: small-test
---

# Small Test Content

This is a small preset with only a few lines.
It should be output directly to stdout.
EOF

# Create large preset (over 500 lines) - should output to cache
{
  cat << 'EOF'
---
name: large-test
---

# Large Test Content

EOF
  for i in $(seq 1 600); do
    echo "Line $i of large content"
  done
} > .ace/bundle/presets/large-test.md

# Create at-threshold preset (~498 content lines + wrapper = ~500 total)
{
  cat << 'EOF'
---
name: at-threshold-test
---

# Test Content

EOF
  for i in $(seq 1 493); do
    echo "Line $i"
  done
} > .ace/bundle/presets/at-threshold-test.md

# Create below-threshold preset (100 lines)
{
  cat << 'EOF'
---
name: below-threshold-test
---

# Test Content

EOF
  for i in $(seq 1 95); do
    echo "Line $i"
  done
} > .ace/bundle/presets/below-threshold-test.md
SANDBOX
```

## Test Cases

### TC-001: Small Content Outputs to Stdio

**Objective:** Verify that content under 500 lines is output directly to stdout.

**Steps:**
1. Load small preset and verify
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle small-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"

   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "# Small Test Content" && echo "PASS: Content output directly" || echo "FAIL: Content not in stdout"
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: No cache message" || echo "FAIL: Unexpected cache message"
   ! echo "$OUTPUT" | grep -q "output file:" && echo "PASS: No file reference" || echo "FAIL: Unexpected file reference"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains "# Small Test Content"
- Output does NOT contain "Bundle saved"
- Output does NOT contain "output file:"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Large Content Outputs to Cache

**Objective:** Verify that content over 500 lines is saved to cache and path is returned.

**Steps:**
1. Load large preset and verify
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle large-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"

   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Cache message present" || echo "FAIL: No cache message"
   echo "$OUTPUT" | grep -q "output file:" && echo "PASS: File reference present" || echo "FAIL: No file reference"
   echo "$OUTPUT" | grep -q ".cache/ace-bundle" && echo "PASS: Cache path in output" || echo "FAIL: No cache path"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains "Bundle saved"
- Output contains "output file:"
- Output contains ".cache/ace-bundle"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Explicit --output stdio Overrides Auto

**Objective:** Verify that `--output stdio` forces large content to stdout.

**Steps:**
1. Load large preset with explicit stdio output and verify
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle large-test --output stdio 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"

   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "# Large Test Content" && echo "PASS: Content output directly" || echo "FAIL: Content not in stdout"
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: No cache message" || echo "FAIL: Unexpected cache message"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains "# Large Test Content" (direct content)
- Output does NOT contain "Bundle saved"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Explicit --output cache Overrides Auto

**Objective:** Verify that `--output cache` forces small content to cache file.

**Steps:**
1. Load small preset with explicit cache output and verify
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle small-test --output cache 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"

   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Cache message present" || echo "FAIL: No cache message"
   echo "$OUTPUT" | grep -q "output file:" && echo "PASS: File reference present" || echo "FAIL: No file reference"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains "Bundle saved"
- Output contains "output file:"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: At Threshold Goes to Cache

**Objective:** Verify that content at/above 500 lines goes to cache.

**Steps:**
1. Load at-threshold preset and verify
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle at-threshold-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"

   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: At threshold goes to cache" || echo "FAIL: Expected cache output"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Content at threshold (500 lines) goes to cache

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Below Threshold Goes to Stdio

**Objective:** Verify that content clearly below 500 lines goes to stdio.

**Steps:**
1. Load below-threshold preset and verify
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle below-threshold-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"

   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Below threshold goes to stdio" || echo "FAIL: Unexpected cache"
   echo "$OUTPUT" | grep -q "# Test Content" && echo "PASS: Content in stdout" || echo "FAIL: Content not found"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Content below threshold goes to stdio
- Content visible in output

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

## Success Criteria

- [ ] TC-001: Small content outputs to stdio
- [ ] TC-002: Large content outputs to cache
- [ ] TC-003: --output stdio overrides auto for large content
- [ ] TC-004: --output cache overrides auto for small content
- [ ] TC-005: At threshold (500 lines) goes to cache
- [ ] TC-006: Below threshold goes to stdio

## Notes

- This test was migrated from `ace-bundle/test/integration/cli_auto_format_test.rb`
- Tests real CLI subprocess behavior with Open3.capture3
- Threshold is 500 lines for auto-format decision
- The preset loader adds ~2-5 lines of wrapper content
