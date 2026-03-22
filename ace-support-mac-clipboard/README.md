---
doc-type: user
title: ace-support-mac-clipboard
purpose: Documentation for ace-support-mac-clipboard/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-support-mac-clipboard

macOS NSPasteboard integration for ACE -- FFI-based access to rich clipboard content including images,
files, and formatted text.

## Overview

`ace-support-mac-clipboard` provides native macOS clipboard support via `NSPasteboard` so ACE applications
can consume more than plain text from the clipboard.

Supported content classes include:

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

## Basic Usage

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

### Integration with ace-idea

The `ace-idea` gem uses this library automatically on macOS:

```bash
# Copy a screenshot (Cmd+Ctrl+Shift+4)
# Then create an idea with the clipboard content
ace-idea create --clipboard "Bug in login form"

# Result: Creates directory with idea.md and clipboard-image-1.png
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

## Development

### Setup

```bash
bundle install
```

### Testing

```bash
# Run package tests
ace-test ace-support-mac-clipboard

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

- [ ] Add video/audio clipboard support
- [ ] Add Markdown conversion for HTML clipboard content
- [ ] Add mocked NSPasteboard coverage for automated tests

## Contributing

1. Create a focused branch for your change.
2. Update docs/examples and validation steps as needed.
3. Open a pull request with a concise summary.

## Part of ACE

`ace-support-mac-clipboard` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first
toolkit for agent-assisted development.

## License

MIT
