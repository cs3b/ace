# Changelog

All notable changes to ace-demo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.3] - 2026-03-13

### Changed
- Updated canonical demo skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.10.2] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-demo-create` and `as-demo-record` skills so provider projections now inherit the canonical skill body unchanged.

## [0.10.1] - 2026-03-12

### Fixed
- Registered the package WFI source so `wfi://demo/create` and `wfi://demo/record` resolve for the canonical demo skills.

## [0.10.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-demo-create` and `as-demo-record` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

## [0.9.0] - 2026-03-10

### Added
- Added canonical handbook-owned demo skills for tape creation and recording workflows.


## [0.8.0] - 2026-03-08

### Added
- Added `retime` command: `ace-demo retime <file> --playback-speed <1x|2x|4x|8x>` to postprocess GIF/MP4/WebM recordings into faster playback variants.
- Added playback speed parser and media retime engine (`ffmpeg`-based) with strict speed validation and format-aware processing.
- Added `assign-drive-showcase` project demo tape under `.ace/demo/tapes/` for delegation/drive walkthrough recording.

### Changed
- Extended `record` with `--playback-speed` and config fallback (`record.postprocess.playback_speed`) to auto-generate retimed artifacts while preserving originals.
- Updated `record --pr` behavior to attach the retimed artifact when playback postprocess is active.
- Updated docs/workflows (`README`, `docs/usage.md`, `docs/setup.md`, `demo/record.wf.md`) to cover retime usage and postprocess configuration.

## [0.7.2] - 2026-03-05

### Fixed
- Fixed `AttachOutputPrinter` printing full comment body to stdout in live mode — now only shown in dry-run preview.
- Fixed `--output` option being silently ignored in inline recording mode — now wired through to `InlineRecorder`.
- Fixed `--pr` with non-GIF formats producing broken image markdown — `DemoCommentFormatter` now uses link format for MP4/WebM.
- Fixed dry-run with `--pr` not previewing attachment step — both tape and inline modes now show attachment preview.
- Fixed dry-run inline preview using unsanitized name in output path placeholder.
- Renamed `gif_path:` parameter to `file_path:` in `GhAssetUploader` for format-neutral naming.
- Changed "GIF not found" error messages to "Recording file not found" in `DemoAttacher` and `GhAssetUploader`.
- Updated `attach` command description and argument help to be format-neutral.
- Fixed incorrect env var passing example in `demo/record` workflow (`TEST_PATH=... ace-demo` instead of positional arg).
- Fixed `docs/usage.md` expected output examples for `list` and `show` commands to match actual implementation.
- Removed redundant project-level WFI source registration (gem default suffices).

### Added
- Added dedicated `DemoNameSanitizer` unit tests covering edge cases: empty input, path traversal, special characters, max length boundary.
- Added escaping regression test for `TapeContentGenerator` double-quote and backslash handling.
- Added `DemoCommentFormatter` test for non-GIF format link rendering.

## [0.7.1] - 2026-03-05

### Added
- Added handbook workflow instructions for tape creation (`demo/create`) and recording (`demo/record`).
- Added skills integration (`ace-demo-create`, `ace-demo-record`) for agent workflow routing via `wfi://` protocol.
- Added WFI source registration for `ace-bundle wfi://demo/*` discovery.
- Added `handbook/**/*` to gemspec `spec.files` per project convention.

### Fixed
- Fixed command escaping in `TapeContentGenerator` — double quotes and backslashes in commands are now properly escaped in `Type` directives.
- Fixed path traversal vulnerability in `TapeCreator` — tape names are now sanitized via `DemoNameSanitizer` before use in file paths.
- Fixed `--dry-run` in tape recording mode — now skips VHS execution entirely instead of only dry-running PR attachment.
- Narrowed auth error detection in `GhAssetUploader` and `DemoCommentPoster` to match specific patterns (`authentication required`, `authentication token`) instead of broad `authentication` substring.
- Removed unused `format:` parameter from `VhsCommandBuilder.build`.

## [0.7.0] - 2026-03-05

### Added
- Added `Atoms::DemoNameSanitizer` for sanitizing user-supplied demo names to filesystem-safe slugs (lowercase, alphanumeric/hyphen, max 55 chars).
- Added `ace-b36ts` runtime dependency for compact 6-character base36 session IDs.
- Replaced `YYYYMMDD-HHMMSS` timestamp session IDs with `Ace::B36ts.now` 6-character b36ts tokens in `InlineRecorder`.
- Name passed to `record` is now sanitized via `DemoNameSanitizer` before use in tape/output paths.

## [0.6.0] - 2026-03-05

