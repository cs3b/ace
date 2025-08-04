---
id: v.0.4.0+task.010
status: done
priority: high
estimate: 4h
dependencies: []
---

# Reorganize Task Templates for Draft-Plan Workflow Separation

## Behavioral Specification

### User Experience
- **Input**: Developers run `create-path task-new --status draft` or `create-path task-new --status pending`
- **Process**: System selects appropriate template based on task status and workflow purpose
- **Output**: Draft tasks get behavioral specification templates, pending tasks get implementation planning templates

### Expected Behavior
- Template system clearly separates WHAT (behavioral specification) from HOW (implementation planning)
- create-path tool uses task.draft.template.md for draft status tasks
- create-path tool uses task.pending.template.md for pending status tasks
- Workflow instructions embed correct templates for their respective purposes
- All templates organized under task-management/ directory with consistent task. prefixes

### Interface Contract
```bash
# CLI Interface
create-path task-new --title "Task Title" --status draft   # Uses behavioral spec template
create-path task-new --title "Task Title" --status pending # Uses implementation template

# Template Structure
dev-handbook/templates/task-management/task.draft.template.md           # Behavioral spec
dev-handbook/templates/task-management/task.pending.template.md         # Implementation
dev-handbook/templates/task-management/task.technical-approach.template.md
dev-handbook/templates/task-management/task.tool-selection-matrix.template.md
dev-handbook/templates/task-management/task.file-modification-checklist.template.md
dev-handbook/templates/task-management/task.risk-assessment.template.md
```

### Success Criteria

- [ ] create-path task-new --status draft uses behavioral specification template
- [ ] create-path task-new --status pending uses implementation planning template
- [ ] draft-task.wf.md embeds task.draft.template.md
- [ ] plan-task.wf.md embeds task.pending.template.md and sub-templates
- [ ] All templates organized under task-management/ with task. prefixes
- [ ] Old release-tasks/task.template.md removed and references updated
- [ ] .coding-agent/create-path.yml configuration updated

### Validation Questions

- [ ] Should create-path support both draft and pending statuses or default based on context?
- [ ] Are the task. prefixed template names clear and consistent?
- [ ] Do we need migration for existing tasks using old template structure?

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/templates | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-handbook/templates
    ├── binstubs
    ├── code-docs
    ├── commit
    ├── idea-manager
    ├── project-docs
    ├── release-codemods
    ├── release-docs
    ├── release-management
    ├── release-planning
    ├── release-reflections
    ├── release-research
    ├── release-tasks          # Contains current task.template.md
    ├── release-testing
    ├── release-ux
    ├── release-v.0.0.0
    ├── review-tasks
    ├── session-management
    └── user-docs
