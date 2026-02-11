---
tc-id: TC-002
title: Process Archives Prompt and Updates Symlink
---

## Objective

Verify that processing a prompt archives it with a Base36 timestamp ID and that the `_previous.md` symlink points to the most recently archived prompt.

## Steps

1. Copy sample prompt to workspace
   ```bash
   mkdir -p .cache/ace-prompt-prep/prompts
   cp sample-prompt.md .cache/ace-prompt-prep/prompts/the-prompt.md
   ```

2. Process the prompt
   ```bash
   ace-prompt-prep
   ```

3. Verify archive file exists with Base36 ID naming (6 alphanumeric chars)
   ```bash
   ARCHIVE_COUNT=$(ls .cache/ace-prompt-prep/prompts/archive/*.md 2>/dev/null | wc -l | tr -d ' ')
   [ "$ARCHIVE_COUNT" -ge 1 ] && echo "PASS: archive file created ($ARCHIVE_COUNT files)" || echo "FAIL: no archive files found"

   ls .cache/ace-prompt-prep/prompts/archive/*.md | while read f; do
     BASENAME=$(basename "$f" .md)
     if echo "$BASENAME" | grep -qE '^[a-z0-9]{6}$'; then
       echo "PASS: archive uses Base36 ID ($BASENAME)"
     else
       echo "INFO: archive name ($BASENAME) - may include suffix"
     fi
   done
   ```

4. Verify _previous.md symlink exists and points to archive
   ```bash
   test -L .cache/ace-prompt-prep/prompts/_previous.md && echo "PASS: _previous.md symlink exists" || echo "FAIL: _previous.md symlink missing"

   SYMLINK_TARGET=$(readlink .cache/ace-prompt-prep/prompts/_previous.md)
   echo "$SYMLINK_TARGET" | grep -q "archive/" && echo "PASS: symlink points to archive ($SYMLINK_TARGET)" || echo "FAIL: symlink target unexpected ($SYMLINK_TARGET)"
   ```

5. Verify archived content matches original prompt
   ```bash
   diff .cache/ace-prompt-prep/prompts/_previous.md sample-prompt.md > /dev/null 2>&1 && echo "PASS: archived content matches original" || echo "FAIL: archived content differs from original"
   ```

## Expected

- Exit code 0 from process command
- Archive file created in `.cache/ace-prompt-prep/prompts/archive/` with Base36 ID
- `_previous.md` symlink exists and points to the archive file
- Archived content matches the original prompt
