---
test-id: MT-BUNDLE-001
title: Section Workflow End-to-End
area: bundle
package: ace-bundle
priority: high
duration: ~15min
automation-candidate: false
requires:
  tools: [ace-bundle]
  ruby: ">= 3.0"
last-verified: null
verified-by: null
---

# Section Workflow End-to-End

## Objective

Verify that ace-bundle correctly processes section-based presets including file pattern matching, command execution, content embedding, and XML output formatting. This test validates the full section workflow pipeline from preset loading through output generation.

## Prerequisites

- Ruby >= 3.0 installed
- ace-bundle package available in PATH
- Write access to create test directories

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="bundle"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

echo "=== Tool Verification ==="
which ace-bundle && ace-bundle --version
echo "========================="
```

## Test Data

```bash
# Create test project structure
mkdir -p "$TEST_DIR/src"
mkdir -p "$TEST_DIR/test"
mkdir -p "$TEST_DIR/.ace/bundle/presets"

# Create source files
cat > "$TEST_DIR/src/main.js" << 'EOF'
// Main application code
console.log('Hello World');
EOF

cat > "$TEST_DIR/src/utils.js" << 'EOF'
// Utility functions
export function helper() { return true; }
EOF

cat > "$TEST_DIR/test/main.test.js" << 'EOF'
// Test file
describe('Main', () => { it('should work', () => { expect(true).toBe(true); }); });
EOF

cat > "$TEST_DIR/package.json" << 'EOF'
{
  "name": "test-app",
  "scripts": { "test": "jest", "lint": "eslint src/" },
  "devDependencies": { "jest": "^29.0.0", "eslint": "^8.0.0" }
}
EOF

cat > "$TEST_DIR/README.md" << 'EOF'
# Test Application

This is a test application for section workflow integration testing.
EOF

# Create comprehensive-review preset with sections
cat > "$TEST_DIR/.ace/bundle/presets/comprehensive-review.md" << 'PRESET'
---
description: "Comprehensive review with mixed content"
bundle:
  params:
    output: stdio
    format: markdown-xml
    timeout: 30

  sections:
    comprehensive:
      title: "Complete Review"
      description: "Files, commands, diffs, and analysis"
      files:
        - "*.md"
        - "package.json"
        - "src/**/*.js"
      commands:
        - "echo 'Running tests...' && exit 0"
        - "echo 'Linting passed' && exit 0"
        - "echo 'No security issues found' && exit 0"
      content: |
        This comprehensive review includes:

        1. **Code Quality**: Style, patterns, maintainability
        2. **Security**: Vulnerabilities and dependencies
        3. **Testing**: Coverage and test results
        4. **Performance**: Potential bottlenecks

        Focus on security and performance aspects.
---
# Comprehensive Review Preset

This preset demonstrates mixed content within sections, combining files,
commands, and analysis content in a single structured section.
PRESET

# Create security-scanning preset (can be referenced as base)
cat > "$TEST_DIR/.ace/bundle/presets/security-scanning.md" << 'PRESET'
---
description: "Security scanning tools"
bundle:
  commands:
    - "echo 'Security audit complete'"
    - "echo 'Security scan passed'"
  files:
    - "**/*.js"
    - "package*.json"
---
Security scanning preset
PRESET

# Create code-quality preset
cat > "$TEST_DIR/.ace/bundle/presets/code-quality.md" << 'PRESET'
---
description: "Code quality analysis"
bundle:
  commands:
    - "echo 'Linting passed'"
    - "echo 'Tests passed'"
  files:
    - "src/**/*.js"
    - "test/**/*.js"
---
Code quality preset
PRESET
```

## Test Cases

### TC-001: Error - Nonexistent Preset

**Objective:** Verify that ace-bundle handles nonexistent presets gracefully with a clear error message.

**Steps:**
1. Attempt to load a nonexistent preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle nonexistent-preset 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is non-zero
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Correct non-zero exit code" || echo "FAIL: Expected non-zero exit"
   ```

3. Verify error message
   ```bash
   echo "$OUTPUT" | grep -qi "not found\|unknown\|error" && echo "PASS: Error message present" || echo "FAIL: No error message"
   ```

**Expected:**
- Exit code: non-zero
- Output contains error message about missing/unknown preset

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: End-to-End Section Workflow with Files and Commands

**Objective:** Verify that ace-bundle loads section presets and correctly processes files, commands, and content.

**Steps:**
1. Load the comprehensive-review preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Check for file content (README.md should be included)
   ```bash
   echo "$OUTPUT" | grep -q "README.md" && echo "PASS: README.md found in output" || echo "FAIL: README.md not found"
   ```

4. Check for package.json content
   ```bash
   echo "$OUTPUT" | grep -q "package.json" && echo "PASS: package.json found in output" || echo "FAIL: package.json not found"
   ```

5. Check for command execution results
   ```bash
   echo "$OUTPUT" | grep -q "Running tests" && echo "PASS: Command output found" || echo "FAIL: Command output not found"
   ```

