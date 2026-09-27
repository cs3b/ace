# Changelog

All notable changes to `ace-herdr` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Gem bootstrap (spec 8wm.t.vs0): push delivery + agent bootstrap for the Herdr runtime, implementing the ace-hitl provider delivery contract (`deliver(ref, answer)` -> `DeliverResult` with `:delivered`/`:retryable`/`:failed`).
