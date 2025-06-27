# ADR-001: Workflow Self-Containment Principle

## Status

Accepted
Date: 2025-06-27

## Context

The Coding Agent Workflow Toolkit project maintains 21 workflow instruction files designed to guide AI coding agents through development tasks. Prior to this decision, these workflows followed a reference-based architecture where workflows frequently referenced external guides, templates, and other workflows to obtain necessary context and instructions.

Analysis of the existing workflow system revealed significant barriers to independent execution by AI coding agents:

- **88% of workflows** contained external dependencies on guides, templates, or other workflows
- **67% required project context loading** through standardized files without embedded guidance
- **43% had circular or complex dependencies** requiring orchestrated execution of multiple workflows
- **76% lacked complete embedded context** for autonomous agent execution

### Key Problems with Reference-Based Workflows

1. **Context Window Limitations**: AI agents must load multiple referenced documents, consuming valuable context window space and reducing processing efficiency.

2. **Dependency Brittleness**: Changes to referenced guides could break multiple workflows without clear visibility into the impact.

3. **Execution Complexity**: Agents needed to understand and manage complex dependency chains, including:
   - Draft-release workflow → breakdown-notes-into-tasks workflow → 7 sub-workflows
   - Task execution chains requiring multiple workflow orchestration
   - Dynamic path resolution requiring runtime discovery

4. **Missing Embedded Context**: Critical information was referenced but not embedded, such as:
   - Conventional commit formats referenced but not specified
   - Testing patterns assumed but not documented
   - Template structures required but not included

5. **Agent Autonomy Barriers**: Workflows required manual context loading, user verification steps, and cross-workflow knowledge that prevented autonomous execution.

## Decision

All workflow instruction files must be completely self-contained and independently executable. This means:

1. **No Cross-Workflow Dependencies**: Workflows cannot require other workflows to run first or assume knowledge from other workflows.

2. **Embedded Essential Content**: All necessary templates, examples, formats, and guidelines must be embedded directly within the workflow file rather than referenced externally.

3. **Explicit Project Context Loading**: Workflows may reference three standardized project context files (`docs/what-do-we-build.md`, `docs/architecture.md`, `docs/blueprint.md`) but must explicitly specify what information to load and why.

4. **Self-Contained Templates**: All required templates and examples must be embedded inline rather than stored in separate template files.

5. **Independent Execution Capability**: Each workflow must contain everything an AI agent needs to execute the workflow successfully without external knowledge or additional file loading.

## Consequences

### Positive

- **Improved Agent Autonomy**: AI agents can execute workflows independently without complex dependency management or external context loading.

- **Enhanced Reliability**: Self-contained workflows are less susceptible to breakage from changes in external dependencies.

- **Better Context Efficiency**: Agents only need to load the single workflow file plus three standardized project context files, maximizing available context window.

- **Simplified Maintenance**: Changes to workflow logic are contained within single files, reducing ripple effects across the system.

- **Faster Execution**: Eliminates time spent resolving dependencies, loading multiple files, and managing cross-workflow state.

- **Clear Boundaries**: Each workflow has explicit, well-defined responsibilities without overlapping concerns.

### Negative

- **Increased File Size**: Workflows contain more embedded content, making individual files larger and potentially more complex.

- **Content Duplication**: Common patterns and examples may be duplicated across multiple workflows rather than centralized.

- **Migration Effort**: Existing workflows require significant refactoring to embed previously referenced content.

- **Template Management Complexity**: Templates must be maintained inline rather than in centralized, reusable files.

### Neutral

- **Changed Guide Role**: Development guides transition from being directly referenced by workflows to serving as reference material for workflow authors and maintenance.

- **Workflow Structure Evolution**: Workflows now include more comprehensive embedded sections, changing their overall structure and organization.

## Alternatives Considered

### Alternative 1: Status Quo (Reference-Based Architecture)

- **Description**: Continue with the existing system of cross-references and external dependencies
- **Why it wasn't chosen**:
  - Creates brittleness and complexity that hinders AI agent autonomy
  - Results in poor context window utilization
  - Makes workflows dependent on external changes
  - Requires complex orchestration logic for execution

### Alternative 2: Hybrid Model with Dependency Declaration

- **Description**: Keep references but add explicit dependency sections and validation
- **Why it wasn't chosen**:
  - Still requires agents to manage multiple files and dependencies
  - Adds complexity without solving core autonomy issues
  - Doesn't address context window efficiency problems
  - Maintains brittleness issues with external changes

### Alternative 3: Centralized Workflow Engine

- **Description**: Create a workflow orchestration system to manage dependencies automatically
- **Why it wasn't chosen**:
  - Adds significant system complexity
  - Creates a single point of failure
  - Doesn't improve individual workflow clarity
  - Increases maintenance burden without addressing core issues

## Related Decisions

This decision establishes the foundational principle for all future workflow development and serves as the architectural basis for the v.0.3.0 workflow system refactoring.

## References

- **Original Requirement**: Documentation review report "Workflow Decision Records Required"
- **Analysis**: dev-taskflow/current/v.0.3.0-workflows/researches/workflow-dependency-analysis.md
- **Validation**: dev-taskflow/current/v.0.3.0-workflows/researches/workflow-independence-validation.md
- **Implementation**: dev-taskflow/current/v.0.3.0-workflows/reflections/20250626-234656-workflow-independence-refactoring.md
- **Template Reference**: dev-handbook/workflow-instructions/create-adr.wf.md

## Examples

### Before: Reference-Based Pattern

```markdown
## Prerequisites
- Load project context: `docs/what-do-we-build.md`
- Review commit format: `dev-handbook/guides/version-control-system.g.md`
- Use task template: `dev-handbook/guides/draft-release/v.x.x.x/tasks/_template.md`
```

### After: Self-Contained Pattern

```markdown
## Project Context Loading
Load these project files to understand context:
- `docs/what-do-we-build.md` - Project objectives and scope
- `docs/architecture.md` - System design principles
- `docs/blueprint.md` - Project structure overview

## Commit Format (Embedded)
Use this conventional commit format:
```

type(scope): description

- Detail 1
- Detail 2

```

Types: feat, fix, docs, style, refactor, test, chore

## Task Template (Embedded)
```yaml
---
id: v.X.Y.Z+task.N
status: pending
priority: [high | medium | low]
estimate: Nh
dependencies: []
---

# Task Title

## Objective
[Clear statement of what needs to be accomplished]
```

```

This architectural decision ensures that all future workflows in the Coding Agent Handbook system prioritize agent autonomy, execution reliability, and maintenance simplicity over centralized template management.
