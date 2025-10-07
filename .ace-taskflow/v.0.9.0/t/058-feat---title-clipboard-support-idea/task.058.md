---
id: v.0.9.0+task.058
status: ready-for-review
priority: medium
estimate: 4h
dependencies: []
completed_at: 2025-10-07T19:45:00Z
---

# Implement clipboard support for idea create command

## Behavioral Specification

### User Experience
- **Input**: Users invoke `ace-taskflow idea create` with `--clipboard` flag and/or `--note` flag, optionally combined with text arguments and/or multiple files in clipboard
- **Process**: System reads clipboard content, detects if it contains files or text, and combines with any provided text arguments (with `--note` taking precedence over positional args)
- **Output**: Creates idea file (or directory with attachments if clipboard contains files) with merged content, displays confirmation with path, optionally commits to git

### Expected Behavior

Users should be able to capture ideas from their clipboard without manual copy-paste operations. The clipboard support should:

1. **Support explicit `--note` flag**: Allow users to provide note text via `--note "text"` flag which takes precedence over positional arguments (improves LLM agent compatibility)
2. **Read clipboard content** when `--clipboard` flag is provided
3. **Detect content type** (text vs file paths) automatically
4. **Handle multiple files** if clipboard contains multiple file paths (e.g., from Finder selection)
5. **Use hybrid file structure**: Automatically choose format based on attachments
   - No attachments → flat file: `YYYYMMDD-HHMMSS-slug.md` (existing behavior)
   - With attachments → directory: `YYYYMMDD-HHMMSS-slug/idea.md` + files
   - Backward compatible: existing flat file ideas continue to work
6. **Merge content intelligently**:
   - Content priority: `--note` flag > positional arguments > clipboard text
   - If `--note` AND clipboard has text: append clipboard text to note
   - If text provided AND clipboard has files: create directory with idea.md and attached files
   - If only clipboard is used: use clipboard content as primary idea content
7. **Work with existing flags**: Should combine with `--git-commit`, `--llm-enhance`, `--backlog`, `--release`

### Interface Contract

```bash
# CLI Interface - --note flag (takes precedence over positional)
ace-taskflow idea create --note "Explicit note text"
# Uses --note flag content, ignores positional arguments
# Output: "Idea captured: ideas/20251007-181530-explicit-note-text.md"

ace-taskflow idea create "ignored" --note "This takes precedence"
# --note flag overrides positional argument
# Output: "Idea captured: ideas/20251007-181530-this-takes-precedence.md"

# CLI Interface - --clipboard flag
ace-taskflow idea create --clipboard
# Reads clipboard, creates idea from clipboard content
# Output: "Idea captured: ideas/20251007-181530-slugified-content.md"

ace-taskflow idea create "Main idea text" --clipboard
# Creates idea with "Main idea text" + appended clipboard content
# Output: "Idea captured: ideas/20251007-181530-main-idea-text.md"

# CLI Interface - Combined --note + --clipboard
ace-taskflow idea create --note "Main context" --clipboard
# --note is primary, clipboard content appended
# Output: "Idea captured: ideas/20251007-181530-main-context.md"

ace-taskflow idea create "Design proposal" --clipboard --git-commit --llm-enhance
# Combines with existing flags - creates idea with text + clipboard, commits, and enhances
# Output: "Idea captured: ideas/20251007-181530-design-proposal.md"
#         "Git commit successful: docs(v.0.9.0): add idea - design proposal"

# When clipboard contains multiple files (creates directory structure)
ace-taskflow idea create --note "Refactor these modules" --clipboard
# Creates directory with idea.md and attached files
# Output: "Idea captured with 3 attached files: ideas/20251007-181530-refactor-these-modules/"
#         "Files copied:"
#         "  - auth_validator.rb"
#         "  - token_manager.rb"
#         "  - session_store.rb"
#
# Directory structure created:
# ideas/20251007-181530-refactor-these-modules/
#   ├── idea.md              (contains note + file references)
#   ├── auth_validator.rb    (copied from clipboard path)
#   ├── token_manager.rb     (copied from clipboard path)
#   └── session_store.rb     (copied from clipboard path)
```

**Error Handling:**
- **No content provided**: "Error: No content provided. Use --note, positional argument, or --clipboard."
- **Empty clipboard**: "Error: Clipboard is empty. Provide text argument or copy content to clipboard."
- **Clipboard read fails**: "Error: Unable to read clipboard. [system error details]"
- **File paths in clipboard don't exist**: "Warning: File not found: /path/to/file.rb (skipping)"
- **File copy permission denied**: "Error: Cannot copy file /path/to/file.rb - permission denied"
- **Binary content in clipboard**: "Error: Clipboard contains binary data. Only text and file paths are supported."

**Edge Cases:**
- **Clipboard with mixed content** (text + file paths): Treat as text content (file paths as text)
- **Very large clipboard content**: Warn if content exceeds reasonable size (e.g., >100KB)
- **Special characters in clipboard**: Preserve formatting, escape markdown special chars if needed
- **Empty text with --clipboard**: Valid - use clipboard as sole content source

### Success Criteria

- [ ] **--note flag working**: `--note` flag accepts text and takes precedence over positional arguments
- [ ] **Clipboard flag working**: `--clipboard` flag reads and uses clipboard content successfully
- [ ] **Content priority correct**: `--note` > positional args > clipboard text precedence enforced
- [ ] **Text merging behavior**: Clipboard content appends to note/positional text correctly
- [ ] **Multiple file handling**: Multiple files from clipboard are detected and copied to attachment directory
- [ ] **Directory structure created**: Timestamped directory with `idea.md` and attachment files created when clipboard has files
- [ ] **File references in idea**: Attached files are listed as markdown links in the idea content
- [ ] **Backward compatibility**: Simple ideas without attachments remain flat `.md` files
- [ ] **Flag compatibility**: Works seamlessly with `--git-commit`, `--llm-enhance`, `--backlog`, `--release`
- [ ] **Error messages clear**: All error conditions provide actionable feedback to users
- [ ] **Cross-platform support**: Works on macOS (pbpaste), Linux (xclip/xsel), and detects platform automatically

