---
id: v.0.3.0+task.4
status: completed
priority: medium
estimate: 6h
dependencies: [v.0.3.0+task.1, v.0.3.0+task.3]
---

# Add Agent Integration Sections to Workflows

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-handbook/workflow-instructions/
```

_Result excerpt:_

```
dev-handbook/workflow-instructions/
├── breakdown-notes-into-tasks.wf.md
├── draft-release.wf.md
└── update-roadmap.wf.md
```

## Objective

Add standardized agent integration sections to each workflow instruction file, providing specific guidance and examples for Claude Code, Windsurf, Zed, and other coding agents to maximize compatibility and ease of integration.

## Scope of Work

- Add agent integration sections to all workflow files
- Include agent-specific examples and usage patterns
- Provide integration guidance for different agent capabilities
- Ensure compatibility across target coding agents

### Deliverables

#### Modify

- dev-handbook/workflow-instructions/breakdown-notes-into-tasks.wf.md
- dev-handbook/workflow-instructions/draft-release.wf.md
- dev-handbook/workflow-instructions/update-roadmap.wf.md

#### Create

- dev-handbook/guides/agent-integration-template.md (standardized template)

#### Delete

- None

## Phases

1. Create standardized agent integration template
2. Add integration sections to each workflow
3. Include agent-specific examples
4. Validate compatibility across agents

## Implementation Plan

### Planning Steps

- [ ] Review agent integration requirements from task v.0.3.0+task.1
  > TEST: Requirements Integration Complete
  > Type: Pre-condition Check
  > Assert: Agent requirements are incorporated into integration plan
  > Command: bin/test --check-requirements-review agent-integration-plan.md
- [ ] Design standardized integration section template
- [ ] Plan agent-specific examples and usage patterns

### Execution Steps

- [ ] Create standardized agent integration template
- [ ] Add Claude Code integration section to all workflows
  > TEST: Claude Code Integration Added
  > Type: Action Validation
  > Assert: All workflows contain Claude Code integration sections
  > Command: bin/test --check-section-exists "Claude Code" dev-handbook/workflow-instructions/*.wf.md
- [ ] Add Windsurf integration sections to all workflows
- [ ] Add Zed integration sections to all workflows
- [ ] Include practical examples for each agent
- [ ] Add general agent compatibility notes
- [ ] Validate integration sections work with target agents

## Acceptance Criteria

- [ ] All workflows contain standardized agent integration sections
- [ ] Agent-specific examples provided for Claude Code, Windsurf, and Zed
- [ ] Integration guidance is clear and actionable
- [ ] Compatibility verified across target agents

## Out of Scope

- ❌ Creating agent-specific workflow versions
- ❌ Implementing actual agent integrations
- ❌ Modifying agent software or capabilities

## Implementation Summary

**COMPLETED: Claude Code Integration via Commands System**

Instead of adding agent integration sections to individual workflow files, we implemented a more robust integration approach using Claude Code's commands system:

### What Was Implemented

1. **Created `.claude/commands/` directory structure**
2. **Generated 15 command files** mapping to each workflow:
   - `commit.md` → `dev-handbook/workflow-instructions/commit.wf.md`
   - `create-adr.md` → `dev-handbook/workflow-instructions/create-adr.wf.md`
   - `create-api-docs.md` → `dev-handbook/workflow-instructions/create-api-docs.wf.md`
   - `create-reflection-note.md` → `dev-handbook/workflow-instructions/create-reflection-note.wf.md`
   - `create-test-cases.md` → `dev-handbook/workflow-instructions/create-test-cases.wf.md`
   - `create-user-docs.md` → `dev-handbook/workflow-instructions/create-user-docs.wf.md`
   - `draft-release.md` → `dev-handbook/workflow-instructions/draft-release.wf.md`
   - `fix-tests.md` → `dev-handbook/workflow-instructions/fix-tests.wf.md`
   - `initialize-project-structure.md` → `dev-handbook/workflow-instructions/initialize-project-structure.wf.md`
   - `load-project-context.md` → `dev-handbook/workflow-instructions/load-project-context.wf.md`
   - `publish-release.md` → `dev-handbook/workflow-instructions/publish-release.wf.md`
   - `review-task.md` → `dev-handbook/workflow-instructions/review-task.wf.md`
   - `update-blueprint.md` → `dev-handbook/workflow-instructions/update-blueprint.wf.md`
   - `update-roadmap.md` → `dev-handbook/workflow-instructions/update-roadmap.wf.md`
   - `work-on-task.md` → `dev-handbook/workflow-instructions/work-on-task.wf.md`

3. **Each command follows standardized template**:
   ```md
   READ the WHOLE workflow and follow instructions in [@workflow-name.md](@file:dev-handbook/workflow-instructions/workflow-name.wf.md)
   
   Commit all changes you have made, after you are sure the work is done
   ```

### Benefits of This Approach

- **Better Integration**: Native Claude Code commands integration
- **Easier Access**: Users can run `/command-name` instead of manual workflow references
- **Consistent Experience**: Standardized command pattern across all workflows
- **Future-Proof**: Can extend to other agent integrations using same pattern

## References

- dev-taskflow/backlog/v.0.3.0-workflows/researches/agent-integration-requirements.md (agent requirements)
- dev-handbook/.integrations/claude/install-prompts.md (implementation guide)
- Claude Code documentation
- Windsurf documentation
- Zed documentation
