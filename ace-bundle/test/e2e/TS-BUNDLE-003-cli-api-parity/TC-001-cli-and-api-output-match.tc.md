---
tc-id: TC-001
title: CLI and API Output Match
---

## Objective

Verify that the CLI subprocess and Ruby API produce identical output for the same input, and both handle errors consistently for invalid inputs.

## Steps

1. Get CLI output for a valid context file
   ```bash
   CLI_OUTPUT=$(ace-bundle test-context.md 2>&1)
   CLI_EXIT=$?
   echo "CLI exit code: $CLI_EXIT"
   ```

2. Get API output for the same file
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

4. Verify CLI error handling for nonexistent file
   ```bash
   CLI_ERR=$(ace-bundle nonexistent-file.md 2>&1)
   CLI_EXIT=$?
   echo "CLI exit: $CLI_EXIT, output: $CLI_ERR"
   [ "$CLI_EXIT" -ne 0 ] && echo "PASS: CLI returns non-zero for invalid input" || echo "FAIL: Expected non-zero exit"
   ```

5. Verify API error handling for nonexistent file
   ```bash
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
   [ "$API_EXIT" -ne 0 ] && echo "PASS: API returns non-zero for invalid input" || echo "FAIL: Expected non-zero exit"
   ```

## Expected

- Both CLI and API exit 0 for valid input
- Outputs are byte-identical for valid input
- Both return non-zero exit code for nonexistent file
- Both indicate file not found or similar error
