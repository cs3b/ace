---
id: v.0.2.0+task.53
title: Verify Documentation Reflects Unified LLM Query Command
created_at: '2025-06-24T20:03:00Z'
updated_at: '2025-06-24T20:03:00Z'
release: v.0.2.0
status: backlog
priority: high
tags: [documentation, cli, llm-query, verification]
owner: TBD
estimate: 2-3h
dependencies: [task.44]
note: |
  As identified in the code review from gpro (commits-after-1361d77-20250624-205941/cr-report-gpro.md), 
  the unified llm-query command represents a significant breaking change to the CLI interface. 
  All user-facing documentation must be updated to reflect this change.
---

# Task: Verify Documentation Reflects Unified LLM Query Command

## Objective

Ensure all user-facing documentation accurately reflects the new unified `llm-query` command syntax (`llm-query <provider>:<model>`) and properly documents the deprecation of the old provider-specific executables (e.g., `llm-google-query`, `llm-anthropic-query`).

## Directory Audit

```bash
# Current documentation structure
docs/
├── README.md
├── SETUP.md
├── DEVELOPMENT.md
├── architecture.md
├── blueprint.md
├── what-do-we-build.md
└── ...

docs-dev/
├── guides/
│   ├── google-query-guide.md
│   ├── model-management-guide.md
│   └── ...
└── ...

exe/
├── llm-query (new unified executable)
├── llm-google-query (deprecated)
├── llm-anthropic-query (deprecated)
└── ...
```

## Scope of Work

Review and update all documentation files that reference LLM query commands to:
1. Replace old provider-specific command syntax with the new unified syntax
2. Add migration notes for users transitioning from old commands
3. Ensure examples demonstrate the new `provider:model` syntax
4. Document backward compatibility wrapper scripts if implemented

## Deliverables

### Files to Review and Update
- [ ] `README.md` - Update all LLM query examples and feature descriptions
- [ ] `docs/SETUP.md` - Update installation and initial usage examples
- [ ] `docs/DEVELOPMENT.md` - Update development workflow examples
- [ ] `docs-dev/guides/google-query-guide.md` - Convert to use unified syntax
- [ ] `docs-dev/guides/model-management-guide.md` - Update model selection examples
- [ ] Any other guides referencing LLM queries

### Files to Create
- [ ] `docs/MIGRATION.md` - Migration guide for users upgrading from old syntax

## Phases

1. **Discovery Phase**: Identify all documentation containing LLM query references
2. **Update Phase**: Systematically update each document with new syntax
3. **Migration Guide Phase**: Create comprehensive migration documentation
4. **Verification Phase**: Test all examples to ensure they work with new syntax

## Implementation Plan

### Planning Steps
* [ ] Search all documentation files for references to old command patterns (`llm-*-query`)
  > TEST: Documentation Search Complete
  >   Type: Pre-condition Check
  >   Assert: All files with old command references are identified
  >   Command: grep -r "llm-[a-z]*-query" docs/ docs-dev/ README.md | wc -l
* [ ] Review current `llm-query` implementation to understand exact syntax and options
* [ ] Identify if backward compatibility wrappers exist and how they work

### Execution Steps
- [ ] Update README.md with new command syntax
  > TEST: README Examples Valid
  >   Type: Action Validation
  >   Assert: All llm-query examples in README use new syntax
  >   Command: grep -E "llm-query\s+\w+:\w+" README.md | wc -l
- [ ] Update SETUP.md installation and usage examples
- [ ] Update DEVELOPMENT.md workflow examples
- [ ] Convert google-query-guide.md to use unified syntax
- [ ] Update model-management-guide.md with new model selection approach
- [ ] Create MIGRATION.md with:
  - Old vs new command comparison table
  - Step-by-step migration instructions
  - Common migration scenarios
  - Backward compatibility notes
- [ ] Test all documented examples to ensure they execute correctly
  > TEST: Example Commands Execute
  >   Type: Action Validation
  >   Assert: All example commands in documentation execute without error
  >   Command: bin/test-doc-examples --pattern "llm-query"

## Acceptance Criteria

- [ ] All documentation files use the new `llm-query <provider>:<model>` syntax
- [ ] No references to old provider-specific executables remain (except in migration guide)
- [ ] Migration guide clearly explains the transition process
- [ ] All code examples in documentation are tested and working
- [ ] Backward compatibility (if available) is properly documented
- [ ] New users can follow documentation without confusion about old vs new syntax

## Out of Scope

- Updating internal/technical documentation about implementation details
- Modifying the actual CLI implementation
- Creating automated migration scripts
- Updating ADRs (these document historical decisions)

## References

- Code review report: `docs-project/current/v.0.2.0-synapse/code_review/commits-after-1361d77-20250624-205941/cr-report-gpro.md`
- Task 44 implementation: `docs-project/current/v.0.2.0-synapse/tasks/v.0.2.0+task.44-implement-unified-llm-query-entry-point.md`
- [Write Actionable Task Guide](docs-dev/guides/task-definition.g.md)

## Risks & Mitigations

**Risk**: Users following old documentation may experience confusion or errors
**Mitigation**: Create clear migration guide and ensure prominent notices about the change

**Risk**: Some documentation may be missed in the update process
**Mitigation**: Use systematic search approach and maintain checklist of all files reviewed