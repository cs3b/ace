# ADR-027: Canonical Skill Platform and Projection Model

## Status

Accepted
Date: 2026-03-13

## Context

Recent ACE work moved skills from provider-owned trees toward package-owned canonical definitions under `handbook/skills/`, with provider-specific trees generated as projections. The migration was not just a file move. It introduced a typed canonical skill schema, `skill://` discovery, explicit workflow bindings, and provider-specific projection metadata that can vary per integration without changing the underlying skill contract.

That shift was applied repeatedly across packages and integrations:

- packages now register canonical `handbook/skills` sources for `skill://` discovery
- linting enforces canonical schema fields such as `skill.kind` and `skill.execution.workflow`
- handbook sync/status flows project canonical skills into provider-native trees such as `.claude/skills` and `.codex/skills`
- legacy integration docs were updated to clarify that provider trees are projections, not the authoritative source

Without an ADR, future contributors could still treat provider-native trees as editable sources, blur the roles of `wfi://`, `tmpl://`, and `prompt://`, or add provider-only behavior directly to generated output trees. That would split ownership, break projection consistency, and weaken schema guarantees.

## Decision

We will treat package-owned canonical skill definitions as the only authoritative source for ACE skills, and provider-native skill folders as generated projections.

Key aspects of this decision:

- Canonical authored skills live in package `handbook/skills/` directories.
- A canonical skill defines the durable contract: name, purpose, allowed tools, workflow binding, and shared metadata.
- Provider-native trees such as `.claude/skills`, `.codex/skills`, `.gemini/skills`, `.opencode/skills`, and `.pi/skills` are generated views derived from canonical skills plus provider manifests/frontmatter overrides.
- Provider projections may add provider-specific execution metadata or frontmatter, but they must not redefine the underlying skill purpose or canonical workflow binding.
- `wfi://` identifies executable workflow instructions and remains the primary binding target for canonical skills.
- `tmpl://` and `prompt://` identify reusable composition resources; they are inputs to workflows/prompts, not replacements for workflow execution contracts.
- Canonical skills must satisfy the typed schema and validation rules enforced by ACE tooling.

## Consequences

### Positive

- Skill ownership is clear and package-local.
- Provider sync becomes deterministic because projections are generated from one source of truth.
- Schema validation can protect canonical contracts before projection.
- Documentation and discovery can consistently point users at canonical package skills and `wfi://` workflows.

### Negative

- Provider-specific changes now require projection-capable metadata and tooling instead of ad hoc edits in generated trees.
- Debugging can require checking both canonical inputs and provider manifests when a generated skill looks wrong.
- Migration work is needed whenever a legacy integration still implies provider-native ownership.

### Neutral

- Provider-native trees remain necessary for agent integrations, but their role is narrowed to projection outputs.
- The same skill can still present slightly different frontmatter per provider as long as the canonical contract stays stable.

## Alternatives Considered

### Alternative 1: Keep provider-native trees as editable sources

- **Description**: Allow `.claude/skills`, `.codex/skills`, and similar trees to remain first-class authored content.
- **Pros**: Simple local edits for a single provider.
- **Cons**: Ownership fragments across providers, drift becomes likely, and schema enforcement weakens.
- **Why not chosen**: ACE now relies on shared canonical skill contracts and projection tooling across providers.

### Alternative 2: Keep a single repo-level shared skill tree outside packages

- **Description**: Centralize all canonical skills in one integration-neutral root directory.
- **Pros**: One obvious location.
- **Cons**: Breaks package ownership, separates skills from the package workflows they wrap, and complicates packaging/discovery.
- **Why not chosen**: Package-local ownership aligns skills with the workflows, guides, and defaults they represent.

### Alternative 3: Use workflows directly with no canonical skill layer

- **Description**: Treat provider integrations as direct wrappers around `wfi://` resources without a canonical skill object.
- **Pros**: Fewer artifacts.
- **Cons**: Loses typed skill metadata, integration-specific validation, and discoverable user-facing command contracts.
- **Why not chosen**: The repository now depends on a typed canonical skill contract and provider projection model.

## Related Decisions

- [ADR-001: Workflow Self-Containment Principle](ADR-001-workflow-self-containment-principle.md)
- [ADR-016: Handbook Directory Architecture](ADR-016-handbook-directory-architecture.md)
- [ADR-026: Protocol-Driven Prompt Composition for ace-llm via ace-bundle](ADR-026-protocol-driven-prompt-composition-for-ace-llm-via-ace-bundle.md)

## References

- `ace-assign/CHANGELOG.md`
- `ace-handbook/CHANGELOG.md`
- `ace-lint/CHANGELOG.md`
- `ace-integration-claude/CHANGELOG.md`
- `ace-handbook-integration-codex/CHANGELOG.md`
- `ace-assign/handbook/skills/`
- `ace-task/handbook/skills/`
- `.codex/skills/`
- `.claude/skills/`

