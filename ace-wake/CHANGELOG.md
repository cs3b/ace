# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-10-30

### Added

- Publishable gem packaging: `ace-wake.gemspec`, `lib/ace/wake/version.rb`, changelog.
- Extension source moved under `handbook/extensions/ace-wake/` — the standard handbook
  projection tree — as the single copy (task 8xs.t.pu0.0).
- Minitest wrapper executing the JavaScript suite (`node --test`) so `ace-test ace-wake`
  runs the real extension tests.

### Changed

- Repository-top-level `index.js`/`wake/` layout replaced by the gem's
  `handbook/extensions/ace-wake/` tree; host-lane manual copy is replaced by
  gem-driven projection (installer / `ace-handbook sync --provider pi`).

### Fixed

- macOS environment fixture: watch delta path assertions compare against the canonical
  realpath of the watched case file (`/var` vs `/private/var` tmpdir).