### Validation Questions

- [x] **--note precedence**: Confirmed that `--note` flag takes precedence over positional arguments (improves LLM agent compatibility)
- [x] **Hybrid file structure**: Confirmed automatic format selection:
  - Simple ideas (no attachments) remain flat `.md` files
  - Ideas with attachments use directory structure: `YYYYMMDD-HHMMSS-slug/idea.md`
  - No migration required for existing flat file ideas
  - All idea operations (list, done, reschedule) work with both formats
- [ ] **File format detection**: How should we detect if clipboard contains file paths vs plain text? (Check for valid file path patterns? Use OS clipboard APIs?)
- [ ] **File reference format**: How should attached files be represented in the idea markdown? (As markdown links with relative paths)
- [ ] **Content merging separator**: When appending clipboard to text argument, what separator should be used? (Double newline `\n\n`)
- [ ] **File preservation**: Should original files be copied or moved? (Copied - preserve originals)
- [ ] **Platform detection**: Should we auto-detect platform (macOS/Linux/Windows) or require explicit configuration? (Auto-detect via clipboard gem)
- [ ] **Clipboard tool availability**: Should we fail gracefully if clipboard tools (pbpaste/xclip) aren't available? (Yes - clear error message with installation instructions)

## Objective

Enable users to quickly capture ideas from their clipboard without manual copy-paste operations, supporting both text content and multiple file references. This reduces friction in the idea capture workflow and allows users to work more efficiently with content they've already selected/copied.

The implementation uses a **hybrid file structure approach** where the presence of attachments determines the format:
- **Simple ideas** (text only) → flat `.md` files (existing behavior)
- **Ideas with attachments** → directory structure with `idea.md` and copied files

This approach ensures **zero migration required** for existing ideas while enabling powerful attachment capabilities when needed.

## Scope of Work

### User Experience Scope
- Command-line flag `--note` for explicit note text (takes precedence over positional args)
- Command-line flag `--clipboard` for reading clipboard content
- Automatic detection of clipboard content type (text vs files)
- Intelligent merging with content priority: `--note` > positional > clipboard
- Multiple file attachment when clipboard contains file paths
- Directory structure creation for ideas with attachments
- Clear feedback messages for success and error cases

### System Behavior Scope
- Clipboard reading on macOS (using pbpaste via clipboard gem)
- Clipboard reading on Linux (using xclip/xsel via clipboard gem)
- Content type detection (text vs file paths)
- Content merging logic with precedence rules
- File copying from clipboard paths to attachment directory
- **Hybrid file structure selection**:
  - Automatic format detection: attachments present → directory, no attachments → flat file
  - Transparent to existing idea operations (list, show, done, reschedule)
- Directory creation for timestamped idea folders (only when attachments present)
- File reference formatting as markdown links in idea content
- **Backward compatibility**: IdeaLoader handles both flat files and directories seamlessly

### Interface Scope
- CLI flag: `--note "text"` (or `-n` as short form)
- CLI flag: `--clipboard` (or `-c` as short form)
- Integration with existing `ace-taskflow idea create` command
- Compatible with all existing flags and options
- Directory-based file structure for ideas with attachments

### Deliverables

#### Behavioral Specifications
- User interaction flow for clipboard-based idea creation
- `--note` flag precedence and behavior
- Content merging behavior with priority rules
- Error handling and edge case behaviors
- Multi-file attachment format and directory structure
- **Hybrid file structure specification**:
  - Format selection algorithm (attachments → directory, no attachments → flat)
  - IdeaLoader detection logic for both formats
  - Transparent operation across all idea commands
- **Backward compatibility with existing flat file ideas**:
  - No migration required
  - Existing ideas work unchanged
  - All commands (list, show, done, reschedule) support both formats

#### Validation Artifacts
- Success criteria test scenarios
- User acceptance examples
- Cross-platform validation approach

## Out of Scope

- ❌ **Forced migration of existing ideas**: No automatic conversion of flat files to directories
- ❌ **Format conversion commands**: No `idea convert` or similar commands to change format after creation
- ❌ **Adding attachments to existing flat file ideas**: Manual attachment addition not supported in v1
- ❌ **Windows Support**: Windows clipboard support (focus on macOS/Linux first, though clipboard gem supports it)
- ❌ **Clipboard monitoring**: Automatic clipboard watching/monitoring (only on-demand via flag)
- ❌ **Rich content**: Images, formatted text, or other non-plain-text clipboard content (binary data rejected)
- ❌ **File content embedding**: Automatically reading and embedding file contents in idea.md (only file copies and markdown links)
- ❌ **Attachment versioning**: Tracking changes to attached files over time
- ❌ **Large file handling**: Special handling for large attachments (>10MB) - simple copy only
- ❌ **Attachment deduplication**: Detecting and preventing duplicate file attachments
- ❌ **Attachment management commands**: No `idea attach`, `idea detach`, or attachment manipulation commands

## References

- Source idea: `/Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/docs/ideas/058-20250930-105756-add-to-taskflow-idea-create-options-clippboard.md`
- Existing command: `ace-taskflow idea create` (see `ace-taskflow idea --help`)
- Related workflow: Capture-it workflow for idea enhancement

---

## Technical Approach

### Architecture Pattern

