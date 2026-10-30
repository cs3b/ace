# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Secret asks wake with the reference only (task 8xs.t.pu0.9): a watch armed
  with `redact` (secret HITL cases) strips the delta's content excerpt, so a
  delivered OTP never passes through the model; the message points at the
  secure channel. Normal asks still name the answer.

- Eyes and user subscriptions coexist (task 8xs.t.pu0.2): `/eyes start` no
  longer retires active loops/watches, and `/watch add`/`/loop add` are no
  longer rejected while eyes observes — one shared delivery infrastructure,
  no competing observation ownership.
- Coexistence is pinned by public-command tests: `/watch add` under active
  eyes registers and delivers exactly one wake per change, eyes activation
  preserves existing watches, and healthy silence produces no extra turns.

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
