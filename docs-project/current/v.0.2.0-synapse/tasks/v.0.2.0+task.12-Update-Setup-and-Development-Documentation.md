---
id: v.0.2.0+task.12
status: pending
priority: high
estimate: 3h
dependencies: [v.0.2.0+task.1]
---

# Update Setup and Development Documentation

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs | grep -E '(SETUP|DEVELOPMENT)' | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── DEVELOPMENT.md
    ├── SETUP.md
```

## Objective

Update the setup and development documentation to reflect the new requirements and development practices introduced in task.1, including updated Ruby version requirements, new API key setup for development, VCR testing configuration, and new architectural patterns that developers need to understand.

## Scope of Work

- Update `docs/SETUP.md` with new Ruby version requirements and API key setup
- Update `docs/DEVELOPMENT.md` with new testing strategies and architectural patterns
- Document VCR setup and usage for API integration tests
- Update build system information with new gem verification steps
- Document new development dependencies and their purpose

### Deliverables

#### Modify

- docs/SETUP.md
- docs/DEVELOPMENT.md

## Phases

1. Audit current setup and development documentation
2. Update SETUP.md with new requirements and configuration
3. Update DEVELOPMENT.md with new testing strategies and patterns
4. Add VCR and API key setup documentation
5. Update build system and development workflow information

## Implementation Plan

### Planning Steps

* [ ] Review current SETUP.md and DEVELOPMENT.md to understand existing structure
  > TEST: Development Docs Structure Analysis
  > Type: Pre-condition Check
  > Assert: Current documentation structure and sections are identified
  > Command: bin/test --check-dev-docs-structure-analyzed
* [ ] Review .tool-versions and new dependencies to understand updated requirements
* [ ] Analyze VCR setup and testing patterns from task.1 implementation
* [ ] Plan content updates to maintain document flow and usability

### Execution Steps

- [ ] Update `docs/SETUP.md` "Prerequisites" section:
  - Update Ruby version requirement to 3.4.2 (from .tool-versions)
  - Add "Configuration" section for API keys setup
  - Document GEMINI_API_KEY and .env.example usage for development
  - Mention spec/.env setup for VCR recording
  > TEST: SETUP.md Updates Complete
  > Type: Action Validation
  > Assert: SETUP.md reflects all new requirements and configuration
  > Command: bin/test --validate-setup-updates docs/SETUP.md
- [ ] Update `docs/DEVELOPMENT.md` "Testing Strategy" section:
  - Add new subsection for "Integration Tests with VCR"
  - Document VCR usage for API-dependent tests
  - Link to docs/testing-with-vcr.md for detailed VCR information
  - Explain API key setup in spec/ for recording new cassettes
- [ ] Update DEVELOPMENT.md "Build System Commands" section:
  - Document new gem installation verification step in bin/build
  - Explain enhanced build confidence through local gem installation testing
- [ ] Add new section in DEVELOPMENT.md for "Architectural Patterns":
  - Mention Zeitwerk autoloading adoption
  - Document dry-monitor observability pattern
  - Explain ATOM-based component organization
  > TEST: DEVELOPMENT.md Updates Complete
  > Type: Action Validation
  > Assert: DEVELOPMENT.md includes all new patterns and testing strategies
  > Command: bin/test --validate-development-updates docs/DEVELOPMENT.md
- [ ] Add cross-references between SETUP.md and DEVELOPMENT.md for consistency
- [ ] Ensure all new dependencies are mentioned with their development purpose

## Acceptance Criteria

- [ ] SETUP.md "Prerequisites" section specifies Ruby >= 3.4.2
- [ ] SETUP.md includes "Configuration" section with GEMINI_API_KEY setup instructions
- [ ] SETUP.md documents .env.example usage and spec/.env setup for VCR
- [ ] DEVELOPMENT.md "Testing Strategy" includes VCR integration testing section
- [ ] DEVELOPMENT.md links to docs/testing-with-vcr.md for detailed VCR information
- [ ] DEVELOPMENT.md "Build System Commands" documents new gem verification step
- [ ] DEVELOPMENT.md includes new "Architectural Patterns" section covering Zeitwerk, dry-monitor, and ATOM organization
- [ ] Both documents maintain consistency in terminology and cross-reference appropriately
- [ ] All new development dependencies are explained with their purpose
- [ ] Documents follow existing project documentation style and formatting

## Out of Scope

- ❌ Creating the detailed VCR testing guide (already exists)
- ❌ Updating other documentation files
- ❌ Modifying actual build scripts or configuration
- ❌ Setting up actual API keys or testing live integrations

## References

- `coding-agent-tools/docs-project/current/v.0.2.0-synapse/code-review/task.1.reviewed/suggestions-gemini.md` (lines 270-286)
- `.tool-versions` file for Ruby version requirements
- `.env.example` files for API key setup patterns
- `docs/testing-with-vcr.md` for VCR testing reference
- `bin/build` script for build system changes
- `docs-dev/guides/documentation.g.md` for style guidelines