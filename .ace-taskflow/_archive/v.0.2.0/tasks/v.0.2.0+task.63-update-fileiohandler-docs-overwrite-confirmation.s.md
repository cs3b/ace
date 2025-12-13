---
id: v.0.2.0+task.63
status: done
priority: critical
estimate: 2h
dependencies: []
---

# Update FileIOHandler Documentation - Interactive Overwrite Confirmation

## Objective / Problem

The recent security hardening changes have introduced interactive overwrite confirmation and a `--force` flag to the FileIOHandler molecule, but this is not documented anywhere. Users will encounter unexpected prompts when attempting to overwrite existing files and may not understand how to bypass them in scripts. This creates a user-blocking situation where the tool's behavior has changed without documentation.

## Directory Audit

Current documentation structure:
```
docs/
├── README.md (contains CLI command examples)
├── SETUP.md
└── other guides...

docs-project/current/v.0.2.1-synapse/doc_review/task-61/
└── dr-report-gpro-final.md (source of this requirement)
```

## Scope of Work

Update user-facing documentation to explain the new interactive overwrite confirmation behavior and `--force` flag introduced in the security hardening changes.

## Deliverables

1. **README.md Updates**:
   - Update `llm-query` command examples to mention the new `--force` flag
   - Add explanation of interactive overwrite confirmation behavior
   - Include examples of both interactive and non-interactive usage

2. **SETUP.md Updates** (if applicable):
   - Add note about the new security behavior for file operations

## Phases

1. **Audit Current Examples**: Review existing CLI command documentation
2. **Update Documentation**: Add `--force` flag and overwrite confirmation explanations
3. **Validate Examples**: Ensure all examples are accurate and complete

## Implementation Plan

### Planning Steps
* [x] Review current `llm-query` command documentation in README.md
* [x] Identify all locations where file output behavior is documented
* [x] Review the actual implementation to understand the exact behavior of `--force` flag and confirmation prompts

### Execution Steps
- [x] Update README.md `llm-query` command section to include `--force` flag documentation
- [x] Add explanation of interactive overwrite confirmation behavior
- [x] Include practical examples showing both interactive and scripted usage
- [x] Update any other relevant documentation mentioning file output behavior
- [x] Validate that all examples work as documented

## Acceptance Criteria

- [x] README.md includes documentation of the `--force` flag for `llm-query` command
- [x] Interactive overwrite confirmation behavior is clearly explained
- [x] Examples demonstrate both interactive and non-interactive usage scenarios
- [x] Users understand why prompts appear and how to bypass them in scripts
- [x] All CLI examples in documentation are accurate and up-to-date

## Out of Scope

- Implementation changes to the FileIOHandler behavior
- Documentation of other security features beyond file overwrite confirmation
- Updates to API documentation (YARD comments)

## References & Risks

- **Source**: `docs-project/current/v.0.2.1-synapse/doc_review/task-61/dr-report-gpro-final.md` section 9 (Critical priority item)
- **Risk**: Without this documentation, users may perceive the new prompts as bugs or breaking changes
- **Testing**: Manual verification that documented examples work as expected