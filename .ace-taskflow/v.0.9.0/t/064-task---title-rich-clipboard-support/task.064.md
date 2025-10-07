---
id: v.0.9.0+task.064
status: pending
priority: high
estimate: 8h
dependencies: [v.0.9.0+task.058]
---

# Rich Clipboard Support for macOS with NSPasteboard Integration

## Behavioral Specification

### User Experience

As a macOS user capturing ideas with `ace-taskflow idea create --clipboard`, I want rich clipboard content (screenshots, Finder files, RTF/HTML) to be automatically saved as attachments alongside my idea notes, so I can preserve visual context and reference materials without manual file management.

### Current Behavior (Text-Only)
```bash
# Plain text - works today
echo "meeting notes" | pbcopy
ace-taskflow idea create --clipboard
# → Creates: 20251007-120000-idea.md (flat file with text)
```

### Desired Behavior (Rich Content on macOS)

**Scenario 1: Screenshot Capture**
```bash
# User takes screenshot (Cmd+Ctrl+Shift+4 → clipboard)
ace-taskflow idea create "UI mockup feedback" --clipboard

# Result: Directory structure created
.ace-taskflow/v.0.9.0/ideas/20251007-120000-ui-mockup-feedback/
  ├── idea.md
  │   # Idea
  │   UI mockup feedback
  │
  │   ## Attached Files
  │   - [clipboard-image-1.png](./clipboard-image-1.png)
  └── clipboard-image-1.png (actual screenshot)
```

**Scenario 2: Finder Files**
```bash
# User copies files in Finder (Cmd+C on selected files)
# Clipboard contains: /Users/mc/Documents/report.pdf, /Users/mc/Documents/data.xlsx
ace-taskflow idea create "Review quarterly reports" --clipboard

# Result:
.ace-taskflow/v.0.9.0/ideas/20251007-120001-review-quarterly-reports/
  ├── idea.md
  │   # Idea
  │   Review quarterly reports
  │
  │   ## Attached Files
  │   - [report.pdf](./report.pdf)
  │   - [data.xlsx](./data.xlsx)
  ├── report.pdf (copied from source)
  └── data.xlsx (copied from source)
```

**Scenario 3: Rich Text from Pages/Safari**
```bash
# User copies formatted text (bold, links, etc.)
ace-taskflow idea create "Meeting agenda" --clipboard

# Result: Saves both plain text and formatted version
.ace-taskflow/v.0.9.0/ideas/20251007-120002-meeting-agenda/
  ├── idea.md (plain text content)
  └── clipboard-content.rtf (formatted version)
```

**Scenario 4: Mixed Content**
```bash
# User types note THEN pastes screenshot
ace-taskflow idea create --note "Bug found in login form" --clipboard

# Result: Note text + screenshot attachment
.ace-taskflow/v.0.9.0/ideas/20251007-120003-bug-found-in-login-form/
  ├── idea.md
  │   # Idea
  │   Bug found in login form
  │   (screenshot shows error state)
  │
  │   ## Attached Files
  │   - [clipboard-image-1.png](./clipboard-image-1.png)
  └── clipboard-image-1.png
```

### Platform Behavior

| Platform | Text | Images | Files | RTF/HTML | Status |
|----------|------|--------|-------|----------|--------|
| **macOS** | ✅ Merge | ✅ Save | ✅ Copy | ✅ Save | Full support (NSPasteboard) |
| **Linux** | ✅ Merge | ❌ | ❌ | ❌ | Graceful fallback (text-only) |
| **Windows** | ✅ Merge | ❌ | ❌ | ❌ | Graceful fallback (text-only) |

### Interface Contract

**Command-Line Interface** (unchanged):
```bash
ace-taskflow idea create --clipboard          # Read all clipboard content
ace-taskflow idea create -c                   # Short form
ace-taskflow idea create --note "text" -c     # Explicit note + clipboard
ace-taskflow idea create -c --git-commit      # Auto-commit with attachments
```

**Internal API Changes** (new ace-support-mac-clipboard gem):
```ruby
# ClipboardReader returns enhanced structure on macOS
result = Ace::Taskflow::Atoms::ClipboardReader.read
# => {
#   success: true,
#   platform: :macos,  # or :linux, :windows
#   content_types: [:text, :image, :files],
#   text: "plain text from clipboard",
#   attachments: [
#     { type: :image, filename: "clipboard-image-1.png", data: binary },
#     { type: :file, filename: "report.pdf", source_path: "/path/to/report.pdf" }
#   ]
# }
```

## Success Criteria

