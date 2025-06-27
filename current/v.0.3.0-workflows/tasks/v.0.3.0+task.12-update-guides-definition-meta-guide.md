---
id: v.0.3.0+task.12
status: pending
priority: medium
estimate: 3h
dependencies: [v.0.3.0+task.10]
---

# Update Guides Definition Meta-Guide

## 0. Directory Audit ✅

_Command run:_
```bash
tree -L 2 dev-handbook/guides/.meta | sed 's/^/    /'
```

_Result excerpt:_
```
dev-handbook/guides/.meta/
├── guides-definition.g.md
├── workflow-instructions-definition.g.md
└── [other meta files...]
```

## Objective

Update the `guides/.meta/guides-definition.g.md` file to reflect the fundamental change in the relationship between guides and workflows. Guides must now focus on conceptual knowledge rather than procedural instructions, which are now embedded within self-contained workflows. This redefinition is essential to maintain consistency across the handbook system.

**Original requirement**: Documentation review identified that the role of guides has fundamentally changed and the meta-guide must be updated to reflect the new separation of concerns.

## Scope of Work

- Redefine the core principles of guides vs workflows
- Update guide structure recommendations
- Establish clear content guidelines for conceptual vs procedural content
- Align with the new self-containment philosophy

### Deliverables

#### Create
- None

#### Modify
- dev-handbook/guides/.meta/guides-definition.g.md

#### Delete
- None

## Phases

1. Research/Analysis - Review current guide definition and identify necessary changes
2. Design/Planning - Plan new content structure and principles
3. Implementation - Update guide definition with new principles
4. Testing/Validation - Ensure updated definition aligns with new workflow model

## Implementation Plan

### Planning Steps

* [ ] Review current guides-definition.g.md content and structure
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: Current guide definition is understood and documented
  > Command: `grep -E "^## |^### " dev-handbook/guides/.meta/guides-definition.g.md`

* [ ] Identify sections that need updates based on new workflow model
  > TEST: Pre-condition Check
  > Type: Pre-condition Check
  > Assert: All sections requiring updates are identified
  > Command: `grep -i "procedure\|workflow\|instruction" dev-handbook/guides/.meta/guides-definition.g.md`

### Execution Steps

- [ ] Update "Core Principles" section to include new principle: "Guides explain the 'Why', Workflows explain the 'How'"
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: New principle is clearly stated in Core Principles
  > Command: `grep -A 5 -B 5 "Why.*How" dev-handbook/guides/.meta/guides-definition.g.md`

- [ ] Add explicit content guidelines distinguishing guides from workflows:
  - Guides should focus on principles, concepts, best practices, and deep-dive knowledge
  - Guides should avoid step-by-step procedural instructions
  - Procedural instructions belong in self-contained workflow files
  - Guides should link to workflows that perform actions rather than explaining how to do them
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Clear content guidelines are established
  > Command: `grep -i "procedural\|step-by-step\|workflow.*action" dev-handbook/guides/.meta/guides-definition.g.md`

- [ ] Update "Guide Structure" section to reflect new relationship with workflows
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Guide structure reflects conceptual vs procedural separation
  > Command: `grep -A 10 "Guide Structure" dev-handbook/guides/.meta/guides-definition.g.md`

- [ ] Add examples of appropriate vs inappropriate guide content
  > TEST: Action Validation
  > Type: Action Validation
  > Assert: Examples clearly illustrate the new guide philosophy
  > Command: `grep -C 3 "example\|appropriate\|inappropriate" dev-handbook/guides/.meta/guides-definition.g.md`

## Acceptance Criteria

- [ ] New principle "Guides explain the 'Why', Workflows explain the 'How'" is clearly stated
- [ ] Content guidelines explicitly prohibit procedural instructions in guides
- [ ] Guide structure section reflects new conceptual focus
- [ ] Examples demonstrate appropriate vs inappropriate guide content
- [ ] Updated definition aligns with workflow self-containment principle
- [ ] Document maintains consistency with existing handbook style
- [ ] Changes are backward compatible with existing conceptual guides

## Out of Scope

- ❌ Updating individual guides to comply with new definition (separate task)
- ❌ Creating new conceptual guides (separate task)
- ❌ Fixing cross-references throughout handbook (separate task)
- ❌ Updating workflow-instructions-definition.g.md (already updated in diff)

## References

- Original requirement: Documentation review report "HIGH PRIORITY UPDATES"
- Related ADR: Task v.0.3.0+task.10 (dependency)
- New workflow model: dev-handbook/guides/.meta/workflow-instructions-definition.g.md
- Context: Fundamental shift from reference-based to self-contained workflows