# Validation Scenario: ace-docs README Subject Diff Filtering

**Scenario ID**: VS-073-001
**Feature**: Subject diff filtering with ace-docs namespace
**Target**: ace-docs/README.md with subject.diff.filters
**Status**: Ready for validation

## Overview

This validation scenario verifies that the `ace-docs diff` command correctly filters git diffs based on the `ace-docs.subject.diff.filters` configuration in the document's frontmatter. This ensures the subject/context architecture implementation is working as expected.

## Preconditions

### Required Frontmatter in ace-docs/README.md

The file `ace-docs/README.md` must contain the following frontmatter configuration:

```yaml
---
doc-type: reference
purpose: Overview and quick start guide for ace-docs
ace-docs:
  last-updated: '2025-10-14'
  context:
    preset: project
  subject:
    diff:
      filters:
        - CHANGELOG.md
        - ace-docs/**/*.rb
        - ace-docs/**/*.md
---
```

**Verification**:
```bash
head -n 15 ace-docs/README.md | grep -A 10 "ace-docs:"
```

## Test Command

**Command to execute**:
```bash
ace-docs diff ace-docs/README.md
```

**Expected internal behavior**:
1. Document model reads frontmatter from ace-docs/README.md
2. Extracts `ace-docs.subject.diff.filters` → `["CHANGELOG.md", "ace-docs/**/*.rb", "ace-docs/**/*.md"]`
3. ChangeDetector merges filters into options: `options[:paths] = filters`
4. Generates git diff with path filtering: `git diff <since>..HEAD -- CHANGELOG.md ace-docs/**/*.rb ace-docs/**/*.md`
5. Returns diff result with filtered content

## Expected Results

### Files that MUST be included (if changed since last-updated)

✅ **Root level**:
- `CHANGELOG.md` (matches first filter)

✅ **ace-docs directory - Ruby files** (match `ace-docs/**/*.rb`):
- `ace-docs/lib/ace/docs.rb`
- `ace-docs/lib/ace/docs/version.rb`
- `ace-docs/lib/ace/docs/cli.rb`
- `ace-docs/lib/ace/docs/commands/*.rb`
- `ace-docs/lib/ace/docs/atoms/*.rb`
- `ace-docs/lib/ace/docs/molecules/*.rb`
- `ace-docs/lib/ace/docs/organisms/*.rb`
- `ace-docs/lib/ace/docs/models/*.rb`
- `ace-docs/test/**/*.rb`
- Any other .rb files within ace-docs/

✅ **ace-docs directory - Markdown files** (match `ace-docs/**/*.md`):
- `ace-docs/README.md`
- `ace-docs/CHANGELOG.md`
- `ace-docs/docs/*.md` (if they exist)
- Any other .md files within ace-docs/

### Files that MUST NOT be included

❌ **Other gems** (not in filters):
- `ace-core/` (any files)
- `ace-taskflow/` (any files)
- `ace-lint/` (any files)
- `ace-llm/` (any files)
- `ace-search/` (any files)
- Any other ace-* gem directories

❌ **Root documentation** (not in filters):
- `docs/` (root level docs, NOT ace-docs/docs/)
- `README.md` (root level README, NOT ace-docs/README.md)

❌ **Task management** (not in filters):
- `.ace-taskflow/` (any files)

❌ **Development files** (not in filters):
- `dev-handbook/`
- `.claude/`
- `.ace/`

❌ **Build/test artifacts** (not in filters):
- `.cache/`
- `tmp/`
- `coverage/`

## Verification Steps

### Step 1: Verify Frontmatter Extraction

**What to check**: Document model correctly reads ace-docs namespace

**Commands**:
```bash
# Check if file has the correct frontmatter
grep -A 10 "ace-docs:" ace-docs/README.md

# Expected output should show:
# ace-docs:
#   last-updated: '2025-10-14'
#   context:
#     preset: project
#   subject:
#     diff:
#       filters:
#         - CHANGELOG.md
#         - ace-docs/**/*.rb
#         - ace-docs/**/*.md
```

**Pass criteria**: Frontmatter contains ace-docs.subject.diff.filters array with three elements

### Step 2: Execute Diff Command

**What to check**: Command runs without errors and produces output

**Commands**:
```bash
# Run the diff command
ace-docs diff ace-docs/README.md

# Check exit code
echo $?  # Should be 0
```