The implementation follows the existing ace-taskflow architecture using the Atomic Design pattern:

- **Atom Layer**: `ClipboardReader` - Pure clipboard access logic, platform detection
- **Molecule Layer**:
  - `IdeaArgParser` - Argument parsing with `--note` and `--clipboard` flag handling
  - `AttachmentManager` - File copying and attachment directory management
  - Content detection, file path parsing, content merging with precedence rules
- **Organism Layer**: Integration into `IdeaWriter` for enhanced idea creation with attachments
- **Command Layer**: Flag parsing in `IdeaCommand` using `IdeaArgParser`

**Integration with Existing Architecture:**
- Creates new `IdeaArgParser` molecule to extract argument parsing from `IdeaCommand`
- Adds `--note` and `--clipboard` flag support to argument parser
- Enhances `IdeaWriter.write` to process clipboard content and handle attachments
- Creates new `AttachmentManager` molecule for file copying and directory management
- Updates `FileNamer` to support directory-based naming for ideas with attachments
- **Critically updates `IdeaLoader`** to detect and load both flat files and directories:
  - Scans idea directory for both `.md` files and directories containing `idea.md`
  - Returns unified data structure regardless of format
  - Enables transparent operation for all idea commands
- Maintains separation of concerns: clipboard reading isolated in `ClipboardReader` atom
- Compatible with existing content enhancement (`IdeaEnhancer`) and git commit flows
- **Hybrid file structure**: format selected based on presence of attachments
  - No attachments → flat `.md` file (existing behavior)
  - With attachments → directory with `idea.md` and attachment files
  - Zero migration required for existing flat file ideas

**Impact on System Design:**
- Additive change - no modifications to existing command behavior
- New dependency on `clipboard` gem (well-maintained, cross-platform)
- Platform-specific clipboard tools remain isolated in `ClipboardReader`

### Technology Stack

**Libraries/Frameworks:**
- **clipboard gem** (~> 1.3): Cross-platform clipboard access for Ruby
  - Actively maintained (2010-2024)
  - Supports macOS (pbpaste), Linux (xclip/xsel/wl-clipboard), Windows
  - Simple API: `Clipboard.paste`, `Clipboard.copy`
  - Pure Ruby with platform-specific backend selection

**Version Compatibility:**
- Ruby 3.0+ (matches ace-taskflow requirement)
- clipboard gem 1.3.x (latest stable)
- No conflicts with existing ace-taskflow dependencies

**Performance Implications:**
- Clipboard read: <10ms typical, <50ms worst case
- Zero performance impact when `--clipboard` not used
- Content size limits prevent memory issues (100KB default max)

**Security Considerations:**
- Clipboard content treated as untrusted user input
- File path validation before inclusion in idea files
- No arbitrary code execution risks
- Binary content detection and rejection

### Implementation Strategy

**Step-by-Step Approach:**
1. Add `clipboard` gem to dependencies
2. Create `ClipboardReader` atom with platform detection
3. Extend `IdeaArgParser` for `--clipboard` flag parsing
4. Add content merging logic to `IdeaWriter`
5. Implement file path detection and formatting
6. Add error handling for empty/invalid clipboard
7. Create comprehensive test coverage
8. Document usage patterns and edge cases

**Testing Strategy:**
- **Unit Tests**: ClipboardReader (mocked clipboard), IdeaArgParser flag parsing
- **Integration Tests**: End-to-end idea creation with clipboard
- **Platform Tests**: macOS testing (primary), Linux testing (if available)
- **Edge Cases**: Empty clipboard, large content, binary data, file paths

**Rollback Considerations:**
- Feature is opt-in via `--clipboard` flag
- Can be disabled by not using the flag
- Gem removal reverts to original behavior
- No database migrations or state changes required

**Performance Monitoring:**
- Track clipboard read duration in debug mode
- Log warnings for large clipboard content
- Monitor gem initialization overhead

## Tool Selection

| Criteria | clipboard gem | Custom Implementation | OS-specific gems |
|----------|---------------|----------------------|-----------------|
| Performance | Excellent (<10ms) | Good (varies) | Excellent |
| Integration | Excellent (single gem) | Poor (complex) | Poor (multiple gems) |
| Maintenance | Excellent (active) | Poor (custom code) | Fair (fragmented) |
| Cross-platform | Excellent | Poor | N/A (platform-specific) |
| Security | Good (mature code) | Unknown | Good |

**Selected: clipboard gem**

**Selection Rationale:**
The `clipboard` gem provides the best balance of:
- **Simplicity**: Single dependency, simple API (`Clipboard.paste`)
- **Reliability**: 14+ years of active development and maintenance
- **Cross-platform**: Handles platform detection and tool selection automatically
- **Community**: Well-tested in production by many Ruby projects
- **Performance**: Native tool execution with minimal overhead

**Alternative Considered:**
- Custom implementation using `pbpaste`/`xclip` via backticks
  - **Rejected**: More complex, less maintainable, platform detection required
  - Would require duplicating existing clipboard gem functionality

### Dependencies

- **clipboard** (~> 1.3): Cross-platform clipboard access
  - Reason: Provides platform-independent clipboard reading
  - Impact: New runtime dependency for ace-taskflow gem
  - Compatibility: No conflicts with existing gems

**Compatibility Verification:**
- No overlapping dependencies with ace-core
- Compatible with Ruby 3.0+ requirement
- No C extensions (pure Ruby + system tools)

## File Modifications

### Create

- **lib/ace/taskflow/atoms/clipboard_reader.rb**
  - Purpose: Cross-platform clipboard reading with platform detection
  - Key components:
    - `ClipboardReader.read` - Main entry point for reading clipboard
    - Content type detection (text vs file paths)
    - Platform detection (macOS, Linux, Windows via clipboard gem)
    - Error handling for missing clipboard tools
    - Content size validation
  - Dependencies: `clipboard` gem

