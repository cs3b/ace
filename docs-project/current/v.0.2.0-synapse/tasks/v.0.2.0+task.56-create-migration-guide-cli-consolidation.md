---
id: v.0.2.0+task.56
status: done
priority: high
estimate: 2h
dependencies: ["v.0.2.0+task.53", "v.0.2.0+task.54", "v.0.2.0+task.55"]
---

# Create Migration Guide for CLI Command Consolidation

## Objective / Problem

The recent consolidation of multiple `llm-*-query` executables into a single unified `llm-query` command represents a significant breaking change. Users who have scripts, aliases, or muscle memory for the old commands need clear guidance on migrating to the new interface. Without a migration guide, users will experience friction when upgrading.

## Directory Audit

```bash
tree -L 2 docs | sed 's/^/    /'

    docs
    ├── ADR-001-CI-Aware-VCR-Configuration.md
    ├── README.md
    ├── SETUP.md
    ├── architecture.md
    ├── blueprint.md
    ├── development.md
    └── what-do-we-build.md
```

## Scope of Work

- Create a comprehensive migration guide (`MIGRATION.md`) in the `docs/` directory
- Document the transition from old CLI commands to new unified command
- Include examples of common migration scenarios
- Add reference to the migration guide in main README.md

## Deliverables / Manifest

| File | Action | Purpose |
|------|--------|---------|
| `docs/MIGRATION.md` | Create | Main migration guide with comprehensive transition instructions |
| `docs/README.md` | Modify | Add prominent link to migration guide for users upgrading |

## Phases

1. **Audit** - Review all old CLI commands and their options
2. **Document** - Write comprehensive migration instructions
3. **Examples** - Provide before/after command examples
4. **Integration** - Link migration guide from README

## Implementation Plan

### Planning Steps
* [x] Review all old `llm-*-query` executables to catalog exact command syntaxes
* [x] Identify all command-line options and their equivalents in new syntax
* [x] Plan migration examples covering common use cases

### Execution Steps
- [x] Create `docs/MIGRATION.md` with the following sections:
  - Breaking Changes overview
  - Old vs New Command Mapping table
  - Step-by-step migration instructions
  - Common examples with before/after
  - Alias suggestions for backward compatibility
  - Troubleshooting section
- [x] Include specific examples for each provider:
  - `llm-gemini-query` → `llm-query google:model`
  - `llm-anthropic-query` → `llm-query anthropic:model`
  - `llm-openai-query` → `llm-query openai:model`
  - `llm-mistral-query` → `llm-query mistral:model`
  - `llm-together-query` → `llm-query together_ai:model`
  - `llm-lms-query` → `llm-query lmstudio:model`
- [x] Document alias support (gflash, csonet, etc.)
- [x] Add backward compatibility suggestions using shell aliases
- [x] Update `README.md` with migration notice at the top
  > TEST: Migration Guide Link
  >   Type: Action Validation
  >   Assert: README.md contains visible link to MIGRATION.md
  >   Command: grep -q "MIGRATION.md" README.md
- [x] Add section about model override syntax changes if applicable

## Acceptance Criteria

- [x] `docs/MIGRATION.md` exists with comprehensive migration instructions
- [x] All six old CLI commands have documented migration paths
- [x] Examples cover basic usage, options, and edge cases
- [x] Shell alias examples provided for backward compatibility
- [x] README.md prominently links to the migration guide
- [x] Guide is clear enough that a user can migrate without reading source code

## Out of Scope

- Modifying the actual CLI implementation
- Creating automated migration scripts
- Updating provider-specific documentation beyond migration needs
- Backporting old command support

## References & Risks

- Task 53: [Verify Documentation Reflects Unified LLM Query Command](v.0.2.0+task.53-verify-documentation-unified-llm-query-command.md)
- Task 54: [Refactor build_client Method to Use Factory Pattern](v.0.2.0+task.54-refactor-build-client-factory-pattern.md)
- Task 55: [Make provider_name an Explicit Class Method](v.0.2.0+task.55-explicit-provider-name-base-client.md)
- Risk: Users may have automated scripts that break with the new syntax - mitigated by clear alias examples