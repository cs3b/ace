---
test-id: MT-LINT-007
title: Validator Configuration Overrides
area: lint
package: ace-lint
priority: high
duration: ~10min
automation-candidate: false
requires:
  tools: [standardrb, rubocop]
  ruby: ">= 3.0"
last-verified: 2026-02-07
verified-by: claude-opus-4-6
---

# Validator Configuration Overrides

## Objective

Verify that ace-lint supports validator selection overrides via CLI `--validators` flag, `.ace/lint/` configuration files, and group-based routing patterns.

## Prerequisites

- Ruby >= 3.0 installed
- StandardRB gem installed (`gem install standardrb`)
- RuboCop gem installed (`gem install rubocop`)
- ace-lint package available in PATH

## Environment Setup + Test Data

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="lint"
SHORT_ID="mt007"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo (needed for project root detection)
git init --quiet .

echo "=== Tool Verification ==="
which ruby && ruby --version
which standardrb && standardrb --version || echo "StandardRB not available"
which rubocop && rubocop --version || echo "RuboCop not available"
echo "========================="

# Valid Ruby file (passes all linters)
cat > "$TEST_DIR/valid.rb" << 'EOF'
# frozen_string_literal: true

class Greeter
  def greet(name)
    "Hello, #{name}!"
  end
end
EOF
```

## Test Cases

### TC-001: CLI Validator Override

**Objective:** Verify that the validator can be explicitly specified via CLI.

**Steps:**
1. Force RuboCop and StandardRB explicitly via --validators flag
   ```bash
   echo "=== TC-001: CLI Validator Override ==="
   echo "=== Force RuboCop ==="
   ace-lint lint --validators rubocop "$TEST_DIR/valid.rb"
   echo "=== Force StandardRB ==="
   ace-lint lint --validators standardrb "$TEST_DIR/valid.rb"
   ```

**Expected:**
- First command uses RuboCop (verify from output)
- Second command uses StandardRB (verify from output)
- Both produce valid lint results

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Configuration Override + TC-003: Group-based Routing

**Objective:** Verify that validator selection can be configured via .ace/lint/ configuration files (TC-002) and that file groups route to correct validators (TC-003).

**Steps:**
1. Create configuration to prefer RuboCop, lint, then overwrite with group routing config and lint each group
   ```bash
   echo "=== TC-002: Configuration Override ==="
   mkdir -p "$TEST_DIR/.ace/lint"
   cat > "$TEST_DIR/.ace/lint/ruby.yml" << 'EOF'
   groups:
     default:
       patterns:
         - "**/*.rb"
       validators:
         - rubocop
   EOF
   cd "$TEST_DIR"
   ace-lint lint valid.rb

   echo "=== TC-003: Group-based Routing ==="
   cat > "$TEST_DIR/.ace/lint/ruby.yml" << 'EOF'
   groups:
     legacy:
       patterns:
         - "**/legacy/**/*.rb"
       validators:
         - rubocop
     modern:
       patterns:
         - "**/modern/**/*.rb"
       validators:
         - standardrb
     default:
       patterns:
         - "**/*.rb"
       validators:
         - standardrb
   EOF
   mkdir -p "$TEST_DIR/legacy" "$TEST_DIR/modern"
   cp "$TEST_DIR/valid.rb" "$TEST_DIR/legacy/"
   cp "$TEST_DIR/valid.rb" "$TEST_DIR/modern/"
   cd "$TEST_DIR"
   echo "=== Legacy (expect RuboCop) ==="
   ace-lint lint legacy/valid.rb
   echo "=== Modern (expect StandardRB) ==="
   ace-lint lint modern/valid.rb
   ```

**Expected:**
- TC-002: Configuration is respected, RuboCop is used despite StandardRB being available
- TC-003: Legacy file uses RuboCop, Modern file uses StandardRB
- All files are linted successfully

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Success Criteria

- [ ] TC-001: CLI --validators flag overrides defaults
- [ ] TC-002: Configuration file overrides validator selection
- [ ] TC-003: Group-based routing directs to correct validators

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- This test requires both StandardRB and RuboCop to be installed
- Auto-fix may produce different results depending on tool versions
