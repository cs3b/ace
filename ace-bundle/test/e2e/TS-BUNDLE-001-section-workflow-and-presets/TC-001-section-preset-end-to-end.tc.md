---
tc-id: TC-001
title: Section Preset End-to-End
---

## Objective

Verify that ace-bundle loads a section preset from disk, processes files matching glob patterns, executes commands, embeds content, and produces proper XML-style tags in markdown-xml format.

## Steps

1. Load the comprehensive-review section preset
   ```bash
   OUTPUT=$(ace-bundle comprehensive-review 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

2. Verify file content is included
   ```bash
   echo "$OUTPUT" | grep -q "README.md" && echo "PASS: README.md found in output" || echo "FAIL: README.md not found"
   echo "$OUTPUT" | grep -q "package.json" && echo "PASS: package.json found in output" || echo "FAIL: package.json not found"
   ```

3. Verify command execution output is captured
   ```bash
   echo "$OUTPUT" | grep -q "Running tests" && echo "PASS: Test command executed" || echo "FAIL: Test command not executed"
   echo "$OUTPUT" | grep -q "Linting passed" && echo "PASS: Lint command executed" || echo "FAIL: Lint command not executed"
   echo "$OUTPUT" | grep -q "No security issues found" && echo "PASS: Security command executed" || echo "FAIL: Security command not executed"
   ```

4. Verify embedded section content
   ```bash
   echo "$OUTPUT" | grep -q "This comprehensive review includes" && echo "PASS: Section content found" || echo "FAIL: Section content not found"
   echo "$OUTPUT" | grep -q "Focus on security and performance" && echo "PASS: Focus statement found" || echo "FAIL: Focus statement not found"
   ```

5. Verify XML-style tags in markdown-xml format
   ```bash
   echo "$OUTPUT" | grep -q "<file path=" && echo "PASS: XML file tags found" || echo "FAIL: XML file tags not found"
   echo "$OUTPUT" | grep -q "</file>" && echo "PASS: Closing file tags found" || echo "FAIL: Closing file tags not found"
   echo "$OUTPUT" | grep -q "<output command=" && echo "PASS: XML output tags found" || echo "FAIL: XML output tags not found"
   echo "$OUTPUT" | grep -q "</output>" && echo "PASS: Closing output tags found" || echo "FAIL: Closing output tags not found"
   echo "$OUTPUT" | grep -q "Complete Review" && echo "PASS: Section title found" || echo "FAIL: Section title not found"
   ```

## Expected

- Exit code: 0
- Output contains file content (README.md, package.json)
- Output contains command execution results (all 3 commands)
- Output contains embedded section content
- Output contains XML-style `<file path=...>` and `<output command=...>` tags with closing tags
- Section title "Complete Review" present in output
