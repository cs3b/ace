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
last-verified: null
verified-by: null
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
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="bundle"
SHORT_ID="mt002"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "=== Tool Verification ==="
which ace-bundle && ace-bundle --version
echo "========================="
```

## Test Data

```bash
# Create minimal .ace structure
mkdir -p "$TEST_DIR/.ace/bundle/presets"

# Create small preset (under 500 lines) - should output to stdio
cat > "$TEST_DIR/.ace/bundle/presets/small-test.md" << 'EOF'
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
} > "$TEST_DIR/.ace/bundle/presets/large-test.md"

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
} > "$TEST_DIR/.ace/bundle/presets/at-threshold-test.md"

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
} > "$TEST_DIR/.ace/bundle/presets/below-threshold-test.md"
```

## Test Cases

### TC-001: Small Content Outputs to Stdio

**Objective:** Verify that content under 500 lines is output directly to stdout.

**Steps:**
1. Load small preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle small-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify success
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify content is output directly (not cache message)
   ```bash
   echo "$OUTPUT" | grep -q "# Small Test Content" && echo "PASS: Content output directly" || echo "FAIL: Content not in stdout"
   ```

4. Verify no cache save message
   ```bash
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: No cache message" || echo "FAIL: Unexpected cache message"
   ```

5. Verify no output file reference
   ```bash
   ! echo "$OUTPUT" | grep -q "output file:" && echo "PASS: No file reference" || echo "FAIL: Unexpected file reference"
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
1. Load large preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle large-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify success
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify cache save message
   ```bash
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Cache message present" || echo "FAIL: No cache message"
   ```

4. Verify output file reference
   ```bash
   echo "$OUTPUT" | grep -q "output file:" && echo "PASS: File reference present" || echo "FAIL: No file reference"
   ```

5. Verify cache path mentioned
   ```bash
   echo "$OUTPUT" | grep -q ".cache/ace-bundle" && echo "PASS: Cache path in output" || echo "FAIL: No cache path"
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
1. Load large preset with explicit stdio output
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle large-test --output stdio 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify success
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify content is output directly
   ```bash
   echo "$OUTPUT" | grep -q "# Large Test Content" && echo "PASS: Content output directly" || echo "FAIL: Content not in stdout"
   ```

4. Verify no cache save message
   ```bash
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: No cache message" || echo "FAIL: Unexpected cache message"
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
1. Load small preset with explicit cache output
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle small-test --output cache 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify success
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify cache save message
   ```bash
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Cache message present" || echo "FAIL: No cache message"
   ```

4. Verify output file reference
   ```bash
   echo "$OUTPUT" | grep -q "output file:" && echo "PASS: File reference present" || echo "FAIL: No file reference"
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
1. Load at-threshold preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle at-threshold-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify success
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify cache behavior (at threshold = cache)
   ```bash
   echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: At threshold goes to cache" || echo "FAIL: Expected cache output"
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
1. Load below-threshold preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle below-threshold-test 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify success
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify stdio behavior
   ```bash
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: Below threshold goes to stdio" || echo "FAIL: Unexpected cache"
   ```

4. Verify content present
   ```bash
   echo "$OUTPUT" | grep -q "# Test Content" && echo "PASS: Content in stdout" || echo "FAIL: Content not found"
   ```

**Expected:**
- Exit code: 0
- Content below threshold goes to stdio
- Content visible in output

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
# Artifacts preserved for debugging - cleanup optional
# rm -rf "$TEST_DIR"
```

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
