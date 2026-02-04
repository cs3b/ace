# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.1] - 2026-02-04

### Added

- CLI-Based Testing Requirement section to create-e2e-test workflow documenting that E2E tests must test through CLI interface, not library imports

## [0.5.0] - 2026-02-01

### Added

- Sandbox isolation checkpoint with 3-check verification (path, git remotes, project markers)
- Standard Setup Script section as authoritative copy-executable source for sandbox setup
- Expected Variables documentation (PROJECT_ROOT, TEST_DIR, REPORTS_DIR, TIMESTAMP_ID)

### Changed

- Consolidated sandbox setup by moving `e2e-sandbox-setup.wf.md` into this package
- Renamed workflow to `setup-e2e-sandbox.wf.md` following verb-first convention
- Updated `run-e2e-test.wf.md` to delegate sandbox setup to `wfi://setup-e2e-sandbox`
- Removed ~30 lines of duplicated inline sandbox logic from run-e2e-test workflow
- Renamed skill from `ace_e2e-sandbox-setup` to `ace_setup-e2e-sandbox`

## [0.4.1] - 2026-01-30

### Fixed

- Updated report path documentation from sibling pattern to subfolder pattern (`-reports/`)
- Removed incorrect `artifacts/` subdirectory from test data path examples

### Technical

- Added pre-creation sandbox verification gate to workflow instructions
- Enhanced directory structure diagrams for consistency across guides and templates

## [0.4.0] - 2026-01-29

### Added

- Parallel E2E test execution with subagents via `/ace:run-e2e-tests` orchestrator skill
- Suite-level report aggregation for multi-test runs
- Subagent return contract for structured result passing between orchestrator and workers

### Changed

- Enhanced sandbox naming with test ID inclusion (`{timestamp}-{package}-{test-id}/`)
- Moved reports outside sandbox as sibling files (`.summary.r.md`, `.experience.r.md`, `.metadata.yml`)

### Breaking Changes

- **Cache directory renamed**: `.cache/test-e2e/` → `.cache/ace-test-e2e/`. External scripts referencing the old path will need updating.

## [0.3.0] - 2026-01-29

### Added

- Persistent test reports (`test-report.md`) capturing pass/fail status, test case details, and environment information
- Agent experience reports (`agent-experience-report.md`) documenting friction points, root cause analysis, and improvement suggestions
- Test execution metadata (`metadata.yml`) storing run-specific details like duration, Git context, and tool versions
- ace-taskflow fixture template for standardized taskflow structure creation in E2E tests

### Changed

- Updated test environment structure to use `artifacts/` subdirectory for test data organization
- Enhanced E2E testing guidelines with emphasis on error path coverage and negative test cases
- Improved test templates with error testing best practices and reviewer checklist
- Updated test execution workflow to automatically generate and persist reports at end of each run

## [0.2.1] - 2026-01-22

### Added

- Container-based E2E test isolation guide for macOS (Lima, OrbStack support)
- Template updates for containerized test scenarios

## [0.2.0] - 2026-01-19

### Added

- E2E test management skills for lifecycle orchestration:
  - `/ace:review-e2e-tests` - Analyze test health, coverage gaps, and outdated scenarios
  - `/ace:create-e2e-test` - Create new test scenarios from template
  - `/ace:manage-e2e-tests` - Orchestrate full lifecycle (review, create, run)
- Workflow instructions for all three new skills
- Protocol source registrations (wfi://, guide://, tmpl://)
- PROJECT_ROOT detection in workflow and template
- Gem entry point for programmatic access
- Expanded best practices section with learnings:
  - Environment setup guidance (PROJECT_ROOT capture)
  - Tool version manager workarounds (mise shim handling)
  - Test data and cleanup patterns

### Changed

- Renamed package from `ace-support-test-manual` to `ace-test-e2e-runner`
- Renamed workflow from `run-manual-test` to `run-e2e-test`
- Renamed test directory convention from `test/scenarios/` to `test/e2e/`
- Renamed cache directory from `.cache/test-manual/` to `.cache/test-e2e/`
- Made `PACKAGE` argument optional (defaults to current directory detection)
- Made `TEST_ID` argument optional (runs all tests in package when omitted)
- Cleanup is now optional and configurable via `cleanup.enabled` setting

### Improved

- Documentation for mise shim workarounds in TC-003
- README clarity on package purpose and usage

## [0.1.0] - 2026-01-18

### Added

- Initial package structure for E2E test support
- Test scenario template (`test-e2e.template.md`)
- Workflow for executing E2E tests (`run-e2e-test.wf.md`)
- Guide documenting E2E testing conventions (`e2e-testing.g.md`)
- Default configuration for test paths and patterns
- Skill for invoking E2E tests (`/ace:run-e2e-test`)
