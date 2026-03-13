# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.15.3] - 2026-03-13

### Changed
- Render Codex `ace-llm` skills from canonical frontmatter by deriving uppercase variables from `argument-hint` and generating `## Variables` / `## Instructions` sections for projected Codex skills.

### Technical
- Added projection regression coverage for `context: ace-llm` rendering and argument-hint-derived Codex variable generation.

## [0.15.2] - 2026-03-12

### Fixed
- Preserved conditional `--sandbox` workflow routing in provider-synced skill projections so generated Claude and Codex skills keep the canonical E2E execute path.

### Technical
- Added provider-sync regression coverage for conditional workflow bodies in projected skills.

## [0.15.1] - 2026-03-12

### Changed
- Updated handbook README, workflow docs, and guidance to document bundle-first workflow usage and the current handbook structure.

## [0.15.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-release-bump-version` and `as-release-update-changelog` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

## [0.14.1] - 2026-03-12

### Technical
- Updated provider sync regression coverage to verify provider-specific `context` and `model` overrides on projected git-commit skills and to keep generated provider output free of canonical `integration` metadata.

## [0.14.0] - 2026-03-12

### Changed
- Changed canonical handbook skill inventory to load from registered `skill://` sources via `ace-support-nav` instead of scanning monorepo package directories directly.

### Technical
- Added nav-backed inventory regression coverage and explicit skill-source registration fixtures for handbook sync/status tests.

## [0.13.1] - 2026-03-12

### Technical
- Added regression coverage for the `.agent/skills` retirement so handbook sync/status changes are exercised against provider-native skill trees only.

## [0.13.0] - 2026-03-12

### Added
- Added canonical skill inventory counts by `source` to `ace-handbook status` output and JSON responses.

### Changed
- Expanded provider status reporting to show expected, installed, in-sync, outdated, missing, and extra skill counts, including comparisons through symlinked provider directories.

## [0.12.0] - 2026-03-10

### Added
- Added a public `ace-handbook` CLI with `sync` and `status` commands for projecting canonical package skills into provider-native folders.
- Added provider manifest discovery and sync/status coverage for handbook integrations, including replacement of legacy provider skill symlinks with real provider directories.

### Changed
- Moved handbook integration execution to `ace-handbook` while provider packages now supply thin provider manifests for projection targets.

## [0.11.0] - 2026-03-10

### Added
- Added canonical handbook-owned skills for handbook management, release workflows, and research/delivery orchestration.


## [0.10.0] - 2026-03-08

### Added
- New `release/publish` workflow for coordinated multi-package releases that auto-detect modified packages, update package and root changelogs, and finish with one release commit.

### Changed
- `/as-release` now loads `wfi://release/publish`, and release documentation now points to the canonical workflow path.

## [0.9.9] - 2026-03-04

### Changed
- Update `perform-delivery` workflow PR skill references from `/ace-git-create-pr` to `/ace-github-pr-create`

## [0.9.8] - 2026-02-25

### Changed
- Update `perform-delivery` workflow task lookup guidance to use `ace-task show <ref>` for explicit task selection.

## [0.9.7] - 2026-02-22

### Technical
- Update `ace-bundle project` → `ace-bundle load project` in update-docs workflow

## [0.9.6] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.9.5] - 2026-02-21

### Added
- "Redundant computation" root cause category in selfimprove workflow with fix template showing compute-once-pass-explicitly pattern

## [0.9.4] - 2026-02-20

### Technical
- Update /ace:create-pr to /ace:git-create-pr in perform-delivery workflow

## [0.9.3] - 2026-02-20

### Technical
- Update stale wfi:// references in workflow definition guide

## [0.9.2] - 2026-02-19

### Technical
- Namespace workflow instructions into handbook/ subdirectory with updated wfi:// URIs
- Update skill name references to use namespaced ace:handbook-action format

## [0.9.1] - 2026-02-04

### Added

- Preference hierarchy for search targets in selfimprove workflow (workflows/guides preferred over skills)

## [0.9.0] - 2026-02-03

### Added
- Self-improve workflow (`selfimprove.wf.md`) for transforming agent mistakes into system improvements

## [0.8.0] - 2026-01-31

