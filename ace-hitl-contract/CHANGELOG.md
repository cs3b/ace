# Changelog

## [Unreleased]

### Fixed
- Reject non-string payload digests and impossible nested calendar timestamps consistently with the Hermes message contract.

### Changed
- Publish the pure managed/v1 envelope codec, incarnation-bound Inbox event identity, distinct nested transport/reverse schemas, shared secret gate and packaged managed/ingress observation examples without adding runtime dependencies.

## [0.1.0] - 2026-10-04

### Added

- Extract the existing HITL provider references, results and error hierarchy into one dependency-free protocol package, preserving their namespace and behavior.
