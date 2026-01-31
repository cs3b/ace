---
test-id: MT-REVIEW-004
title: GitHub CLI Integration
area: review
package: ace-review
priority: high
duration: ~15min
automation-candidate: true
requires:
  tools: [gh, ace-review]
  ruby: ">= 3.0"
  external: [github-auth, network]
last-verified: null
verified-by: null
---

# GitHub CLI Integration

## Objective

Verify that ace-review's GitHub CLI integration correctly handles gh CLI detection, authentication verification, PR data fetching (diff, metadata, comments), and error scenarios with real GitHub API interactions.

## Prerequisites

- Ruby >= 3.0 installed
- gh CLI installed and authenticated
- Network access to GitHub API
- A real public repository with pull requests (ace-task repo)

## Environment Setup

```bash
# Capture project root before changing directories
PROJECT_ROOT="$(pwd)"

TIMESTAMP_ID="$(ace-timestamp encode)"
SHORT_PKG="review"
SHORT_ID="mt004"
TEST_DIR="$PROJECT_ROOT/.cache/ace-test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# Initialize git repo (needed for project root detection)
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

# Set PROJECT_ROOT_PATH for isolated testing
export PROJECT_ROOT_PATH="$TEST_DIR"

# Test PR configuration - use a real public PR from ace-task repo
# PR #90 is a known merge PR that should be available
TEST_REPO="cs3b/ace-task"
TEST_PR_NUMBER="90"
NONEXISTENT_PR_NUMBER="999999"

echo "=== Tool Verification ==="
which gh && gh --version || echo "gh not in PATH"
which ace-review && ace-review --version || echo "ace-review not in PATH"
echo "========================="
```

## Test Data

```bash
# Create minimal preset for testing
mkdir -p "$TEST_DIR/.ace/review/presets"

cat > "$TEST_DIR/.ace/review/presets/pr.yml" << 'EOF'
description: "PR review preset for testing"
model: test-model
EOF

cat > "$TEST_DIR/.ace/review/config.yml" << 'EOF'
defaults:
  model: "test-model"
EOF

# Create a test file for subject when needed
echo "# Test File" > "$TEST_DIR/test.rb"
git add .
git commit -m "Initial commit" --quiet
```

## Test Cases

### TC-001: gh CLI Installation Check

**Objective:** Verify that gh CLI is installed and accessible.