### Added
- Added inline recording to `record` command: `ace-demo record <name> -- <commands...>` generates a session-local tape and records it in one step.
- Added `Molecules::InlineRecorder` for session-scoped tape generation and VHS execution with timestamped output directories (`.ace-local/demo/<session_id>/`).
- Added create-style options to `record` command for inline mode: `--timeout`, `--desc`, `--tags`, `--width`, `--height`, `--font-size`.
- Added stdin support for piping commands into `record` (one command per line).
- Added dry-run support for inline recording that previews tape content without executing VHS.
- Added tests for inline recorder molecule and CLI inline record integration.

## [0.5.0] - 2026-03-05

### Added
- Added `create` command: `ace-demo create <name> [--timeout] [--desc] [--tags] [--width] [--height] [--font-size] [--format] [--force] [--dry-run] -- <commands...>` for generating tape files from shell commands.
- Added tape creation pipeline components:
  - `Atoms::TapeContentGenerator` for pure tape content generation from structured params.
  - `Molecules::TapeWriter` for conflict-aware file I/O to `.ace/demo/tapes/`.
  - `Organisms::TapeCreator` for orchestrating content generation and file writing.
- Added `TapeAlreadyExistsError` for conflict detection with `--force` override.
- Added stdin support for piping commands into `create` (one command per line).
- Added tests for generator, writer, creator, and CLI command behavior.
- Updated defaults to 960x480px at font size 16 (~100 columns) for better terminal rendering.

## [0.4.3] - 2026-03-05

### Fixed
- Extracted shared tape search directory construction to `Atoms::TapeSearchDirs` and reused it in tape scanner/resolver paths.
- Extracted shared attach output rendering to `Atoms::AttachOutputPrinter` and reused it across `record` and `attach` commands.
- Hardened PR-not-found detection in demo comment posting to avoid broad stderr misclassification.
- Applied runtime config defaults (`vhs_bin`, `output_dir`) in demo recording execution paths and added coverage for configured defaults.

## [0.4.2] - 2026-03-05

### Fixed
- Moved `ExecutionResult` from molecules to models and updated recorder/executor references for ATOM layer consistency.
- Optimized `TapeScanner#find` to use direct layered lookup instead of full tape-list scans for single-name lookups.
- Updated config load fallback to emit a warning when loading fails, improving diagnostics for invalid config states.
- Added regression coverage for direct lookup behavior and config-fallback warning behavior.

## [0.4.1] - 2026-03-05

### Fixed
- Fixed tape precedence handling to consistently prefer project tapes over home and gem defaults.
- Removed redundant VHS availability pre-check and now report missing VHS from the actual execution path.
- Updated dry-run attach behavior to avoid `gh` CLI/network/auth calls.
- Removed unsupported `--format` emission from VHS command construction.
- Removed duplicate `Error:` message prefixing in CLI command error propagation.
- Added debug-mode diagnostics when config loading fails instead of silently swallowing all errors.

## [0.4.0] - 2026-03-05

### Added
- Added demo tape discovery commands:
  - `ace-demo list` to enumerate available tapes with description and source path.
  - `ace-demo show <name>` to display tape metadata and full tape contents.
- Added tape library components:
  - `Atoms::TapeMetadataParser` for parsing VHS comment metadata.
  - `Molecules::TapeScanner` for config-cascade discovery with override semantics and direct-path lookup.
- Added built-in default tapes in `.ace-defaults/demo/tapes/`:
  - `hello.tape`
  - `ace-test.tape`
- Added tests for parser/scanner behavior and new CLI commands.

## [0.3.0] - 2026-03-05

### Added
- Added `attach` command: `ace-demo attach <file> --pr <number> [--dry-run]` for uploading GIFs to the `demo-assets` release and posting inline PR comments.
- Added PR-attachment ATOM components:
  - `Atoms::DemoCommentFormatter`
  - `Molecules::GhAssetUploader`
  - `Molecules::DemoCommentPoster`
  - `Organisms::DemoAttacher`
- Added `record --pr <number>` flow to record and attach in one command.
- Added package tests for formatter, uploader, comment poster, attacher, and CLI integration.

## [0.2.0] - 2026-03-05

### Added
- Added new `ace-demo` gem scaffold with executable, module loading, and dry-cli integration.
- Added `record` command: `ace-demo record <tape> [--output] [--format gif|mp4|webm]`.
- Added VHS recording pipeline components:
  - `Atoms::VhsCommandBuilder`
  - `Molecules::TapeResolver`
  - `Molecules::VhsExecutor`
  - `Organisms::DemoRecorder`
- Added `.ace-defaults/demo/` config and tape preset structure.
- Added package test suite for atom, molecules, organism, and CLI command behavior.

### Fixed
- Added explicit error handling for missing tape files, missing VHS binary, unsupported formats, and VHS execution failures with actionable messages.
