# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-02-03

### Added
- Step 3b "Implementation Subprocess Detection" in verify-test-suite workflow
- Explicit subprocess source file search in molecules checklist
- Test base class check (Section 6) in test-review-checklist guide

### Changed
- Molecules checklist now requires searching SOURCE files for subprocess patterns
- Renumbered E2E section to 7 in test-review-checklist guide

## [0.1.0] - 2026-01-22

### Added
- Initial release of ace-test gem as pure workflow package
- Testing guides extracted from docs/testing-patterns.md:
  - `quick-reference.g.md` - TL;DR testing patterns
  - `testing-philosophy.g.md` - Testing pyramid and IO isolation
  - `test-organization.g.md` - Flat structure and naming conventions
  - `mocking-patterns.g.md` - Git, HTTP, subprocess, ENV mocking
  - `test-performance.g.md` - Performance targets and optimization
  - `testable-code-patterns.g.md` - Status codes, exceptions, exit handling
- Migrated workflow instructions from ace-taskflow:
  - `create-test-cases.wf.md` - Generate structured test cases
  - `fix-tests.wf.md` - Diagnose and fix failing tests
- Copied guides from ace-test-runner:
  - `testing.g.md` - General testing guidelines
  - `testing-tdd-cycle.g.md` - TDD implementation cycle
  - `test-driven-development-cycle/` subdirectory (7 files)
  - `testing/` subdirectory (7 files)
- Copied guide from ace-docs:
  - `embedded-testing-guide.g.md` - Embedding tests in workflows
- 3 new testing agents:
  - `test.ag.md` - Run tests with smart defaults
  - `mock.ag.md` - Generate mock helpers
  - `profile-tests.ag.md` - Profile slow tests
- Protocol registration for guide://, wfi://, agent://, and tmpl:// discovery
- Complete gem structure following ACE patterns

### Technical Details
- Pure workflow package with no Ruby runtime dependencies
- Auto-discovery via ace-nav through handbook/ directories
- Protocol registration enables ace-nav to discover resources from installed gem
