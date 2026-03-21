---
doc-type: template
title: E2E Sandbox Setup Checklist
purpose: E2E sandbox setup checklist
ace-docs:
  last-updated: 2026-03-04
  last-checked: 2026-03-21
---

# E2E Sandbox Setup Checklist

**Test ID**: TS-{{AREA}}-{{NNN}}
**Package**: {{package}}
**Date**: {{date}}

## Pre-Setup Verification

### Tool Requirements

- [ ] Required tools installed:
  - [ ] {{tool_1}} (version: {{version}})
  - [ ] {{tool_2}} (version: {{version}})
- [ ] Tool versions verified:
  ```bash
  {{tool_1}} --version
  {{tool_2}} --version
  ```

### Environment Requirements

- [ ] Ruby version: {{version}}
- [ ] Working directory writable
- [ ] Network access (if needed): {{yes/no}}
- [ ] External API access (if needed): {{yes/no}}

---

## Sandbox Creation

### 1. Create Isolated Directory

```bash
TIMESTAMP_ID="$(ace-b36ts encode)"
SHORT_PKG="{{short-pkg}}"  # Package name without ace- prefix
SHORT_ID="ts{{nnn}}"       # Lowercase test number
TEST_DIR=".ace-local/test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
REPORTS_DIR="${TEST_DIR}-reports"

mkdir -p "$TEST_DIR"
mkdir -p "$REPORTS_DIR"
cd "$TEST_DIR"

# Capture for cleanup
echo "$TEST_DIR" > /tmp/current-e2e-sandbox
```

- [ ] Directory created
- [ ] Reports directory created
- [ ] Path recorded for cleanup

### 2. Set Environment Variables

```bash
# Isolate from main project
export PROJECT_ROOT_PATH="$TEST_DIR"

# Disable any caching that might pollute
export ACE_TEST_MODE=true

# Set test-specific config if needed
export ACE_CONFIG_PATH="$TEST_DIR/.ace"
```

- [ ] PROJECT_ROOT_PATH set to sandbox
- [ ] Test mode enabled
- [ ] Config path isolated

### 3. Initialize Git Repository (if needed)

```bash
git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"
```

- [ ] Git initialized
- [ ] User config set (prevents prompts)

---

## External API Safety

### API Token Handling

- [ ] Using test/sandbox tokens, NOT production
- [ ] Token scope limited to minimum required
- [ ] Token stored in environment variable, not file

```bash
# Example: GitHub test token with limited scope
export GITHUB_TOKEN="${TEST_GITHUB_TOKEN:-}"
if [ -z "$GITHUB_TOKEN" ]; then
  echo "SKIP: No test token available"
  exit 0
fi
```

### API Call Safety

- [ ] Test endpoints used (not production)
- [ ] Rate limiting considered
- [ ] Cleanup API calls planned

| API | Test Endpoint | Production Endpoint | Using |
|-----|---------------|---------------------|-------|
| GitHub | api.github.com (test org) | api.github.com | Test |
| LLM | - | - | Skipped/Mocked |

### Rollback Plan

If test creates resources that need cleanup:

```bash
# Record resources created
echo "{{resource_type}}: {{resource_id}}" >> "$REPORTS_DIR/resources-created.txt"

# Cleanup function
cleanup_resources() {
  while read -r line; do
    type=$(echo "$line" | cut -d: -f1)
    id=$(echo "$line" | cut -d: -f2)
    # Delete resource
    {{cleanup_command}} "$id"
  done < "$REPORTS_DIR/resources-created.txt"
}
```

- [ ] Resources tracked
- [ ] Cleanup function defined
- [ ] Cleanup runs on success AND failure

---

## Test Data Setup

### Create Test Files

```bash
cat > "$TEST_DIR/{{filename}}" << 'EOF'
{{file_content}}
EOF
```

- [ ] Test files created
- [ ] File permissions correct
- [ ] Content matches test requirements

### Create Test Configuration

```bash
mkdir -p "$TEST_DIR/.ace/{{tool}}"
cat > "$TEST_DIR/.ace/{{tool}}/config.yml" << 'EOF'
{{config_content}}
EOF
```

- [ ] Config directory created
- [ ] Config file created
- [ ] Config values appropriate for test

---

## Execution Safety

### Timeout Protection

```bash
# Prevent runaway tests
timeout 300 {{command}} || {
  echo "FAIL: Command timed out after 300s"
  exit 1
}
```

- [ ] Timeout set for long-running commands
- [ ] Timeout value appropriate

### Output Capture

```bash
# Capture all output for analysis
{{command}} > "$REPORTS_DIR/stdout.txt" 2> "$REPORTS_DIR/stderr.txt"
EXIT_CODE=$?
echo "$EXIT_CODE" > "$REPORTS_DIR/exit_code.txt"
```

- [ ] stdout captured
- [ ] stderr captured
- [ ] Exit code recorded

---

## Cleanup

### On Success

```bash
# Optional: Remove sandbox if test passed
if [ "$ALL_TESTS_PASSED" = "true" ]; then
  rm -rf "$TEST_DIR"
  echo "Sandbox cleaned up"
fi
```

### On Failure

```bash
# Keep sandbox for debugging
echo "Sandbox preserved at: $TEST_DIR"
echo "Reports at: $REPORTS_DIR"
```

### Always

```bash
# Restore environment
unset PROJECT_ROOT_PATH
unset ACE_TEST_MODE
unset ACE_CONFIG_PATH

# Clean up any API resources
cleanup_resources 2>/dev/null || true
```

- [ ] Environment variables restored
- [ ] API resources cleaned up
- [ ] Sandbox disposition documented

---

## Verification Checklist

Before running test:

- [ ] Sandbox is isolated (PROJECT_ROOT_PATH set)
- [ ] Git is initialized (if needed)
- [ ] Test tokens are non-production
- [ ] API scopes are minimal
- [ ] Cleanup is defined
- [ ] Timeouts are set
- [ ] Output capture is configured

After running test:

- [ ] Results recorded in reports directory
- [ ] Resources cleaned up (or cleanup planned)
- [ ] Sandbox preserved (failure) or cleaned (success)
- [ ] No pollution to main project

---

## Quick Setup Script

```bash
#!/bin/bash
# e2e-sandbox-setup.sh

set -e

TIMESTAMP_ID="$(ace-b36ts encode)"
SHORT_PKG="${1:-unknown}"
SHORT_ID="${2:-ts000}"

TEST_DIR=".ace-local/test-e2e/${TIMESTAMP_ID}-${SHORT_PKG}-${SHORT_ID}"
REPORTS_DIR="${TEST_DIR}-reports"

mkdir -p "$TEST_DIR" "$REPORTS_DIR"
cd "$TEST_DIR"

export PROJECT_ROOT_PATH="$TEST_DIR"
export ACE_TEST_MODE=true

git init --quiet .
git config user.email "test@example.com"
git config user.name "Test User"

echo "Sandbox ready: $TEST_DIR"
echo "Reports: $REPORTS_DIR"
```