---
id: v.0.4.0+task.1
status: draft
priority: high
estimate: 8h
dependencies: []
---

# Create ideas-manager Tool for Idea Capture

## Objective

Create a new Ruby gem executable `ideas-manager` that captures raw ideas in the project context, enhancing them with relevant questions and storing them in the appropriate release ideas folder. This tool will be the entry point for the specification cycle, handling vague, unstructured input that may or may not become formal tasks.

## What: Behavioral Specification

### User Experience
- **Command**: `ideas-manager capture "my raw idea text"`
- **Options**:
  - `--release` (default: backlog, can be current or specific version)
  - `--clipboard` to read from clipboard
  - `--file PATH` to read from file(s)
- **Output**: Enhanced idea file with timestamp prefix in the appropriate ideas/ directory

### Expected Behavior
1. Accept raw idea input from various sources (text, clipboard, files)
2. Analyze idea in project context (architecture, existing features)
3. Generate contextual questions that need answering for specification
4. Create timestamped idea file with enhanced content
5. Return path to created idea file

### Interface Contract
```bash
# Basic usage
ideas-manager capture "Add dark mode support"
# => Created: dev-taskflow/backlog/ideas/20250130-1430-dark-mode-support.md

# With specific release
ideas-manager capture --release v.0.4.0-replanning "Improve task workflows"
# => Created: dev-taskflow/backlog/v.0.4.0-replanning/ideas/20250130-1431-improve-task-workflows.md

# From clipboard
ideas-manager capture --clipboard
# => Created: dev-taskflow/current/v.0.3.0-workflows/ideas/20250130-1432-clipboard-idea.md
```

## How: Implementation Plan

### Planning Steps
* [ ] Research existing tool patterns in dev-tools for consistency
* [ ] Design idea enhancement prompt for LLM integration
* [ ] Plan file naming and storage strategy
* [ ] Define question generation logic

### Execution Steps
- [ ] Create ideas-manager executable in dev-tools/exe/
- [ ] Implement IdeaCapture organism in dev-tools/lib/coding_agent_tools/organisms/
- [ ] Add clipboard reading molecule if not exists
- [ ] Create idea enhancement prompt templates
- [ ] Implement timestamped file creation logic
- [ ] Add validation for release parameter
- [ ] Create comprehensive tests in dev-tools/spec/
- [ ] Update dev-tools documentation

## Scope of Work

### Deliverables

#### Create
- dev-tools/exe/ideas-manager
- dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb
- dev-tools/lib/coding_agent_tools/molecules/idea_enhancer.rb
- dev-tools/spec/organisms/idea_capture_spec.rb
- dev-tools/spec/cli/ideas_manager_spec.rb
- dev-handbook/templates/idea-manager/system.prompt.md (will be used for enhacing the idea with llm-query)
- dev-handbook/templates/idea-manager/idea.template.md (the format of the idea)

#### Modify
- dev-tools/lib/coding_agent_tools.rb (register new components)
- docs/tools.md (add ideas-manager documentation)

## Acceptance Criteria

- [ ] Tool captures ideas from text, clipboard, and files
- [ ] Ideas are enhanced with project context
- [ ] Relevant questions are generated for each idea
- [ ] Files are created with proper timestamp naming
- [ ] Release targeting works correctly
- [ ] All tests pass
- [ ] Documentation is complete

## Example

```bash
idea-manager capture "every task definition should have an example section, that should demo how medium level example should work when job is done"
```
1. it saves the idea in tmp file -> ./tmp/20250730-102915-task-definition-with-example.md

2. it prepare the system prompt -> ./tmp/20250730-102915-task-definition-with-example.system.prompt.md

## the system prompt include:

- the instruction
- the output format (need to create format )
- the project context (docs/*.md) (embeded as they are )

```markdown
# Instruction

Enhance the note into idea. Use the template idea.template.md and take into account context

...

<template>
    # title

    # goal

    # project context

    # questions
    ...
</template>

<context>
    <document path="docs/what-do-we-do.md">
        ...
    </document>
    <document path="docs/architecture.md">
        ...
    </document>

    ...
</context>
```

1. it calls

```bash
llm-query gflash ./tmp/20250730-102915-task-definition-with-example.md \
--system-prompt ./tmp/20250730-102915-task-definition-with-example.system.prompt.md \
--output dev-taskflow/backlog/20250730-102915-task-definition-with-example.md
```

## Out of Scope

- ❌ Automatic task creation from ideas
- ❌ Idea prioritization or filtering
- ❌ Integration with task-manager
- ❌ Idea status tracking

## References

- Research document: dev-taskflow/current/v.0.3.0-workflows/backlog/research/how-to-build-planning-agents-without-loosing-control.md
- Existing idea: dev-taskflow/backlog/ideas/exe-capture-it-new.md
