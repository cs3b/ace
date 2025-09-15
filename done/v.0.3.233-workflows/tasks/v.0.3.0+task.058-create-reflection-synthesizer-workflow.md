---
id: v.0.3.0+task.58
status: done
priority: high
estimate: 8h
dependencies: []
---

# Create Reflection Synthesizer Workflow

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions/
    ├── create-reflection-note.wf.md
    ├── review-synthesizer.wf.md (to be renamed)
    └── other workflow files...
```

## Objective

Create a new workflow instruction file `synthesize-reflection-notes.wf.md` that provides systematic analysis and compaction of multiple reflection notes, with cross-referencing against architecture documentation, impact-based prioritization, and actionable solution proposals.

## Scope of Work

* Design workflow for systematic reflection note analysis
* Implement scanning capabilities for reflection notes across releases
* Add cross-reference functionality with architecture documentation
* Create impact-based categorization and prioritization system
* Design solution proposal framework with implementation paths
* Include archival and compaction of processed reflections
* Follow self-containment principles and embed all necessary templates

### Deliverables

#### Create

* .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

## Phases

1. Analyze existing reflection synthesizer patterns from compact-self-reflection-note.md
2. Design workflow structure following workflow instruction standards
3. Create systematic reflection scanning and analysis framework
4. Implement prioritization and solution proposal capabilities
5. Add archival and compaction functionality
6. Validate workflow compliance and self-containment

## Implementation Plan

### Planning Steps

* [x] Analyze requirements from compact-self-reflection-note.md for synthesis capabilities
  > TEST: Requirements Understanding
  > Type: Pre-condition Check
  > Assert: Synthesis requirements are documented and understood
  > Command: cat .ace/taskflow/current/v.0.3.0-workflows/backlog/claude-commands/compact-self-reflection-note.md

* [x] Review existing review-synthesizer.wf.md for patterns and structure
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: Existing synthesizer patterns are analyzed for adaptation
  > Command: grep -E "^##|^###" .ace/handbook/workflow-instructions/review-synthesizer.wf.md

* [x] Design reflection scanning strategy for multiple releases and projects
  > TEST: Scanning Strategy Design
  > Type: Pre-condition Check
  > Assert: Strategy includes multi-release scanning and filtering
  > Command: echo "Scanning strategy design documented"

### Execution Steps

* [x] Create workflow file with standard structure (Goal, Prerequisites, Context Loading, Process Steps)
  > TEST: File Structure Creation
  > Type: Action Validation
  > Assert: File created with all required workflow sections
  > Command: grep -E "^## (Goal|Prerequisites|Project Context Loading|Process Steps)" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

* [x] Implement systematic reflection note scanning across .ace/taskflow structure
  > TEST: Scanning Implementation
  > Type: Action Validation
  > Assert: Workflow includes commands for scanning reflection notes
  > Command: grep -A 10 "find.*reflections\|ls.*reflections" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

* [x] Add cross-reference functionality with architecture and blueprint documentation
  > TEST: Cross-Reference Implementation
  > Type: Action Validation
  > Assert: Workflow includes architecture cross-referencing steps
  > Command: grep -A 5 "docs/architecture\|docs/blueprint" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

* [x] Create impact-based categorization system (Critical, High, Medium, Low)
  > TEST: Categorization System
  > Type: Action Validation
  > Assert: Impact-based categorization is implemented with clear criteria
  > Command: grep -A 10 "Critical\|High.*Impact\|Medium.*Impact\|Low.*Impact" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

* [x] Implement solution proposal framework with concrete implementation paths
  > TEST: Solution Framework
  > Type: Action Validation
  > Assert: Solution proposals include implementation steps and examples
  > Command: grep -A 5 "solution.*proposal\|implementation.*path" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

* [x] Add archival and compaction functionality for processed reflections
  > TEST: Archival Implementation
  > Type: Action Validation
  > Assert: Workflow includes steps for archiving processed reflections
  > Command: grep -A 5 "archiv\|compact\|processed.*reflection" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

* [x] Embed analysis report template for synthesis output
  > TEST: Template Embedding
  > Type: Action Validation
  > Assert: Embedded template follows proper format with all required sections
  > Command: grep -A 20 "<template.*reflection.*analysis" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

* [x] Validate workflow follows self-containment principles
  > TEST: Self-Containment Validation
  > Type: Post-condition Check
  > Assert: Workflow contains all necessary context, examples, and templates
  > Command: grep -c "## Project Context Loading\|<template\|```bash" .ace/handbook/workflow-instructions/synthesize-reflection-notes.wf.md

## Acceptance Criteria

* [x] AC 1: Workflow file created with proper verb-first naming (synthesize-reflection-notes.wf.md)
* [x] AC 2: Systematic scanning of reflection notes across releases is implemented
* [x] AC 3: Cross-reference functionality with architecture documentation included
* [x] AC 4: Impact-based categorization system (Critical/High/Medium/Low) implemented
* [x] AC 5: Solution proposal framework with concrete implementation paths included
* [x] AC 6: Archival and compaction functionality for processed reflections added
* [x] AC 7: Embedded analysis report template follows proper format
* [x] AC 8: Workflow follows self-containment principles with no external dependencies
* [x] AC 9: All automated checks in the Implementation Plan pass

## Out of Scope

* ❌ Modifying existing reflection note files or templates
* ❌ Creating external tools or scripts outside the workflow
* ❌ Changing the structure of .ace/taskflow directories
* ❌ Implementing automatic reflection processing without user control

## References

* .ace/taskflow/current/v.0.3.0-workflows/backlog/claude-commands/compact-self-reflection-note.md
* .ace/handbook/workflow-instructions/review-synthesizer.wf.md (pattern reference)
* .ace/handbook/.meta/gds/workflow-instructions-definition.g.md
* docs/architecture.md
* docs/blueprint.md