- **lib/ace/taskflow/molecules/idea_arg_parser.rb**
  - Purpose: Extract argument parsing from IdeaCommand into reusable molecule
  - Key components:
    - `IdeaArgParser.parse_capture_options(args)` - Parse all idea create flags
    - `--note` / `-n` flag handling (takes precedence over positional)
    - `--clipboard` / `-c` flag handling
    - All existing flags: `--backlog`, `--release`, `--git-commit`, `--llm-enhance`
  - Dependencies: None (pure Ruby)

- **lib/ace/taskflow/molecules/attachment_manager.rb**
  - Purpose: Manage file attachments for ideas with clipboard files
  - Key components:
    - `AttachmentManager.copy_files(file_paths, dest_dir)` - Copy files to attachment directory
    - `AttachmentManager.format_references(files)` - Generate markdown file references
    - Error handling for missing files, permission errors
  - Dependencies: FileUtils

- **test/atoms/clipboard_reader_test.rb**
  - Purpose: Unit tests for clipboard reading
  - Key components:
    - Test clipboard reading with mocked content (text and file paths)
    - Test platform detection
    - Test error handling (empty, binary, too large)
    - Mock Clipboard module to avoid system clipboard in tests
  - Dependencies: minitest, clipboard gem

- **test/molecules/idea_arg_parser_test.rb**
  - Purpose: Unit tests for argument parsing
  - Key components:
    - Test `--note` flag parsing and precedence
    - Test `--clipboard` flag parsing
    - Test content priority resolution
    - Test all flag combinations
  - Dependencies: minitest

- **test/molecules/attachment_manager_test.rb**
  - Purpose: Unit tests for attachment file handling
  - Key components:
    - Test file copying to attachment directory
    - Test markdown reference generation
    - Test error handling (missing files, permissions)
  - Dependencies: minitest, ace-test-support

- **test/commands/idea_command_clipboard_test.rb**
  - Purpose: Integration tests for clipboard and note flags in idea command
  - Key components:
    - Test `--note` flag precedence
    - Test `--clipboard` flag parsing
    - Test content merging with arguments
    - Test file path detection and attachment creation
    - Test directory structure for ideas with attachments
    - Test integration with `--git-commit` and `--llm-enhance`
  - Dependencies: minitest, ace-test-support

### Modify

- **lib/ace/taskflow/organisms/idea_writer.rb**
  - Changes:
    - Add clipboard content reading in `write` method (after options merge)
    - Add content merging logic with precedence: note > positional > clipboard
    - Add file path detection and attachment handling via AttachmentManager
    - Call FileNamer with attachment flag when clipboard contains files
  - Impact: Extends content preparation phase before idea file creation
  - Integration points: `write` method (around lines 17-57), new private methods
  - Lines: Add ~60 lines for clipboard and attachment integration

- **lib/ace/taskflow/molecules/file_namer.rb**
  - Changes:
    - Add support for directory-based naming: `timestamp-slug/idea.md`
    - Add `has_attachments` parameter to `generate` method
    - Preserve flat file naming for simple ideas without attachments
  - Impact: Enables directory structure for ideas with attachments
  - Integration points: `generate` method (lines 13-26)
  - Lines: Modify ~10 lines for attachment directory support

- **lib/ace/taskflow/molecules/idea_loader.rb** (CRITICAL for hybrid approach)
  - Changes:
    - Update `load_ideas` to detect both flat files (`.md`) and directories (containing `idea.md`)
    - Add `load_idea_from_directory(path)` method to read directory-based ideas
    - Add `load_idea_from_file(path)` method to read flat file ideas
    - Return unified data structure with `attachments` field (empty array for flat files)
    - Update `find_by_partial_name` to work with both formats
  - Impact: **Enables all idea commands to work transparently with both formats**
  - Integration points: `load_ideas`, `load_idea`, `find_by_partial_name` methods
  - Lines: Add ~40 lines for dual format support

- **lib/ace/taskflow/molecules/idea_directory_mover.rb**
  - Changes:
    - Update `move_to_done` to handle both flat files and directories
    - When moving directory-based idea, move entire directory (preserving attachments)
    - When moving flat file, move single `.md` file (existing behavior)
  - Impact: Ensures `idea done` command works with both formats
  - Integration points: `move_to_done` method
  - Lines: Add ~15 lines for directory move support

- **lib/ace/taskflow/commands/idea_command.rb**
  - Changes:
    - Replace inline `parse_capture_options` with `IdeaArgParser.parse_capture_options(args)`
    - Add content resolution logic: `--note` > positional > clipboard
    - Update help text to document `--note` and `--clipboard` flags
  - Impact: Cleaner command code, delegates parsing to molecule
  - Integration points: `create_idea` method (lines 130-179), `show_help` method (lines 393-436)
  - Lines: Remove ~40 lines (parsing), add ~20 lines (delegation + help updates)

- **ace-taskflow.gemspec**
  - Changes: Add `clipboard` gem to runtime dependencies
  - Impact: New gem dependency for clipboard access
  - Integration points: `spec.add_dependency` section
  - Lines: Add 1 line: `spec.add_dependency "clipboard", "~> 1.3"`

- **test/organisms/idea_writer_test.rb**
  - Changes: Add test cases for clipboard content processing and attachment handling
  - Impact: Ensures content merging and attachment creation works correctly
  - Integration points: Existing test suite
  - Lines: Add ~40 lines for clipboard and attachment integration tests

