# Changelog

All notable changes to ace-demo will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.17.3] - 2026-03-22

### Fixed
- Updated `record --dry-run` tape-mode previews to resolve YAML tape specs before reporting preview format/output behavior.

### Changed
- Switched generated `.tape.yml` template rendering to structured YAML serialization for safer escaping and multiline handling.
- Removed default `copy-fixtures` from generated project tape templates to avoid guaranteed no-op setup warnings.

### Technical
- Updated command/organism test expectations and added dry-run YAML format coverage for the new preview/serialization behavior.

## [0.17.2] - 2026-03-22

### Changed
- Removed the legacy `YamlDemoRecorder`/`DemoSetupExecutor` pipeline and consolidated YAML recording on the production `DemoRecorder` sandbox flow.
- Updated getting-started docs to reflect `.tape.yml` output paths for created and inline tapes.

### Technical
- Removed obsolete legacy YAML parser/content-generator compatibility files and their test coverage.
- Added production-path regression coverage for `DemoRecorder` YAML execution, teardown behavior, and migrated getting-started tape smoke checks.

## [0.17.1] - 2026-03-22

### Fixed
- Honored YAML `settings.format` during `ace-demo record` tape-mode execution when `--format` is omitted.
- Cleaned up sandbox directories on setup failures and preserved `ArgumentError` type for invalid setup directives.
- Guarded missing YAML `setup`/`teardown` sections and normalized `.tape.yaml` compiled tape naming.

### Technical
- Added regression tests for CLI format passthrough, YAML compiled naming, and sandbox-builder failure cleanup behavior.

## [0.17.0] - 2026-03-22

### Changed
- Removed the built-in non-CLI `ace-test` demo tape from default demo inventory so `ace-demo list` only shows CLI-relevant demos.
- Updated getting-started guidance and list/scan test fixtures to reflect the cleaned built-in tape set.

## [0.16.0] - 2026-03-22

### Added
- Added `DemoYamlParser` and `VhsTapeCompiler` atoms for strict `.tape.yml` schema validation and VHS script compilation.
- Added `DemoSandboxBuilder` and `DemoTeardownExecutor` molecules for sandbox lifecycle management, fixture setup, and teardown execution.

### Changed
- Updated `DemoRecorder` to support unified `.tape`/`.tape.yml` routing with YAML pipeline execution.
- Updated `TapeResolver` and `TapeScanner` to support dual-format discovery and YAML-first extensionless resolution.
- Updated `ace-demo create`/`TapeCreator` to generate `.tape.yml` templates as the default authoring format.
- Updated CLI `list` and `show` output to include tape format and YAML metadata details.
- Added `sandbox_dir` default configuration (`.ace-local/demo/sandbox`).

### Technical
- Added and updated tests across atoms, molecules, organisms, and commands for the new YAML engine path and compatibility shims.

## [0.15.0] - 2026-03-22

### Added
- Added YAML demo recording support in `ace-demo record` for `.tape.yml` inputs, including YAML parsing, scene compilation, sandbox setup execution, and teardown cleanup.
- Added demo spike artifacts for `ace-task` YAML recording (`ace-task-getting-started.tape.yml`) and fixture-based setup support.

### Changed
- Updated `VhsExecutor#run` to support sandbox-scoped execution via optional `chdir:`.
- Updated usage docs to include `.tape.yml` recording workflow.

### Technical
- Added parser/compiler/setup/recorder test coverage for the YAML demo pipeline and CLI routing.

## [0.14.2] - 2026-03-22

### Fixed
- Corrected `ace-demo create` usage syntax to show options before `--`, matching CLI argument parsing behavior.

## [0.14.1] - 2026-03-22

### Fixed
- Removed the duplicated `0.13.0` changelog section that repeated `0.14.0` release notes.

## [0.14.0] - 2026-03-22

### Changed
- Refreshed package README and documentation with landing-focused messaging for agent workflows.
- Expanded command usage coverage in `docs/usage.md` and added new getting-started and handbook guides.
- Added a reusable example tape asset at `.ace/demo/tapes/my-demo.tape` and updated project docs for inline demo creation.

## [0.12.0] - 2026-03-21

### Changed
- Added initial `TS-DEMO-001` value-gated smoke E2E coverage for CLI help surface, tape create/show lifecycle, inline record dry-run preview, and attach validation error behavior.
- Added `e2e-decision-record.md` with explicit ADD/SKIP decisions and unit-coverage evidence for retained and deferred E2E candidates.

## [0.11.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.11.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.10.4] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

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