### Functional Requirements
- [ ] Screenshot on clipboard → saved as PNG attachment with correct dimensions
- [ ] Multiple Finder files on clipboard → all copied to idea directory
- [ ] Rich text (RTF) → saved with formatting preserved
- [ ] HTML content → saved as .html file
- [ ] Plain text → merged into idea.md content (existing behavior unchanged)
- [ ] Mixed content (note + clipboard) → note in idea.md, rich content as attachments
- [ ] File size validation → warn if attachment >10MB, reject if total >50MB
- [ ] Auto-generated filenames → `clipboard-image-N.png`, `clipboard-content.rtf`
- [ ] Finder filenames preserved → use actual filenames for copied files

### Platform Requirements
- [ ] macOS: Full NSPasteboard integration via FFI
- [ ] Linux/Windows: Graceful fallback to text-only (existing clipboard gem)
- [ ] Platform detection automatic
- [ ] Clear error messages on unsupported platforms for rich content

### Non-Functional Requirements
- [ ] Performance: Clipboard read <500ms for typical content
- [ ] Memory: Handle images up to 10MB without OOM
- [ ] Security: Validate file paths (no directory traversal)
- [ ] Compatibility: Works on macOS 10.14+

### Test Coverage
- [ ] ace-support-mac-clipboard unit tests: NSPasteboard mocking
- [ ] ace-taskflow integration tests: Platform detection, content merging
- [ ] Manual testing: Real clipboard with screenshots, files, RTF
- [ ] Regression: All existing clipboard tests (58 tests) still pass

## Validation Questions

### Scope Clarifications
1. **File Size Limits**:
   - Per-file limit: 10MB? 25MB?
   - Total attachments per idea: 50MB? 100MB?

2. **File Type Support**:
   - Should we support video clips from clipboard? (macOS supports MOV from screen recording)
   - Should we support audio clips?
   - Should we generate PDF previews for attachments?

3. **Multiple Files**:
   - How to handle 50+ files copied from Finder? (Warn? Limit? Paginate?)
   - Should we create a ZIP for bulk file attachments?

4. **Rich Text Formats**:
   - Save both RTF and plain text versions?
   - Convert HTML to Markdown automatically?

### Technical Decisions
1. **Dependency Management**:
   - ace-support-mac-clipboard as separate gem or monorepo package?
   - FFI version constraints?

2. **Naming Conventions**:
   - Auto-generated vs preserving clipboard metadata?
   - Collision handling for duplicate filenames?

3. **Error Handling**:
   - Failed file copy (permission denied) → skip or abort?
   - Partial clipboard read → save what works or fail completely?

## Related Work

### Builds Upon
- **task.058**: Clipboard support implementation (text-only)
  - ClipboardReader atom (basic text support)
  - IdeaWriter clipboard merging
  - Hybrid file structure (flat vs directory)

### Enables
- Visual bug reports with screenshots
- Document review workflows with attached PDFs
- Design feedback with mockup images
- Meeting notes with formatted agendas

## Notes

- **macOS-Only Rich Content**: This is acceptable - graceful degradation on other platforms
- **clipboard gem limitation**: Can only read text, hence new NSPasteboard integration needed
- **Finder file copies**: macOS stores as `public.file-url` UTI type in NSPasteboard
- **Screenshot format**: Usually `public.png` or `public.tiff` depending on source

## Implementation Plan

### Phase 1: Create ace-support-mac-clipboard Package

#### 1.1 Package Structure Setup
- [ ] Create `ace-support-mac-clipboard/` directory in monorepo
  ```
  ace-support-mac-clipboard/
  ├── lib/ace/support/mac_clipboard/
  │   ├── reader.rb          # FFI → NSPasteboard bridge
  │   ├── content_parser.rb  # Parse UTI types → Ruby structures
  │   ├── content_type.rb    # UTI mappings and constants
  │   └── version.rb
  ├── test/mac_clipboard/
  │   ├── reader_test.rb
  │   └── content_parser_test.rb
  ├── ace-support-mac-clipboard.gemspec
  ├── Rakefile
  └── Gemfile
  ```
  > TEST: Directory structure exists
  > Command: `test -d ace-support-mac-clipboard/lib/ace/support/mac_clipboard`

#### 1.2 Create FFI Bridge to NSPasteboard
- [ ] Implement `Reader` class with FFI
  - Attach Objective-C runtime functions (`objc_getClass`, `sel_registerName`, `objc_msgSend`)
  - Helper method `objc_send(object, selector, *args)` for cleaner ObjC calls
  - Method: `available_types` → enumerate NSPasteboard UTI types
  - Method: `read_type(uti)` → get data for specific UTI
  > TEST: Can enumerate types from mocked NSPasteboard
  > Command: `cd ace-support-mac-clipboard && rake test TEST=test/mac_clipboard/reader_test.rb`

