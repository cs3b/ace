# Changelog

All notable changes to ace-taskflow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.10.0] - 2025-10-07

### Added

- **Rich Clipboard Support (macOS)**: Idea creation now supports rich clipboard content
  - Automatically detects and saves images (PNG, JPEG, TIFF)
  - Copies files from Finder with original filenames
  - Preserves HTML and RTF formatted content
  - Platform detection with graceful fallback to text-only on non-macOS
  - New `ace-support-mac-clipboard` gem with NSPasteboard FFI integration

- **Enhanced Ideas List Display**: Multiple display formats for different use cases
  - Default format shows file paths (LLM-optimized for direct file access)
  - `--short` flag hides paths and shows IDs (human-friendly)
  - `--format json` provides structured output with metadata
  - Rich ideas marked with 📎 icon and attachment count
  - Paths for rich ideas point to `idea.md` file inside directory

- **Directory-based Ideas**: Ideas with attachments stored as directories
  - Simple ideas: Single `.md` file (e.g., `20251007-125830-title.md`)
  - Rich ideas: Directory with `idea.md` + attachments (e.g., `20251007-125830-title/`)

### Changed

- Ideas list default format now optimized for LLM access (shows paths)
- ID display now conditional: hidden when paths shown, visible with `--short`
- Updated help text to document new display formats and options

### Technical

- Added `ace-support-mac-clipboard` package with FFI bridge to AppKit/NSPasteboard
- Implemented ContentType, Reader, and ContentParser for clipboard data
- Enhanced IdeaLoader to handle both flat file and directory-based ideas
- Updated AttachmentManager with `save_attachments` method
- IdeaWriter now supports clipboard merge and attachment handling

## [0.9.0] - 2025-09-24

### Initial Features

- Task and idea management with timestamped organization
- Descriptive task paths with semantic directory names
- Retrospective management
- Configuration cascade system
- ATOM architecture pattern
