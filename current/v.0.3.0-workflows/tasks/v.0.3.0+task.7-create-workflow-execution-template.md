---
id: v.0.3.0+task.7
status: pending
priority: high
estimate: 4h
dependencies: [v.0.3.0+task.1]
---

# Create Standardized Workflow Execution Template

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-handbook/workflow-instructions/work-on-task.wf.md
```

_Result excerpt:_

```
-rw-r--r--@ 1 user staff 4532 Jun 26 21:15 dev-handbook/workflow-instructions/work-on-task.wf.md
```

## Objective

Create a standardized template for high-level execution plans that will be embedded into all 21 workflow files, based on the pattern demonstrated in work-on-task.wf.md and the specific 7-step pattern provided in the requirements.

## Scope of Work

- Analyze work-on-task.wf.md execution pattern for template design
- Create standardized high-level execution plan template
- Design project context loading template section
- Create template for removing cross-workflow references
- Document template usage guidelines

### Deliverables

#### Create

- dev-handbook/guides/workflow-execution-template.md
- dev-handbook/guides/workflow-context-loading-template.md

#### Modify

- None (template creation phase)

#### Delete

- None

## Phases

1. Analyze work-on-task.wf.md pattern
2. Extract standardized execution plan structure
3. Create project context loading template
4. Document template application guidelines

## Implementation Plan

### Planning Steps

- [ ] Analyze work-on-task.wf.md structure and execution pattern
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Execution pattern elements identified and documented
  > Command: bin/test --check-pattern-analysis workflow-pattern-analysis.md
- [ ] Review the 7-step execution pattern from requirements
- [ ] Design standardized template structure

### Execution Steps

- [ ] Create high-level execution plan template based on 7-step pattern
  > TEST: Execution Template Created
  > Type: Action Validation
  > Assert: Template includes all 7 required steps
  > Command: bin/test --check-template-completeness workflow-execution-template.md
- [ ] Create project context loading template with required sections
- [ ] Document template application guidelines for all workflow types
- [ ] Create examples of template usage for different workflow categories
- [ ] Validate template covers all workflow execution scenarios

## Acceptance Criteria

- [ ] Standardized execution template created with 7-step pattern
- [ ] Project context loading template includes all required sections
- [ ] Template application guidelines documented
- [ ] Examples provided for different workflow types

## Out of Scope

- ❌ Applying templates to actual workflows (separate task)
- ❌ Creating agent-specific variations
- ❌ Modifying existing workflow files

## References

- dev-handbook/workflow-instructions/work-on-task.wf.md (pattern source)
- User requirements with 7-step execution pattern
- docs/what-do-we-build.md, docs/architecture.md, docs/blueprint.md (context files)
