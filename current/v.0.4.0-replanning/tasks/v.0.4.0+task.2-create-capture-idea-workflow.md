---
id: v.0.4.0+task.2
status: draft
priority: high
estimate: 4h
dependencies: []
---

# Create capture-idea Workflow Instruction

## Objective

Design and implement the `capture-idea.wf.md` workflow instruction that guides AI agents and developers through capturing raw ideas in the project context. This workflow is the entry point for the specification cycle, focusing on contextual enhancement and question generation.

## What: Behavioral Specification

### User Experience
- **Trigger**: User provides raw idea text or reference to idea sources
- **Process**: AI agent captures, enhances, and stores the idea
- **Output**: Enhanced idea file with questions that bridge to behavioral specification

### Expected Behavior
1. Accept various forms of input (text, file references, mixed)
2. Load project context to understand the idea's relevance
3. Enhance the idea with project-specific context
4. Generate critical questions for future specification phases
5. Store in appropriate ideas/ directory with proper naming

### Workflow Contract
- **Input**: Raw ideas in any format
- **Context**: Project architecture, existing features, current roadmap
- **Enhancement**: Add project relevance, potential impact, implementation considerations
- **Questions**: Generate 3-5 key questions that must be answered for specification
- **Output**: Structured idea file ready for future draft-task phase

## How: Implementation Plan

### Planning Steps
* [ ] Analyze existing workflow patterns for consistency
* [ ] Design idea template structure
* [ ] Define question generation categories
* [ ] Plan integration with ideas-manager tool

### Execution Steps
- [ ] Create capture-idea.wf.md in dev-handbook/workflow-instructions/
- [ ] Define prerequisites and context loading requirements
- [ ] Document step-by-step process for idea capture
- [ ] Include idea enhancement guidelines
- [ ] Add question generation templates by category
- [ ] Create examples for different input types
- [ ] Define success criteria and output format
- [ ] Add error handling for common scenarios

## Scope of Work

### Deliverables

#### Create
- dev-handbook/workflow-instructions/capture-idea.wf.md
- dev-handbook/templates/ideas/idea.template.md

#### Modify
- dev-handbook/workflow-instructions/README.md (add new workflow)

## Acceptance Criteria

- [ ] Workflow handles all input types (text, files, mixed)
- [ ] Clear process for contextual enhancement
- [ ] Question generation guidelines produce actionable questions
- [ ] Integration with ideas-manager tool documented
- [ ] Examples cover common use cases
- [ ] Error scenarios addressed

## Out of Scope

- ❌ Automatic task creation
- ❌ Idea validation or approval
- ❌ Complex project analysis
- ❌ Integration with external systems

## References

- Planning agent research: dev-taskflow/current/v.0.3.0-workflows/backlog/research/how-to-build-planning-agents-without-loosing-control.md
- Existing create-task workflow: dev-handbook/workflow-instructions/create-task.wf.md