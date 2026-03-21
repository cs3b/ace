---
doc-type: user
title: ace-support-mac-clipboard
purpose: Documentation for ace-support-mac-clipboard/README.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# ace-support-mac-clipboard

macOS NSPasteboard integration for ACE - provides FFI-based access to rich clipboard content on macOS.

## Overview

This gem provides native macOS clipboard support via `NSPasteboard`, enabling ACE applications to read rich content including:

- **Images**: PNG, JPEG, TIFF from screenshots or image editors
- **Files**: File paths from Finder clipboard
- **Rich Text**: RTF and HTML formatted content
- **Plain Text**: UTF-8 text content

## Platform Support

- **macOS**: Full rich clipboard support via NSPasteboard (macOS 10.14+)
- **Linux/Windows**: Not supported (use fallback text-only clipboard reading)

## Installation

Add to your Gemfile:

```ruby
gem 'ace-support-mac-clipboard', '~> 0.1.0'
```

Or install directly:

```bash
gem install ace-support-mac-clipboard
```

## Usage

### Reading Clipboard Content

```ruby
require 'ace/support/mac_clipboard'

# Read raw clipboard data
result = Ace::Support::MacClipboard::Reader.read
# => { success: true, types: [...], raw_pasteboard: <pointer> }

# Parse clipboard content
parsed = Ace::Support::MacClipboard::ContentParser.parse(result)
# => {
#   text: "plain text content",
#   attachments: [
#     { type: :image, format: :png, data: <binary>, filename: "clipboard-image-1.png" },
#     { type: :file, source_path: "/path/to/file.pdf", filename: "file.pdf" }
#   ]
# }
```

### Supported Content Types

The gem maps macOS Uniform Type Identifiers (UTIs) to Ruby symbols:

| UTI | Symbol | Description |
|-----|--------|-------------|
| `public.utf8-plain-text` | `:text` | Plain text content |
| `public.png` | `:image` | PNG image |
| `public.jpeg` | `:image` | JPEG image |
| `public.tiff` | `:image` | TIFF image |
| `public.file-url` | `:files` | File paths from Finder |
| `NSFilenamesPboardType` | `:files` | File paths from Finder (copy operation) |
| `public.rtf` | `:rtf` | Rich Text Format |
| `public.html` | `:html` | HTML content |

### Attachment Structure

Parsed attachments follow this structure:

#### Image Attachment
```ruby
{
  type: :image,
  format: :png,  # or :jpeg, :tiff
  data: <binary_data>,
  filename: "clipboard-image-1.png"
}
```

#### File Attachment
```ruby
{
  type: :file,
  source_path: "/Users/you/Documents/report.pdf",
  filename: "report.pdf"
}
```

**Note**: When multiple files are copied from Finder, each file generates a separate attachment entry. The gem automatically handles both single and multiple file selections.

#### Rich Text Attachment
```ruby
{
  type: :rtf,  # or :html
  data: <binary_data>,
  filename: "clipboard-content.rtf"
}
```

## Architecture

### Components

- **Reader**: FFI bridge to Objective-C runtime and NSPasteboard
- **ContentParser**: Transforms raw NSPasteboard data into Ruby structures
- **ContentType**: UTI type mappings and constants

### FFI Implementation

The gem uses Ruby FFI to call Objective-C runtime functions:

```ruby
# Load Objective-C runtime and AppKit
ffi_lib "/usr/lib/libobjc.dylib"
ffi_lib "/System/Library/Frameworks/AppKit.framework/AppKit"

# Attach runtime functions
attach_function :objc_getClass, [:string], :pointer
attach_function :sel_registerName, [:string], :pointer
attach_function :objc_msgSend, [:pointer, :pointer], :pointer
```

## Examples

### Inspect Clipboard Contents

Use the included inspector script:

```bash
# Copy something to clipboard
echo "test" | pbcopy

# Inspect
ruby bin/inspect_clipboard.rb
```

Output:
```
============================================================
macOS Clipboard Inspector
============================================================

Available UTI Types:
------------------------------------------------------------
  1. public.utf8-plain-text → text
  2. NSStringPboardType → text

Text Content:
------------------------------------------------------------
test

Attachments:
------------------------------------------------------------
  (none)

Summary:
------------------------------------------------------------
  Types found: 2
  Text present: Yes
  Attachments: 0
```

### Integration with ace-taskflow

The `ace-taskflow` gem uses this library automatically on macOS:

```bash
# Copy a screenshot (Cmd+Ctrl+Shift+4)
# Then create an idea with the clipboard content
ace-idea create --clipboard "Bug in login form"

# Result: Creates directory with idea.md and clipboard-image-1.png
```

## Development

### Setup

```bash
bundle install
```

### Testing

```bash
# Run test suite (requires mocking - coming soon)
bundle exec rake test

# Manual testing
echo "test" | pbcopy && ruby bin/inspect_clipboard.rb
```

### Debugging

Use the debug script to diagnose FFI issues:

```bash
ruby bin/debug_clipboard.rb
```

## Limitations

- **macOS Only**: Requires macOS and AppKit framework
- **No Video/Audio**: Currently doesn't support video or audio clips
- **File Size**: Large clipboard content (>100MB) may cause performance issues

## Future Enhancements

- [ ] Video/audio clip support
- [ ] Markdown conversion for HTML content
- [ ] ZIP creation for bulk file attachments
- [ ] Unit tests with mocked NSPasteboard

## License

MIT

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write tests
5. Submit a pull request

## Credits

Part of the ACE (Agentic Coding Environment) ecosystem.
