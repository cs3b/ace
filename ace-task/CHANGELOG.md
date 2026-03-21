# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.30.1] - 2026-03-21

### Changed
- Consolidated dedicated hierarchy move/reparent workflows in `task/update` and removed the deprecated `task/reorganize` workflow and skill.
- Migrated coverage workflow ownership from task to test by removing `task-improve-coverage` and routing coverage planning to the test domain.

### Technical
- Removed stale references to retired task coverage/reorganize workflows and updated task discovery/update workflow guidance.

## [0.30.0] - 2026-03-21

### Changed
- Added initial `ace-task` TS-format smoke E2E coverage at `test/e2e/TS-TASK-001-core-cli-smoke` with runner/verifier goal contracts for help survey, create/show/list lifecycle, archive updates, and doctor health/error transitions.
- Added an E2E Decision Record documenting ADD/SKIP value-gate outcomes with unit-coverage evidence for `create`, `update`, `doctor`, and `plan` command suites.