#### 1.3 Implement Content Parsing
- [ ] Create `ContentParser` to transform raw NSPasteboard data
  - `parse_text(data)` → extract UTF-8 strings
  - `parse_file_urls(data)` → extract file paths from `public.file-url`
  - `parse_image(data, uti)` → binary data + detect format (PNG/JPEG/TIFF)
  - `parse_rtf(data)` → binary RTF data
  - `parse_html(data)` → HTML string
  - Return unified structure:
    ```ruby
    {
      text: "combined plain text",
      attachments: [
        { type: :image, format: :png, data: binary, filename: "clipboard-image-1.png" },
        { type: :file, source_path: "/path/to/file.pdf", filename: "file.pdf" }
      ]
    }
    ```
  > TEST: Parse mocked clipboard data correctly
  > Command: `cd ace-support-mac-clipboard && rake test TEST=test/mac_clipboard/content_parser_test.rb`

#### 1.4 Define UTI Type Mappings
- [ ] Create `ContentType` module
  - Map UTI strings → symbols (`:text`, `:image`, `:files`, `:rtf`, `:html`)
  - Priority ordering for multi-type clipboard
  - File extension mapping (`.png`, `.rtf`, `.html`)
  > TEST: UTI mappings correct
  > Command: Manual verification of constants

#### 1.5 Integration Test with Real Clipboard
- [ ] Manual test script: `bin/inspect_clipboard.rb`
  - Read actual macOS clipboard
  - Print all available types
  - Display parsed content summary
  > TEST: Script runs on macOS and shows clipboard content
  > Command: `echo "test" | pbcopy && ruby bin/inspect_clipboard.rb`

---

### Phase 2: Integrate with ace-taskflow

#### 2.1 Add ace-support-mac-clipboard Dependency
- [ ] Update `ace-taskflow.gemspec`
  ```ruby
  spec.add_dependency "ace-support-mac-clipboard", "~> 0.1.0"
  ```
- [ ] Add to root `Gemfile` with path
  ```ruby
  gem "ace-support-mac-clipboard", path: "ace-support-mac-clipboard"
  ```
- [ ] Run `bundle install`
  > TEST: Dependency resolves
  > Command: `bundle install && bundle list | grep ace-support-mac-clipboard`

#### 2.2 Update ClipboardReader with Platform Detection
- [ ] Modify `ace-taskflow/lib/ace/taskflow/atoms/clipboard_reader.rb`
  ```ruby
  def self.read
    if RUBY_PLATFORM =~ /darwin/ && defined?(Ace::Support::MacClipboard)
      # Use NSPasteboard on macOS
      read_macos
    else
      # Fallback to text-only
      read_generic
    end
  end

  private

  def self.read_macos
    result = Ace::Support::MacClipboard::Reader.read
    # Transform to ace-taskflow format
    {
      success: true,
      platform: :macos,
      type: result[:attachments].any? ? :rich : :text,
      content: result[:text],
      files: result[:attachments].select { |a| a[:type] == :file }.map { |a| a[:source_path] },
      attachments: result[:attachments]
    }
  end

  def self.read_generic
    # Existing clipboard gem implementation
    content = Clipboard.paste
    # ... existing logic
  end
  ```
  > TEST: Platform detection works
  > Command: `ruby -e "require 'ace/taskflow/atoms/clipboard_reader'; p ClipboardReader.read"`

#### 2.3 Update IdeaWriter Content Merging
- [ ] Enhance `merge_content_with_clipboard` in `idea_writer.rb`
  ```ruby
  def merge_content_with_clipboard(content, clipboard_result, options)
    return [content, []] unless clipboard_result[:success]

    # Merge text content
    merged_text = merge_text_content(content, clipboard_result[:content])

    # Extract attachments
    attachments = clipboard_result[:attachments] || []

    [merged_text, attachments]
  end
  ```
  > TEST: Text merged correctly, attachments preserved
  > Command: Unit test for merge logic

