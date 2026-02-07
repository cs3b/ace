---
test-id: MT-LINT-003
title: Skill File Validation
area: lint
package: ace-lint
priority: high
duration: ~5min
automation-candidate: true
requires:
  tools: [ace-lint, ace-timestamp]
  ruby: ">= 3.0"
last-verified: 2026-02-07
verified-by: claude-opus-4-6
---

# Skill File Validation

## Objective

Verify that ace-lint auto-detects SKILL.md files and runs skill-specific validation, producing correct pass/fail results based on the skill schema requirements.

## Prerequisites

- Ruby >= 3.0 installed
- ace-lint package available in PATH
- ace-timestamp available (for test directory ID)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="lint"
SHORT_ID="mt003"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo (needed for project root detection)
git init --quiet .

echo "=== Tool Verification ==="
which ace-lint && ace-lint --version
echo "========================="
```

## Test Data

```bash
# Valid SKILL.md with all required fields and comments
cat > "$TEST_DIR/SKILL.md" << 'EOF'
---
name: ace:example-skill
description: A valid example skill for testing
# bundle: project
# agent: Bash
user-invocable: true
allowed-tools:
  - Read
  - Glob
source: test/fixtures/example.rb
---

This skill demonstrates proper structure.
EOF

# Invalid SKILL.md missing required 'source' field
mkdir -p "$TEST_DIR/invalid"
cat > "$TEST_DIR/invalid/SKILL.md" << 'EOF'
---
name: ace:invalid-skill
description: A skill missing the source field
# bundle: project
# agent: Bash
user-invocable: true
allowed-tools:
  - Read
---

This skill is missing the required source field.
EOF
```

## Test Cases

### TC-001: Valid Skill File Passes

**Objective:** Verify that ace-lint detects SKILL.md, validates it against the skill schema, and exits 0 when valid.

**Steps:**
1. Lint the valid SKILL.md file
   ```bash
   OUTPUT=$(ace-lint lint "$TEST_DIR/SKILL.md" 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   test "$EXIT_CODE" -eq 0 && echo "PASS: Exit code is 0" || echo "FAIL: Exit code is $EXIT_CODE"
   ```

3. Verify output indicates pass
   ```bash
   echo "$OUTPUT" | grep -qE "(passed|ok|✓)" && echo "PASS: Output indicates success" || echo "FAIL: No success indicator in output"
   ```

**Expected:**
- Exit code: 0
- Output shows file passed validation
- No validation errors reported

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Invalid Skill File Fails

**Objective:** Verify that ace-lint detects SKILL.md with missing required field, reports validation failure, and identifies the missing 'source' field.

**Steps:**
1. Lint the invalid SKILL.md file
   ```bash
   OUTPUT=$(ace-lint lint "$TEST_DIR/invalid/SKILL.md" 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify output shows file failed validation
   ```bash
   echo "$OUTPUT" | grep -qE "(failed|error)" && echo "PASS: Output indicates failure" || echo "FAIL: Output should indicate failure"
   ```

3. Verify report mentions missing 'source' field
   ```bash
   REPORT_DIR=$(echo "$OUTPUT" | grep "Reports:" | sed 's/Reports: //' | sed 's|/$||')
   grep -qi "source" "${REPORT_DIR}/pending.md" && echo "PASS: Report mentions 'source' field" || echo "FAIL: Report should mention missing 'source' field"
   ```

**Expected:**
- Output shows "✗ N failed" indicating validation failure
- pending.md report contains error about missing "source" field
- File is identified as having validation errors

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Valid SKILL.md passes validation with exit code 0 and "All files passed" output
- [ ] TC-002: Invalid SKILL.md shows failure with "failed" in output and pending.md mentions missing 'source' field

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- SKILL.md files are auto-detected by ace-lint when present
- Schema validation requires: name, description, user-invocable, allowed-tools, source
- Required comments (`# bundle:`, `# agent:`) must appear INSIDE the YAML frontmatter
- name field must start with 'ace:' or 'ace-'
- Exit codes: 0 (success), 1 (errors), 2 (fatal) - but check output for validation status
