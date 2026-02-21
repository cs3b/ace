---
tc-id: TC-001
title: Help and Version Commands
---

## Objective

Verify that help command displays available commands and that version command outputs a valid semantic version.

## Steps

1. Verify help command output
   ```bash
   HELP_OUTPUT=$(ace-b36ts --help 2>&1)
   HELP_EXIT=$?
   echo "$HELP_OUTPUT"

   if echo "$HELP_OUTPUT" | grep -qi "encode"; then
     echo "PASS: Shows encode command"
   else
     echo "FAIL: Missing encode"
   fi
   if echo "$HELP_OUTPUT" | grep -qi "decode"; then
     echo "PASS: Shows decode command"
   else
     echo "FAIL: Missing decode"
   fi
   ```

2. Verify version command output
   ```bash
   VERSION_OUTPUT=$(ace-b36ts version 2>&1)
   VERSION_EXIT=$?
   echo "Version: $VERSION_OUTPUT"
   echo "Exit code: $VERSION_EXIT"

   if [ "$VERSION_EXIT" -eq 0 ]; then
     echo "PASS: Exit code 0"
   else
     echo "FAIL: Non-zero exit"
   fi
   if echo "$VERSION_OUTPUT" | grep -qE '^ace-b36ts [0-9]+\.[0-9]+\.[0-9]+$'; then
     echo "PASS: Valid semver format"
   else
     echo "FAIL: Not semver"
   fi
   ```

3. Verify --version flag also works
   ```bash
   FLAG_OUTPUT=$(ace-b36ts --version 2>&1)
   echo "Flag output: $FLAG_OUTPUT"
   if echo "$FLAG_OUTPUT" | grep -qE '^ace-b36ts [0-9]+\.[0-9]+\.[0-9]+$'; then
     echo "PASS: --version flag works"
   else
     echo "FAIL: --version flag failed"
   fi
   ```

## Expected

- Help output contains "encode" and "decode" commands
- Version command exits 0 and outputs semver pattern (e.g., "0.4.0")
- Both `version` subcommand and `--version` flag produce semver output