**Pass criteria**:
- Command completes successfully
- Exit code is 0
- Output shows diff analysis or "no changes" message

### Step 3: Verify Filter Extraction in Metadata

**What to check**: Filters are correctly extracted and stored in session metadata

**Commands**:
```bash
# Find the most recent diff session
LATEST_DIFF=$(ls -t .cache/ace-docs/diff-* 2>/dev/null | head -n 1)

# Check metadata for filter paths
cat "$LATEST_DIFF/metadata.yml" 2>/dev/null | grep -A 5 ":paths:"

# Expected output:
# :paths:
#   - CHANGELOG.md
#   - ace-docs/**/*.rb
#   - ace-docs/**/*.md
```

**Pass criteria**: Metadata file contains `:paths:` with all three filter values

### Step 4: Verify Included Files

**What to check**: Only files matching filter patterns appear in diff

**Commands**:
```bash
# Get list of files in diff output
LATEST_DIFF=$(ls -t .cache/ace-docs/diff-* 2>/dev/null | head -n 1)
cat "$LATEST_DIFF"/*.md 2>/dev/null | grep -E "^(diff --git|---|\+\+\+)" | grep "a/" | sed 's/.*a\///'

# All files should match one of these patterns:
# - CHANGELOG.md
# - ace-docs/**/*.rb
# - ace-docs/**/*.md
```

**Pass criteria**:
- Every file path starts with `CHANGELOG.md` OR
- Every file path starts with `ace-docs/` and ends with `.rb` OR
- Every file path starts with `ace-docs/` and ends with `.md`

### Step 5: Verify Excluded Files

**What to check**: No files outside filter patterns appear in diff

**Commands**:
```bash
# Check for files that should NOT be in diff
LATEST_DIFF=$(ls -t .cache/ace-docs/diff-* 2>/dev/null | head -n 1)
cat "$LATEST_DIFF"/*.md 2>/dev/null | grep -E "^(diff --git|---|\+\+\+)" | grep -E "(ace-core/|ace-taskflow/|ace-lint/|^docs/|dev-handbook/)"

# Expected: No output (empty)
# If any output: FAIL - files outside filters detected
```

**Pass criteria**: Command returns no results (exit code 1 from grep)

### Step 6: Manual Review of Diff Content

**What to check**: Diff content makes sense for ace-docs README

**Commands**:
```bash
# View the full diff output
LATEST_DIFF=$(ls -t .cache/ace-docs/diff-* 2>/dev/null | head -n 1)
cat "$LATEST_DIFF"/*.md

# Review content manually:
# - Are changes relevant to ace-docs gem?
# - Is CHANGELOG.md included if it changed?
# - Are ace-docs source files included if they changed?
```

**Pass criteria**: All changes are relevant to ace-docs documentation context

## Pass/Fail Criteria

### ✅ PASS - All conditions must be true

1. **Frontmatter**: ace-docs/README.md contains ace-docs.subject.diff.filters
2. **Execution**: Command completes with exit code 0
3. **Metadata**: Session metadata contains correct `:paths:` array
4. **Inclusion**: Diff includes ALL changed files matching filter patterns
5. **Exclusion**: Diff includes NO files outside filter patterns
6. **Relevance**: All diff content is relevant to ace-docs documentation
7. **No Errors**: No warnings or errors during execution

### ❌ FAIL - Any condition triggers failure

1. **Missing Filters**: Frontmatter missing or filters not extracted
2. **Execution Error**: Command exits with non-zero code
3. **Missing Metadata**: Session metadata missing `:paths:` field
4. **Wrong Inclusion**: Expected files missing from diff
5. **Wrong Exclusion**: Files from other gems appear in diff
6. **Invalid Output**: Diff contains files not matching any filter pattern
7. **Errors**: Warnings or errors appear during execution

## Validation Script

**Automated validation** (copy and run):

