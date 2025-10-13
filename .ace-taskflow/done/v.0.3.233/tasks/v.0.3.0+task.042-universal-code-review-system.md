---
id: v.0.3.0+task.42
status: done
priority: high
estimate: 8h
dependencies: []
---

# Create Universal Code Review System

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
.ace/handbook/guides
├── code-review-diff-for-docs-update.g.md
├── initialize-project-templates
└── ...
```

## Objective

Create a unified, flexible code review system that replaces multiple specialized review tools with a single universal command. The system should support different review focuses (code, tests, docs, combined), various target types (git diffs, file patterns, specific files), and configurable project context loading.

## Scope of Work

* Create universal code review workflow instruction
* Build Claude Code command wrapper
* Leverage existing review templates and LLM tools
* Support flexible parameter combinations
* Auto-load project context with override capability

### Deliverables

#### Create

* .ace/handbook/workflow-instructions/review-code.wf.md
* .claude/commands/review-code.md

#### Modify

* None required - leverages existing infrastructure

#### Delete

* None - existing tools remain for backward compatibility

## Phases

1. Analyze existing review tools and templates
2. Design universal command structure
3. Create comprehensive workflow instruction
4. Build Claude Code command wrapper
5. Document usage patterns and examples

## Implementation Plan

### Planning Steps

* [x] Analyze current system/codebase to understand existing patterns
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Key components and their relationships are identified
  > Command: Existing review templates, LLM tools, and workflow patterns analyzed
* [x] Research best practices and design approach
* [x] Plan detailed implementation strategy

### Execution Steps

* [x] Create universal code review workflow instruction
* [x] Build flexible parameter system (focus, target, context)
  > TEST: Verify Parameter System
  > Type: Action Validation
  > Assert: All parameter combinations properly handled
  > Command: Workflow instruction supports all specified parameter patterns
* [x] Integrate with existing templates and tools
* [x] Create Claude Code command wrapper
  > TEST: Verify Command Wrapper
  > Type: Action Validation
  > Assert: Command properly references workflow instruction
  > Command: .claude/commands/review-code.md correctly implemented
* [x] Document comprehensive usage examples

## Acceptance Criteria

* [x] Universal workflow instruction created with comprehensive parameter support
* [x] Claude Code command wrapper properly references workflow instruction
* [x] System supports all focus areas: code, tests, docs, combined
* [x] System supports all target types: git ranges, file patterns, specific files
* [x] Project context loading configurable: auto, none, custom
* [x] All usage examples documented and validated

## Out of Scope

* ❌ Modifying existing review templates (reuses as-is)
* ❌ Creating new LLM integration tools (leverages existing)
* ❌ Backward compatibility changes to existing tools
* ❌ Performance optimizations beyond basic design

## References

* Existing review templates: .ace/handbook/templates/review-_/_.md
* LLM tools: .ace/tools/exe/llm-query
* Project context loading: .ace/handbook/workflow-instructions/load-project-context.wf.md
* Original requirements: .ace/taskflow/current/v.0.3.0-workflows/backlog/code-review.md