**Steps:**
1. Check gh CLI version
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(gh --version 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify gh is installed
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: gh CLI is installed" || echo "FAIL: gh CLI not found"
   echo "$OUTPUT" | grep -q "gh version" && echo "PASS: gh version string present" || echo "FAIL: Version string missing"
   ```

**Expected:**
- Exit code: 0
- Output contains "gh version"

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-002: gh Authentication Status

**Objective:** Verify that gh CLI is authenticated with GitHub.

**Steps:**
1. Check authentication status
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(gh auth status 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify authenticated
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: gh is authenticated" || echo "FAIL: gh not authenticated"
   echo "$OUTPUT" | grep -qi "logged in\|authenticated" && echo "PASS: Auth status confirmed" || echo "INFO: Auth message may vary"
   ```

**Expected:**
- Exit code: 0
- Output indicates logged in status

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-003: Fetch PR Diff

**Objective:** Verify that PR diff can be fetched via gh CLI.

**Steps:**
1. Fetch diff for a known PR
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(gh pr diff "$TEST_PR_NUMBER" --repo "$TEST_REPO" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Diff length: ${#OUTPUT} characters"
   echo "First 500 chars:"
   echo "${OUTPUT:0:500}"
   ```

2. Verify diff content
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Diff fetched successfully" || echo "FAIL: Failed to fetch diff"
   [ ${#OUTPUT} -gt 0 ] && echo "PASS: Diff has content" || echo "FAIL: Diff is empty"
   echo "$OUTPUT" | grep -qE "^(\+|\-|diff|@@)" && echo "PASS: Diff format looks correct" || echo "INFO: May be a no-change PR"
   ```

**Expected:**
- Exit code: 0
- Output contains diff content (unified diff format)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-004: Fetch PR Metadata

**Objective:** Verify that PR metadata can be fetched as JSON via gh CLI.

**Steps:**
1. Fetch PR metadata
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(gh pr view "$TEST_PR_NUMBER" --repo "$TEST_REPO" --json number,state,title,author,isDraft,baseRefName,headRefName 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify metadata content
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Metadata fetched successfully" || echo "FAIL: Failed to fetch metadata"
   echo "$OUTPUT" | jq -e '.number' > /dev/null 2>&1 && echo "PASS: Valid JSON with number field" || echo "FAIL: Invalid JSON or missing number"
   echo "$OUTPUT" | jq -e '.state' > /dev/null 2>&1 && echo "PASS: State field present" || echo "FAIL: State field missing"
   echo "$OUTPUT" | jq -e '.title' > /dev/null 2>&1 && echo "PASS: Title field present" || echo "FAIL: Title field missing"
   ```

**Expected:**
- Exit code: 0
- Valid JSON with number, state, title fields

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-005: Fetch PR Comments via GraphQL

**Objective:** Verify that PR comments and review threads can be fetched via GraphQL API.

**Steps:**
1. Fetch PR comments using GraphQL
   ```bash
   cd "$TEST_DIR"
   # Extract owner and repo from TEST_REPO
   OWNER=$(echo "$TEST_REPO" | cut -d'/' -f1)
   REPO=$(echo "$TEST_REPO" | cut -d'/' -f2)

   QUERY='query($owner: String!, $repo: String!, $number: Int!) {
     repository(owner: $owner, name: $repo) {
       pullRequest(number: $number) {
         number
         title
         comments(first: 10) {
           nodes {
             id
             body
             author { login }
           }
         }
         reviews(first: 10) {
           nodes {
             id
             state
             author { login }
           }
         }
         reviewThreads(first: 10) {
           nodes {
             id
             isResolved
             path
           }
         }
       }
     }
   }'

   OUTPUT=$(gh api graphql -f query="$QUERY" -F owner="$OWNER" -F repo="$REPO" -F number="$TEST_PR_NUMBER" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT" | jq '.' 2>/dev/null || echo "$OUTPUT"
   ```

2. Verify GraphQL response
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: GraphQL query succeeded" || echo "FAIL: GraphQL query failed"
   echo "$OUTPUT" | jq -e '.data.repository.pullRequest.number' > /dev/null 2>&1 && echo "PASS: PR data in response" || echo "FAIL: Missing PR data"
   echo "$OUTPUT" | jq -e '.data.repository.pullRequest.comments' > /dev/null 2>&1 && echo "PASS: Comments field present" || echo "FAIL: Comments missing"
   echo "$OUTPUT" | jq -e '.data.repository.pullRequest.reviewThreads' > /dev/null 2>&1 && echo "PASS: Review threads field present" || echo "FAIL: Review threads missing"
   ```

**Expected:**
- Exit code: 0
- Valid GraphQL response with PR data, comments, and review threads

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-006: Error Handling for Non-Existent PR

**Objective:** Verify that appropriate error is returned for a non-existent PR.

**Steps:**
1. Attempt to fetch a non-existent PR
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(gh pr view "$NONEXISTENT_PR_NUMBER" --repo "$TEST_REPO" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify error handling
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit for missing PR" || echo "FAIL: Expected non-zero exit code"
   echo "$OUTPUT" | grep -qi "not found\|could not\|no pull request" && echo "PASS: Appropriate error message" || echo "INFO: Error message may vary"
   ```

**Expected:**
- Exit code: non-zero
- Error message indicates PR not found

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Error Handling for Network/Timeout Scenarios

**Objective:** Verify behavior with invalid repository (simulates connectivity issues).

**Steps:**
1. Attempt to access invalid repository
   ```bash
   cd "$TEST_DIR"
   OUTPUT=$(gh pr view 1 --repo "nonexistent-user-xyz/nonexistent-repo-abc" 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output:"
   echo "$OUTPUT"
   ```

2. Verify error handling
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit for invalid repo" || echo "FAIL: Expected non-zero exit code"
   echo "$OUTPUT" | grep -qi "not found\|could not resolve\|error" && echo "PASS: Error indicates failure" || echo "INFO: Error message may vary"
   ```

**Expected:**
- Exit code: non-zero
- Error message indicates repository or PR not found

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

Cleanup is optional. The workflow controls this via `cleanup.enabled` setting (default: disabled).
Artifacts in `.cache/ace-test-e2e/` are gitignored, so keeping them doesn't affect the repository.

```bash
# Only run if cleanup is enabled - reports are preserved by default
# rm -rf "$TEST_DIR"
```

## Success Criteria

- [ ] TC-001: gh CLI is installed and accessible
- [ ] TC-002: gh CLI is authenticated
- [ ] TC-003: PR diff can be fetched
- [ ] TC-004: PR metadata can be fetched as JSON
- [ ] TC-005: PR comments can be fetched via GraphQL
- [ ] TC-006: Non-existent PR returns appropriate error
- [ ] TC-007: Invalid repository returns appropriate error

## Observations

{Record any observations, edge cases, or issues discovered during test execution}

## Notes

- These tests replace integration tests from:
  - ace-review/test/molecules/gh_cli_executor_test.rb (13 tests)
  - ace-review/test/molecules/gh_pr_fetcher_test.rb (13 tests)
  - ace-review/test/molecules/gh_pr_comment_fetcher_test.rb (19 tests)
- Tests use real GitHub API calls to verify end-to-end functionality
- PR #90 from cs3b/ace-task is used as a stable test fixture
- Authentication must be configured via `gh auth login` before running
- Tests verify the gh CLI layer that ace-review depends on for PR operations
