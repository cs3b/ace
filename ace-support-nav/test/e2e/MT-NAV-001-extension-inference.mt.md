---
test-id: MT-NAV-001
title: Extension Inference for Protocol Resolution
area: NAV
package: ace-support-nav
priority: high
duration: ~10min
automation-candidate: true
requires:
  tools: [ace-nav, ace-timestamp]
  ruby: ">= 3.0"
last-verified: 2026-01-24
verified-by: claude-opus-4.5
---

# Extension Inference for Protocol Resolution

## Objective

Verify that ace-nav correctly infers file extensions when resolving protocol URIs. This tests the DWIM (Do What I Mean) behavior implemented in Task 224, where users can request `guide://markdown-style` and the system will find `markdown-style.g.md`.

## Prerequisites

- Ruby >= 3.0 installed
- ace-nav package available in PATH
- ace-timestamp available (for unique test directory naming)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="support-nav"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Verify tools are available
echo "=== Tool Verification ==="
which ruby && ruby --version
which ace-nav && echo "ace-nav available"
echo "========================="
```

## Test Data

```bash
# Create test directory structure with protocol resources
mkdir -p "$TEST_DIR/.ace/nav/protocols/guide-sources"
mkdir -p "$TEST_DIR/.ace/nav/protocols/wfi-sources"
mkdir -p "$TEST_DIR/handbook/guides"
mkdir -p "$TEST_DIR/handbook/workflows"

# Create guide protocol config
cat > "$TEST_DIR/.ace/nav/protocols/guide.yml" << 'EOF'
protocol: guide
description: Guide documents
extensions:
  - ".g.md"
  - ".guide.md"
  - ".md"
inferred_extensions:
  - ".g"
  - ".guide"
  - ".g.md"
  - ".guide.md"
  - ".md"
EOF

# Create workflow protocol config
cat > "$TEST_DIR/.ace/nav/protocols/wfi.yml" << 'EOF'
protocol: wfi
description: Workflow documents
extensions:
  - ".wf.md"
  - ".wfi.md"
  - ".workflow.md"
  - ".md"
inferred_extensions:
  - ".wf"
  - ".wfi"
  - ".workflow"
  - ".wf.md"
  - ".wfi.md"
  - ".workflow.md"
  - ".md"
EOF

# Create source configs pointing to handbook directories (using absolute paths)
cat > "$TEST_DIR/.ace/nav/protocols/guide-sources/local.yml" << EOF
name: local
type: directory
path: $TEST_DIR/handbook/guides
priority: 10
EOF

cat > "$TEST_DIR/.ace/nav/protocols/wfi-sources/local.yml" << EOF
name: local
type: directory
path: $TEST_DIR/handbook/workflows
priority: 10
EOF

# Create test guide files with various extensions
cat > "$TEST_DIR/handbook/guides/markdown-style.g.md" << 'EOF'
# Markdown Style Guide
This is a guide with shorthand extension .g.md
EOF

cat > "$TEST_DIR/handbook/guides/coding-standards.guide.md" << 'EOF'
# Coding Standards Guide
This is a guide with full extension .guide.md
EOF

cat > "$TEST_DIR/handbook/guides/quick-reference.md" << 'EOF'
# Quick Reference
This is a guide with generic .md extension
EOF

# Create test workflow file
cat > "$TEST_DIR/handbook/workflows/setup.wf.md" << 'EOF'
# Setup Workflow
This is a workflow with shorthand extension .wf.md
EOF

