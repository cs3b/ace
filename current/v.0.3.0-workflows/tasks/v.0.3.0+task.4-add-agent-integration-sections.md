---
id: v.0.3.0+task.4
status: pending
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

* [ ] Review agent integration requirements from task v.0.3.0+task.1
  > TEST: Requirements Integration Complete
  > Type: Pre-condition Check
  > Assert: Agent requirements are incorporated into integration plan
  > Command: bin/test --check-requirements-review agent-integration-plan.md
* [ ] Design standardized integration section template
* [ ] Plan agent-specific examples and usage patterns

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

## References

- dev-taskflow/backlog/v.0.3.0-workflows/researches/agent-integration-requirements.md (agent requirements)
- Claude Code documentation
- Windsurf documentation
- Zed documentation