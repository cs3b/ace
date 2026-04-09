# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.4] - 2026-04-09

### Changed
- Expanded `as-test-verify-suite` canonical skill metadata so public `verify-test-suite` assign-step discovery is skill-owned while keeping step-template rendering in catalog YAML.

## [0.6.2] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.6.1] - 2026-03-29

### Technical
- Register package-level `.ace-defaults` skill-sources for ace-test to enable canonical skill discovery in fresh installs.

## [0.6.0] - 2026-03-24

### Changed
- Refreshed README tagline to emphasize knowledge-base role and fast, reliable tests.
- Fixed verify-suite use-case to reference `ace-test-runner` instead of stale `ace-test` CLI link.

## [0.5.2] - 2026-03-23

### Changed
- Refreshed README structure to match the current package layout pattern, including quick links, use-case framing, and standardized section flow.

## [0.5.1] - 2026-03-22

### Technical
- Removed obsolete `docs/demo` recording assets (`ace-test-getting-started.tape` and generated GIF) from the non-CLI documentation package.

## [0.5.0] - 2026-03-22

### Changed
- Rewrote README as concise landing page (~57 lines, down from 233)
- Updated gemspec summary and description to match new tagline

### Added
- New `docs/getting-started.md` tutorial-style guide
- New `docs/usage.md` with full CLI reference
- New `docs/handbook.md` with skills and workflows catalog
- Demo VHS tape and GIF in `docs/demo/`

## [0.4.6] - 2026-03-21

### Fixed
- Restored the historical release entries removed during the documentation sweep so the package changelog again preserves prior release traceability.

## [0.4.5] - 2026-03-21

### Added
- Added `as-test-improve-coverage` as the canonical workflow skill for coverage gap planning.
- Added `test/improve-coverage.wf.md` workflow instruction to execute coverage planning from the test domain.
- Updated package README and handbook references to point to `wfi://test/improve-coverage`.

### Changed
- Removed task-domain ownership of coverage planning workflow artifacts and migrated those responsibilities to `ace-test`.

## [0.4.4] - 2026-03-13

### Technical
- Updated canonical test planning skills for direct workflow execution in this project.

## [0.4.3] - 2026-03-13

### Changed
- Updated canonical test-planning and suite-health skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.4.2] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-test-verify-suite` skill so provider projections now inherit the canonical skill body unchanged.

## [0.4.1] - 2026-03-12

### Changed
- Updated README and workflow guidance to use direct `ace-bundle` workflow loading instead of legacy slash-command references.

## [0.4.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-test-verify-suite` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

## [0.3.0] - 2026-03-10

### Added
- Added canonical handbook-owned test planning, optimization, suite verification, performance-audit, and test-review skills.
- Added package workflows for `wfi://test/performance-audit` and `wfi://test/review` to replace inline legacy skill bodies.

## [0.2.2] - 2026-03-04

### Changed
- E2E sandbox checklist template now uses `.ace-local/test-e2e`.

## [0.2.1] - 2026-02-24

### Changed
- Strengthen `test/analyze-failures` output contract with autonomous fix decisions, concrete candidate file targets, and explicit no-touch boundaries.
- Update `test/fix` to consume autonomous analysis decisions directly and proceed without user clarification for normal targeting/scope choices.

## [0.2.0] - 2026-02-24

### Added
- Add `test/analyze-failures` workflow to classify failing tests before applying fixes.

### Changed
- Rewrite `test/fix` as an execution-only workflow with a hard gate to prior analysis output.
- Update testing guide references to use analyze-first then fix workflow sequencing.

## [0.1.5] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.1.4] - 2026-02-20

### Technical
- Update stale wfi://work-on-task references to wfi://task/work

## [0.1.3] - 2026-02-19

### Technical
- Namespace workflow instructions into test/ subdirectory with updated wfi:// URIs
- Update skill name references to use namespaced ace:test-action format

## [0.1.2] - 2026-02-18

### Changed
- Remove all MT-format references from guides, workflows, and templates — TS-format is now the only documented E2E test format
- Update E2E test location references from `test/e2e/*.mt.md` to `test/e2e/TS-*/` across testing-philosophy, testing-strategy, test-layer-decision, test-review-checklist, and test-responsibility-map guides
- Update create-test-cases, optimize-tests, and plan-tests workflows to use TS-format examples and directory creation instead of MT single-file patterns
- Update e2e-sandbox-checklist, test-responsibility-map, and test-review-checklist templates to use `TS-` prefix and TS-format paths

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
