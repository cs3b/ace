---
tc-id: TC-001
title: Help and Version Commands
---

## Objective

Verify that help command displays available commands and that version command outputs a valid semantic version.

## Steps

1. Verify help command output
   ```bash
   HELP_OUTPUT=$(ace-timestamp --help 2>&1)
   HELP_EXIT=$?
   echo "$HELP_OUTPUT"

   echo "$HELP_OUTPUT" | grep -qi "encode" && echo "PASS: Shows encode command" || echo "FAIL: Missing encode"
   echo "$HELP_OUTPUT" | grep -qi "decode" && echo "PASS: Shows decode command" || echo "FAIL: Missing decode"
   ```

2. Verify version command output
   ```bash
   VERSION_OUTPUT=$(ace-timestamp version 2>&1)
   VERSION_EXIT=$?
   echo "Version: $VERSION_OUTPUT"
   echo "Exit code: $VERSION_EXIT"

   [ "$VERSION_EXIT" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Non-zero exit"
   echo "$VERSION_OUTPUT" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+' && echo "PASS: Valid semver format" || echo "FAIL: Not semver"
   ```

3. Verify --version flag also works
   ```bash
   FLAG_OUTPUT=$(ace-timestamp --version 2>&1)
   echo "Flag output: $FLAG_OUTPUT"
   echo "$FLAG_OUTPUT" | grep -qE '[0-9]+\.[0-9]+\.[0-9]+' && echo "PASS: --version flag works" || echo "FAIL: --version flag failed"
   ```

## Expected

- Help output contains "encode" and "decode" commands
- Version command exits 0 and outputs semver pattern (e.g., "0.4.0")
- Both `version` subcommand and `--version` flag produce semver output