```bash
#!/bin/bash

echo "=== Validation Scenario: VS-073-001 ==="
echo "Testing: ace-docs diff ace-docs/README.md"
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# Test 1: Check frontmatter
echo "Test 1: Verify frontmatter has ace-docs.subject.diff.filters"
if grep -q "ace-docs:" ace-docs/README.md && \
   grep -A 10 "ace-docs:" ace-docs/README.md | grep -q "filters:"; then
    echo -e "${GREEN}✓ PASS${NC}: Frontmatter contains filters"
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL${NC}: Frontmatter missing or incorrect"
    ((FAIL_COUNT++))
fi
echo ""

# Test 2: Run diff command
echo "Test 2: Execute ace-docs diff ace-docs/README.md"
if ace-docs diff ace-docs/README.md > /tmp/ace-docs-diff-output.txt 2>&1; then
    echo -e "${GREEN}✓ PASS${NC}: Command executed successfully"
    ((PASS_COUNT++))
else
    EXIT_CODE=$?
    echo -e "${RED}✗ FAIL${NC}: Command failed with exit code $EXIT_CODE"
    cat /tmp/ace-docs-diff-output.txt
    ((FAIL_COUNT++))
fi
echo ""

# Test 3: Check metadata
echo "Test 3: Verify session metadata contains filter paths"
LATEST_DIFF=$(ls -t .cache/ace-docs/diff-* 2>/dev/null | head -n 1)
if [ -n "$LATEST_DIFF" ] && grep -q ":paths:" "$LATEST_DIFF/metadata.yml" 2>/dev/null; then
    echo -e "${GREEN}✓ PASS${NC}: Metadata contains :paths:"
    echo "  Paths found:"
    grep -A 5 ":paths:" "$LATEST_DIFF/metadata.yml" | sed 's/^/  /'
    ((PASS_COUNT++))
else
    echo -e "${RED}✗ FAIL${NC}: Metadata missing or no :paths: field"
    ((FAIL_COUNT++))
fi
echo ""

# Test 4: Check for unwanted files
echo "Test 4: Verify no files from other gems in diff"
if [ -n "$LATEST_DIFF" ]; then
    UNWANTED=$(cat "$LATEST_DIFF"/*.md 2>/dev/null | grep -E "^diff --git" | grep -E "(ace-core/|ace-taskflow/|ace-lint/|^a/docs/|dev-handbook/)" | head -n 5)
    if [ -z "$UNWANTED" ]; then
        echo -e "${GREEN}✓ PASS${NC}: No files from other gems found"
        ((PASS_COUNT++))
    else
        echo -e "${RED}✗ FAIL${NC}: Found files outside filter paths:"
        echo "$UNWANTED" | sed 's/^/  /'
        ((FAIL_COUNT++))
    fi
else
    echo -e "${YELLOW}⚠ SKIP${NC}: No diff session found"
fi
echo ""

# Test 5: Verify filter patterns match
echo "Test 5: Verify all files match filter patterns"
if [ -n "$LATEST_DIFF" ]; then
    TOTAL_FILES=$(cat "$LATEST_DIFF"/*.md 2>/dev/null | grep -E "^diff --git" | wc -l)
    MATCHING_FILES=$(cat "$LATEST_DIFF"/*.md 2>/dev/null | grep -E "^diff --git" | grep -E "(CHANGELOG\.md|ace-docs/.*\.(rb|md))" | wc -l)

    if [ "$TOTAL_FILES" -eq 0 ]; then
        echo -e "${YELLOW}⚠ INFO${NC}: No files in diff (no changes or empty diff)"
        ((PASS_COUNT++))
    elif [ "$TOTAL_FILES" -eq "$MATCHING_FILES" ]; then
        echo -e "${GREEN}✓ PASS${NC}: All $TOTAL_FILES files match filter patterns"
        ((PASS_COUNT++))
    else
        echo -e "${RED}✗ FAIL${NC}: $((TOTAL_FILES - MATCHING_FILES)) files don't match filter patterns"
        cat "$LATEST_DIFF"/*.md 2>/dev/null | grep -E "^diff --git" | grep -vE "(CHANGELOG\.md|ace-docs/.*\.(rb|md))" | sed 's/^/  /'
        ((FAIL_COUNT++))
    fi
else
    echo -e "${YELLOW}⚠ SKIP${NC}: No diff session found"
fi
echo ""

# Summary
echo "==================================="
echo "Validation Summary:"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo "==================================="

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ VALIDATION PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ VALIDATION FAILED${NC}"
    exit 1
fi
```

**To run validation**:
```bash
chmod +x validate-vs-073-001.sh
./validate-vs-073-001.sh
```

## Example Expected Output

