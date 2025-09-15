---
id: v.0.3.0+task.48
status: done
priority: high
estimate: 4h
dependencies: []
---

# Update Review Synthesizer Workflow with Direct Synthesis Option

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/workflow-instructions | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/handbook/workflow-instructions
    ├── commit.wf.md
    ├── create-adr.wf.md
    ├── create-api-docs.wf.md
    ├── create-reflection-note.wf.md
    ├── create-task.wf.md
    ├── create-test-cases.wf.md
    ├── create-user-docs.wf.md
    ├── draft-release.wf.md
    ├── fix-tests.wf.md
    ├── initialize-project-structure.wf.md
    ├── load-project-context.wf.md
    ├── publish-release.wf.md
    ├── review-code.wf.md
    ├── review-synthesizer.wf.md ← TARGET FILE
    ├── review-task.wf.md
    ├── save-session-context.wf.md
    ├── update-blueprint.wf.md
    ├── update-roadmap.wf.md
    └── work-on-task.wf.md
```

## Objective

Enhance the review-synthesizer workflow based on real-world usage learnings from the handbook review synthesis session. The current workflow defaults to external LLM tools when AI agents can often perform synthesis directly with better efficiency and control.

## Scope of Work

* Add direct synthesis option for AI agents with built-in synthesis capabilities
* Create decision framework for choosing between external tools vs. direct synthesis
* Enhance error handling and fallback mechanisms
* Document cost-efficiency insights and multi-model strategy recommendations
* Improve workflow usability based on session reflection findings

### Deliverables

#### Modify

* .ace/handbook/workflow-instructions/review-synthesizer.wf.md

## Phases

1. Analysis of current workflow limitations
2. Design direct synthesis approach
3. Implement workflow enhancements
4. Add decision logic and error handling

## Implementation Plan

### Planning Steps

* [x] Review current workflow structure and identify insertion points for new content
  > TEST: Workflow Structure Analysis
  > Type: Pre-condition Check
  > Assert: Current workflow sections and dependencies are mapped
  > Command: grep -n "^### [0-9]" .ace/handbook/workflow-instructions/review-synthesizer.wf.md
* [x] Analyze reflection learnings to extract specific improvement requirements
* [x] Design decision tree for synthesis method selection
* [x] Plan integration points with existing workflow sections

### Execution Steps

* [x] Add new section "4. Direct Synthesis Execution (Default)" before "Multi-Model Synthesis Execution"
  > TEST: Section Added Correctly
  > Type: Action Validation
  > Assert: New section is properly positioned and formatted
  > Command: grep -A 5 -B 5 "Direct Synthesis Option" .ace/handbook/workflow-instructions/review-synthesizer.wf.md
* [x] Insert decision framework at beginning of synthesis execution section
* [x] Enhance error handling in existing synthesis execution steps
* [x] Add cost-efficiency analysis section with multi-model strategy guidance
* [x] Update success criteria to include direct synthesis validation
* [x] Add usage examples demonstrating both synthesis approaches

## Acceptance Criteria

* [x] Direct synthesis option is clearly documented with step-by-step instructions
* [x] Decision framework helps AI agents choose appropriate synthesis method
* [x] Enhanced error handling covers both external tool and direct synthesis failures
* [x] Cost-efficiency insights are documented for future reference
* [x] All new content follows existing workflow instruction format and standards
* [x] Workflow maintains backward compatibility for external tool usage

## Out of Scope

* ❌ Modifying the system prompt template (handled separately)
* ❌ Changes to other workflow instructions
* ❌ Implementation of new external tools or scripts

## References

* Session reflection: .ace/taskflow/current/v.0.3.0-workflows/reflections/20250703-review-synthesis-session.md
* Current workflow: .ace/handbook/workflow-instructions/review-synthesizer.wf.md
* Synthesis session results: .ace/taskflow/current/v.0.3.0-workflows/code_review/20250703-232338-handbook-workflows/cr-report.md
