---
id: v.0.9.0+task.058
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Add clipboard support to idea create command

## Behavioral Specification

### User Experience
- **Input**: Users invoke `ace-taskflow idea create` with `--clipboard` flag, optionally combined with text arguments and/or multiple files in clipboard
- **Process**: System reads clipboard content, detects if it contains files or text, and combines with any provided text arguments
- **Output**: Creates idea file with merged content (text + clipboard text/files), displays confirmation with path, optionally commits to git

### Expected Behavior

Users should be able to capture ideas from their clipboard without manual copy-paste operations. The clipboard support should:

1. **Read clipboard content** when `--clipboard` flag is provided
2. **Detect content type** (text vs file paths) automatically
3. **Handle multiple files** if clipboard contains multiple file paths (e.g., from Finder selection)
4. **Merge content intelligently**:
   - If text is provided as argument AND clipboard has text: append clipboard text to argument text
   - If text is provided AND clipboard has files: attach files as references to the text
   - If only clipboard is used: use clipboard content as primary idea content
5. **Work with existing flags**: Should combine with `--git-commit`, `--llm-enhance`, `--backlog`, `--release`

### Interface Contract

```bash
# CLI Interface - New flag
ace-taskflow idea create --clipboard
# Reads clipboard, creates idea from clipboard content
# Output: "Created idea: [timestamp]-[slugified-content].md"

ace-taskflow idea create "Main idea text" --clipboard
# Creates idea with "Main idea text" + appended clipboard content
# Output: "Created idea with clipboard content: [path]"

ace-taskflow idea create "Design proposal" --clipboard --git-commit --llm-enhance
# Combines with existing flags - creates idea with text + clipboard, commits, and enhances
# Output: "Created and enhanced idea: [path]"
#         "Committed to git: [commit-hash]"

# When clipboard contains multiple files
ace-taskflow idea create "Review these files" --clipboard
# Creates idea with text and references to all files from clipboard
# Output: "Created idea with 3 attached files: [path]"
#         Files:
#         - /path/to/file1.rb
#         - /path/to/file2.rb
#         - /path/to/file3.rb
```

**Error Handling:**
- **Empty clipboard**: "Error: Clipboard is empty. Provide text argument or copy content to clipboard."
- **Clipboard read fails**: "Error: Unable to read clipboard. [system error details]"
- **File paths in clipboard don't exist**: "Warning: Some clipboard file paths don't exist. Including as references anyway."
- **Binary content in clipboard**: "Error: Clipboard contains binary data. Only text and file paths are supported."

**Edge Cases:**
- **Clipboard with mixed content** (text + file paths): Treat as text content (file paths as text)
- **Very large clipboard content**: Warn if content exceeds reasonable size (e.g., >100KB)
- **Special characters in clipboard**: Preserve formatting, escape markdown special chars if needed
- **Empty text with --clipboard**: Valid - use clipboard as sole content source

### Success Criteria

- [ ] **Clipboard flag working**: `--clipboard` flag reads and uses clipboard content successfully
- [ ] **Text merging behavior**: Clipboard content appends to provided text arguments correctly
- [ ] **Multiple file handling**: Multiple files from clipboard are detected and attached as references
- [ ] **Flag compatibility**: Works seamlessly with `--git-commit`, `--llm-enhance`, `--backlog`, `--release`
- [ ] **Error messages clear**: All error conditions provide actionable feedback to users
- [ ] **Cross-platform support**: Works on macOS (pbpaste), Linux (xclip/xsel), and detects platform automatically

### Validation Questions

- [ ] **File format detection**: How should we detect if clipboard contains file paths vs plain text? (Check for valid file path patterns? Use OS clipboard APIs?)
- [ ] **File reference format**: How should attached files be represented in the idea markdown? (As links? As code blocks? As list items?)
- [ ] **Content merging separator**: When appending clipboard to text argument, what separator should be used? (Newline? Blank line? Custom marker?)
- [ ] **Platform detection**: Should we auto-detect platform (macOS/Linux/Windows) or require explicit configuration?
- [ ] **Clipboard tool availability**: Should we fail gracefully if clipboard tools (pbpaste/xclip) aren't available?

## Objective

Enable users to quickly capture ideas from their clipboard without manual copy-paste operations, supporting both text content and multiple file references. This reduces friction in the idea capture workflow and allows users to work more efficiently with content they've already selected/copied.

## Scope of Work

### User Experience Scope
- Command-line flag `--clipboard` for reading clipboard content
- Automatic detection of clipboard content type (text vs files)
- Intelligent merging of text arguments with clipboard content
- Multiple file attachment when clipboard contains file paths
- Clear feedback messages for success and error cases

### System Behavior Scope
- Clipboard reading on macOS (using pbpaste)
- Clipboard reading on Linux (using xclip/xsel)
- Content type detection (text vs file paths)
- Content merging logic (append, prepend, or standalone)
- File reference formatting in markdown

### Interface Scope
- CLI flag: `--clipboard` (or `-c` as short form)
- Integration with existing `ace-taskflow idea create` command
- Compatible with all existing flags and options

### Deliverables

#### Behavioral Specifications
- User interaction flow for clipboard-based idea creation
- Content merging behavior specifications
- Error handling and edge case behaviors
- Multi-file attachment format

#### Validation Artifacts
- Success criteria test scenarios
- User acceptance examples
- Cross-platform validation approach

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby gems/libraries for clipboard access
- ❌ **Technology Decisions**: Choice between different clipboard libraries
- ❌ **Windows Support**: Windows clipboard support (focus on macOS/Linux first)
- ❌ **Clipboard monitoring**: Automatic clipboard watching/monitoring (only on-demand via flag)
- ❌ **Rich content**: Images, formatted text, or other non-plain-text clipboard content
- ❌ **File content inclusion**: Automatically reading and embedding file contents (only references)

## References

- Source idea: `/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/docs/ideas/058-20250930-105756-add-to-taskflow-idea-create-options-clippboard.md`
- Existing command: `ace-taskflow idea create` (see `ace-taskflow idea --help`)
- Related workflow: Capture-it workflow for idea enhancement
