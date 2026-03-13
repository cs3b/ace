# ADR-029: Local Artifact Layout Standardization

## Status

Accepted
Date: 2026-03-13

## Context

Between late 2025 and early 2026, many ACE packages migrated runtime outputs from scattered `.cache/ace-*` paths or package-name `.ace-local/ace-*` paths toward a consistent short-name layout under `.ace-local/`. This affected caches, reports, sessions, hidden specs, sandbox artifacts, and workflow documentation across multiple packages.

The same migration pattern appeared repeatedly:

- defaults changed from `.cache/ace-*` to `.ace-local/<short-name>`
- documentation corrected `.ace-local/ace-*` examples to short-name paths
- tools that discover or ignore project-local artifacts were updated to treat `.ace-local` as the standard repo-local artifact root
- some packages retained legacy read behavior to preserve existing data while shifting all new writes and docs to the new convention

Without an ADR, new packages could reintroduce package-name pathing, invent new top-level artifact roots, or remove compatibility too aggressively.

## Decision

We will standardize repo-local runtime artifacts on `.ace-local/<short-name>/...`.

Key aspects of this decision:

- `.ace-local/` is the standard project-local root for ACE runtime artifacts, caches, reports, hidden specs, sessions, and sandbox outputs unless a temporary system directory is more appropriate.
- Package paths use a short-name segment such as `assign`, `bundle`, `docs`, `review`, `sim`, `test`, or `test-e2e`, not package names like `ace-assign` or `ace-review`.
- New defaults, documentation, and examples must use the short-name `.ace-local` layout.
- Legacy `.cache/ace-*` and `.ace-local/ace-*` paths may remain readable where already shipped, but they are compatibility paths, not current write targets.
- Cross-cutting tooling such as scanners, cleanup logic, and ignore patterns should treat `.ace-local` as the canonical repo-local artifact root.

## Consequences

### Positive

- Artifact locations become predictable across packages.
- Workflow documentation can use one consistent path convention.
- Cleanup, ignore rules, and support tooling can target one repo-local root.
- Shorter paths improve readability and reduce duplicated package prefixes.

### Negative

- Migration notes and fallbacks are needed while older artifact locations still exist in the field.
- Operators may temporarily need to recognize both legacy and canonical paths.
- Packages that previously embedded package names in local paths lose that redundancy.

### Neutral

- The ADR standardizes repo-local artifact layout, not every temporary file decision. Some workflows still legitimately use `/tmp` or similar system temp locations.
- Existing packages may keep compatibility reads until those older paths are no longer needed operationally.

## Alternatives Considered

### Alternative 1: Keep package-name paths under `.ace-local/ace-*`

- **Description**: Use `.ace-local/ace-assign`, `.ace-local/ace-review`, and similar package-name directories.
- **Pros**: Directly mirrors gem names.
- **Cons**: Verbose, inconsistent with the adopted short-name convention, and repeatedly corrected in docs.
- **Why not chosen**: The repository has already converged on short-name pathing.

### Alternative 2: Keep `.cache/ace-*` as the long-term default

- **Description**: Continue using the older cache-root convention for runtime state.
- **Pros**: Historical continuity.
- **Cons**: Fragmented user experience, weaker project-local discoverability, and repeated migration churn.
- **Why not chosen**: ACE has already moved multiple packages and docs to `.ace-local`.

### Alternative 3: Let each package choose its own local artifact root

- **Description**: Treat local artifact layout as package-specific.
- **Pros**: Maximum flexibility.
- **Cons**: Poor predictability, more ignore/scanner complexity, and cross-tool friction.
- **Why not chosen**: Cross-package operator workflows benefit from one canonical local layout.

## Related Decisions

- [ADR-004: Consistent Path Standards](ADR-004-consistent-path-standards.md)
- [ADR-022: Configuration Default and Override Pattern](ADR-022-configuration-default-and-override-pattern.md)

## References

- `CHANGELOG.md`
- `ace-assign/CHANGELOG.md`
- `ace-bundle/CHANGELOG.md`
- `ace-docs/CHANGELOG.md`
- `ace-review/CHANGELOG.md`
- `ace-test-runner/CHANGELOG.md`
- `docs/blueprint.md`
- `AGENTS.md`

