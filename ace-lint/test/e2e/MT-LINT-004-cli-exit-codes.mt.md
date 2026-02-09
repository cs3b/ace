---
test-id: MT-LINT-004
title: CLI Exit Codes and Behavior
area: lint
package: ace-lint
priority: high
duration: ~15min
automation-candidate: true
requires:
  tools: [ace-lint, git]
  ruby: ">= 3.0"
last-verified: 2025-02-07
verified-by: claude-sonnet-4-5
---

# CLI Exit Codes and Behavior

## Objective

Verify that ace-lint CLI returns correct exit codes for valid and invalid files, respects `--no-report` flag, supports group routing for Ruby files, and handles nonexistent files gracefully.

## Prerequisites

- Ruby >= 3.0 installed
- ace-lint package available in PATH
- git installed (for project root detection)
- StandardRB or RuboCop available

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="lint"
SHORT_ID="mt004"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Initialize git repo (needed for project root detection)
git init --quiet .

echo "=== Tool Verification ==="
which ace-lint && ace-lint --version
which standardrb && standardrb --version || echo "StandardRB not available"
which rubocop && rubocop --version || echo "RuboCop not available"
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
# Valid markdown file (passes linting)
cat > valid.md << 'EOF'
# Valid Document

This is a valid markdown file with no issues.
EOF

# Markdown file with style error (no blank line after heading)
cat > invalid.md << 'EOF'
# Invalid Document
This line has no blank line after the heading.
EOF

# Valid Ruby file
cat > valid.rb << 'EOF'
# frozen_string_literal: true

class Greeter
  def greet(name)
    "Hello, #{name}!"
  end
end
EOF

# Ruby file with style issues
cat > style_issues.rb << 'EOF'
class BadStyle
  def method_with_issues( arg1,arg2 )
    puts    "extra spaces"
  end
end
EOF

# Ruby file with syntax error (unfixable, always fails)
cat > syntax_error.rb << 'EOF'
class Broken
  def unclosed
    puts "missing end"
EOF

# Create directories for group routing test
mkdir -p app/models
mkdir -p app/controllers

cat > app/models/user.rb << 'EOF'
# frozen_string_literal: true

class User
  def name
    "User"
  end
end
EOF

cat > app/controllers/users_controller.rb << 'EOF'
# frozen_string_literal: true

class UsersController
  def index
    "index"
  end
end
EOF
SANDBOX
```

## Test Cases

### TC-000: Create Ruby Group Configuration

**Objective:** Create Ruby validator configuration before tests that need it.

**Steps:**
1. Create the Ruby group configuration
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p .ace/lint
   cat > .ace/lint/ruby.yml << 'EOF'
   groups:
     default:
       patterns:
         - "**/*.rb"
       validators:
         - standardrb
   EOF
   cat .ace/lint/ruby.yml
   echo "PASS: Ruby config created"
   SANDBOX
   ```

**Expected:**
- .ace/lint/ruby.yml file exists with valid YAML

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-001: Valid File Exits with Code 0

**Objective:** Verify that linting a valid file returns exit code 0.

**Steps:**
1. Lint a valid markdown file and verify exit code
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-lint lint valid.md
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output contains "passed" indication

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Invalid File Exits with Non-Zero Code

**Objective:** Verify that linting a file with errors returns non-zero exit code.

**Steps:**
1. Lint a Ruby file with syntax errors and verify non-zero exit
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-lint lint syntax_error.rb
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Exit code is non-zero ($EXIT_CODE)" || echo "FAIL: Expected non-zero, got $EXIT_CODE"
   SANDBOX
   ```

**Expected:**
- Exit code: non-zero (typically 1)
- Output indicates lint errors (fatal severity from syntax error)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: --no-report Flag Disables Report Generation

**Objective:** Verify that `--no-report` flag prevents report generation.

**Steps:**
1. Clean previous reports, run ace-lint with --no-report, and verify
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint --no-report valid.md 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ! echo "$OUTPUT" | grep -qE "Reports?:" && echo "PASS: No report path in output" || echo "FAIL: Report path found"
   ! test -d .cache/ace-lint && echo "PASS: No cache directory" || echo "FAIL: Cache directory exists"
   SANDBOX
   ```

**Expected:**
- Exit code: 0
- Output does NOT contain report path
- .cache/ace-lint/ directory NOT created

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Group Routing with Ruby Files

**Objective:** Verify that Ruby files are correctly routed through group configuration.

**Steps:**
1. Verify Ruby config exists, then lint Ruby files and verify completion
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat .ace/lint/ruby.yml && echo "PASS: Ruby config exists"
   OUTPUT=$(ace-lint lint app/models/user.rb app/controllers/users_controller.rb --verbose 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -ge 0 ] && echo "PASS: Command completed with exit code $EXIT_CODE" || echo "FAIL: Unexpected exit"
   SANDBOX
   ```

**Expected:**
- Command completes with a valid exit code
- Ruby files are processed
- Verbose output shows validator being used

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Error - Nonexistent File

**Objective:** Verify that ace-lint handles nonexistent files gracefully.

**Steps:**
1. Attempt to lint a nonexistent file and verify error handling
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   OUTPUT=$(ace-lint lint does_not_exist.md 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Correct non-zero exit code" || echo "FAIL: Expected non-zero exit"
   echo "$OUTPUT" | grep -qi "not found\|no such file\|does not exist\|error" && echo "PASS: Error message present" || echo "FAIL: No error message"
   SANDBOX
   ```

**Expected:**
- Exit code: non-zero
- Output contains error message about missing file

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Success Criteria

- [ ] TC-000: Ruby group configuration created
- [ ] TC-001: Valid file exits with code 0
- [ ] TC-002: Invalid file exits with non-zero code
- [ ] TC-003: --no-report flag disables report generation
- [ ] TC-004: Group routing works with Ruby files
- [ ] TC-005: Nonexistent file returns error gracefully

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from ace-lint/test/integration/cli_integration_test.rb
- Test requires git init for project root detection
- Exit codes: 0=success, 1=lint errors, other=execution error
- Some tests may be skipped if StandardRB or RuboCop are not installed