# Create file with only shorthand extension (no .md suffix)
# This tests inference fallback when shorthand matches first
cat > "$TEST_DIR/handbook/guides/shortcuts.g" << 'EOF'
# Shortcuts Guide (shorthand only)
EOF
```

## Test Cases

### TC-001: Basic Extension Inference - Shorthand Extension

**Objective:** Verify that requesting a resource without extension finds the file with shorthand protocol extension (.g.md).

**Steps:**
1. Resolve guide URI without extension
   ```bash
   cd "$TEST_DIR"
   ace-nav guide://markdown-style
   ```

**Expected:**
- Exit code: 0
- Output contains path to `markdown-style.g.md`
- File content is accessible (path is valid)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Basic Extension Inference - Full Extension

**Objective:** Verify that requesting a resource without extension finds the file with full protocol extension (.guide.md).

**Steps:**
1. Resolve guide URI without extension
   ```bash
   cd "$TEST_DIR"
   ace-nav guide://coding-standards
   ```

**Expected:**
- Exit code: 0
- Output contains path to `coding-standards.guide.md`
- Extension inference tried shorthand first, then found full extension

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Basic Extension Inference - Generic Markdown

**Objective:** Verify that requesting a resource without extension falls back to generic .md extension.

**Steps:**
1. Resolve guide URI without extension
   ```bash
   cd "$TEST_DIR"
   ace-nav guide://quick-reference
   ```

**Expected:**
- Exit code: 0
- Output contains path to `quick-reference.md`
- Inference tried protocol extensions first, then found .md

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Fallback Order Verification

**Objective:** Verify the fallback priority: protocol_shorthand -> protocol_full -> generic_markdown -> bare.

**Steps:**
1. Create files with different extensions for the same base name
   ```bash
   cd "$TEST_DIR"
   # Create multiple extension variants
   cat > "$TEST_DIR/handbook/guides/multi-ext.g.md" << 'EOF'
   # Multi Extension - Shorthand
   EOF
   cat > "$TEST_DIR/handbook/guides/multi-ext.guide.md" << 'EOF'
   # Multi Extension - Full
   EOF
   cat > "$TEST_DIR/handbook/guides/multi-ext.md" << 'EOF'
   # Multi Extension - Generic
   EOF
   ```

2. Resolve the resource
   ```bash
   ace-nav guide://multi-ext
   ```

3. Check which file was selected
   ```bash
   # The shorthand .g.md should be selected first per fallback order
   ace-nav guide://multi-ext | head -1
   ```

**Expected:**
- The `.g.md` version is returned (shorthand has highest priority)
- Only one result returned (DWIM: first match wins)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: No Match Fallback - Graceful Error

**Objective:** Verify that requesting a non-existent resource produces a graceful error.

**Steps:**
1. Request non-existent resource
   ```bash
   cd "$TEST_DIR"
   ace-nav guide://nonexistent-resource 2>&1
   echo "Exit code: $?"
   ```

**Expected:**
- Exit code: non-zero (indicates resource not found)
- Error message is informative (not a stack trace)
- Suggests available resources or indicates no match found

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Disabled Extension Inference - Exact Match Only

**Objective:** Verify that when extension_inference.enabled is false, only exact matches work.

**Steps:**
1. Create config that disables extension inference
   ```bash
   cd "$TEST_DIR"
   mkdir -p "$TEST_DIR/.ace/nav"
   cat > "$TEST_DIR/.ace/nav/config.yml" << 'EOF'
   extension_inference:
     enabled: false
   EOF
   ```

2. Try to resolve without extension (should fail)
   ```bash
   ace-nav guide://markdown-style 2>&1
   echo "Exit code without extension: $?"
   ```

3. Try to resolve with exact extension (should work)
   ```bash
   ace-nav guide://markdown-style.g.md 2>&1
   echo "Exit code with extension: $?"
   ```

4. Re-enable extension inference for subsequent tests
   ```bash
   rm "$TEST_DIR/.ace/nav/config.yml"
   ```

**Expected:**
- Without extension: Exit code non-zero (no inference, exact match fails)
- With extension: Exit code 0 (exact match works)
- Demonstrates that config correctly disables inference

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Exact Match Takes Precedence

**Objective:** Verify that providing an explicit extension bypasses inference and matches exactly.

**Steps:**
1. Resolve with explicit extension
   ```bash
   cd "$TEST_DIR"
   ace-nav guide://coding-standards.guide.md
   ```

**Expected:**
- Exit code: 0
- Output contains path to `coding-standards.guide.md`
- Exact match used (no inference needed)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-008: Cross-Protocol Extension Inference (wfi://)

**Objective:** Verify extension inference works consistently across different protocols.

**Steps:**
1. Resolve workflow URI without extension
   ```bash
   cd "$TEST_DIR"
   ace-nav wfi://setup
   ```

**Expected:**
- Exit code: 0
- Output contains path to `setup.wf.md`
- wfi:// protocol inference works like guide://

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
rm -rf "$TEST_DIR"
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-001: Shorthand extension (.g.md) found via inference
- [ ] TC-002: Full extension (.guide.md) found via inference
- [ ] TC-003: Generic markdown (.md) found via inference fallback
- [ ] TC-004: Fallback order respects configured priority
- [ ] TC-005: Non-existent resource produces graceful error
- [ ] TC-006: Disabling inference requires exact matches
- [ ] TC-007: Exact extension bypasses inference
- [ ] TC-008: Extension inference works across protocols (wfi://)

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Extension inference was implemented in Task 224 (v0.17.3)
- Default fallback order: protocol_shorthand -> protocol_full -> generic_markdown -> bare
- The DWIM behavior returns the first match, not all matches
- Inference only triggers when the exact pattern match fails
- Unit tests for ExtensionInferrer exist in `test/atoms/extension_inferrer_test.rb`
- Integration tests exist in `test/molecules/protocol_scanner_test.rb`
