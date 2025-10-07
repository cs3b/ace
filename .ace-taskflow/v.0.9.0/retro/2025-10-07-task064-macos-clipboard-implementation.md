# Retro: Task 064 - macOS Rich Clipboard Implementation

**Date**: 2025-10-07
**Context**: Implementation of rich clipboard support for macOS with NSPasteboard integration
**Author**: Claude + User
**Type**: Conversation Analysis

## What Went Well

- Successfully implemented FFI bridge to macOS NSPasteboard with proper AppKit framework loading
- Modular architecture with clear separation (Reader, ContentParser, ContentType) made the codebase maintainable
- Platform detection with graceful fallback to text-only clipboard on non-macOS systems worked smoothly
- Test-driven approach with `inspect_clipboard.rb` helped debug issues quickly
- Documentation created alongside implementation (README.md)

## What Could Be Improved

- Initial implementation missed Finder file clipboard format (`NSFilenamesPboardType`)
- First attempt at reading file URLs used wrong approach (raw data parsing vs property list)
- Required user to manually test with real files to discover the issue
- Needed a follow-up fix session after initial "completion"

## Key Learnings

- **macOS Clipboard Complexity**: Finder stores copied files as `NSFilenamesPboardType` property lists (NSArray), not simple file URL strings
- **FFI Function Signatures**: Some Objective-C runtime functions (like `objc_msgSend_stret`) don't exist on ARM64 and caused LoadErrors
- **AppKit Framework Required**: NSPasteboard requires loading `/System/Library/Frameworks/AppKit.framework/AppKit`, not just libobjc
- **Property Lists vs Raw Data**: File URLs require `propertyListForType:` selector, not raw data reading
- **Multiple UTI Types**: Clipboard can have 12+ UTI types for a single copied file, need to handle the right ones

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Wrong NSPasteboard Reading Method**: Initial implementation
  - Occurrences: 1 (but blocked entire feature)
  - Impact: Finder files weren't detected at all - feature appeared broken to user
  - Root Cause: Assumed file URLs were stored as raw string data, but macOS uses property list format (NSArray of strings)
  - **Solution**: Rewrote `read_file_urls()` to use `propertyListForType:` and iterate through NSArray

- **Missing UTI Type Mapping**: `NSFilenamesPboardType` marked as `:unknown`
  - Occurrences: 1
  - Impact: ContentParser skipped file attachments completely
  - Root Cause: Only mapped `public.file-url`, didn't know about Finder-specific type
  - **Solution**: Added `NSFilenamesPboardType => :files` to ContentType mappings

#### Medium Impact Issues

- **FFI Function Not Found**: `objc_msgSend_stret` doesn't exist on ARM64 macOS
  - Occurrences: 1
  - Impact: Script wouldn't load until function was removed
  - Root Cause: Used deprecated/platform-specific FFI function
  - **Solution**: Removed unused `objc_msgSend_stret` attachment

- **AppKit Framework Missing**: Initial FFI setup only loaded libobjc
  - Occurrences: 1
  - Impact: NSPasteboard class wasn't found (returned null pointer)
  - Root Cause: AppKit framework provides NSPasteboard, not just Objective-C runtime
  - **Solution**: Added `ffi_lib "/System/Library/Frameworks/AppKit.framework/AppKit"`

#### Low Impact Issues

- **Single File Limitation**: Original `read_file_urls()` only returned one file
  - Occurrences: 1
  - Impact: Multiple file selection would only copy first file
  - Root Cause: Singular logic instead of array iteration
  - **Solution**: Property list approach naturally handles multiple files via NSArray

### Improvement Proposals

#### Process Improvements

- **Test with Real Data Earlier**: Could have tested with actual Finder files before marking task complete
  - Proposed: Add manual testing checklist items to implementation plan
  - Benefit: Catch platform-specific issues before "completion"

