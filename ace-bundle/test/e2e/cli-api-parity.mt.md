---
test-id: MT-BUNDLE-001
title: CLI and API Output Parity
area: cli
package: ace-bundle
priority: high
duration: ~2min
automation-candidate: false
requires:
  tools: [ace-bundle]
  ruby: ">= 3.0"
last-verified: 2026-01-31
verified-by: claude
---

# CLI and API Output Parity

## Objective

Verify that `ace-bundle` CLI and Ruby API produce identical output for the same input, ensuring users get consistent results regardless of how they invoke the tool.

## Prerequisites

- Ruby >= 3.0 installed
- ace-bundle gem available
- Project with .ace/bundle/presets/ structure

## Environment Setup

```bash
PROJECT_ROOT="$(pwd)"
TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="bundle"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
```

## Test Data

```bash
# Create test context file with sections
mkdir -p .ace/bundle/presets
cat > test-context.md << 'EOF'
---
bundle:
  base: "Base prompt content for parity test"
  sections:
    format:
      title: "Format Guidelines"
      files:
        - "prompt://format/standard"
    tone:
      title: "Communication Style"
      files:
        - "prompt://guidelines/tone"
---
EOF
```

## Test Cases

### TC-001: CLI and API Output Match

**Objective:** Verify CLI subprocess and Ruby API produce byte-identical output

**Steps:**
1. Get CLI output
   ```bash
   CLI_OUTPUT=$(ace-bundle test-context.md 2>&1)
   CLI_EXIT=$?
   echo "CLI exit code: $CLI_EXIT"
   ```

2. Get API output via Ruby
   ```bash
   API_OUTPUT=$(ruby -r ace/bundle -e '
     result = Ace::Bundle.load_file("test-context.md")
     puts result.content
   ' 2>&1)
   API_EXIT=$?
   echo "API exit code: $API_EXIT"
   ```

3. Compare outputs
   ```bash
   if [ "$CLI_OUTPUT" = "$API_OUTPUT" ]; then
     echo "PASS: CLI and API outputs are identical"
   else
     echo "FAIL: Outputs differ"
     echo "=== CLI OUTPUT ==="
     echo "$CLI_OUTPUT" | head -20
     echo "=== API OUTPUT ==="
     echo "$API_OUTPUT" | head -20
   fi
   ```

**Expected:**
- Both exit code: 0
- Outputs are byte-identical
- Both contain "Base prompt content"
- Both have embedded section content (not just references)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Error - Invalid Input Parity

**Objective:** Verify CLI and API produce similar error handling for invalid inputs

**Steps:**
1. Test with non-existent file
   ```bash
   CLI_ERR=$(ace-bundle nonexistent-file.md 2>&1)
   CLI_EXIT=$?
   echo "CLI exit: $CLI_EXIT, output: $CLI_ERR"
   ```

2. Test API with same input
   ```bash
   API_ERR=$(ruby -r ace/bundle -e '
     begin
       Ace::Bundle.load_file("nonexistent-file.md")
     rescue => e
       puts e.message
       exit 1
     end
   ' 2>&1)
   API_EXIT=$?
   echo "API exit: $API_EXIT, output: $API_ERR"
   ```

**Expected:**
- Both return non-zero exit code
- Both indicate file not found or similar error

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

## Cleanup

```bash
# Artifacts preserved for debugging - cleanup optional
# rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: CLI and API produce identical output for valid input
- [ ] TC-002: Both handle errors consistently

## Notes

- This test was migrated from `ace-bundle/test/integration/cli_api_parity_test.rb`
- Requires real subprocess execution - cannot be mocked
- Tests the contract between CLI and API layers
