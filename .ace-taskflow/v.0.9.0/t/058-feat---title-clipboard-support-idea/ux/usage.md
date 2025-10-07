# Clipboard and Note Support for Idea Create - Usage Guide

## Overview

The enhanced idea create command adds `--note` and `--clipboard` flags to `ace-taskflow idea create`, enabling explicit note specification and clipboard-based idea capture with file attachments.

**Available Features:**
- Explicit note text with `--note` flag (takes precedence over positional args)
- Read clipboard content with `--clipboard` flag
- Automatic content type detection (text vs file paths)
- Intelligent content merging with priority: `--note` > positional > clipboard
- Automatic file attachment handling (directory structure for ideas with files)
- Multiple file copying from clipboard to idea directory
- Seamless integration with existing flags (`--git-commit`, `--llm-enhance`, etc.)

**Key Benefits:**
- Clear content priority for LLM agents (--note flag preferred)
- Faster idea capture workflow
- Support for multi-file attachments from clipboard
- **Hybrid file structure**: simple ideas stay flat, complex ideas get directories
- Organized directory structure for ideas with attachments
- **Zero migration required**: existing flat file ideas work unchanged
- Cross-platform support (macOS, Linux)
- Zero manual file selection or copy-paste

## Command Types

This feature enhances the **bash CLI command**: `ace-taskflow idea create`

All examples below are bash commands run from your terminal, not Claude Code commands.

## Command Structure

### Basic Syntax

```bash
ace-taskflow idea create [content] [--note "text"] [--clipboard] [options]
```

### Parameters

- `content` (optional): Positional text content for the idea
- `--note "text"`, `-n`: Explicit note text (takes precedence over positional content)
- `--clipboard`, `-c`: Flag to read from clipboard
- `--git-commit`, `-gc`: Auto-commit the created idea file
- `--llm-enhance`, `-llm`: Enhance idea with LLM suggestions
- `--backlog`: Create idea in backlog instead of active release
- `--release <name>`: Create idea in specific release

### Content Priority

Content is resolved in this order:
1. `--note` flag (highest priority)
2. Positional arguments
3. `--clipboard` content (appended if note/positional exists)

### Default Behavior

- Without flags: Creates idea from positional arguments
- With `--note`: Uses note text, ignores positional
- With `--clipboard` (text): Appends clipboard to note/positional
- With `--clipboard` (files): Creates directory with idea.md and attached files

### File Structure (Hybrid Approach)

The system automatically chooses the appropriate file structure based on content:

**Simple Ideas (No Attachments) → Flat File**
```
ideas/
  └── 20251007-181530-add-rate-limiting.md     # Single file
```

**Ideas with Attachments → Directory**
```
ideas/
  └── 20251007-181645-refactor-auth/           # Directory
      ├── idea.md                               # Main content
      ├── validator.rb                          # Attachment
      ├── token_manager.rb                      # Attachment
      └── session_store.rb                      # Attachment
```

**Mixed (Backward Compatible)**
```
ideas/
  ├── 20251002-old-idea.md                     # Existing flat file (works!)
  ├── 20251007-181530-simple-idea.md           # New flat file
  └── 20251007-181645-with-files/              # New directory
      ├── idea.md
      └── auth.rb
```

**Key Points:**
- ✅ Existing flat file ideas continue to work (no migration)
- ✅ All commands (list, show, done, reschedule) work with both formats
- ✅ Format selection is automatic and transparent
- ✅ `idea done` moves entire directory for attachment-based ideas

## Usage Scenarios

### Scenario 1: Use --note Flag for Explicit Content

**Goal:** Specify idea content explicitly with `--note` flag (recommended for LLM agents)

**Steps:**
```bash
# Create idea using --note flag
ace-taskflow idea create --note "Add rate limiting to API endpoints"
```

