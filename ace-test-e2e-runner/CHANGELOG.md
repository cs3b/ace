# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Renamed package from `ace-support-test-manual` to `ace-test-e2e-runner`
- Renamed workflow from `run-manual-test` to `run-e2e-test`
- Renamed test directory convention from `test/scenarios/` to `test/e2e/`
- Renamed cache directory from `.cache/test-manual/` to `.cache/test-e2e/`
- Made `PACKAGE` argument optional (defaults to current directory detection)
- Made `TEST_ID` argument optional (runs all tests in package when omitted)
- Cleanup is now optional and configurable via `cleanup.enabled` setting

### Added

- Protocol source registrations (wfi://, guide://, tmpl://)
- PROJECT_ROOT detection in workflow and template
- Gem entry point for programmatic access
- Expanded best practices section with learnings:
  - Environment setup guidance (PROJECT_ROOT capture)
  - Tool version manager workarounds (mise shim handling)
  - Test data and cleanup patterns

### Improved

- Documentation for mise shim workarounds in TC-003
- README clarity on package purpose and usage

## [0.1.0] - 2026-01-18

### Added

- Initial package structure for manual test support
- Test scenario template (`test-scenario.template.md`)
- Workflow for executing manual tests (`run-e2e-test.wf.md`)
- Guide documenting manual testing conventions (`manual-testing.g.md`)
- Default configuration for test paths and patterns
- Skill for invoking manual tests (`/ace:run-e2e-test`)
