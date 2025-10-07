# Clipboard Support for Idea Create - Usage Guide

## Overview

The clipboard support feature adds a `--clipboard` flag to the `ace-taskflow idea create` command, allowing users to capture ideas directly from their system clipboard. This eliminates manual copy-paste operations and enables faster idea capture workflows.

**Available Features:**
- Read clipboard content with `--clipboard` flag
- Automatic content type detection (text vs file paths)
- Content merging (clipboard + command arguments)
- Multiple file attachment support
- Seamless integration with existing flags (`--git-commit`, `--llm-enhance`, etc.)

**Key Benefits:**
- Faster idea capture workflow
- Support for multi-file references from clipboard
- Cross-platform support (macOS, Linux)
- Zero manual file selection or copy-paste

## Command Types

This feature enhances the **bash CLI command**: `ace-taskflow idea create`

All examples below are bash commands run from your terminal, not Claude Code commands.

## Command Structure

### Basic Syntax

```bash
ace-taskflow idea create [content] --clipboard [options]
```

### Parameters

- `content` (optional): Text content for the idea
- `--clipboard` (required): Flag to read from clipboard
- `--git-commit`, `-gc`: Auto-commit the created idea file
- `--llm-enhance`, `-llm`: Enhance idea with LLM suggestions
- `--backlog`: Create idea in backlog instead of active release
- `--release <name>`: Create idea in specific release

### Default Behavior

- Without `--clipboard`: Creates idea from command arguments only
- With `--clipboard` + content: Merges clipboard content with arguments
- With `--clipboard` only: Uses clipboard as sole content source

## Usage Scenarios

### Scenario 1: Capture from Clipboard Only

**Goal:** Quickly capture an idea that's already in your clipboard

**Steps:**
```bash
# 1. Copy text to clipboard (e.g., from browser, editor, etc.)
# Text in clipboard: "Add rate limiting to API endpoints"

# 2. Create idea from clipboard
ace-taskflow idea create --clipboard
```

**Expected Output:**
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251007-123456-add-rate-limiting-to-api-endpoints.md
```

**Result:** New idea file created with clipboard text as content

---

### Scenario 2: Combine Text Arguments with Clipboard

**Goal:** Add context to clipboard content with a descriptive prefix

**Steps:**
```bash
# 1. Copy implementation details to clipboard
# Clipboard: "Use redis for distributed rate limiting with 100 req/min limit"

# 2. Create idea with context + clipboard content
ace-taskflow idea create "API Enhancement:" --clipboard
```

**Expected Output:**
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251007-123457-api-enhancement.md
```

**Result:** Idea file contains:
```markdown
API Enhancement:

Use redis for distributed rate limiting with 100 req/min limit

---
Captured: 2025-10-07 12:34:57
```

---

### Scenario 3: Multiple Files from Clipboard

**Goal:** Create idea with multiple file references selected in Finder/file manager

**Steps:**
```bash
# 1. In Finder (macOS) or file manager (Linux):
#    - Select multiple files
#    - Copy them (Cmd+C on macOS, Ctrl+C on Linux)
#    - Clipboard now contains file paths

# 2. Create idea with file references
ace-taskflow idea create "Refactor these authentication modules" --clipboard
```

**Expected Output:**
```
Idea captured with 3 attached files: .ace-taskflow/v.0.9.0/ideas/20251007-123458-refactor-these-authentication-modules.md
Files:
- lib/ace/taskflow/auth/validator.rb
- lib/ace/taskflow/auth/token_manager.rb
- lib/ace/taskflow/auth/session_store.rb
```

**Result:** Idea file contains text + file reference list

---

### Scenario 4: Auto-commit with LLM Enhancement

**Goal:** Capture idea from clipboard, enhance it with LLM, and commit to git

**Steps:**
```bash
# 1. Copy rough idea to clipboard
# Clipboard: "batch idea processing multiple ideas at once"

# 2. Create, enhance, and commit
ace-taskflow idea create --clipboard --llm-enhance --git-commit
```

**Expected Output:**
```
Enhancing idea with LLM...
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251007-123459-implement-batch-idea-processing.md
Git commit successful: docs(v.0.9.0): add idea - implement batch idea processing
```

**Result:** Enhanced idea file created and committed to git

---

### Scenario 5: Empty Clipboard Error

**Goal:** Understand error handling when clipboard is empty

**Steps:**
```bash
# 1. Clear clipboard (or ensure it's empty)

# 2. Try to create idea from clipboard
ace-taskflow idea create --clipboard
```

**Expected Output:**
```
Error: Clipboard is empty. Provide text argument or copy content to clipboard.
```

**Result:** Command fails with helpful error message

---

### Scenario 6: Backlog Idea from Clipboard

**Goal:** Capture future idea from clipboard directly to backlog

