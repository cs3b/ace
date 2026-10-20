# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [0.27.3] - 2026-10-20

### Fixed

- `TaskIDExtractor`: preserve the complete subtask segment chain of
  multi-level task ids. `extract`, `short_id`, and `normalize` now accept
  any depth (`8xh.t.ddd.0.0` -> `ddd.0.0`), so third/fourth-level tasks
  get deterministic, reversible worktree directories (`t.ddd.0.0`) and
  branches (`ddd.0.0-<slug>`) instead of collapsing every deep leaf onto
  `t.unknown` / `unknown-<slug>`; directory-name normalization
  (`t.ddd.0.0`) keeps the same chain.