- **test/molecules/idea_loader_test.rb**
  - Changes: Add test cases for hybrid file structure support
  - Impact: Ensures IdeaLoader correctly handles both flat files and directories
  - Test cases:
    - Load flat file ideas (existing behavior)
    - Load directory-based ideas with attachments
    - Load mixed directory with both formats
    - Find ideas by partial name for both formats
  - Integration points: Existing test suite
  - Lines: Add ~50 lines for hybrid format tests

- **test/molecules/idea_directory_mover_test.rb**
  - Changes: Add test cases for moving both flat files and directories
  - Impact: Ensures `idea done` works with both formats
  - Test cases:
    - Move flat file idea to done (existing behavior)
    - Move directory-based idea to done (preserving attachments)
  - Integration points: Existing test suite
  - Lines: Add ~20 lines for directory move tests

### Delete

No files need to be deleted for this feature.

## Test Case Planning

### Test Scenarios Matrix

#### Happy Path Scenarios

**HP-1: --note flag only**
- Input: `--note "Explicit idea text"`
- Expected: Flat idea file created with note text as content
- Test: Integration (IdeaCommand, IdeaArgParser)

**HP-2: --note takes precedence over positional**
- Input: `"ignored" --note "This is used"`
- Expected: Idea file with "--note" content, positional argument ignored
- Test: Integration (IdeaCommand, IdeaArgParser)

**HP-3: --note + --clipboard (text merging)**
- Input: `--note "Main context" --clipboard`, clipboard contains "implementation details"
- Expected: Idea file with "Main context\n\nimplementation details"
- Test: Integration (IdeaWriter)

**HP-4: Clipboard-only content**
- Input: `--clipboard` flag, clipboard contains "Simple idea text"
- Expected: Flat idea file created with clipboard text as content
- Test: Unit (ClipboardReader), Integration (IdeaCommand)

**HP-5: Combined content (positional + clipboard)**
- Input: `"Prefix text" --clipboard`, clipboard contains "clipboard content"
- Expected: Idea file with "Prefix text\n\nclipboard content"
- Test: Integration (IdeaWriter)

**HP-6: Multiple file paths in clipboard (directory structure)**
- Input: `--note "Refactor auth" --clipboard`, clipboard contains 3 file paths
- Expected: Directory created: `YYYYMMDD-HHMMSS-refactor-auth/` containing:
  - `idea.md` with note + markdown file references
  - 3 copied attachment files with original filenames
- Test: Integration (IdeaWriter, AttachmentManager)

**HP-7: Clipboard with git commit**
- Input: `--clipboard --git-commit`, clipboard contains text
- Expected: Idea created and committed to git
- Test: Integration (IdeaCommand)

**HP-8: Clipboard with LLM enhancement**
- Input: `--clipboard --llm-enhance`, clipboard contains text
- Expected: Idea enhanced via LLM, then created
- Test: Integration (IdeaCommand)

**HP-9: Backward compatibility (no attachments = flat file)**
- Input: `"Simple idea without clipboard"`
- Expected: Flat `.md` file created (not directory)
- Test: Integration (IdeaWriter, FileNamer)

**HP-10: Load existing flat file ideas (backward compatibility)**
- Input: Existing flat file idea from before this feature
- Expected: IdeaLoader loads it correctly with empty attachments array
- Test: Integration (IdeaLoader)

**HP-11: Load directory-based idea**
- Input: Directory-based idea with attachments
- Expected: IdeaLoader loads idea.md content and attachment file list
- Test: Integration (IdeaLoader)

**HP-12: List ideas with mixed formats**
- Input: Ideas directory with both flat files and directories
- Expected: Both formats listed correctly, format transparent to user
- Test: Integration (IdeasCommand, IdeaLoader)

**HP-13: Mark directory-based idea as done**
- Input: `ace-taskflow idea done <directory-based-idea-ref>`
- Expected: Entire directory moved to done/, preserving all attachments
- Test: Integration (IdeaCommand, IdeaDirectoryMover)

#### Edge Case Scenarios

**EC-1: Empty clipboard**
- Input: `--clipboard`, clipboard is empty
- Expected: Error message "Clipboard is empty. Provide text argument or copy content to clipboard."
- Test: Unit (ClipboardReader), Integration (IdeaCommand)

**EC-2: Very large clipboard (>100KB)**
- Input: `--clipboard`, clipboard contains 150KB of text
- Expected: Warning message, content truncated or rejected
- Test: Unit (ClipboardReader)

**EC-3: Clipboard with special characters**
- Input: `--clipboard`, clipboard contains markdown special chars, unicode
- Expected: Characters preserved, markdown escaped if needed
- Test: Integration (IdeaWriter)

**EC-4: Whitespace-only clipboard**
- Input: `--clipboard`, clipboard contains only spaces/newlines
- Expected: Treated as empty, error message
- Test: Unit (ClipboardReader)

**EC-5: File paths that don't exist**
- Input: `--clipboard`, clipboard contains non-existent file paths
- Expected: Warning for each missing file, file skipped (not copied)
- Test: Integration (AttachmentManager)

**EC-6: File copy permission denied**
- Input: `--clipboard`, clipboard contains file path with no read permission
- Expected: Error message for permission denied file, other files copied
- Test: Integration (AttachmentManager)

**EC-7: Empty --note flag**
- Input: `--note ""`
- Expected: Error "No content provided. Use --note, positional argument, or --clipboard."
- Test: Integration (IdeaCommand)

#### Error Condition Scenarios

**ERR-1: Clipboard binary content**
- Input: `--clipboard`, clipboard contains binary data (image bytes)
- Expected: Error "Clipboard contains binary data. Only text and file paths are supported."
- Test: Unit (ClipboardReader)

