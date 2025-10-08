# Changelog

All notable changes to ace-test-support will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.2] - 2025-10-08

### Changed

- **Test Structure Migration**: Migrated to flat ATOM structure
  - From: `test/unit/atoms/` and `test/unit/molecules/`
  - To: `test/atoms/` and `test/molecules/`
  - Aligns with standardized test organization across all ACE packages
  - Simplifies test discovery and maintenance

## [0.9.1] - 2025-10-08

### Changed
- **Test directory structure**: Reorganized tests to follow ATOM architecture
  - Moved tests from flat `test/*.rb` structure to `test/unit/atoms/` and `test/unit/molecules/`
  - Makes tests discoverable by ace-test-runner
  - Aligns with project-wide ATOM architecture pattern (ADR-011)
  - Files organized as:
    - `test/unit/atoms/`: base_test_case_test.rb, test_helper_test.rb
    - `test/unit/molecules/`: config_helpers_test.rb, test_environment_test.rb

## [0.9.0] - 2025-10-05

Initial release with shared test utilities for ACE ecosystem.
