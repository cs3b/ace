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
```

## Test Data

```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
# Create test directory structure with protocol resources
mkdir -p ".ace/nav/protocols/guide-sources"
mkdir -p ".ace/nav/protocols/wfi-sources"
mkdir -p "handbook/guides"
mkdir -p "handbook/workflows"

# Create guide protocol config
cat > ".ace/nav/protocols/guide.yml" << 'EOF'
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
cat > ".ace/nav/protocols/wfi.yml" << 'EOF'
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
cat > ".ace/nav/protocols/guide-sources/local.yml" << EOF
name: local
type: directory
path: handbook/guides
priority: 10
EOF

cat > ".ace/nav/protocols/wfi-sources/local.yml" << EOF
name: local
type: directory
path: handbook/workflows
priority: 10
EOF

# Create test guide files with various extensions
cat > "handbook/guides/markdown-style.g.md" << 'EOF'
# Markdown Style Guide
This is a guide with shorthand extension .g.md
EOF

cat > "handbook/guides/coding-standards.guide.md" << 'EOF'
# Coding Standards Guide
This is a guide with full extension .guide.md
EOF

cat > "handbook/guides/quick-reference.md" << 'EOF'
# Quick Reference
This is a guide with generic .md extension
EOF

# Create test workflow file
cat > "handbook/workflows/setup.wf.md" << 'EOF'
# Setup Workflow
This is a workflow with shorthand extension .wf.md
EOF

# Create file with only shorthand extension (no .md suffix)
# This tests inference fallback when shorthand matches first
cat > "handbook/guides/shortcuts.g" << 'EOF'
# Shortcuts Guide (shorthand only)
EOF
SANDBOX
```

## Test Cases

### TC-001: Basic Extension Inference - Shorthand Extension

**Objective:** Verify that requesting a resource without extension finds the file with shorthand protocol extension (.g.md).

**Steps:**
1. Resolve guide URI without extension
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-nav guide://markdown-style
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
   ace-test-e2e-sh "$TEST_DIR" ace-nav guide://coding-standards
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
   ace-test-e2e-sh "$TEST_DIR" ace-nav guide://quick-reference
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   # Create multiple extension variants
   cat > "handbook/guides/multi-ext.g.md" << 'EOF'
   # Multi Extension - Shorthand
   EOF
   cat > "handbook/guides/multi-ext.guide.md" << 'EOF'
   # Multi Extension - Full
   EOF
   cat > "handbook/guides/multi-ext.md" << 'EOF'
   # Multi Extension - Generic
   EOF
   SANDBOX
   ```

2. Resolve the resource
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-nav guide://multi-ext
   ```

3. Check which file was selected
   ```bash
   ace-test-e2e-sh "$TEST_DIR" ace-nav guide://multi-ext | head -1
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-nav guide://nonexistent-resource 2>&1
   echo "Exit code: $?"
   SANDBOX
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
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   mkdir -p ".ace/nav"
   cat > ".ace/nav/config.yml" << 'EOF'
   extension_inference:
     enabled: false
   EOF
   SANDBOX
   ```

2. Try to resolve without extension (should fail)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-nav guide://markdown-style 2>&1
   echo "Exit code without extension: $?"
   SANDBOX
   ```

3. Try to resolve with exact extension (should work)
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   ace-nav guide://markdown-style.g.md 2>&1
   echo "Exit code with extension: $?"
   SANDBOX
   ```

4. Re-enable extension inference for subsequent tests
   ```bash
   ace-test-e2e-sh "$TEST_DIR" rm ".ace/nav/config.yml"
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
   ace-test-e2e-sh "$TEST_DIR" ace-nav guide://coding-standards.guide.md
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
   ace-test-e2e-sh "$TEST_DIR" ace-nav wfi://setup
   ```

**Expected:**
- Exit code: 0
- Output contains path to `setup.wf.md`
- wfi:// protocol inference works like guide://

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Known Issues

- **TC-006**: Setting `extension_inference: false` in nav config does not disable extension inference as expected. The `ace-nav` command continues to infer extensions regardless of the config setting. This is a code bug in config handling, not a test issue.

## Cleanup

```bash
ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
rm -rf "$TEST_DIR"
echo "Cleanup complete"
SANDBOX
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
