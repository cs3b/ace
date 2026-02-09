---
test-id: MT-BUNDLE-001a
title: Error Handling and Section Workflow
area: bundle
package: ace-bundle
priority: high
duration: ~5min
automation-candidate: true
requires:
  tools: [ace-bundle]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Error Handling and Section Workflow

## Objective

Verify that ace-bundle handles nonexistent presets gracefully and correctly processes section-based presets with files, commands, and content.

## Prerequisites

- Ruby >= 3.0 installed
- ace-bundle package available in PATH
- Write access to create test directories

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="bundle"
SHORT_ID="mt001a"
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
# Create test project structure
mkdir -p src
mkdir -p test
mkdir -p .ace/bundle/presets

# Create source files
cat > src/main.js << 'EOF'
// Main application code
console.log('Hello World');
EOF

cat > src/utils.js << 'EOF'
// Utility functions
export function helper() { return true; }
EOF

cat > test/main.test.js << 'EOF'
// Test file
describe('Main', () => { it('should work', () => { expect(true).toBe(true); }); });
EOF

cat > package.json << 'EOF'
{
  "name": "test-app",
  "scripts": { "test": "jest", "lint": "eslint src/" },
  "devDependencies": { "jest": "^29.0.0", "eslint": "^8.0.0" }
}
EOF

cat > README.md << 'EOF'
# Test Application

This is a test application for section workflow integration testing.
EOF

# Create comprehensive-review preset with sections
cat > .ace/bundle/presets/comprehensive-review.md << 'PRESET'
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
SANDBOX
```

## Test Cases

### TC-001: Error - Nonexistent Preset

**Objective:** Verify that ace-bundle handles nonexistent presets gracefully with a clear error message.

**Steps:**
1. Attempt to load a nonexistent preset and verify error handling
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle nonexistent-preset 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Correct non-zero exit code" || echo "FAIL: Expected non-zero exit"
   echo "$OUTPUT" | grep -qi "not found\|unknown\|error" && echo "PASS: Error message present" || echo "FAIL: No error message"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"

   PASS=0; FAIL=0
   echo "$OUTPUT" | grep -q "README.md" && { echo "PASS: README.md found in output"; PASS=$((PASS+1)); } || { echo "FAIL: README.md not found"; FAIL=$((FAIL+1)); }
   echo "$OUTPUT" | grep -q "package.json" && { echo "PASS: package.json found in output"; PASS=$((PASS+1)); } || { echo "FAIL: package.json not found"; FAIL=$((FAIL+1)); }
   echo "$OUTPUT" | grep -q "Running tests" && { echo "PASS: Command output found"; PASS=$((PASS+1)); } || { echo "FAIL: Command output not found"; FAIL=$((FAIL+1)); }
   echo "$OUTPUT" | grep -q "This comprehensive review includes" && { echo "PASS: Section content found"; PASS=$((PASS+1)); } || { echo "FAIL: Section content not found"; FAIL=$((FAIL+1)); }
   echo "$OUTPUT" | grep -q "Focus on security and performance" && { echo "PASS: Focus statement found"; PASS=$((PASS+1)); } || { echo "FAIL: Focus statement not found"; FAIL=$((FAIL+1)); }
   echo "TC-002 assertions: $PASS passed, $FAIL failed"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains file content (README.md, package.json)
- Output contains command execution results
- Output contains embedded section content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

## Success Criteria

- [ ] TC-001: Nonexistent preset returns error gracefully
- [ ] TC-002: Section workflow loads files, commands, and content