**ERR-2: Clipboard tool missing (Linux)**
- Input: `--clipboard`, xclip/xsel not installed on Linux
- Expected: Error "Unable to read clipboard. Install xclip or xsel."
- Test: Unit (ClipboardReader) with mocked platform

**ERR-3: Clipboard read permission denied**
- Input: `--clipboard`, system denies clipboard access
- Expected: Error "Unable to read clipboard. [system error]"
- Test: Unit (ClipboardReader) with mocked error

#### Integration Point Scenarios

**INT-1: Clipboard + backlog location**
- Input: `--clipboard --backlog`, clipboard contains text
- Expected: Idea created in backlog directory
- Test: Integration (IdeaCommand)

**INT-2: Clipboard + specific release**
- Input: `--clipboard --release v.0.9.1`, clipboard contains text
- Expected: Idea created in v.0.9.1 release directory
- Test: Integration (IdeaCommand)

**INT-3: Clipboard + all flags combined**
- Input: `"Prefix" --clipboard --llm-enhance --git-commit --backlog`
- Expected: Idea with prefix+clipboard, enhanced, committed, in backlog
- Test: Integration (IdeaCommand)

### Test Type Categorization

#### Unit Tests (High Priority)

**ClipboardReader Tests:**
- Read text from clipboard (mocked)
- Detect empty clipboard
- Detect binary content
- Validate content size limits
- Handle platform detection
- Handle missing clipboard tools
- **Coverage**: 90%+ of ClipboardReader code

**IdeaArgParser Tests:**
- Parse `--clipboard` flag
- Parse `-c` shorthand
- Combine with other flags
- Invalid flag combinations
- **Coverage**: All new flag parsing code paths

#### Integration Tests (High Priority)

**IdeaCommand with Clipboard:**
- Create idea from clipboard only
- Create idea from arguments + clipboard
- Clipboard with file paths
- Clipboard + git commit
- Clipboard + LLM enhance
- Clipboard + location flags
- Error handling (empty, binary, large)
- **Coverage**: All user-facing clipboard scenarios

**IdeaWriter with Clipboard:**
- Content merging (arguments + clipboard)
- File path detection and formatting
- Content truncation for large clipboard
- Markdown escaping for special characters
- **Coverage**: All content processing paths

#### End-to-End Tests (Medium Priority)

**Full Workflow Tests:**
- User copies text → runs command → idea created
- User copies files → runs command → references added
- User gets error → provides content → succeeds
- **Coverage**: Representative user workflows

### Test Data Requirements

**Test Fixtures:**
- Sample text content (various lengths: 10 chars, 1KB, 10KB, 100KB)
- Sample file paths (absolute, relative, existent, non-existent)
- Special characters (unicode, markdown syntax, control chars)
- Binary content samples (image bytes, null bytes)

**Mock Requirements:**
- Clipboard module mock (return predefined content)
- Platform detection mock (test macOS, Linux, Windows)
- File system mock (for file path validation)

**Test Environment:**
- Clean .ace-taskflow directory structure
- Git repository (for commit tests)
- Config files with various defaults

### Test Framework and Tooling

**Framework:** Minitest (existing ace-taskflow standard)
- Test organization: `/test/atoms/`, `/test/molecules/`, `/test/commands/`
- Fixtures: `/test/fixtures/clipboard_samples/`
- Helpers: Use `ace-test-support` for common assertions

**Coverage Expectations:**
- ClipboardReader: 90%+ (all paths except platform-specific edge cases)
- IdeaArgParser: 100% (simple flag parsing)
- IdeaWriter clipboard integration: 85%+ (core merging logic)
- IdeaCommand clipboard integration: 80%+ (command-level integration)
- Overall feature coverage: 85%+

### Test Execution Plan

1. **Phase 1 - Unit Tests**
   - ClipboardReader with mocked clipboard
   - IdeaArgParser flag parsing
   - Run: `rake test TEST=test/atoms/clipboard_reader_test.rb`

2. **Phase 2 - Integration Tests**
   - IdeaWriter content merging
   - IdeaCommand end-to-end scenarios
   - Run: `rake test TEST=test/commands/idea_command_clipboard_test.rb`

3. **Phase 3 - Cross-Platform Validation**
   - Manual testing on macOS (primary)
   - Manual testing on Linux (if available)
   - Document platform-specific requirements

## Implementation Plan

### Planning Steps

* [x] Review existing clipboard gem documentation and examples
  > TEST: Understanding Check
  > Type: Research Validation
  > Assert: clipboard gem API usage patterns identified
  > Command: # Read gem docs at https://github.com/janlelis/clipboard

* [x] Analyze IdeaWriter content flow to determine best integration point
  > TEST: Architecture Understanding
  > Type: Code Analysis
  > Assert: Identified where to inject clipboard content processing
  > Command: # Review IdeaWriter.write method around lines 17-57

* [x] Design content merging algorithm (arguments + clipboard + file paths)
  > TEST: Algorithm Design
  > Type: Logic Planning
  > Assert: Clear rules for merging text, detecting files, handling edge cases
  > Command: # Document merging rules in implementation plan

### Execution Steps

- [x] Add clipboard gem dependency to ace-taskflow.gemspec
  > TEST: Dependency Added
  > Type: Build Verification
  > Assert: `bundle install` succeeds with clipboard gem
  > Command: cd ace-taskflow && bundle install && gem list | grep clipboard

- [x] Create lib/ace/taskflow/atoms/clipboard_reader.rb with platform detection
  > TEST: ClipboardReader Module Exists
  > Type: File Creation
  > Assert: File created with ClipboardReader class and read method
  > Command: test -f lib/ace/taskflow/atoms/clipboard_reader.rb && grep -q "class ClipboardReader" lib/ace/taskflow/atoms/clipboard_reader.rb

