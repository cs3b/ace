---
test-id: MT-BUNDLE-003
title: CLI and API Output Parity
area: cli
package: ace-bundle
priority: high
duration: ~2min
automation-candidate: false
requires:
  tools: [ace-bundle]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
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
TIMESTAMP_ID="${RUN_ID:-$(ace-timestamp encode)}"
SHORT_PKG="bundle"
SHORT_ID="mt003"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR" || { echo "FATAL: Cannot cd to sandbox"; exit 1; }

# Set PROJECT_ROOT_PATH for sandbox isolation
export PROJECT_ROOT_PATH="$TEST_DIR"

# Init git repo so ProjectRootFinder finds sandbox as root
git init "$TEST_DIR"
git -C "$TEST_DIR" config user.email "test@example.com"
git -C "$TEST_DIR" config user.name "Test User"

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
SANDBOX
```

## Test Cases

### TC-001: CLI and API Output Match

**Objective:** Verify CLI subprocess and Ruby API produce byte-identical output

**Steps:**
1. Get CLI and API output, then compare
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   CLI_OUTPUT=$(ace-bundle test-context.md 2>&1)
   CLI_EXIT=$?
   echo "CLI exit code: $CLI_EXIT"

   API_OUTPUT=$(ruby -r ace/bundle -e '
     result = Ace::Bundle.load_file("test-context.md")
     puts result.content
   ' 2>&1)
   API_EXIT=$?
   echo "API exit code: $API_EXIT"

   if [ "$CLI_OUTPUT" = "$API_OUTPUT" ]; then
     echo "PASS: CLI and API outputs are identical"
   else
     echo "FAIL: Outputs differ"
     echo "=== CLI OUTPUT ==="
     echo "$CLI_OUTPUT" | head -20
     echo "=== API OUTPUT ==="
     echo "$API_OUTPUT" | head -20
   fi
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   CLI_ERR=$(ace-bundle nonexistent-file.md 2>&1)
   CLI_EXIT=$?
   echo "CLI exit: $CLI_EXIT, output: $CLI_ERR"
   SANDBOX
   ```

2. Test API with same input
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   API_ERR=$(ruby -r ace/bundle -e '
     result = Ace::Bundle.load_file("nonexistent-file.md")
     if result.metadata[:error]
       puts result.metadata[:error]
       exit 1
     else
       puts "No error returned"
       exit 0
     end
   ' 2>&1)
   API_EXIT=$?
   echo "API exit: $API_EXIT, output: $API_ERR"
   SANDBOX
   ```

**Expected:**
- Both return non-zero exit code (CLI via CLI::Error, API via metadata[:error] check)
- Both indicate file not found or similar error

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

## Success Criteria

- [ ] TC-001: CLI and API produce identical output for valid input
- [ ] TC-002: Both handle errors consistently

## Notes

- This test was migrated from `ace-bundle/test/integration/cli_api_parity_test.rb`
- Requires real subprocess execution - cannot be mocked
- Tests the contract between CLI and API layers
