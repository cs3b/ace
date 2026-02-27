# Task Management Templates

This directory contains templates for creating and managing tasks in the development workflow. The templates follow a behavior-first approach that separates **what** needs to be accomplished from **how** it will be implemented.

## Template Overview

### Two-Phase Template System

The task management system uses a two-template approach that mirrors the specification cycle architecture:

1. **Draft Template** (`task.draft.template.md`) - **WHAT** (Behavioral Specification)
2. **Pending Template** (`task.pending.template.md`) - **HOW** (Implementation Planning)

## Template Usage Guide

### Phase 1: Draft Template (Behavioral Specification)

**When to use**: Start with this template for any new task or feature request.

**Purpose**: Define **what** needs to be accomplished from a behavioral perspective:
- User experience requirements
- System behavior specifications
- Interface contracts and interactions
- Success criteria and validation questions

**Key Sections**:
- **User Experience**: Input/Process/Output flow
- **Expected Behavior**: Observable system behavior (not implementation)
- **Interface Contract**: APIs, CLIs, UI interactions with error handling
- **Success Criteria**: Measurable behavioral outcomes
- **Validation Questions**: Requirements clarification

**Status**: `draft` - indicates behavioral requirements are being defined

### Phase 2: Pending Template (Implementation Planning)

**When to use**: After behavioral specification is complete and approved.

**Purpose**: Define **how** the behavioral requirements will be implemented:
- Technical approach and architecture decisions
- Implementation planning and execution steps
- Risk assessment and mitigation strategies
- Tool selection and dependency management

**Key Sections**:
- **Behavioral Context**: Reference to completed behavioral specification
- **Planning Steps**: Research, analysis, design (use `* [ ]` markers)
- **Execution Steps**: Implementation actions (use `- [ ]` markers)
- **Technical Details**: Architecture, tools, file modifications
- **Risk Assessment**: Technical, integration, and performance risks

**Status**: `pending` - indicates task is ready for implementation

## Workflow Process

### Draft → Pending Transition

1. **Complete Behavioral Specification**: Fill out draft template completely
2. **Validate Requirements**: Ensure all validation questions are resolved
3. **Review and Approve**: Get stakeholder approval on behavioral requirements
4. **Create Implementation Task**: Use pending template referencing the behavioral spec
5. **Update Status**: Change task status from `draft` to `pending`

### Key Principles

#### Behavior-First Approach
- Always start with **what** before **how**
- Focus on user experience and observable outcomes
- Defer technical decisions until behavioral requirements are clear
- Maintain clear separation between specification and implementation
- Prefer **better, not more**: improve clarity and defaults rather than adding specialized template sections

#### Template Markers
- **Draft Template**: Pure behavioral focus, no implementation details
- **Pending Template**: Implementation focus, assumes behavior is defined
- **Planning Steps** (`* [ ]`): Research and analysis activities
- **Execution Steps** (`- [ ]`): Concrete implementation actions

#### Embedded Testing
Both templates support embedded test specifications:
```
- [ ] Step description
  > TEST: Test Name
  > Type: Test Category
  > Assert: Expected outcome
  > Command: bin/test --verify-something
```

## Examples

### Good Draft Task (Behavioral Focus)
```markdown
### Expected Behavior
When a user runs `task-manager list --filter status:draft`, the system should:
- Display all tasks with draft status
- Show task ID, title, and creation time
- Return appropriate message if no draft tasks exist
```

### CLI Task (Exit Codes & Validation)
```markdown
### Interface Contract
**Exit Codes:**
| Code | Meaning |
|------|---------|
| 0 | Success - tasks listed |
| 1 | General error |
| 2 | Invalid filter syntax |

**Input Validation:**
- Filter format: Must be `key:value` pairs
- Missing filter: Returns all tasks (no error)

**Cleanup Behavior:**
- Success: No temp files
- Failure: Partial output cleared
- Interruption: Graceful exit with code 130
```

### Good Pending Task (Implementation Focus)
```markdown
### Execution Steps
- [ ] **Filter Implementation**: Add status filtering logic to TaskManager#list method
  > TEST: Filter Functionality
  > Type: Unit Test
  > Assert: Only draft status tasks are returned
  > Command: bin/test --verify-filter-logic
```

## Common Patterns

### API/CLI Features
- **Draft**: Focus on command syntax, output format, error messages
- **Pending**: Focus on argument parsing, validation logic, output formatting

**CLI-Specific Requirements** (must include in draft):
- Exit code contract (what each code means)
- Input validation rules (required fields, format validation)
- Concurrency considerations (if file-based state)
- Cleanup behavior (temp files, partial state)
- SIGINT handling (interruption behavior)

### UI Features
- **Draft**: Focus on user interactions, visual feedback, navigation flows
- **Pending**: Focus on component structure, state management, styling

### Backend Features
- **Draft**: Focus on data transformations, business rules, external interfaces
- **Pending**: Focus on data models, service layer, integration patterns

### Data-Driven Features
- **Draft**: Focus on input format, validation rules, error messages
- **Pending**: Focus on parsing, schema validation, error handling

**Data-Driven Requirements** (must include in draft):
- Schema/format specification
- Required vs optional fields
- Validation error messages
- Fallback/default behavior

## Quality Checklist

### Draft Template Quality
- [ ] Expected Behavior written from user perspective
- [ ] Interface Contract specifies inputs/outputs clearly
- [ ] Success Criteria are measurable and behavioral
- [ ] At least one failure or invalid-input path is specified
- [ ] Defaults are explicit where behavior could be ambiguous
- [ ] Spec is decision-complete for implementers
- [ ] No implementation details present
- [ ] All validation questions addressed

### Pending Template Quality
- [ ] References completed behavioral specification
- [ ] Clear Planning vs Execution step distinction
- [ ] Embedded tests throughout execution steps
- [ ] Risk assessment covers technical concerns
- [ ] Acceptance criteria map to behavioral requirements

## Tools Integration

### Creating Tasks
```bash
# Create draft task (behavioral specification)
task-manager create --title "Feature Name" --status "draft"

# Create pending task (implementation planning)
task-manager create --title "Feature Name" --status "pending"
```

### Task Management
```bash
# List draft tasks (behavioral specification phase)
task-manager list --filter status:draft

# List pending tasks (ready for implementation)
task-manager list --filter status:pending
```

This template system ensures that behavioral requirements are clearly defined before technical implementation begins, leading to better outcomes and clearer communication throughout the development process.