- **Research Clipboard Formats First**: Could have investigated UTI types before implementing
  - Proposed: Create spike task to explore clipboard data structures on target platform
  - Benefit: Avoid wrong assumptions about data formats

- **Incremental Testing**: Test each UTI type (text, image, files) separately
  - Proposed: Create test fixtures or manual test steps for each content type
  - Benefit: Isolate issues to specific content types

#### Tool Enhancements

- **clipboard-inspector with Debug Mode**: Add verbose flag to show raw data
  - Proposed Command: `--debug` flag to dump raw bytes/structures
  - Benefit: Diagnose data format issues faster

- **Clipboard Test Fixture Generator**: Tool to create test clipboard content
  - Proposed: Script to programmatically set clipboard to known states
  - Benefit: Automated testing without manual Finder operations

#### Communication Protocols

- **Explicit Success Criteria Verification**: Confirm each acceptance criterion with actual test
  - Current: Marked criteria as "implemented" without real testing
  - Proposed: Mark as "implemented, needs manual test" until verified
  - Benefit: Clear distinction between code complete and feature verified

### Token Limit & Truncation Issues

- **Large Output Instances**: None encountered (conversation stayed within limits)
- **Truncation Impact**: N/A
- **Mitigation Applied**: N/A
- **Prevention Strategy**: Used targeted file reads and limited output commands

## Action Items

### Stop Doing

- Marking tasks as "done" before testing with real user data/workflows
- Assuming clipboard data formats without researching platform specifics
- Skipping manual testing steps listed in implementation plan

### Continue Doing

- Creating inspector/debug tools for new integrations (`inspect_clipboard.rb`)
- Modular architecture with clear component boundaries
- Documentation alongside implementation
- Using FFI for native platform integration instead of shelling out

### Start Doing

- Add "Manual Verification Required" checklist items for platform-specific features
- Create spike tasks for unfamiliar APIs/frameworks before main implementation
- Test with real user scenarios before marking acceptance criteria complete
- Document platform-specific quirks in code comments (e.g., "Finder uses NSFilenamesPboardType")

## Technical Details

### NSPasteboard Property List Format

When files are copied in Finder, they're stored as:
- **UTI Type**: `NSFilenamesPboardType`
- **Data Structure**: Property list containing NSArray of file path strings
- **Reading Method**: `propertyListForType:` selector (not `dataForType:`)

### FFI Implementation Pattern

```ruby
# Get property list (returns NSArray)
prop_list_sel = sel_registerName("propertyListForType:")
array_obj = objc_msgSend_id(pasteboard, prop_list_sel, uti_str)

# Iterate array
count = objc_msgSend_uint(array_obj, sel_registerName("count"))
count.times do |i|
  path_obj = objc_msgSend_uint64(array_obj, sel_registerName("objectAtIndex:"), i)
  # Extract UTF8String...
end
```

### Key Files Modified

**Initial Implementation** (task.064):
- `ace-support-mac-clipboard/` (new gem with Reader, ContentParser, ContentType)
- `ace-taskflow/lib/ace/taskflow/atoms/clipboard_reader.rb` (platform detection)
- `ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb` (attachment handling)
- `ace-taskflow/lib/ace/taskflow/molecules/attachment_manager.rb` (save_attachments)

**Follow-up Fix**:
- `content_type.rb` (+1 line: NSFilenamesPboardType mapping)
- `reader.rb` (+57 lines: property list reading logic)
- `content_parser.rb` (-13 lines: simplified file handling)

## Additional Context

- **Task ID**: v.0.9.0+task.064
- **Commits**:
  - `f7b381b9` - Initial implementation
  - `3570e674` - Fix for Finder files
- **Related Issues**: User reported files not attaching after initial implementation
- **Testing**: Verified with 3 .srt files copied from Finder

---

**Retrospective Value**: This retro captures the learning that macOS clipboard integration requires understanding platform-specific data formats (property lists) and proper FFI method selection. The fix pattern (research → test → iterate) is now documented for future native integrations.