**Expected Output:**
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251007-181530-add-rate-limiting-to-api-endpoints.md
```

**Result:** Flat idea file created with note text as content

**Why this matters:** LLM agents prefer explicit flags over positional arguments, reducing ambiguity in command interpretation.

---

### Scenario 2: --note Takes Precedence Over Positional

**Goal:** Understand that `--note` overrides positional arguments

**Steps:**
```bash
# Positional argument is ignored when --note is present
ace-taskflow idea create "This is ignored" --note "This is used"
```

**Expected Output:**
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/20251007-181531-this-is-used.md
```

**Result:** Idea contains only the `--note` content, positional argument ignored

---

### Scenario 3: Capture from Clipboard Only

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

### Scenario 4: Combine Text Arguments with Clipboard

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

### Scenario 5: Multiple Files from Clipboard (Directory Structure)

**Goal:** Create idea with multiple file attachments selected in Finder/file manager

**Steps:**
```bash
# 1. In Finder (macOS) or file manager (Linux):
#    - Select multiple files
#    - Copy them (Cmd+C on macOS, Ctrl+C on Linux)
#    - Clipboard now contains file paths

# 2. Create idea with file attachments using --note flag
ace-taskflow idea create --note "Refactor these authentication modules" --clipboard
```

**Expected Output:**
```
Idea captured with 3 attached files: .ace-taskflow/v.0.9.0/ideas/20251007-181530-refactor-these-authentication-modules/
Files copied:
  - validator.rb
  - token_manager.rb
  - session_store.rb
```

**Directory Structure Created:**
```
.ace-taskflow/v.0.9.0/ideas/20251007-181530-refactor-these-authentication-modules/
├── idea.md                # Main idea content with file references
├── validator.rb           # Copied from clipboard path
├── token_manager.rb       # Copied from clipboard path
└── session_store.rb       # Copied from clipboard path
```

**Idea Content (idea.md):**
```markdown
# Idea

Refactor these authentication modules

## Attached Files

- [validator.rb](./validator.rb)
- [token_manager.rb](./token_manager.rb)
- [session_store.rb](./session_store.rb)

---
Captured: 2025-10-07 18:15:30
```

**Result:** Directory created with idea.md and attached files copied from clipboard

---

### Scenario 6: Auto-commit with LLM Enhancement

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

### Scenario 7: Empty Clipboard Error

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

### Scenario 8: Backlog Idea from Clipboard

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
ace-taskflow idea create [CONTENT...] [--note "text"] [--clipboard] [OPTIONS]
```

### Options Detail

| Option | Shorthand | Description | Default |
|--------|-----------|-------------|---------|
| `--note "text"` | `-n` | Explicit note text (overrides positional args) | Not set |
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

**Success (simple idea - flat file):**
```
Idea captured: .ace-taskflow/v.0.9.0/ideas/YYYYMMDD-HHMMSS-slug.md
```

**Success (idea with attachments - directory):**
```
Idea captured with N attached files: .ace-taskflow/v.0.9.0/ideas/YYYYMMDD-HHMMSS-slug/
Files copied:
  - filename1.rb
  - filename2.rb
  ...
```

**Error:**
```
Error: <descriptive-error-message>
```

### Internal Implementation

The command uses the following internal components:
- `Atoms::ClipboardReader` - Cross-platform clipboard access with content type detection
- `Molecules::IdeaArgParser` - Parses command arguments including `--note` and `--clipboard`
- `Molecules::AttachmentManager` - Manages file copying and reference generation
- `Molecules::FileNamer` - Generates file paths (flat or directory-based)
- `Organisms::IdeaWriter` - Writes idea files/directories with merged content
- Ruby gem: `clipboard` (~> 1.3) for cross-platform clipboard support

## Working with Both File Formats

All idea commands work transparently with both flat files and directory-based ideas:

### Listing Ideas

```bash
ace-taskflow ideas
```

**Output (Mixed Formats):**
```
Ideas (3):
  1. 20251002-old-idea.md                     # Flat file (existing)
  2. 20251007-181530-simple-idea.md           # Flat file (new)
  3. 20251007-181645-refactor-auth/           # Directory (with attachments)
