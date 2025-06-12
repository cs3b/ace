---
id: v.0.2.0+task.11
status: pending
priority: high
estimate: 5h
dependencies: [v.0.2.0+task.1]
---

# Update Architecture and Blueprint Documentation

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs-project | sed 's/^/    /'
```

_Result excerpt:_

```
    docs-project
    ├── architecture.md
    ├── backlog
    ├── blueprint.md
    ├── current
    ├── decisions
    ├── done
    ├── roadmap.md
    └── what-do-we-build.md
```

## Objective

Update the core architecture and blueprint documentation to reflect the significant architectural changes introduced in task.1, including new ATOM-based components, architectural patterns (Zeitwerk, dry-monitor), HTTP client strategy, and updated file organization. These documents serve as the primary reference for understanding the project's technical structure and design decisions.

## Scope of Work

- Update `docs-project/architecture.md` with new ATOM components and architectural patterns
- Update `docs-project/blueprint.md` with new project organization and technology stack
- Document new runtime and development dependencies
- Update file organization sections to reflect new directory structure
- Document new architectural patterns and cross-cutting concerns

### Deliverables

#### Modify

- docs-project/architecture.md
- docs-project/blueprint.md

## Phases

1. Audit current architecture and blueprint documentation
2. Identify all new components and architectural changes from task.1
3. Update ATOM-based code structure sections
4. Update file organization and technology stack sections
5. Add new architectural patterns and cross-cutting concerns
6. Update dependency lists and entry points

## Implementation Plan

### Planning Steps

* [ ] Review current architecture.md and blueprint.md to understand existing structure
  > TEST: Documentation Structure Analysis
  > Type: Pre-condition Check
  > Assert: Current documentation structure and sections are mapped
  > Command: bin/test --check-arch-docs-structure-analyzed
* [ ] Analyze task.1 implementation to identify all new components and patterns
* [ ] Review suggestions-gemini.md specifications for exact architectural updates needed
* [ ] Plan content organization to maintain document coherence and readability

### Execution Steps

- [ ] Update `docs-project/architecture.md` "ATOM-Based Code Structure" section:
  - Add new Atoms: EnvReader, HTTPClient, JSONFormatter
  - Add new Molecules: APICredentials, HTTPRequestBuilder, APIResponseParser
  - Add new Organisms: GeminiClient, PromptProcessor
  - Add new cross-cutting concerns: middlewares/, notifications.rb, error_reporter.rb, cli_registry.rb
  > TEST: ATOM Structure Updates
  > Type: Action Validation
  > Assert: All new ATOM components are properly documented
  > Command: bin/test --validate-atom-structure-updates docs-project/architecture.md
- [ ] Update architecture.md "File Organization" section with new files and directories
- [ ] Add new "Development Patterns" subsections for "Testing with VCR" and "Observability with dry-monitor"
- [ ] Update architecture.md "Dependencies" sections with new runtime (faraday, zeitwerk, dry-monitor, dry-configurable, addressable) and development (vcr, webmock) dependencies
- [ ] Update `docs-project/blueprint.md` "Project Organization" section for new lib/ subdirectories and exe/ directory
- [ ] Update blueprint.md "Technology Stack" section with new gems and patterns
- [ ] Update blueprint.md "Entry Points" and "Common Workflows" to include exe/llm-gemini-query
- [ ] Update blueprint.md "Dependencies" sections with new runtime and development dependencies
  > TEST: Blueprint Updates Complete
  > Type: Action Validation
  > Assert: Blueprint documentation reflects all new project organization changes
  > Command: bin/test --validate-blueprint-updates docs-project/blueprint.md
- [ ] Add cross-references between architecture.md and blueprint.md for consistency
- [ ] Ensure all new architectural patterns are explained with their purpose and benefits

## Acceptance Criteria

- [ ] architecture.md "ATOM-Based Code Structure" includes all new Atoms, Molecules, and Organisms
- [ ] architecture.md "File Organization" reflects new directory structure and key files
- [ ] architecture.md includes new "Development Patterns" section covering VCR and dry-monitor
- [ ] architecture.md "Dependencies" sections are updated with all new runtime and development dependencies
- [ ] blueprint.md "Project Organization" reflects new lib/ subdirectories and exe/ directory
- [ ] blueprint.md "Technology Stack" includes new gems and architectural patterns
- [ ] blueprint.md "Entry Points" and "Common Workflows" include exe/llm-gemini-query
- [ ] blueprint.md "Dependencies" sections match architecture.md dependency updates
- [ ] Both documents maintain consistent terminology and cross-reference each other appropriately
- [ ] All new architectural patterns are explained with context and rationale
- [ ] Documents follow existing project documentation style and formatting

## Out of Scope

- ❌ Creating new ADR documents (separate task)
- ❌ Updating other documentation files beyond architecture.md and blueprint.md
- ❌ Modifying actual code or implementation
- ❌ Creating detailed API documentation

## References

- `coding-agent-tools/docs-project/current/v.0.2.0-synapse/code-review/task.1.reviewed/suggestions-gemini.md` (lines 236-269)
- Current `lib/` directory structure for new components
- `exe/llm-gemini-query` for new entry point documentation
- `docs-dev/guides/documentation.g.md` for style guidelines
- Existing architecture.md and blueprint.md for formatting reference