### Scenario: Changes in ace-docs/lib/ace/docs/version.rb and CHANGELOG.md

**Command**: `ace-docs diff ace-docs/README.md`

**Expected output**:
```
Analyzing document: ace-docs/README.md
Document type: reference
Last updated: 2025-10-14
Applying subject filters: ["CHANGELOG.md", "ace-docs/**/*.rb", "ace-docs/**/*.md"]

Generating diff since 2025-10-14...

Changes detected in 2 files:

==================================================
File: CHANGELOG.md
==================================================
+## [0.3.3] - 2025-10-16
+- Add subject/context architecture
+- Implement subject.diff.filters
+
 ## [0.3.2] - 2025-10-14

==================================================
File: ace-docs/lib/ace/docs/version.rb
==================================================
 module Ace
   module Docs
-    VERSION = "0.3.2"
+    VERSION = "0.3.3"
   end
 end

Session saved to: .cache/ace-docs/diff-20251016-143522/
```

**Key observations**:
- Only shows 2 files (both match filters)
- CHANGELOG.md included (matches first filter)
- ace-docs/lib/ace/docs/version.rb included (matches `ace-docs/**/*.rb` filter)
- No files from other gems
- Clean, focused output

## Troubleshooting Guide

### Issue: Command fails with "document not found"

**Possible causes**:
- File path incorrect
- Document not in ace-docs discovery paths

**Resolution**:
```bash
# Check if document exists
ls -la ace-docs/README.md

# Verify frontmatter is valid YAML
head -n 20 ace-docs/README.md
```

### Issue: Diff includes files from other gems

**Possible causes**:
- Filters not being extracted from frontmatter
- ChangeDetector not using document.subject_diff_filters
- Backward compatibility fallback not working

**Resolution**:
```bash
# Check if Document model has subject_diff_filters method
grep -n "def subject_diff_filters" ace-docs/lib/ace/docs/models/document.rb

# Check if ChangeDetector uses the method
grep -n "subject_diff_filters" ace-docs/lib/ace/docs/molecules/change_detector.rb

# Verify metadata
cat .cache/ace-docs/diff-*/metadata.yml | grep -A 5 ":paths:"
```

### Issue: Metadata file missing :paths: field

**Possible causes**:
- Filters not being merged into options
- Options not being passed to metadata generation

**Resolution**:
```bash
# Check ChangeDetector implementation
grep -A 30 "def self.get_diff_for_document" ace-docs/lib/ace/docs/molecules/change_detector.rb

# Look for: options = options.merge(paths: filters)
```

### Issue: No files in diff output

**Possible causes**:
- No changes since last-updated date
- Filter paths don't match any changed files
- Since date too recent

**Resolution**:
```bash
# Check if files changed since last-updated
git log --since="2025-10-14" --oneline -- CHANGELOG.md ace-docs/

# If no output, no changes in those paths (expected)
```

## Agent Instructions

**When validating this scenario, you MUST**:

1. ✅ **Read the preconditions** - Verify frontmatter is correct
2. ✅ **Run the command** - Execute `ace-docs diff ace-docs/README.md`
3. ✅ **Check all verification steps** - Follow steps 1-6 above
4. ✅ **Run validation script** - Execute automated validation
5. ✅ **Review pass/fail criteria** - Ensure ALL pass conditions met
6. ✅ **Document results** - Note any failures or issues
7. ✅ **Report status** - PASS or FAIL with evidence

**Do NOT mark implementation complete if**:
- ❌ Any verification step fails
- ❌ Validation script exits with code 1
- ❌ Files from other gems appear in diff
- ❌ Metadata missing :paths: field
- ❌ Filters not extracted from frontmatter

**Report format**:
```
Validation Scenario: VS-073-001
Status: [PASS|FAIL]
Timestamp: [datetime]
Pass Count: X/5
Fail Count: Y/5

Failures (if any):
- Test N: [description of failure]

Evidence:
- [command outputs]
- [file paths showing issue]
```

## Success Criteria

This validation scenario is **PASSED** when:

✅ All 5 verification steps pass
✅ Validation script exits with code 0
✅ No files outside filters appear in diff
✅ Metadata contains correct :paths: array
✅ Implementation matches expected behavior

This scenario is **CRITICAL** for task 073 completion - it validates the core feature of subject diff filtering with the new ace-docs namespace architecture.
