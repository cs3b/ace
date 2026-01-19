---
test-id: MT-{AREA}-{NNN}
title: {Descriptive Title}
area: {area-name}
package: {package-name}
priority: high|medium|low
duration: ~{X}min
automation-candidate: true|false
requires:
  tools: [{tool1}, {tool2}]
  ruby: ">= 3.0"
last-verified: YYYY-MM-DD
verified-by: {agent-name}
---

# {Title}

## Objective

{What this test verifies - 1-2 sentences describing the purpose and scope}

## Prerequisites

- {Requirement 1 - e.g., Ruby >= 3.0 installed}
- {Requirement 2 - e.g., StandardRB gem available}

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TEST_ID="$(ace-timestamp encode)"
TEST_DIR="$PROJECT_ROOT/.cache/test-e2e/${TEST_ID}-{package-name}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Use $PROJECT_ROOT/bin/ace-{tool} for project binaries
```

## Test Data

```bash
# Create test files
cat > "$TEST_DIR/example.rb" << 'EOF'
# Example Ruby file for testing
class Example
  def hello
    puts "Hello, World!"
  end
end
EOF
```

## Test Cases

### TC-001: {Test Case Name}

**Objective:** {What this specific test case verifies}

**Steps:**
1. {Step description}
   ```bash
   {command to execute}
   ```

**Expected:**
- Exit code: {expected exit code}
- Output contains: "{expected output substring}"
- {Additional expectations}

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: {Test Case Name}

**Objective:** {What this specific test case verifies}

**Steps:**
1. {Step description}
   ```bash
   {command to execute}
   ```

**Expected:**
- {Expected behavior}

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: {Summary criterion}
- [ ] TC-002: {Summary criterion}

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- {Any additional notes about this test scenario}
- {Known limitations or considerations}
