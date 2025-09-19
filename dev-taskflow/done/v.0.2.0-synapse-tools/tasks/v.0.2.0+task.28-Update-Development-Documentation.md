---
id: v.0.2.0+task.28
status: done
priority: high
estimate: 2h
dependencies: []
---

# Update Development Documentation with New Tools and Testing Patterns

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs | sed 's/^/    /'
```

_Result excerpt:_

```
    docs
    ├── DEVELOPMENT.md
    ├── SETUP.md
    └── architecture
        ├── ADR-001-CI-Aware-VCR-Configuration.md
        └── README.md
```

## Objective

Update DEVELOPMENT.md to document the new `bin/cr` code review tool and establish the VCR-wrapped localhost probe pattern as a best practice for testing services like LM Studio. This ensures developers are aware of all available tools and follow consistent testing patterns.

## Scope of Work

- Add documentation for the new `bin/cr` tool in the developer tools section
- Document the VCR-wrapped localhost probe pattern for CI-safe testing
- Reference the updated ADR-001 for detailed localhost testing guidance
- Ensure the documentation follows existing style and structure

### Deliverables

#### Modify

- docs/DEVELOPMENT.md

## Phases

1. Audit current DEVELOPMENT.md structure
2. Add bin/cr tool documentation
3. Update testing strategy section
4. Add cross-references to related documentation

## Implementation Plan

### Planning Steps

* [x] Locate appropriate sections in DEVELOPMENT.md for updates
  > TEST: Section Identification
  > Type: Pre-condition Check
  > Assert: Developer tools and testing strategy sections are identified
  > Command: grep -n "^##" docs/DEVELOPMENT.md | grep -E "Tool|Test|Build"
* [x] Review bin/cr script to understand its functionality
* [x] Analyze the VCR localhost testing pattern from the code review

### Execution Steps

- [x] Add new subsection for bin/cr in developer tools or build system commands
  > TEST: bin/cr Documentation Added
  > Type: Action Validation
  > Assert: bin/cr tool is documented with purpose and usage
  > Command: grep -A5 "bin/cr" docs/DEVELOPMENT.md
- [x] Document bin/cr purpose: generates comprehensive code review prompts from git diff
- [x] Add usage example for bin/cr
- [x] Update Testing Strategy section with VCR-wrapped localhost probe pattern
  > TEST: Localhost Testing Pattern Documented
  > Type: Action Validation
  > Assert: VCR-wrapped probe pattern is explained for localhost services
  > Command: grep -A3 "localhost.*VCR" docs/DEVELOPMENT.md
- [x] Add example of lm_studio_available? helper pattern
- [x] Add cross-reference to ADR-001 for detailed localhost testing guidance
  > TEST: ADR Reference Added
  > Type: Action Validation
  > Assert: ADR-001 is referenced in the testing section
  > Command: grep "ADR-001" docs/DEVELOPMENT.md

## Acceptance Criteria

- [x] bin/cr tool is fully documented with purpose, usage, and examples
- [x] The tool documentation mentions it wraps docs-dev/tools/generate-code-review-prompt
- [x] VCR-wrapped localhost probe pattern is documented as a best practice
- [x] The pattern explains why direct Net::HTTP calls in test before blocks cause CI fragility
- [x] Example code for the lm_studio_available? helper pattern is included
- [x] Cross-reference to ADR-001 is added for detailed localhost testing guidance
- [x] All additions follow existing documentation style and formatting

## Out of Scope

- ❌ Documenting other developer tools not mentioned in the review
- ❌ Rewriting existing testing documentation
- ❌ Adding detailed VCR configuration (this belongs in ADR-001)
- ❌ Creating new testing helpers or scripts

## References

- Documentation Review: docs-project/current/v.0.2.0-synapse/code-review/task-4/docs-review-gemini-2.5-pro.md
- Suggested content for bin/cr:
  ```markdown
  #### `bin/cr` (Code Review Prompt Generator)
  **Purpose**: Generates a comprehensive code review prompt from the current git diff.
  ```bash
  # Generate a prompt for the current changes
  bin/cr
  ```
  - Wraps the `docs-dev/tools/generate-code-review-prompt` tool.
  - Useful for preparing context for AI-assisted or peer code reviews.
  ```
- VCR localhost pattern: Use dedicated, VCR-wrapped availability check to avoid CI fragility