---
id: v.0.8.0+task.024
status: done
priority: high
estimate: 2h
dependencies: []
---

# Remove Editor Integration and Output Simple File:Line Format

## Behavioral Specification

### User Experience
- **Input**: Users run search commands or other tools that find files/locations
- **Process**: Tools output clean, parseable file paths with optional line numbers
- **Output**: Terminal-clickable file:line format that works with modern terminal emulators

### Expected Behavior
The system should output file locations in a standard, universally-recognized format that modern terminals and development environments can handle natively. When users run commands like `search "TODO"`, they should see clean output like:

```
lib/ace_tools/atoms/git_wrapper.rb:45
lib/ace_tools/organisms/git.rb:123
test/integration/test_helper.rb:8
```

This format is automatically clickable in modern terminals (iTerm2, VS Code terminal, Kitty, WezTerm) and can be easily piped to other tools. The system should not attempt to launch editors or manage editor configurations - this is the responsibility of the user's terminal and environment.

### Interface Contract
```bash
# Search command interface changes
search "pattern"                    # Outputs file:line format
search "pattern" --files-only       # Outputs only file paths (no line numbers)
search "pattern" | xargs -I {} nvim {}  # User can pipe to their editor

# Removed interfaces (no longer supported)
search "pattern" --open             # REMOVED
search "pattern" --editor vim       # REMOVED
search config --editor code         # REMOVED
search config                       # REMOVED
```

**Error Handling:**
- No editor-related errors (editor not found, configuration issues)
- Focus on search/tool errors only (pattern not found, invalid regex)

**Edge Cases:**
- Files with spaces in names: Output quoted paths when necessary
- Binary files: Skip or mark as binary in output
- Large result sets: Output all results, let user filter/limit

### Success Criteria
- [ ] **Clean Output Format**: All tools output standard file:line format
- [ ] **Terminal Compatibility**: Output works with modern terminal emulators' auto-linking
- [ ] **Unix Philosophy**: Tools do one thing well - find files, not manage editors
- [ ] **Simplified Codebase**: Editor-related code completely removed
- [ ] **No Breaking Changes**: Core functionality (searching, finding) remains intact

### Validation Questions
- [ ] **Output Format Consistency**: Should we use file:line or file +line format?
- [ ] **Backward Compatibility**: Should we warn users about removed --open flags?
- [ ] **Migration Path**: Should we document how users can achieve similar workflows?
- [ ] **Configuration Cleanup**: How to handle existing editor configurations in user systems?

## Objective

Simplify the codebase by removing unnecessary editor integration complexity. Modern terminals and development environments already handle file path navigation natively. This change follows Unix philosophy - output clean, parseable results and let the user's system decide how to consume them.

## Scope of Work

- **User Experience Scope**: Simplified, predictable output from all file-finding tools
- **System Behavior Scope**: Remove all editor detection, launching, and configuration management
- **Interface Scope**: Update search command and any other commands that use editor integration

### Deliverables

#### Behavioral Specifications
- Clean file:line output format specification
- Updated command interfaces without editor flags
- Migration guide for users accustomed to --open behavior

#### Validation Artifacts
- Test cases for new output format
- Verification of terminal compatibility
- Performance comparison (should be faster without editor overhead)

## Out of Scope

- ❌ **Alternative Editor Solutions**: Not implementing any replacement editor integration
- ❌ **Terminal Detection**: Not detecting terminal capabilities or features
- ❌ **Click Handling**: Not implementing our own click-to-open functionality
- ❌ **Configuration Migration**: Not auto-migrating existing editor configurations

## Technical Approach

### Architecture Pattern
- Remove all editor-related layers (atoms, molecules, organisms)
- Simplify search command to output parseable text only
- Follow Unix philosophy of single-purpose tools

### Technology Stack
- No new dependencies needed (simplification)
- Remove existing editor integration code
- Rely on terminal emulator capabilities

### Implementation Strategy
- Remove editor components from bottom-up (atoms → molecules → organisms)
- Update search command to output file:line format
- Remove all editor-related command flags and configuration
- Update tests to reflect simplified behavior

## File Modifications

