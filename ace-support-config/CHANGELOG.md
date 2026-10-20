# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


## [0.18.3] - 2026-10-20

### Fixed
- `ConfigFinder#find_all`: deterministic per-tier tie order — when
  several file patterns match in the same search path (e.g. both
  `config.yml` and `config.yaml` exist in one tier), the earlier
  pattern consistently takes priority; previously the tie relied on
  `Array#sort`, which is unstable for equal priorities. Shared by
  every consumer of the finder (`ConfigResolver#resolve_file`,
  ace-coworker's executor probe), so the yml/yaml policy no longer
  diverges between loaders (8xi1p4z9).