### Added
- Multi-agent research synthesis capabilities (Task 254):
  - `multi-agent-research.g.md` guide explaining when/how to use parallel agents
  - `research-comparison.template.md` for structured synthesis comparison
  - `parallel-research.wf.md` workflow for setting up parallel agent research
  - `synthesize-research.wf.md` workflow for combining agent outputs
  - `research.wf.md` with single/multi-agent decision criteria
- Template protocol source configuration for ace-handbook templates

## [0.7.1] - 2026-01-29

### Fixed
- Refine exit code handling documentation for dry-cli framework with exception-based pattern

## [0.7.0] - 2026-01-22

### Added
- New guides extracted from ace-gems.g.md for better discoverability:
  - `prompt-caching.g.md` - PromptCacheManager patterns for LLM prompt generation
  - `cli-dry-cli.g.md` - Complete dry-cli framework reference
  - `mono-repo-patterns.g.md` - Mono-repo development patterns and binstubs
- Document IO isolation and testing pyramid patterns

### Technical
- Lower Ruby version requirement to >= 3.2.0

## [0.6.0] - 2026-01-18

### Added
- Add perform-delivery workflow for multi-step delivery tracking with automatic TodoWrite externalization

### Technical
- Update guides for bundle terminology

## [0.5.2] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.5.1] - 2026-01-08

### Fixed
- Fixed `guide://` protocol links in ace-test-runner guides (added `.g` suffix for `.g.md` files)
- Cross-gem guide:// links now properly resolve to resources with `.g` extension

## [0.5.0] - 2026-01-08

### Added
- Migrated 10 generic guides from dev-handbook to handbook/guides/
  - ai-agent-integration.g.md, atom-pattern.g.md, changelog.g.md
  - coding-standards.g.md, debug-troubleshooting.g.md, error-handling.g.md
  - performance.g.md, quality-assurance.g.md, strategic-planning.g.md
- Migrated 5 meta-guides to handbook/guides/meta/
  - agents-definition.g.md, guides-definition.g.md, markdown-definition.g.md
  - tools-definition.g.md, workflow-instructions-definition.g.md
- Guide subdirectories with language-specific content (ruby, rust, typescript)
- initialize-project-structure.wf.md workflow for project setup
- Templates: cookbooks/cookbook.template.md, completed-work-documentation.md
- Template discovery protocol (.ace-defaults/nav/protocols/tmpl-sources/)

### Changed
- Consolidates dev-handbook content into ace-handbook gem
- All development guides now distributed with gem installation

## [0.4.0] - 2026-01-03

### Added
- Guides support with handbook/guides/ directory
- workflow-context-embedding.g.md guide for embed_document_source pattern
- Guide discovery protocol (.ace-defaults/nav/protocols/guide-sources/ace-handbook.yml)

## [0.3.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.2.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory

## [0.1.0] - 2025-11-05

### Added
- Initial release of ace-handbook gem as pure workflow package
- 6 handbook management workflows accessible via wfi:// protocol:
  - `wfi://manage-guides` - Create and update development guides
  - `wfi://review-guides` - Review guides for quality and consistency
  - `wfi://manage-workflow-instructions` - Create and validate workflow files
  - `wfi://review-workflows` - Review workflow instructions
  - `wfi://manage-agents` - Create and update agent definitions
  - `wfi://update-handbook-docs` - Update handbook README and structure
- Path references updated for project-relative usage
- Complete gem structure following ACE patterns
- Comprehensive documentation and usage examples
- Auto-discovery support through ace-nav gem

### Changed
- Migrated workflows from dev-handbook/.meta/wfi/ to installable gem
- Updated path references to be project-root relative
- Removed dev-handbook specific dependencies

### Removed
- Moved `update-tools-docs.wf.md` to ace-docs package (tools documentation management)
- Moved `update-integration-claude.wf.md` to ace-integration-claude package (Claude Code integration)

### Fixed
- Added ace-nav protocol registration (.ace.example/nav/protocols/wfi-sources/ace-handbook.yml)
- Updated gemspec to include protocol registration files for proper discovery

### Technical Details
- Pure workflow package with no Ruby runtime dependencies
- Auto-discovery via ace-nav through handbook/workflow-instructions/ directory
- Protocol registration enables ace-nav to discover workflows from installed gem
- Template embedding framework ready for ADR-002 compliance
- Standard ACE gem structure with lib/, handbook/, gemspec, README, CHANGELOG