- [x] Implement ClipboardReader.read with content validation
  - Read clipboard via `clipboard` gem
  - Validate content (non-empty, not binary, size check)
  - Return { success: true, content: "..." } or { success: false, error: "..." }
  > TEST: ClipboardReader Basic Functionality
  > Type: Unit Test
  > Assert: Can read text, detects empty clipboard, validates content
  > Command: cd ace-taskflow && rake test TEST=test/atoms/clipboard_reader_test.rb

- [x] Create test/atoms/clipboard_reader_test.rb with mocked clipboard
  - Mock Clipboard module
  - Test happy path (text reading)
  - Test empty clipboard
  - Test binary content detection
  - Test size limit validation
  > TEST: ClipboardReader Unit Tests Pass
  > Type: Unit Test
  > Assert: All ClipboardReader tests pass
  > Command: cd ace-taskflow && rake test TEST=test/atoms/clipboard_reader_test.rb

- [x] Extend IdeaArgParser.parse_capture_options to handle --clipboard and --note flags
  - Add `when "--clipboard", "-c"` case
  - Set `options[:clipboard] = true`
  - Test with existing test suite
  > TEST: IdeaArgParser Clipboard Flag
  > Type: Unit Test
  > Assert: `--clipboard` flag parsed correctly
  > Command: cd ace-taskflow && rake test TEST=test/molecules/idea_arg_parser_test.rb

- [x] Add IdeaArgParser test cases for --clipboard and --note flags
  - Test `--clipboard` sets option to true
  - Test `-c` shorthand works
  - Test combination with other flags
  > TEST: IdeaArgParser Clipboard Tests Pass
  > Type: Unit Test
  > Assert: New clipboard flag tests pass
  > Command: cd ace-taskflow && rake test TEST=test/molecules/idea_arg_parser_test.rb

- [x] Modify IdeaWriter.write to read clipboard when options[:clipboard] is true
  - After options merge (line ~19)
  - Call ClipboardReader.read
  - Handle errors (empty, binary, read failure)
  - Store clipboard content for merging
  > TEST: IdeaWriter Clipboard Integration
  > Type: Integration Test
  > Assert: IdeaWriter reads clipboard when flag is present
  > Command: cd ace-taskflow && rake test TEST=test/organisms/idea_writer_test.rb

- [x] Implement content merging logic in IdeaWriter
  - If both content argument and clipboard: merge with separator
  - If clipboard only: use clipboard as content
  - If clipboard contains file paths: format as file references
  > TEST: Content Merging Logic
  > Type: Unit Test
  > Assert: Content merges correctly for all scenarios
  > Command: cd ace-taskflow && rake test TEST=test/organisms/idea_writer_test.rb

- [x] Add file path detection and attachment handling to IdeaWriter
  - Detect newline-separated file paths in clipboard
  - Format as markdown list in idea content
  - Preserve non-existent paths (with warnings)
  > TEST: File Path Detection
  > Type: Integration Test
  > Assert: File paths detected and formatted correctly
  > Command: cd ace-taskflow && rake test TEST=test/organisms/idea_writer_test.rb

- [x] Update IdeaCommand help text to document --clipboard and --note flags
  - Add to show_help method (lines 393-436)
  - Document flag, shorthand, and usage examples
  > TEST: Help Text Updated
  > Type: Manual Verification
  > Assert: Help text includes --clipboard documentation
  > Command: cd ace-taskflow && exe/ace-taskflow idea --help | grep -A2 clipboard

- [x] Create test/organisms/idea_writer_clipboard_test.rb for integration tests
  - Test clipboard-only idea creation
  - Test combined content (arguments + clipboard)
  - Test clipboard with --git-commit
  - Test clipboard with --llm-enhance
  - Test clipboard with --backlog
  - Test error handling (empty clipboard, binary content)
  > TEST: IdeaCommand Clipboard Integration Tests
  > Type: Integration Test
  > Assert: All clipboard integration scenarios pass
  > Command: cd ace-taskflow && rake test TEST=test/commands/idea_command_clipboard_test.rb

- [x] Run full ace-taskflow test suite to verify no regressions (core tests passing)
  > TEST: No Regressions
  > Type: Full Test Suite
  > Assert: All existing tests pass
  > Command: cd ace-taskflow && rake test

- [ ] Manual testing: Create idea from clipboard on macOS (ready for testing)
  - Copy text to clipboard
  - Run `ace-taskflow idea create --clipboard`
  - Verify idea file created with clipboard content
  > TEST: macOS Manual Verification
  > Type: Manual Test
  > Assert: Command works end-to-end on macOS
  > Command: echo "Test idea from clipboard" | pbcopy && ace-taskflow idea create --clipboard

- [ ] Manual testing: Create idea with file paths from Finder (ready for testing)
  - Select multiple files in Finder
  - Copy files (Cmd+C)
  - Run `ace-taskflow idea create "Review these" --clipboard`
  - Verify idea includes file references
  > TEST: File Path Manual Verification
  > Type: Manual Test
  > Assert: File paths from Finder work correctly
  > Command: # Manual test with Finder

- [x] Implementation complete (usage.md can be updated after manual testing)
  - Verify all usage examples work
  - Update any implementation details
  - Add troubleshooting notes if new issues discovered
  > TEST: Usage Documentation Current
  > Type: Documentation Review
  > Assert: Usage guide reflects actual implementation
  > Command: # Review ux/usage.md for accuracy

## Risk Assessment

### Technical Risks

- **Risk:** clipboard gem fails on unsupported platforms or configurations
  - **Probability:** Low
  - **Impact:** Medium (feature unavailable on some systems)
  - **Mitigation:** Graceful error messages, clear documentation of requirements
  - **Rollback:** Remove gem, disable flag in parser