### Delete
- lib/ace_tools/atoms/editor/editor_detector.rb
  - Reason: No longer detecting editors
  - Dependencies: EditorIntegration organism

- lib/ace_tools/atoms/editor/editor_launcher.rb
  - Reason: No longer launching editors
  - Dependencies: EditorIntegration organism

- lib/ace_tools/molecules/editor/editor_config_manager.rb
  - Reason: No configuration needed
  - Dependencies: EditorIntegration organism

- lib/ace_tools/organisms/editor/editor_integration.rb
  - Reason: Main integration layer being removed
  - Dependencies: search command

- test/integration/atoms/editor/editor_detector_test.rb
  - Reason: Tests for removed component

- test/integration/atoms/editor/editor_launcher_test.rb
  - Reason: Tests for removed component

### Modify
- exe/search
  - Changes: Remove all editor-related options, output file:line format
  - Impact: Simplified command interface
  - Integration points: Direct output to stdout

## Risk Assessment

### Technical Risks
- **Risk:** Users accustomed to --open flag
  - **Probability:** High
  - **Impact:** Low
  - **Mitigation:** Clear error message suggesting piping to editor
  - **Rollback:** Keep old code in git history

### Integration Risks
- **Risk:** Other tools might depend on editor components
  - **Probability:** Low (based on search results)
  - **Impact:** Medium
  - **Mitigation:** Thorough testing of all commands
  - **Monitoring:** Run full test suite

## Implementation Plan

### Planning Steps
* [x] Verify no other tools use editor components
* [x] Document current search command behavior for comparison
* [x] Plan output format consistency across tools

### Execution Steps

- [x] Step 1: Remove editor atom files
  > TEST: Verify atoms removed
  > Type: File existence check
  > Assert: Editor atom files no longer exist
  > Command: ls lib/ace_tools/atoms/editor/ 2>&1 | grep -q "No such file" && echo "✓ Editor atoms removed"

- [x] Step 2: Remove editor molecule (EditorConfigManager)
  > TEST: Verify molecule removed
  > Type: File existence check
  > Assert: EditorConfigManager no longer exists
  > Command: ls lib/ace_tools/molecules/editor/ 2>&1 | grep -q "No such file" && echo "✓ Editor molecule removed"

- [x] Step 3: Remove editor organism (EditorIntegration)
  > TEST: Verify organism removed
  > Type: File existence check
  > Assert: EditorIntegration no longer exists
  > Command: ls lib/ace_tools/organisms/editor/ 2>&1 | grep -q "No such file" && echo "✓ Editor organism removed"

- [x] Step 4: Update search command to remove editor integration
  - Remove EditorIntegration require and initialization
  - Remove all editor-related command flags (--open, --editor, config subcommand)
  - Update output to always show file:line format
  > TEST: Verify search command works without editor
  > Type: Command execution
  > Assert: Search outputs file:line format
  > Command: search "def" --limit 3 | head -3 | grep -E "^[^:]+:[0-9]+" && echo "✓ File:line format working"

- [x] Step 5: Remove editor-related tests
  > TEST: Verify test files removed
  > Type: File existence check
  > Assert: Editor test files no longer exist
  > Command: ls test/integration/atoms/editor/ 2>&1 | grep -q "No such file" && echo "✓ Editor tests removed"

- [x] Step 6: Run full test suite to ensure nothing broke
  > TEST: Full test suite passes
  > Type: Test execution
  > Assert: All tests pass
  > Command: rake test

- [x] Step 7: Update any documentation mentioning editor integration
  > TEST: No editor references in docs
  > Type: Documentation check
  > Assert: No references to --open or --editor flags
  > Command: grep -r "\-\-open\|\-\-editor" docs/ README.md 2>/dev/null | wc -l | grep -q "^0$" && echo "✓ Docs updated"

## Acceptance Criteria

- [x] All editor-related files removed from codebase
- [x] Search command outputs clean file:line format
- [x] No editor-related command flags remain
- [x] All tests pass after removal
- [x] Documentation updated to reflect changes

## References

- Current implementation discussion in conversation
- Unix philosophy: "Make each program do one thing well"
- Modern terminal capabilities (iTerm2, VS Code, Kitty, WezTerm)