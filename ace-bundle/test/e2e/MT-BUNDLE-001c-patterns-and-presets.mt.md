---
test-id: MT-BUNDLE-001c
title: File Pattern Matching and Preset Loading
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

# File Pattern Matching and Preset Loading

## Objective

Verify that file patterns in sections correctly match and include files, and that simple presets without sections load correctly.

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
SHORT_ID="mt001c"
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

# Create security-scanning preset
cat > .ace/bundle/presets/security-scanning.md << 'PRESET'
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
SANDBOX
```

## Test Cases

### TC-005: File Pattern Matching

**Objective:** Verify that file patterns in sections correctly match and include files.

**Steps:**
1. Load the preset and capture output
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)

   PASS=0; FAIL=0
   echo "$OUTPUT" | grep -q "Test Application" && { echo "PASS: README.md content included"; PASS=$((PASS+1)); } || { echo "FAIL: README.md content not included"; FAIL=$((FAIL+1)); }
   echo "$OUTPUT" | grep -q "Hello World" && { echo "PASS: main.js content included"; PASS=$((PASS+1)); } || { echo "FAIL: main.js content not included"; FAIL=$((FAIL+1)); }
   echo "$OUTPUT" | grep -q "helper()" && { echo "PASS: utils.js content included"; PASS=$((PASS+1)); } || { echo "FAIL: utils.js content not included"; FAIL=$((FAIL+1)); }
   ! echo "$OUTPUT" | grep -q "describe('Main'" && { echo "PASS: test files correctly excluded"; PASS=$((PASS+1)); } || { echo "INFO: test files may be included by another pattern"; FAIL=$((FAIL+1)); }
   echo "TC-005 assertions: $PASS passed, $FAIL failed"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-bundle security-scanning 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"

   PASS=0; FAIL=0
   echo "$OUTPUT" | grep -q "Security audit complete" && { echo "PASS: Security audit command found"; PASS=$((PASS+1)); } || { echo "FAIL: Security audit not found"; FAIL=$((FAIL+1)); }
   echo "$OUTPUT" | grep -qE "main.js|utils.js|package.json" && { echo "PASS: JS/JSON files found"; PASS=$((PASS+1)); } || { echo "FAIL: Expected files not found"; FAIL=$((FAIL+1)); }
   echo "TC-006 assertions: $PASS passed, $FAIL failed"
   SANDBOX
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

## Success Criteria

- [ ] TC-005: File patterns correctly match files
- [ ] TC-006: Simple presets load correctly