#### 2.4 Update AttachmentManager for Rich Content
- [ ] Add `save_attachments` method
  ```ruby
  def self.save_attachments(attachments, dest_dir)
    FileUtils.mkdir_p(dest_dir)

    saved = []
    failed = []

    attachments.each do |att|
      case att[:type]
      when :image
        filename = att[:filename] || generate_image_filename(att[:format])
        File.write(File.join(dest_dir, filename), att[:data], mode: 'wb')
        saved << filename
      when :file
        FileUtils.cp(att[:source_path], File.join(dest_dir, att[:filename]))
        saved << att[:filename]
      when :rtf, :html
        filename = att[:filename] || "clipboard-content.#{att[:type]}"
        File.write(File.join(dest_dir, filename), att[:data], mode: 'wb')
        saved << filename
      end
    rescue => e
      failed << { filename: att[:filename], error: e.message }
    end

    { success: failed.empty?, saved_files: saved, failed_files: failed }
  end
  ```
  > TEST: Attachments saved correctly
  > Command: Unit test with mocked file operations

#### 2.5 Update IdeaWriter.write for Attachments
- [ ] Modify `write` method to handle clipboard attachments
  ```ruby
  # After clipboard processing
  merged_content, clipboard_attachments = merge_content_with_clipboard(...)

  # Combine with existing attachment detection
  all_attachments = clipboard_attachments + detected_file_attachments

  if all_attachments.any?
    # Create directory structure
    # Save attachments using AttachmentManager.save_attachments
    # Add references to idea.md
  end
  ```
  > TEST: Directory created, attachments saved, references added
  > Command: Integration test

---

### Phase 3: Testing

#### 3.1 Unit Tests
- [ ] ace-support-mac-clipboard: 15+ tests
  - Mock NSPasteboard responses
  - Test each UTI type parsing
  - Test error handling
  > Command: `cd ace-support-mac-clipboard && rake test`

- [ ] ace-taskflow: 10+ new tests
  - Platform detection
  - Content merging with attachments
  - AttachmentManager.save_attachments
  - Directory structure creation
  > Command: `cd ace-taskflow && rake test TEST=test/atoms/clipboard_reader_test.rb`

#### 3.2 Integration Tests
- [ ] End-to-end scenarios
  - Text-only clipboard (regression)
  - Screenshot clipboard → PNG saved
  - Finder files → files copied
  - Mixed content → text + attachments
  > Command: Manual testing with real clipboard

#### 3.3 Manual Testing Checklist
- [ ] Copy screenshot (Cmd+Ctrl+Shift+4) → `ace-taskflow idea create -c "Screenshot test"`
- [ ] Copy 3 files in Finder → `ace-taskflow idea create -c "Files test"`
- [ ] Copy formatted text from Pages → `ace-taskflow idea create -c "RTF test"`
- [ ] Type note + paste image → `ace-taskflow idea create --note "Bug" -c`
- [ ] Test on Linux VM → verify text-only fallback
- [ ] Verify all existing clipboard tests still pass

---

### Phase 4: Documentation

#### 4.1 ace-support-mac-clipboard README
- [ ] Create `ace-support-mac-clipboard/README.md`
  - Overview of NSPasteboard integration
  - Usage examples
  - Platform compatibility
  - API reference
  > TEST: README complete and accurate

#### 4.2 Update ace-taskflow Help
- [ ] Modify `IdeaCommand.show_help`
  - Document rich clipboard support on macOS
  - Show examples with attachments
  - Note platform limitations
  > Command: `ace-taskflow idea --help | grep -A5 clipboard`

#### 4.3 Usage Examples
- [ ] Add to task.064 as verification
  - Screenshot capture example
  - Finder files example
  - Mixed content example
  > TEST: Examples work as documented

---

### Execution Order

1. **Phase 1** (3-4 hours): Build ace-support-mac-clipboard gem
2. **Phase 2** (2-3 hours): Integrate with ace-taskflow
3. **Phase 3** (1-2 hours): Comprehensive testing
4. **Phase 4** (1 hour): Documentation

**Total Estimate**: 8 hours

### Dependencies

- **Requires**: task.058 (clipboard support foundation)
- **Blocks**: None
- **Enables**: Rich visual bug reports, document workflows

### Risk Mitigation

- **FFI complexity**: Use proven mac_clipboard_inspect.rb pattern from guide
- **Platform testing**: Test fallback on Linux early
- **File size issues**: Implement limits early (10MB/file, 50MB total)
- **Filename collisions**: Auto-increment (clipboard-image-1, clipboard-image-2)

### Technical Decisions

**Answered**:
- Package structure: Monorepo package (not separate gem repo)
- FFI version: `~> 1.15` (Ruby 3.x compatible)
- File limits: 10MB per file, 50MB total
- Filename strategy: Auto-generate for clipboard, preserve for Finder files
- Error handling: Skip failed files, continue with others

**Deferred**:
- Video/audio support: Not in scope (future enhancement)
- Markdown conversion: Save RTF/HTML as-is (no conversion)
- Bulk file handling: Warn at 20+ files, no automatic ZIP
