---
id: v.0.3.0+task.10
status: pending
priority: high
estimate: 4h
dependencies: []
---

# Create ADR for Workflow Self-Containment Principle

## 0. Directory Audit ✅

_Command run:_
```bash
tree -L 2 dev-taskflow/current/v.0.3.0-workflows | sed 's/^/    /'
```

_Result excerpt:_
```
dev-taskflow/current/v.0.3.0-workflows/
├── decisions/
├── tasks/
└── [other directories...]
```

## Objective

Create an Architecture Decision Record (ADR) to formally document the pivotal decision to shift from reference-based workflows to self-contained, independent workflows. This ADR will provide architectural justification for the breaking change and establish the foundation for all future workflow development in the handbook system.

**Original requirement**: Documentation review identified need for formal ADR to document the fundamental architectural shift in workflow design.

## Scope of Work

- Document the decision context and problem statement
- Capture the rationale for self-containment over reference-based approaches
- Record alternatives considered and why they were rejected
- Define implications and consequences of the decision
- Establish this as foundational principle for future development

### Deliverables

#### Create
- dev-taskflow/current/v.0.3.0-workflows/decisions/ADR-XXX-workflow-self-containment-principle.md

#### Modify
- None

#### Delete
- None

## Phases

1. Research/Analysis - Understand the full context and rationale for the change
2. Design/Planning - Structure ADR content following standard template
3. Implementation - Write comprehensive ADR documenting the decision
4. Testing/Validation - Review ADR for completeness and accuracy

## Implementation Plan

### Planning Steps

* [ ] Review ADR template and format requirements from handbook
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: ADR template is available and understood
  > Command: `find dev-handbook -name "*adr*" -o -name "*decision*" | head -5`

* [ ] Analyze the complete workflow transformation to understand full scope
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: All aspects of the workflow change are documented
  > Command: `grep -r "self-contained\|reference-based" dev-handbook/workflow-instructions/ | wc -l`

### Execution Steps

- [ ] Determine appropriate ADR number by checking existing decisions
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: ADR number is sequential and doesn't conflict
  > Command: `ls dev-taskflow/current/v.0.3.0-workflows/decisions/ADR-*.md | sort`

- [ ] Create comprehensive ADR with following sections:
  - Title: Workflow Self-Containment Principle
  - Status: Accepted
  - Context: Problems with reference-based workflows (brittleness, context limits, dependencies)
  - Decision: All workflows must be self-contained with embedded content
  - Rationale: AI agent autonomy, reliability, portability
  - Alternatives Considered: Status quo, hybrid model
  - Consequences: One-time refactoring cost, changed guide role, simplified execution
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: ADR contains all required sections with detailed content
  > Command: `grep -E "^## " dev-taskflow/current/v.0.3.0-workflows/decisions/ADR-*-workflow-self-containment-principle.md`

- [ ] Include specific examples of old vs new workflow patterns
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: ADR contains concrete examples and implications
  > Command: `grep -c "example\|before\|after" dev-taskflow/current/v.0.3.0-workflows/decisions/ADR-*-workflow-self-containment-principle.md`

## Acceptance Criteria

- [ ] ADR file created with sequential number in decisions directory
- [ ] ADR follows standard format with all required sections
- [ ] Context clearly explains problems with reference-based approach
- [ ] Decision statement is unambiguous about self-containment requirement
- [ ] Rationale explains benefits for AI agents and system reliability
- [ ] Alternatives considered section documents rejected approaches
- [ ] Consequences section addresses both positive and negative implications
- [ ] ADR establishes principle for future workflow development

## Out of Scope

- ❌ Implementing the workflow changes (already done in diff)
- ❌ Creating migration guide (separate task)
- ❌ Updating existing workflows to comply (separate tasks)
- ❌ Communicating the change to users (covered in migration guide)

## References

- Original requirement: Documentation review report "Workflow Decision Records Required"
- Related changes: Complete workflow instruction refactoring in current diff
- Template reference: ADR format from create-adr.wf.md workflow
- Context: guides/.meta/workflow-instructions-definition.g.md