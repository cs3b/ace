---
id: v.0.9.0+task.058
status: pending
priority: medium
estimate: 4h
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

---

## Technical Approach

### Architecture Pattern

The implementation follows the existing ace-taskflow architecture using the Atomic Design pattern:

- **Atom Layer**: `ClipboardReader` - Pure clipboard access logic, platform detection
- **Molecule Layer**: Content detection, file path parsing, content merging
- **Organism Layer**: Integration into `IdeaWriter` for enhanced idea creation
- **Command Layer**: Flag parsing in `IdeaCommand` and `IdeaArgParser`

**Integration with Existing Architecture:**
- Extends `IdeaArgParser.parse_capture_options` to handle `--clipboard` flag
- Enhances `IdeaWriter.write` to process clipboard content before file creation
- Maintains separation of concerns: clipboard reading is isolated in a dedicated atom
- Compatible with existing content enhancement (`IdeaEnhancer`) and git commit flows

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
    - Platform detection (macOS, Linux, Windows)
    - Error handling for missing clipboard tools
    - Content size validation
  - Dependencies: `clipboard` gem

- **test/atoms/clipboard_reader_test.rb**
  - Purpose: Unit tests for clipboard reading
  - Key components:
    - Test clipboard reading with mocked content
    - Test platform detection
    - Test error handling (empty, binary, too large)
    - Mock Clipboard module to avoid system clipboard in tests
  - Dependencies: minitest, clipboard gem

- **test/commands/idea_command_clipboard_test.rb**
  - Purpose: Integration tests for clipboard flag in idea command
  - Key components:
    - Test `--clipboard` flag parsing
    - Test content merging with arguments
    - Test file path detection
    - Test integration with `--git-commit` and `--llm-enhance`
  - Dependencies: minitest, ace-test-support

### Modify

- **lib/ace/taskflow/molecules/idea_arg_parser.rb**
  - Changes: Add `--clipboard` (and `-c` shorthand) flag to `parse_capture_options`
  - Impact: Adds `clipboard: true/false` to returned options hash
  - Integration points: IdeaCommand.parse_capture_options, IdeaCommand.create_idea
  - Lines: ~12-52 (flag parsing loop)

- **lib/ace/taskflow/organisms/idea_writer.rb**
  - Changes:
    - Add clipboard content reading in `write` method (after options merge)
    - Add content merging logic (clipboard + arguments)
    - Add file path detection and formatting
  - Impact: Extends content preparation phase before idea file creation
  - Integration points: `write` method (around lines 17-30), new private methods
  - Lines: Add ~40 lines for clipboard integration

- **lib/ace/taskflow/commands/idea_command.rb**
  - Changes:
    - Update help text to document `--clipboard` flag
    - No logic changes (uses IdeaArgParser)
  - Impact: User-facing documentation in CLI help
  - Integration points: `show_help` method (lines 393-436)
  - Lines: Add 2-3 lines to help output

- **ace-taskflow.gemspec**
  - Changes: Add `clipboard` gem to runtime dependencies
  - Impact: New gem dependency for clipboard access
  - Integration points: `spec.add_dependency` section
  - Lines: Add 1 line: `spec.add_dependency "clipboard", "~> 1.3"`

- **test/molecules/idea_arg_parser_test.rb**
  - Changes: Add test cases for `--clipboard` flag parsing
  - Impact: Ensures flag parsing works correctly
  - Integration points: Existing test suite
  - Lines: Add ~20 lines for clipboard flag tests

- **test/organisms/idea_writer_test.rb**
  - Changes: Add test cases for clipboard content processing
  - Impact: Ensures content merging works correctly
  - Integration points: Existing test suite
  - Lines: Add ~30 lines for clipboard integration tests

### Delete

No files need to be deleted for this feature.

## Test Case Planning

### Test Scenarios Matrix

#### Happy Path Scenarios

**HP-1: Clipboard-only content**
- Input: `--clipboard` flag, clipboard contains "Simple idea text"
- Expected: Idea file created with clipboard text as content
- Test: Unit (ClipboardReader), Integration (IdeaCommand)

**HP-2: Combined content (arguments + clipboard)**
- Input: `"Prefix text" --clipboard`, clipboard contains "clipboard content"
- Expected: Idea file with "Prefix text\n\nclipboard content"
- Test: Integration (IdeaWriter)

**HP-3: Multiple file paths in clipboard**
- Input: `--clipboard`, clipboard contains 3 file paths (newline-separated)
- Expected: Idea file with file references formatted as markdown list
- Test: Integration (IdeaWriter)

**HP-4: Clipboard with git commit**
- Input: `--clipboard --git-commit`, clipboard contains text
- Expected: Idea created and committed to git
- Test: Integration (IdeaCommand)

**HP-5: Clipboard with LLM enhancement**
- Input: `--clipboard --llm-enhance`, clipboard contains text
- Expected: Idea enhanced via LLM, then created
- Test: Integration (IdeaCommand)

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
- Expected: Warning logged, paths included anyway (as references)
- Test: Integration (IdeaWriter)

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

* [ ] Review existing clipboard gem documentation and examples
  > TEST: Understanding Check
  > Type: Research Validation
  > Assert: clipboard gem API usage patterns identified
  > Command: # Read gem docs at https://github.com/janlelis/clipboard

* [ ] Analyze IdeaWriter content flow to determine best integration point
  > TEST: Architecture Understanding
  > Type: Code Analysis
  > Assert: Identified where to inject clipboard content processing
  > Command: # Review IdeaWriter.write method around lines 17-57