```

## Objective

Reorganize task templates to support the new draft-task → plan-task workflow separation, ensuring behavioral specifications (WHAT) are clearly separated from implementation planning (HOW).

## Scope of Work

- Create task-management/ template directory with draft and pending templates
- Split behavioral specification concerns from implementation planning concerns
- Update workflow embedded templates to use correct paths
- Update create-path configuration for proper template selection

### Deliverables

#### Interface Contracts
- Template selection based on task status (draft vs pending)
- Consistent task. prefixed naming convention
- Clear separation of behavioral vs implementation templates

#### Behavioral Documentation
- Behavioral specification template for draft tasks
- Implementation planning template for pending tasks
- Sub-templates for technical concerns

## Out of Scope

- ❌ Migrating existing task files to new template structure
- ❌ Changing workflow instruction logic beyond template paths
- ❌ Modifying task status lifecycle management
- ❌ Adding new task statuses beyond draft/pending

## Technical Approach

### Architecture Pattern
- **Pattern**: Template directory reorganization with embedded XML template path updates
- **Rationale**: Maintains existing template embedding system while organizing by purpose
- **Integration**: Works with current create-path YAML configuration and workflow embedding

### Technology Stack
- **Template System**: Existing XML embedded template system
- **Configuration**: YAML-based create-path configuration
- **File Operations**: Standard file system operations for template creation
- **Dependencies**: No new dependencies required

### Implementation Strategy
- Create new template directory structure first
- Split existing template content by behavioral vs implementation concerns
- Update configuration and embedded paths
- Remove old templates after verification

## Tool Selection

| Criteria | File Operations | Template Embedding | Config Updates | Selected |
|----------|----------------|-------------------|----------------|-----------|
| Performance | Fast | Instant | Fast | All standard |
| Integration | Native | Existing system | YAML standard | Perfect |
| Maintenance | Simple | Established | Well-documented | Excellent |
| Security | Safe | Validated | Low risk | Secure |
| Learning Curve | None | Known pattern | Familiar | Minimal |

**Selection Rationale:** All operations use existing, well-established patterns in the project.

## File Modifications

### Create
- dev-handbook/templates/task-management/ (directory)
- dev-handbook/templates/task-management/task.draft.template.md
  - Purpose: Behavioral specification template for draft tasks
  - Key components: User Experience, Interface Contract, Success Criteria, Validation Questions
  - Dependencies: None
- dev-handbook/templates/task-management/task.pending.template.md
  - Purpose: Implementation planning template for pending tasks  
  - Key components: Technical Approach, File Modifications, Implementation Plan, Risk Assessment
  - Dependencies: References to sub-templates
- dev-handbook/templates/task-management/task.technical-approach.template.md
  - Purpose: Technical approach planning sub-template
  - Key components: Architecture Pattern, Technology Stack, Implementation Strategy
  - Dependencies: None
- dev-handbook/templates/task-management/task.tool-selection-matrix.template.md
  - Purpose: Tool selection criteria and comparison matrix
  - Key components: Evaluation criteria table, selection rationale
  - Dependencies: None
- dev-handbook/templates/task-management/task.file-modification-checklist.template.md
  - Purpose: File operation planning template
  - Key components: Create/Modify/Delete sections with purpose and impact
  - Dependencies: None
- dev-handbook/templates/task-management/task.risk-assessment.template.md
  - Purpose: Risk analysis and mitigation planning
  - Key components: Technical risks, integration risks, performance risks
  - Dependencies: None

### Modify
- .coding-agent/create-path.yml
  - Changes: Update task-new template path from release-tasks to task-management
  - Impact: create-path task-new will use new template structure
  - Integration points: Template variable substitution system
- dev-handbook/workflow-instructions/draft-task.wf.md
  - Changes: Update embedded template path to task.draft.template.md
  - Impact: Workflow will embed correct behavioral specification template
  - Integration points: XML template embedding system
- dev-handbook/workflow-instructions/plan-task.wf.md
  - Changes: Update embedded template paths to task.pending.template.md and sub-templates
  - Impact: Workflow will embed correct implementation planning templates
  - Integration points: XML template embedding system with multiple templates

### Delete
- dev-handbook/templates/release-tasks/task.template.md
  - Reason: Replaced by split templates for behavioral vs implementation concerns
  - Dependencies: Verify no other references exist before deletion

## Implementation Plan

### Planning Steps

* [ ] Analyze current template content to identify behavioral vs implementation sections
  > TEST: Content Analysis Complete
  > Type: Pre-condition Check
  > Assert: Template sections clearly categorized as behavioral or implementation
  > Command: grep -E "(User Experience|Interface|Success|Technical|Implementation|Risk)" dev-handbook/templates/release-tasks/task.template.md

* [ ] Research embedded template paths in workflow instructions
  > TEST: Template References Found
  > Type: Pre-condition Check  
  > Assert: All template path references identified
  > Command: grep -r "template.*path.*task.template" dev-handbook/workflow-instructions/

* [ ] Plan template content split based on draft-task vs plan-task workflow purposes
* [ ] Design consistent task. prefixed naming convention for sub-templates

### Execution Steps

- [ ] Create task-management directory structure
  > TEST: Directory Created
  > Type: Action Validation
  > Assert: task-management directory exists and is empty
  > Command: test -d dev-handbook/templates/task-management && ls -la dev-handbook/templates/task-management

- [ ] Create task.draft.template.md with behavioral specification content
  > TEST: Draft Template Created
  > Type: Action Validation
  > Assert: Draft template contains behavioral specification sections
  > Command: grep -E "(User Experience|Interface Contract|Success Criteria)" dev-handbook/templates/task-management/task.draft.template.md

- [ ] Create task.pending.template.md with implementation planning content
  > TEST: Pending Template Created
  > Type: Action Validation
  > Assert: Pending template contains implementation planning sections
  > Command: grep -E "(Technical Approach|File Modifications|Implementation Plan)" dev-handbook/templates/task-management/task.pending.template.md

- [ ] Create sub-templates with task. prefixes for implementation planning components
  > TEST: Sub-templates Created
  > Type: Action Validation
  > Assert: All sub-templates exist with correct prefixes
  > Command: ls dev-handbook/templates/task-management/task.*.template.md | wc -l | grep -q "6"

- [ ] Update .coding-agent/create-path.yml to use task.draft.template.md for task-new
  > TEST: Configuration Updated
  > Type: Action Validation
  > Assert: create-path configuration points to new template
  > Command: grep -q "task-management/task.draft.template.md" .coding-agent/create-path.yml

- [ ] Update draft-task.wf.md embedded template path
  > TEST: Draft Workflow Updated
  > Type: Action Validation
  > Assert: draft-task workflow embeds correct template
  > Command: grep -q "task-management/task.draft.template.md" dev-handbook/workflow-instructions/draft-task.wf.md

- [ ] Update plan-task.wf.md embedded template paths for all sub-templates
  > TEST: Plan Workflow Updated
  > Type: Action Validation
  > Assert: plan-task workflow embeds all correct templates
  > Command: grep -c "task-management/task\." dev-handbook/workflow-instructions/plan-task.wf.md | grep -q "5"

- [ ] Verify no other references to old template path exist
  > TEST: Old References Removed
  > Type: Action Validation
  > Assert: No references to old template path remain
  > Command: ! grep -r "release-tasks/task.template.md" dev-handbook/ dev-taskflow/ docs/ .coding-agent/

- [ ] Remove old dev-handbook/templates/release-tasks/task.template.md
  > TEST: Old Template Removed
  > Type: Action Validation
  > Assert: Old template file no longer exists
  > Command: ! test -f dev-handbook/templates/release-tasks/task.template.md

- [ ] Test create-path task-new with both draft and pending statuses
  > TEST: Template Selection Works
  > Type: Integration Test
  > Assert: Different templates used based on status
  > Command: create-path task-new --title "Test" --status draft && create-path task-new --title "Test2" --status pending

## Risk Assessment

### Technical Risks
- **Risk**: Breaking embedded template references in workflows
  - **Probability**: Medium
  - **Impact**: High
  - **Mitigation**: Test all embedded template paths after updates
  - **Rollback**: Revert template paths to original references

### Integration Risks
- **Risk**: create-path configuration syntax errors
  - **Probability**: Low
  - **Impact**: Medium
  - **Mitigation**: Validate YAML syntax after changes
  - **Rollback**: Restore original configuration file

### Performance Risks
- **Risk**: Multiple sub-template embedding causing slowdown
  - **Probability**: Low
  - **Impact**: Low
  - **Mitigation**: Monitor workflow execution times
  - **Rollback**: Consolidate templates if performance degrades

## References

- Current template structure analysis from directory audit
- draft-task.wf.md and plan-task.wf.md workflow requirements
- .coding-agent/create-path.yml configuration patterns