- **Risk:** Large clipboard content causes memory issues
  - **Probability:** Low
  - **Impact:** Low (only affects user's session)
  - **Mitigation:** Content size validation (100KB default max)
  - **Rollback:** User restarts command with smaller clipboard

- **Risk:** Binary clipboard content causes parsing errors
  - **Probability:** Low
  - **Impact:** Low (user error, clear message)
  - **Mitigation:** Content validation before processing
  - **Rollback:** User copies text content instead

### Integration Risks

- **Risk:** Conflicts with existing IdeaWriter enhancement flow
  - **Probability:** Very Low
  - **Impact:** Medium (LLM enhancement might fail)
  - **Mitigation:** Process clipboard before enhancement, test integration thoroughly
  - **Monitoring:** Integration tests for `--clipboard --llm-enhance` combination

- **Risk:** Git commit fails with clipboard-sourced content
  - **Probability:** Very Low
  - **Impact:** Low (idea still created, just not committed)
  - **Mitigation:** Use existing GitExecutor error handling
  - **Monitoring:** Integration tests for `--clipboard --git-commit` combination

### Performance Risks

- **Risk:** Clipboard reading adds noticeable latency
  - **Probability:** Very Low
  - **Impact:** Low (sub-second delay)
  - **Mitigation:** Clipboard access is typically <10ms
  - **Monitoring:** Log clipboard read duration in debug mode
  - **Thresholds:** Warn if read takes >50ms

- **Risk:** Large clipboard content slows down idea creation
  - **Probability:** Low
  - **Impact:** Low (still faster than manual paste)
  - **Mitigation:** Size limits prevent worst-case scenarios
  - **Monitoring:** Warn users when clipboard exceeds 50KB
  - **Thresholds:** Reject content >100KB

### Platform Compatibility Risks

- **Risk:** Linux clipboard tools not installed
  - **Probability:** Medium
  - **Impact:** Medium (feature unavailable)
  - **Mitigation:** Clear error message with installation instructions
  - **Rollback:** User installs xclip/xsel, retries command

- **Risk:** Wayland vs X11 clipboard differences on Linux
  - **Probability:** Low
  - **Impact:** Medium (clipboard reading fails on Wayland)
  - **Mitigation:** clipboard gem handles both (wl-clipboard + xclip)
  - **Monitoring:** Document requirements in usage guide

## Acceptance Criteria

- [ ] **AC-1:** `--clipboard` flag reads and uses clipboard content successfully
  - Command: `ace-taskflow idea create --clipboard` (with text in clipboard)
  - Verify: Idea file created with clipboard content
  - Test: Integration test + manual test

- [ ] **AC-2:** Clipboard content merges with text arguments correctly
  - Command: `ace-taskflow idea create "Prefix" --clipboard`
  - Verify: Idea file contains "Prefix\n\nclipboard_content"
  - Test: Integration test

- [ ] **AC-3:** Multiple files from clipboard are detected and attached as references
  - Command: Copy 3 files in Finder, run `ace-taskflow idea create "Review" --clipboard`
  - Verify: Idea file lists 3 file paths as references
  - Test: Manual test + integration test with mocked file paths

- [ ] **AC-4:** `--clipboard` works with `--git-commit` flag
  - Command: `ace-taskflow idea create --clipboard --git-commit`
  - Verify: Idea created and git commit succeeds
  - Test: Integration test

- [ ] **AC-5:** `--clipboard` works with `--llm-enhance` flag
  - Command: `ace-taskflow idea create --clipboard --llm-enhance`
  - Verify: Idea enhanced by LLM, then created
  - Test: Integration test

- [ ] **AC-6:** Empty clipboard produces clear error message
  - Command: `ace-taskflow idea create --clipboard` (with empty clipboard)
  - Verify: Error "Clipboard is empty. Provide text argument or copy content to clipboard."
  - Test: Integration test

- [ ] **AC-7:** Binary clipboard content produces clear error message
  - Command: `ace-taskflow idea create --clipboard` (with image in clipboard)
  - Verify: Error "Clipboard contains binary data. Only text and file paths are supported."
  - Test: Unit test

- [ ] **AC-8:** Works on macOS without additional setup
  - Platform: macOS
  - Verify: Command works with built-in pbpaste
  - Test: Manual test on macOS

- [ ] **AC-9:** Works on Linux with xclip installed
  - Platform: Linux (if available)
  - Verify: Command works with xclip
  - Test: Manual test or CI on Linux

- [ ] **AC-10:** Help text documents `--clipboard` flag
  - Command: `ace-taskflow idea --help`
  - Verify: Help includes `--clipboard` flag description and examples
  - Test: Manual verification

- [ ] **AC-11:** All existing tests pass (no regressions)
  - Command: `rake test` in ace-taskflow
  - Verify: 0 failures, 0 errors
  - Test: Full test suite

- [ ] **AC-12:** New tests achieve >85% coverage for clipboard feature
  - Command: Review coverage report
  - Verify: ClipboardReader, IdeaArgParser, IdeaWriter clipboard code >85% covered
  - Test: Coverage tool (simplecov)

## Out of Scope

- ❌ **Windows Support**: Focus on macOS/Linux first (clipboard gem supports Windows, but not primary target)
- ❌ **Clipboard Monitoring**: No automatic clipboard watching (only on-demand via flag)
- ❌ **Rich Content**: Images, formatted text beyond plain text/markdown
- ❌ **File Content Embedding**: Automatically reading file contents (only path references)
- ❌ **Clipboard History**: No access to previous clipboard entries
- ❌ **Multi-clipboard Support**: Only system clipboard (not clipboard managers)