**Steps:**
```bash
# 1. Copy future feature idea to clipboard
# Clipboard: "Support for idea templates with custom fields"

# 2. Create in backlog
ace-taskflow idea create --clipboard --backlog
```

**Expected Output:**
```
Idea captured: .ace-taskflow/backlog/ideas/20251007-123500-support-for-idea-templates.md
```

**Result:** Idea created in backlog instead of active release

## Command Reference

### Full Command Syntax

```bash
ace-taskflow idea create [CONTENT...] --clipboard [OPTIONS]
```

### Options Detail

| Option | Shorthand | Description | Default |
|--------|-----------|-------------|---------|
| `--clipboard` | `-c` | Read content from system clipboard | Not enabled |
| `--git-commit` | `-gc` | Auto-commit created idea file | From config |
| `--no-git-commit` | - | Disable auto-commit | - |
| `--llm-enhance` | `-llm` | Enhance idea with LLM | From config |
| `--no-llm-enhance` | - | Disable LLM enhancement | - |
| `--backlog` | - | Create in backlog | Active release |
| `--release NAME` | `-r NAME` | Create in specific release | Active release |
| `--current` | - | Create in current release | Default |

### Input Format

**Text Content:**
- Any valid string from clipboard
- Supports multi-line text
- Markdown formatting preserved

**File Paths:**
- Absolute paths: `/Users/username/project/file.rb`
- Relative paths: `./lib/module/file.rb`
- Multiple files separated by newlines
- File existence not required (warnings given)

### Output Format

**Success (text):**
```
Idea captured: <relative-path-to-idea-file>
```

**Success (files):**
```
Idea captured with N attached files: <relative-path-to-idea-file>
Files:
- <file-path-1>
- <file-path-2>
...
```

**Error:**
```
Error: <descriptive-error-message>
```

### Internal Implementation

The command uses the following internal components:
- `Molecules::ClipboardReader` - Cross-platform clipboard access
- `Molecules::IdeaArgParser` - Parses command arguments including `--clipboard`
- `Organisms::IdeaWriter` - Writes idea files with merged content
- Ruby gem: `clipboard` (~> 1.3) for cross-platform clipboard support

## Tips and Best Practices

### Efficient Workflows

1. **Quick Capture:** Keep clipboard populated with ideas while browsing/reading
2. **File References:** Select files in Finder first, then run command
3. **Enhanced Ideas:** Use `--llm-enhance` for rough ideas that need structure
4. **Batch Processing:** Copy multiple ideas separated by sections, create separately

### Common Pitfalls to Avoid

- **Empty Clipboard:** Always verify clipboard has content before running
- **Large Content:** Clipboard content over 100KB will trigger warnings
- **Binary Data:** Only text and file paths supported, images/binaries rejected
- **Missing Files:** Referenced files don't need to exist, but warnings shown

### Platform Considerations

**macOS:**
- Uses `pbpaste` (built-in, no setup required)
- File paths from Finder automatically formatted

**Linux:**
- Requires `xclip` or `xsel` installed
  ```bash
  # Ubuntu/Debian
  sudo apt-get install xclip

  # Fedora/RHEL
  sudo dnf install xclip
  ```
- Wayland: Requires `wl-clipboard` package

### Performance Considerations

- Clipboard read is near-instant (<10ms typical)
- Large clipboard content (>50KB) may add slight delay
- LLM enhancement adds 2-5 seconds if enabled
- Git commit adds <1 second overhead

### Troubleshooting

**Issue:** "Error: Unable to read clipboard"
- **macOS:** Check clipboard isn't locked by another app
- **Linux:** Verify `xclip` or `xsel` is installed and on PATH

**Issue:** "Error: Clipboard contains binary data"
- **Solution:** Clipboard has image or other non-text content
- **Fix:** Copy text content instead

**Issue:** File paths not detected
- **Solution:** Clipboard reader treats all content as text by default
- **Expected:** File detection happens when paths match filesystem patterns

## Configuration

Set defaults in `.ace/taskflow/config.yml`:

```yaml
taskflow:
  idea:
    defaults:
      git_commit: true        # Auto-commit by default
      llm_enhance: false      # Don't enhance by default
      idea_location: active   # Create in active release
  clipboard:
    max_size: 102400         # 100KB max clipboard content
    detect_files: true        # Auto-detect file paths
```

## Migration Notes

This feature is **additive** - no changes to existing `idea create` behavior.

**Before (still works):**
```bash
ace-taskflow idea create "My idea text"
```

**After (new capability):**
```bash
ace-taskflow idea create --clipboard
ace-taskflow idea create "Prefix:" --clipboard
```

**Key Differences:**
- `--clipboard` flag is opt-in
- Existing commands unchanged
- No breaking changes to API