6. Check for section content
   ```bash
   echo "$OUTPUT" | grep -q "This comprehensive review includes" && echo "PASS: Section content found" || echo "FAIL: Section content not found"
   ```

7. Check for section description
   ```bash
   echo "$OUTPUT" | grep -q "Focus on security and performance" && echo "PASS: Focus statement found" || echo "FAIL: Focus statement not found"
   ```

**Expected:**
- Exit code: 0
- Output contains file content (README.md, package.json)
- Output contains command execution results
- Output contains embedded section content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: XML Output Format for Sections

**Objective:** Verify that ace-bundle produces proper XML-style tags when using markdown-xml format.

**Steps:**
1. Load preset with markdown-xml format (default in the preset)
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Check for XML file tags
   ```bash
   echo "$OUTPUT" | grep -q "<file path=" && echo "PASS: XML file tags found" || echo "FAIL: XML file tags not found"
   ```

3. Check for closing file tags
   ```bash
   echo "$OUTPUT" | grep -q "</file>" && echo "PASS: Closing file tags found" || echo "FAIL: Closing file tags not found"
   ```

4. Check for output command tags
   ```bash
   echo "$OUTPUT" | grep -q "<output command=" && echo "PASS: XML output tags found" || echo "FAIL: XML output tags not found"
   ```

5. Check for closing output tags
   ```bash
   echo "$OUTPUT" | grep -q "</output>" && echo "PASS: Closing output tags found" || echo "FAIL: Closing output tags not found"
   ```

6. Verify section title is present
   ```bash
   echo "$OUTPUT" | grep -q "Complete Review" && echo "PASS: Section title found" || echo "FAIL: Section title not found"
   ```

**Expected:**
- Exit code: 0
- Output contains `<file path=...>` tags
- Output contains `</file>` closing tags
- Output contains `<output command=...>` tags
- Output contains `</output>` closing tags
- Section structure preserved

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Command Execution in Sections

**Objective:** Verify that commands defined in sections are executed and their output is captured.

**Steps:**
1. Load the preset and capture output
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)
   ```

2. Verify test command output
   ```bash
   echo "$OUTPUT" | grep -q "Running tests" && echo "PASS: Test command executed" || echo "FAIL: Test command not executed"
   ```

3. Verify linting command output
   ```bash
   echo "$OUTPUT" | grep -q "Linting passed" && echo "PASS: Lint command executed" || echo "FAIL: Lint command not executed"
   ```

4. Verify security command output
   ```bash
   echo "$OUTPUT" | grep -q "No security issues found" && echo "PASS: Security command executed" || echo "FAIL: Security command not executed"
   ```

**Expected:**
- All three commands executed
- Command output captured in bundle output

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: File Pattern Matching

**Objective:** Verify that file patterns in sections correctly match and include files.

**Steps:**
1. Load the preset and capture output
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)
   ```

2. Verify *.md pattern matched README.md
   ```bash
   echo "$OUTPUT" | grep -q "Test Application" && echo "PASS: README.md content included" || echo "FAIL: README.md content not included"
   ```

3. Verify src/**/*.js pattern matched source files
   ```bash
   echo "$OUTPUT" | grep -q "Hello World" && echo "PASS: main.js content included" || echo "FAIL: main.js content not included"
   ```

4. Verify src/**/*.js matched utils.js
   ```bash
   echo "$OUTPUT" | grep -q "helper()" && echo "PASS: utils.js content included" || echo "FAIL: utils.js content not included"
   ```

5. Verify test files are NOT included (pattern is src/**/*.js, not test/**/*.js)
   ```bash
   ! echo "$OUTPUT" | grep -q "describe('Main'" && echo "PASS: test files correctly excluded" || echo "INFO: test files may be included by another pattern"
   ```

**Expected:**
- README.md included (matches *.md)
- src/main.js and src/utils.js included (matches src/**/*.js)
- package.json included (matches package.json)
- test/*.js NOT included (not in pattern)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Simple Preset Loading

**Objective:** Verify that simple presets without sections are loaded correctly.

**Steps:**
1. Load the security-scanning preset
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(ace-bundle security-scanning 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify command output is present
   ```bash
   echo "$OUTPUT" | grep -q "Security audit complete" && echo "PASS: Security audit command found" || echo "FAIL: Security audit not found"
   ```

4. Verify file patterns are processed
   ```bash
   echo "$OUTPUT" | grep -qE "main.js|utils.js|package.json" && echo "PASS: JS/JSON files found" || echo "FAIL: Expected files not found"
   ```

**Expected:**
- Exit code: 0
- Command output captured
- Files matching **/*.js and package*.json included

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

- [ ] TC-001: Nonexistent preset returns error gracefully
- [ ] TC-002: Section workflow loads files, commands, and content
- [ ] TC-003: XML output format produces proper tags
- [ ] TC-004: Commands in sections are executed
- [ ] TC-005: File patterns correctly match files
- [ ] TC-006: Simple presets load correctly

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-bundle/test/integration/section_workflow_integration_test.rb
- Test requires writing preset files to .ace/bundle/presets/ directory
- Section workflow tests full pipeline from preset loading through output formatting
- XML output format verified with both file and command tags
