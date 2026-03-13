# ADR-030: Cross-Cutting Compact ID Contract

## Status

Accepted
Date: 2026-03-13

## Context

ACE increasingly uses short, human-readable identifiers for tasks, retros, assignments, reports, and time-derived artifacts. Recent work reinforced Base36 encoding behavior, canonical examples for compact timestamp IDs, and artifact naming patterns that assume short, sortable identifiers rather than long opaque strings.

At the same time, the repository already contains persisted legacy identifiers and older naming patterns. A forward-looking contract is needed so new work converges on one compact format without forcing disruptive rewrites of existing history.

## Decision

We will standardize new ACE artifact identifiers on 6-character Base36 compact IDs in the current release line, while preserving explicit compatibility for legacy formats.

Key aspects of this decision:

- New human-facing IDs for artifacts, tasks, reports, and related repo-local records should use 6-character Base36 identifiers unless a stronger domain-specific constraint is already documented.
- When time-derived IDs are needed, `ace-b36ts` is the canonical generator and decoder.
- New naming conventions should assume compact IDs are stable, sortable enough for operational use, and short enough for terminal/UI display.
- Existing persisted identifiers in legacy formats remain readable and may continue to appear in historical data, file paths, or compatibility surfaces.
- This ADR does not require mass renaming or backfilling of historical artifacts.

## Consequences

### Positive

- IDs remain short enough for terminal displays, dashboards, and filenames.
- Cross-package tooling can assume a consistent compact identifier style for new work.
- Time-derived IDs have a clear canonical implementation path through `ace-b36ts`.

### Negative

- Compatibility code and docs may still need to recognize older timestamp or legacy ID shapes.
- Some domains may still need special-purpose identifiers, which requires explicit exceptions instead of silent drift.
- Compact IDs carry less embedded meaning than verbose slugs or longer UUID-like strings.

### Neutral

- The ADR is forward-looking: it standardizes new identifiers without rewriting historical records.
- Slug suffixes or descriptive filenames may still be combined with compact IDs when a workflow needs human-readable names.

## Alternatives Considered

### Alternative 1: Use variable-length Base36 IDs per package

- **Description**: Let each package choose any compact length or encoding variant.
- **Pros**: Package flexibility.
- **Cons**: Inconsistent UX and more parsing/documentation burden.
- **Why not chosen**: ACE benefits from a single compact-ID expectation across packages.

### Alternative 2: Standardize on long UUID-style identifiers

- **Description**: Use UUIDs or similarly long opaque identifiers for all new artifacts.
- **Pros**: Familiar and collision-resistant.
- **Cons**: Poor terminal ergonomics and worse filename readability.
- **Why not chosen**: ACE workflows emphasize compact operator-friendly IDs.

### Alternative 3: Keep legacy timestamp and mixed-format IDs indefinitely

- **Description**: Make no new standard and continue the mixed historical approach.
- **Pros**: No migration guidance needed.
- **Cons**: New packages would continue to diverge in naming, sorting, and operator UX.
- **Why not chosen**: The repo now has enough compact-ID adoption to justify a forward contract.

## Related Decisions

- [ADR-022: Configuration Default and Override Pattern](ADR-022-configuration-default-and-override-pattern.md)
- [ADR-029: Local Artifact Layout Standardization](ADR-029-local-artifact-layout-standardization.md)

## References

- `ace-b36ts/CHANGELOG.md`
- `CHANGELOG.md`
- `ace-b36ts/handbook/skills/as-b36ts/SKILL.md`
- `ace-task/CHANGELOG.md`

