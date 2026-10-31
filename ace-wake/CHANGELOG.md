# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Agent-callable eyes start with configPath, returning initial pending revisions
  without a redundant wake; quota breakers and retirement remain protected.

## [0.1.0] - 2026-10-30

First publishable release of the ace-wake asset package (task family
8xs.t.pu0).

### Added

- Publishable gem packaging: `ace-wake.gemspec`, `lib/ace/wake/version.rb`,
  changelog, Rakefile.
- Extension source under `handbook/extensions/ace-wake/` — the standard
  handbook projection tree — as the single copy (task 8xs.t.pu0.0);
  deployment converged from the gem (`ace-handbook sync --provider pi`,
  `ace-lab install` extension projections) instead of the manual host copy.
- Minitest wrapper executing the JavaScript suite (`node --test`) so
  `ace-test ace-wake` runs the real extension tests.
- Zero-idle window coverage (8xs.t.pu0.f): 30 minutes of healthy silence
  consume zero model turns while technical polling is counted separately.
- Secret-ask coverage: a redacted watch wakes with the case reference only.

### Changed

- Eyes and user subscriptions coexist (task 8xs.t.pu0.2): `/eyes start` no
  longer retires active loops/watches, and `/watch add`/`/loop add` are no
  longer rejected while eyes observes — one shared delivery infrastructure,
  no competing observation ownership.
- Secret asks wake with the reference only (task 8xs.t.pu0.9): a watch armed
  with `redact` (secret HITL cases) strips the delta's content excerpt, so a
  delivered OTP never passes through the model; the message points at the
  secure channel. Normal asks still name the answer.

### Fixed

- macOS environment fixture: watch delta path assertions compare against
  the canonical realpath of the watched case file (`/var` vs
  `/private/var` tmpdir).