```

Format is transparent - both show up in lists normally.

---

### Showing Ideas

```bash
# Works for both formats
ace-taskflow idea show refactor-auth
```

**Output for Directory-Based Idea:**
```
Idea: 20251007-181645-refactor-auth
Title: Refactor these authentication modules
Created: 2025-10-07 18:15:30
Path: .ace-taskflow/v.0.9.0/ideas/20251007-181645-refactor-auth/

Attachments (3):
  - validator.rb
  - token_manager.rb
  - session_store.rb

--- Content ---
# Idea

Refactor these authentication modules

## Attached Files

- [validator.rb](./validator.rb)
- [token_manager.rb](./token_manager.rb)
- [session_store.rb](./session_store.rb)
```

---

### Marking Ideas as Done

```bash
# Flat file idea
ace-taskflow idea done simple-idea
# Result: Moves 20251007-181530-simple-idea.md → done/

# Directory-based idea
ace-taskflow idea done refactor-auth
# Result: Moves entire 20251007-181645-refactor-auth/ directory → done/
#         (preserving all attachments)
```

**Key Point:** `idea done` preserves attachments by moving the entire directory.

---

### Rescheduling Ideas

```bash
# Works for both formats
ace-taskflow idea reschedule refactor-auth --add-next
```

Both flat files and directories can be rescheduled normally.

---

## Tips and Best Practices

### Efficient Workflows

1. **Use --note for LLM Agents:** Prefer `--note "text"` over positional arguments when working with LLM agents
2. **Quick Capture:** Keep clipboard populated with ideas while browsing/reading
3. **File Attachments:** Select files in Finder first, copy them, then use `--note` + `--clipboard`
4. **Enhanced Ideas:** Use `--llm-enhance` for rough ideas that need structure
5. **Batch Processing:** Create multiple ideas by copying different content to clipboard sequentially

### Common Pitfalls to Avoid

- **Positional vs --note:** Remember that `--note` takes precedence over positional arguments
- **Empty Content:** Provide content via `--note`, positional, OR `--clipboard` (at least one required)
- **Empty Clipboard:** Always verify clipboard has content before using `--clipboard` flag
- **Large Content:** Clipboard content over 100KB will trigger warnings
- **Binary Data:** Only text and file paths supported, images/binaries rejected
- **Missing Files:** Files that don't exist will be skipped with warnings (not copied)
- **File Permissions:** Files without read permissions will fail to copy with error messages

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

This feature is **fully backward compatible** - zero migration required.

### Existing Ideas

**All existing flat file ideas work exactly as before:**
```
ideas/
  ├── 20251001-old-idea.md        ✅ Works unchanged
  ├── 20251002-another-idea.md    ✅ Works unchanged
  └── ...
```

**No action needed:**
- ❌ No file conversion required
- ❌ No directory restructuring
- ❌ No command changes for existing workflows
- ✅ All idea commands work with existing ideas
- ✅ Listing, showing, marking done, rescheduling all work

### New Ideas

**Simple ideas remain flat files:**
```bash
ace-taskflow idea create "My idea text"
# Creates: 20251007-181530-my-idea-text.md  (flat file, as before)
```

**Ideas with attachments use directories:**
```bash
ace-taskflow idea create --note "Refactor auth" --clipboard
# If clipboard has files:
# Creates: 20251007-181530-refactor-auth/  (directory with attachments)
```

### Command Compatibility

**Before (still works exactly the same):**
```bash
ace-taskflow idea create "My idea text"
ace-taskflow ideas
ace-taskflow idea show my-idea
ace-taskflow idea done my-idea
```

**After (new capabilities, old commands unchanged):**
```bash
ace-taskflow idea create --note "text"           # New --note flag
ace-taskflow idea create --clipboard             # New --clipboard flag
ace-taskflow idea create --note "text" --clipboard  # Combined
```

**Key Points:**
- ✅ `--note` and `--clipboard` flags are opt-in
- ✅ Existing commands work identically
- ✅ No breaking changes to any API
- ✅ Hybrid file structure is automatic and transparent
