---
tc-id: TC-001
title: Setup Creates Prompt Workspace
---

## Objective

Verify that `ace-prompt-prep setup` creates the workspace directory structure with a template prompt file using the real binary (no mocks).

## Steps

1. Run setup command to create workspace
   ```bash
   ace-prompt-prep setup
   ```

2. Verify workspace directory was created
   ```bash
   test -d .cache/ace-prompt-prep/prompts && echo "PASS: workspace directory exists" || echo "FAIL: workspace directory missing"
   ```

3. Verify template prompt file exists and has content
   ```bash
   test -f .cache/ace-prompt-prep/prompts/the-prompt.md && echo "PASS: template file exists" || echo "FAIL: template file missing"
   wc -l < .cache/ace-prompt-prep/prompts/the-prompt.md | awk '{if ($1 > 0) print "PASS: template has content ("$1" lines)"; else print "FAIL: template is empty"}'
   ```

## Expected

- Exit code 0 from setup command
- `.cache/ace-prompt-prep/prompts/` directory exists
- `the-prompt.md` file created with template content (non-empty)