* [ ] Design content merging algorithm (arguments + clipboard + file paths)
  > TEST: Algorithm Design
  > Type: Logic Planning
  > Assert: Clear rules for merging text, detecting files, handling edge cases
  > Command: # Document merging rules in implementation plan

### Execution Steps

- [ ] Add clipboard gem dependency to ace-taskflow.gemspec
  > TEST: Dependency Added
  > Type: Build Verification
  > Assert: `bundle install` succeeds with clipboard gem
  > Command: cd ace-taskflow && bundle install && gem list | grep clipboard

- [ ] Create lib/ace/taskflow/atoms/clipboard_reader.rb with platform detection
  > TEST: ClipboardReader Module Exists
  > Type: File Creation
  > Assert: File created with ClipboardReader class and read method
  > Command: test -f lib/ace/taskflow/atoms/clipboard_reader.rb && grep -q "class ClipboardReader" lib/ace/taskflow/atoms/clipboard_reader.rb

- [ ] Implement ClipboardReader.read with content validation
  - Read clipboard via `clipboard` gem
  - Validate content (non-empty, not binary, size check)
  - Return { success: true, content: "..." } or { success: false, error: "..." }
  > TEST: ClipboardReader Basic Functionality
  > Type: Unit Test
  > Assert: Can read text, detects empty clipboard, validates content
  > Command: cd ace-taskflow && rake test TEST=test/atoms/clipboard_reader_test.rb

- [ ] Create test/atoms/clipboard_reader_test.rb with mocked clipboard
  - Mock Clipboard module
  - Test happy path (text reading)
  - Test empty clipboard
  - Test binary content detection
  - Test size limit validation
  > TEST: ClipboardReader Unit Tests Pass
  > Type: Unit Test
  > Assert: All ClipboardReader tests pass
  > Command: cd ace-taskflow && rake test TEST=test/atoms/clipboard_reader_test.rb

- [ ] Extend IdeaArgParser.parse_capture_options to handle --clipboard flag
  - Add `when "--clipboard", "-c"` case
  - Set `options[:clipboard] = true`
  - Test with existing test suite
  > TEST: IdeaArgParser Clipboard Flag
  > Type: Unit Test
  > Assert: `--clipboard` flag parsed correctly
  > Command: cd ace-taskflow && rake test TEST=test/molecules/idea_arg_parser_test.rb

- [ ] Add IdeaArgParser test cases for --clipboard flag
  - Test `--clipboard` sets option to true
  - Test `-c` shorthand works
  - Test combination with other flags
  > TEST: IdeaArgParser Clipboard Tests Pass
  > Type: Unit Test
  > Assert: New clipboard flag tests pass
  > Command: cd ace-taskflow && rake test TEST=test/molecules/idea_arg_parser_test.rb

- [ ] Modify IdeaWriter.write to read clipboard when options[:clipboard] is true
  - After options merge (line ~19)
  - Call ClipboardReader.read
  - Handle errors (empty, binary, read failure)
  - Store clipboard content for merging
  > TEST: IdeaWriter Clipboard Integration
  > Type: Integration Test
  > Assert: IdeaWriter reads clipboard when flag is present
  > Command: cd ace-taskflow && rake test TEST=test/organisms/idea_writer_test.rb

- [ ] Implement content merging logic in IdeaWriter
  - If both content argument and clipboard: merge with separator
  - If clipboard only: use clipboard as content
  - If clipboard contains file paths: format as file references
  > TEST: Content Merging Logic
  > Type: Unit Test
  > Assert: Content merges correctly for all scenarios
  > Command: cd ace-taskflow && rake test TEST=test/organisms/idea_writer_test.rb

- [ ] Add file path detection logic to IdeaWriter
  - Detect newline-separated file paths in clipboard
  - Format as markdown list in idea content
  - Preserve non-existent paths (with warnings)
  > TEST: File Path Detection
  > Type: Integration Test
  > Assert: File paths detected and formatted correctly
  > Command: cd ace-taskflow && rake test TEST=test/organisms/idea_writer_test.rb

- [ ] Update IdeaCommand help text to document --clipboard flag
  - Add to show_help method (lines 393-436)
  - Document flag, shorthand, and usage examples
  > TEST: Help Text Updated
  > Type: Manual Verification
  > Assert: Help text includes --clipboard documentation
  > Command: cd ace-taskflow && exe/ace-taskflow idea --help | grep -A2 clipboard

- [ ] Create test/commands/idea_command_clipboard_test.rb for integration tests
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

- [ ] Run full ace-taskflow test suite to verify no regressions
  > TEST: No Regressions
  > Type: Full Test Suite
  > Assert: All existing tests pass
  > Command: cd ace-taskflow && rake test

- [ ] Manual testing: Create idea from clipboard on macOS
  - Copy text to clipboard
  - Run `ace-taskflow idea create --clipboard`
  - Verify idea file created with clipboard content
  > TEST: macOS Manual Verification
  > Type: Manual Test
  > Assert: Command works end-to-end on macOS
  > Command: echo "Test idea from clipboard" | pbcopy && ace-taskflow idea create --clipboard

- [ ] Manual testing: Create idea with file paths from Finder
  - Select multiple files in Finder
  - Copy files (Cmd+C)
  - Run `ace-taskflow idea create "Review these" --clipboard`
  - Verify idea includes file references
  > TEST: File Path Manual Verification
  > Type: Manual Test
  > Assert: File paths from Finder work correctly
  > Command: # Manual test with Finder

- [ ] Update ux/usage.md based on implementation (if needed)
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
