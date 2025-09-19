---
id: v.0.3.0+task.2
status: pending
priority: high
estimate: 3h
dependencies: []
---

# Research Agent Integration Requirements

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la .ace/handbook/workflow-instructions/
```

_Result excerpt:_

```
.ace/handbook/workflow-instructions/
├── breakdown-notes-into-tasks.wf.md
├── draft-release.wf.md
└── update-roadmap.wf.md
```

## Objective

Research how Claude Code, Windsurf, Zed, and other coding agents consume workflow instructions to understand integration requirements and design patterns for maximum compatibility.

## Scope of Work

- Research Claude Code workflow integration patterns
- Investigate Windsurf workflow consumption methods
- Analyze Zed coding agent capabilities
- Identify common patterns and requirements across agents

### Deliverables

#### Create

- .ace/taskflow/backlog/v.0.3.0-workflows/researches/agent-integration-requirements.md

#### Modify

- None (research phase)

#### Delete

- None

## Phases

1. Research Claude Code integration patterns
2. Investigate Windsurf workflow handling
3. Analyze Zed agent capabilities
4. Document common requirements and patterns

## Implementation Plan

### Planning Steps

- [ ] Identify available documentation for each target coding agent
  > TEST: Documentation Sources Identified
  > Type: Pre-condition Check
  > Assert: Documentation links and sources are catalogued
  > Command: bin/test --check-research-sources agent-integration-requirements.md
- [ ] Plan research methodology for each agent
- [ ] Define evaluation criteria for integration compatibility

### Execution Steps

- [ ] Research Claude Code workflow integration capabilities and requirements
- [ ] Investigate Windsurf workflow consumption patterns and limitations
  > TEST: Windsurf Research Complete
  > Type: Action Validation
  > Assert: Windsurf integration patterns documented
  > Command: bin/test --check-section-exists "Windsurf Integration" agent-integration-requirements.md
- [ ] Analyze Zed coding agent workflow handling capabilities
- [ ] Document common patterns and requirements across all agents
- [ ] Create integration compatibility matrix
- [ ] Provide recommendations for workflow structure modifications

## Acceptance Criteria

- [ ] All target agents researched and documented
- [ ] Common integration patterns identified
- [ ] Compatibility requirements clearly defined
- [ ] Recommendations provided for workflow modifications

## Out of Scope

- ❌ Implementing actual integration features
- ❌ Modifying existing workflows
- ❌ Creating agent-specific workflow versions

## References

- Claude Code documentation
- Windsurf documentation
- Zed documentation
- Current workflow instruction files
