---
test-id: MT-PREP-001
title: Basic Prompt Processing Workflow
area: prep
package: ace-prompt-prep
priority: high
duration: ~15min
automation-candidate: false
requires:
  tools: [ace-prompt-prep, ace-bundle, ace-timestamp]
  ruby: ">= 3.0"
last-verified:
verified-by:
---

# Basic Prompt Processing Workflow

## Objective

Verify the core ace-prompt-prep workflow: setup creates workspace with template, process archives prompts with Base36 IDs, symlinks are maintained correctly, and context loading integrates with ace-bundle.

## Prerequisites

- Ruby >= 3.0 installed
- ace-prompt-prep package available in PATH
- ace-bundle package available (for context loading tests)
- ace-timestamp package available (for test ID generation)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="prompt-prep"
SHORT_ID="mt001"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Create isolated prompt workspace for testing
export ACE_PROMPT_PREP_ROOT="$TEST_DIR/prompt-workspace"
mkdir -p "$ACE_PROMPT_PREP_ROOT"

# Verify tools are available
echo "=== Tool Verification ==="
which ruby && ruby --version
which ace-prompt-prep && ace-prompt-prep --version
which ace-bundle && ace-bundle --version 2>/dev/null || echo "ace-bundle available"
which ace-timestamp && ace-timestamp --version 2>/dev/null || echo "ace-timestamp available"
echo "========================="
```

## Test Data

```bash
# Create a sample prompt file
cat > "$TEST_DIR/sample-prompt.md" << 'EOF'
---
bundle:
  presets:
    - project
---

# Task: Implement Feature X

Please help me implement feature X with the following requirements:

1. Create a new module
2. Add unit tests
3. Update documentation

## Context

This is for the ACE project.
EOF

# Create a minimal prompt (no frontmatter)
cat > "$TEST_DIR/minimal-prompt.md" << 'EOF'
Help me debug this error in my Ruby code.

The error message is: undefined method 'foo' for nil:NilClass
EOF

# Create a prompt for task-specific testing
cat > "$TEST_DIR/task-prompt.md" << 'EOF'
---
task: 121
---

Work on task 121: Fix the authentication bug.
EOF
```

## Test Cases

### TC-001: Setup Creates Prompt Workspace

**Objective:** Verify that `ace-prompt-prep setup` creates the workspace directory structure with a template prompt file.

**Steps:**
1. Run setup command
   ```bash
   cd "$TEST_DIR"
   ace-prompt-prep setup
   ```

2. Verify directory structure was created
   ```bash
   ls -la "$ACE_PROMPT_PREP_ROOT/prompts/" 2>/dev/null || ls -la .cache/ace-prompt-prep/prompts/
   ```

3. Verify template file exists
   ```bash
   cat .cache/ace-prompt-prep/prompts/the-prompt.md 2>/dev/null | head -20
   ```

**Expected:**
- Exit code: 0
- `.cache/ace-prompt-prep/prompts/` directory exists
- `the-prompt.md` file created with template content
- Template includes frontmatter section

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: Process Archives Prompt with Base36 ID

**Objective:** Verify that processing a prompt archives it with a Base36 timestamp ID.

**Steps:**
1. Copy sample prompt to workspace
   ```bash
   cp "$TEST_DIR/sample-prompt.md" .cache/ace-prompt-prep/prompts/the-prompt.md
   ```

2. Process the prompt
   ```bash
   ace-prompt-prep
   ```

3. List archived files
   ```bash
   ls -la .cache/ace-prompt-prep/prompts/
   ```

4. Verify archive file naming (Base36 format: 6 alphanumeric chars)
   ```bash
   ls .cache/ace-prompt-prep/prompts/*.md | grep -E '[a-z0-9]{6}\.md'
   ```

**Expected:**
- Exit code: 0
- Archive file created with Base36 ID (e.g., `i50jj3.md`)
- Original prompt content preserved in archive
- Output contains the processed prompt content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: _previous.md Symlink Updated Correctly

**Objective:** Verify that the `_previous.md` symlink points to the most recently archived prompt.

**Steps:**
1. Ensure we have a processed prompt from TC-002
   ```bash
   ls -la .cache/ace-prompt-prep/prompts/
   ```

2. Check symlink exists and target
   ```bash
   ls -la .cache/ace-prompt-prep/prompts/_previous.md
   ```

3. Verify symlink points to an archive file
   ```bash
   readlink .cache/ace-prompt-prep/prompts/_previous.md
   ```

4. Verify content matches
   ```bash
   diff .cache/ace-prompt-prep/prompts/_previous.md "$TEST_DIR/sample-prompt.md"
   ```

**Expected:**
- `_previous.md` symlink exists
- Symlink points to the archive file (e.g., `i50jj3.md`)
- Content of symlink target matches original prompt

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Multiple Archives Maintain History

**Objective:** Verify that processing multiple prompts creates sequential archives and updates the symlink.

**Steps:**
1. Process first prompt (should already exist from TC-002)
   ```bash
   FIRST_ARCHIVE=$(readlink .cache/ace-prompt-prep/prompts/_previous.md)
   echo "First archive: $FIRST_ARCHIVE"
   ```

2. Copy and process a different prompt
   ```bash
   cp "$TEST_DIR/minimal-prompt.md" .cache/ace-prompt-prep/prompts/the-prompt.md
   sleep 1  # Ensure different timestamp
   ace-prompt-prep
   ```

3. Get second archive
   ```bash
   SECOND_ARCHIVE=$(readlink .cache/ace-prompt-prep/prompts/_previous.md)
   echo "Second archive: $SECOND_ARCHIVE"
   ```

4. Verify archives are different
   ```bash
   [ "$FIRST_ARCHIVE" != "$SECOND_ARCHIVE" ] && echo "Archives are different (PASS)" || echo "Archives are same (FAIL)"
   ```

5. List all archives
   ```bash
   ls -la .cache/ace-prompt-prep/prompts/
   ```

**Expected:**
- Two different archive files exist
- `_previous.md` now points to the second archive
- Both archives contain their respective original content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Bundle Processing with --bundle Flag

**Objective:** Verify that the `--bundle` flag integrates with ace-bundle SDK to process the prompt.

**Steps:**
1. Copy prompt with bundle frontmatter
   ```bash
   cp "$TEST_DIR/sample-prompt.md" .cache/ace-prompt-prep/prompts/the-prompt.md
   ```

2. Process with bundle flag
   ```bash
   cd "$PROJECT_ROOT"  # Need to be in project root for bundle processing
   ace-prompt-prep --bundle 2>&1 | head -50
   ```

3. Verify output includes bundled content
   ```bash
   ace-prompt-prep --bundle 2>&1 | grep -E "(Project Context|Files|Context loaded)" || echo "Check output manually"
   ```

**Expected:**
- Exit code: 0
- Output includes processed content from ace-bundle SDK
- Original prompt content is preserved
- Bundle content appears before or after prompt content

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
echo "Cleanup complete: $TEST_DIR removed"
```

## Success Criteria

- [ ] TC-001: Setup creates workspace with template prompt
- [ ] TC-002: Process archives prompt with Base36 ID
- [ ] TC-003: _previous.md symlink correctly maintained
- [ ] TC-004: Multiple archives create history chain
- [ ] TC-005: Bundle processing integrates with ace-bundle SDK

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- Base36 IDs use ace-timestamp encoding (format: 6 lowercase alphanumeric characters)
- The `_previous.md` symlink is relative to the prompts directory
- Bundle processing requires being in a valid ace project directory
- Enhancement features (--enhance flag) are not tested here - see MT-PREP-002 for LLM integration tests
