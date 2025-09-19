---
id: v.0.3.0+task.51
status: done
priority: high
estimate: 4h
dependencies: []
---

# Migrate Deprecated Tool Dependencies

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools | sed 's/^/    /'
```

_Result excerpt:_

```
    .ace/tools
    ├── bin
    ├── exe
    ├── exe-old
    ├── lib
    └── spec
```

## Objective

Investigate and resolve the .ace/tools/exe-old/ dependency in initialize-project-structure.wf.md workflow. Create a comprehensive migration plan to integrate task management tools (tn, tr, rc, etc.) from exe-old into the coding_agent_tools Ruby gem architecture, addressing the security/stability risk identified by Google Pro reviewer while supporting the architectural evolution toward a unified gem-based approach.

## Scope of Work

* Audit all references to exe-old directory across the codebase
* Identify which tools are being used from exe-old and analyze their functionality
* Design integration of task management tools into coding_agent_tools Ruby gem using ATOM architecture
* Create migration plan for rewriting exe-old tools as gem CLI commands
* Update workflows to use unified gem-based tool access (.ace/tools/exe/coding_agent_tools <command>)
* Plan binstub preservation strategy to maintain current bin/ entry points
* Document the migration approach and architectural integration for future reference

### Deliverables

#### Create

* .ace/taskflow/current/v.0.3.0-workflows/researches/tool-migration-plan.md - Comprehensive migration strategy document
* .ace/taskflow/current/v.0.3.0-workflows/researches/gem-architecture-integration.md - ATOM architecture integration design

#### Modify

* .ace/handbook/workflow-instructions/initialize-project-structure.wf.md - Update tool references
* Any other workflows using exe-old tools

#### Delete

* None (exe-old removal is out of scope - may be needed for backward compatibility)

## Phases

1. Audit - Find all exe-old dependencies and analyze tool functionality
2. Architecture Design - Plan integration into coding_agent_tools gem using ATOM pattern
3. Migration Strategy - Create roadmap for rewriting tools as gem CLI commands
4. Workflow Updates - Update tool references to use unified gem access
5. Implementation Plan - Document development roadmap for tool rewrite
6. Testing Strategy - Plan validation of migrated functionality

## Implementation Plan

### Planning Steps

* [x] Search for all references to exe-old across the codebase
  > TEST: Dependency Audit Complete
  > Type: Pre-condition Check
  > Assert: All exe-old references identified
  > Command: rg "exe-old" --type md
* [x] Catalog all exe-old tools and analyze their interfaces and functionality
  > TEST: Tool Inventory Complete
  > Type: Pre-condition Check
  > Assert: All exe-old tools documented with interfaces
  > Command: ls -la .ace/tools/exe-old/ && head -20 .ace/tools/exe-old/*
* [x] Analyze current coding_agent_tools gem architecture and CLI structure
  > TEST: Gem Architecture Analysis
  > Type: Pre-condition Check
  > Assert: Current gem CLI commands and ATOM structure understood
  > Command: .ace/tools/exe/coding_agent_tools --help && find .ace/tools/lib -name "*.rb" | head -10
* [x] Design ATOM architecture integration for task management commands
* [x] Plan CLI command structure for unified tool access
* [x] Design binstub preservation strategy for seamless migration

### Execution Steps

* [x] Create comprehensive migration plan document with architectural design
  > TEST: Migration Plan Created
  > Type: Action Validation
  > Assert: Migration plan exists with architectural integration details
  > Command: test -f .ace/taskflow/current/v.0.3.0-workflows/researches/tool-migration-plan.md
* [x] Create gem architecture integration design document
  > TEST: Architecture Integration Designed
  > Type: Action Validation
  > Assert: ATOM integration plan exists
  > Command: test -f .ace/taskflow/current/v.0.3.0-workflows/researches/gem-architecture-integration.md
* [x] Plan workflow update strategy for post-implementation phase
  > TEST: Workflow Update Strategy Documented
  > Type: Documentation Validation
  > Assert: Clear guidance exists on when to update workflows
  > Command: grep -q "Workflow Update Timing" .ace/taskflow/current/v.0.3.0-workflows/researches/tool-migration-plan.md
* [x] Document which workflows need updating after gem implementation
  > TEST: Workflow Update List Complete
  > Type: Documentation Validation
  > Assert: All workflows requiring updates are identified
  > Command: grep -q "initialize-project-structure.wf.md" .ace/taskflow/current/v.0.3.0-workflows/researches/tool-migration-plan.md
* [x] Document tool mapping and implementation roadmap
  > TEST: Implementation Roadmap Complete
  > Type: Documentation Validation
  > Assert: Complete roadmap exists for tool rewrite
  > Command: grep -q "Implementation Timeline\|Development Phases" .ace/taskflow/current/v.0.3.0-workflows/researches/tool-migration-plan.md

## Acceptance Criteria

* [x] AC 1: All exe-old dependencies identified and analyzed with functionality documentation
* [x] AC 2: Comprehensive migration plan created with ATOM architecture integration design
* [x] AC 3: Strategy documented for updating workflows after gem implementation complete
* [x] AC 4: List of workflows requiring updates documented in migration plan
* [x] AC 5: Implementation roadmap documented for rewriting tools as gem commands
* [x] AC 6: Binstub preservation strategy documented for seamless user experience
* [x] AC 7: ATOM architecture integration plan complete with CLI command structure

## Out of Scope

* ❌ Deleting exe-old directory (may break backward compatibility during transition)
* ❌ Actually implementing the tool rewrites (covered in future development tasks)
* ❌ Modifying the existing Ruby gem structure (only planning integration)
* ❌ Breaking current bin/ script functionality during planning phase

## References

* Review report: .ace/taskflow/current/v.0.3.0-workflows/code_review/20250703-232338-handbook-workflows/cr-report.md
* Deprecated tools: .ace/tools/exe-old/
* Current tools: .ace/tools/exe/
* Affected workflow: .ace/handbook/workflow-instructions/initialize-project-structure.wf.md
