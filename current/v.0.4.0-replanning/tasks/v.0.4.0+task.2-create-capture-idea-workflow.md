---
id: v.0.4.0+task.2
status: draft
priority: medium
estimate: 2h
dependencies: [v.0.4.0+task.1]
---

# Create capture-idea Workflow Instruction

## Objective

Create a workflow instruction that guides AI agents and developers through using the `ideas-manager` tool to capture and enhance raw ideas. This workflow orchestrates the existing tool and focuses on when and how to use it effectively within the specification cycle.

## What: Behavioral Specification

### User Experience
- **Trigger**: User wants to capture a raw idea for future development
- **Process**: AI agent uses `ideas-manager capture` with appropriate options
- **Output**: Enhanced idea file ready for future specification phases

### Expected Behavior
1. Determine appropriate release target for the idea
2. Choose input method (text, clipboard, file)
3. Execute `ideas-manager capture` with proper options
4. Verify successful idea creation and enhancement
5. Provide path to created idea file

### Workflow Contract
- **Prerequisites**: `ideas-manager` tool available (from task 1)
- **Input**: Raw idea text or reference to idea sources
- **Process**: Tool orchestration with context awareness
- **Output**: Path to enhanced idea file

## How: Implementation Plan

### Planning Steps
* [ ] Review `ideas-manager` tool interface and options
* [ ] Analyze existing workflow instruction patterns
* [ ] Define decision tree for release targeting
* [ ] Plan integration with project context loading

### Execution Steps
- [ ] Create capture-idea.wf.md in dev-handbook/workflow-instructions/
- [ ] Document `ideas-manager` command usage patterns
- [ ] Add decision guidance for release targeting
- [ ] Include error handling and troubleshooting
- [ ] Create examples showing tool usage
- [ ] Define success criteria
- [ ] Update workflow-instructions README.md

## Scope of Work

### Deliverables

#### Create
- dev-handbook/workflow-instructions/capture-idea.wf.md

#### Modify
- dev-handbook/workflow-instructions/README.md (add new workflow reference)

## Acceptance Criteria

- [ ] Workflow clearly documents `ideas-manager` usage
- [ ] Decision guidance for release targeting included
- [ ] Examples cover common usage patterns
- [ ] Error handling documented
- [ ] Integration with project context explained

## Example

### Scenario: Capturing Ideas Using ideas-manager Tool

**User Input**: "I want better error handling in the task manager"

**Workflow Execution:**
```bash
# Step 1: AI determines release target (current backlog)
# Step 2: AI uses ideas-manager tool to capture and enhance the idea
ideas-manager capture "I want better error handling in the task manager" --release backlog

# Output: Created: dev-taskflow/backlog/ideas/20250730-1430-better-error-handling-task-manager.md
```

**Result**: The `ideas-manager` tool automatically:
- Loads project context from docs/*.md files
- Enhances the raw idea with project-specific details
- Generates contextual questions for future specification
- Creates a properly formatted and timestamped idea file

**Follow-up**: AI provides the path to the created idea file for future reference and development planning.

## Out of Scope

- ❌ Automatic task creation
- ❌ Idea validation or approval
- ❌ Complex project analysis
- ❌ Integration with external systems

## References

- Planning agent research: dev-taskflow/current/v.0.3.0-workflows/backlog/research/how-to-build-planning-agents-without-loosing-control.md
- Existing create-task workflow: dev-handbook/workflow-instructions/create-task.wf.md