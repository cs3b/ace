---
id: v.0.2.0+task.30
status: pending
priority: medium
estimate: 2h
dependencies: []
---

# Update Blueprint Documentation with New Features and Tools

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 docs-project | sed 's/^/    /'
```

_Result excerpt:_

```
    docs-project
    ├── README.md
    ├── architecture.md
    ├── blueprint.md
    ├── current
    │   └── v.0.2.0-synapse
    ├── history
    ├── what-do-we-build.md
    └── why-do-we-build.md
```

## Objective

Update blueprint.md to include the new model management commands and developer tools introduced in v.0.2.0. This ensures the project blueprint accurately reflects current capabilities and workflows.

## Scope of Work

- Add new model management commands to common workflows section
- Include llm-lmstudio-query in the list of available commands
- Add bin/cr to the developer tools section
- Ensure all new features from v.0.2.0 are represented in the blueprint

### Deliverables

#### Modify

- docs-project/blueprint.md

## Phases

1. Audit current blueprint.md structure
2. Identify sections needing updates
3. Add new commands to workflows
4. Add new developer tools
5. Review for completeness

## Implementation Plan

### Planning Steps

* [ ] Review current blueprint.md structure and identify update locations
  > TEST: Blueprint Structure Analysis
  > Type: Pre-condition Check
  > Assert: Common workflows and developer tools sections are identified
  > Command: grep -n "^##" docs-project/blueprint.md | grep -E "Workflow|Tool|Command"
* [ ] Map new features to appropriate blueprint sections
* [ ] Ensure consistency with other updated documentation

### Execution Steps

- [ ] Add llm-gemini-models to common workflows or commands section
  > TEST: Gemini Models Command Added
  > Type: Action Validation
  > Assert: llm-gemini-models is documented in the blueprint
  > Command: grep "llm-gemini-models" docs-project/blueprint.md
- [ ] Add llm-lmstudio-models to common workflows or commands section
- [ ] Add llm-lmstudio-query to available commands section
  > TEST: LM Studio Query Command Added
  > Type: Action Validation
  > Assert: llm-lmstudio-query appears in the blueprint
  > Command: grep "llm-lmstudio-query" docs-project/blueprint.md
- [ ] Add bin/cr to developer tools section with brief description
  > TEST: Code Review Tool Documented
  > Type: Action Validation
  > Assert: bin/cr tool is listed in developer tools
  > Command: grep "bin/cr" docs-project/blueprint.md
- [ ] Update any workflow examples that could benefit from model selection features
- [ ] Ensure all additions maintain consistent formatting and style

## Acceptance Criteria

- [ ] All three new commands (llm-gemini-models, llm-lmstudio-models, llm-lmstudio-query) are documented
- [ ] bin/cr developer tool is listed with its purpose
- [ ] Model discovery workflow is represented in appropriate section
- [ ] LM Studio integration is clearly indicated as a key capability
- [ ] Documentation style remains consistent with existing blueprint content
- [ ] No v.0.2.0 features are missing from the blueprint

## Out of Scope

- ❌ Restructuring the entire blueprint document
- ❌ Adding detailed implementation information
- ❌ Documenting features from other releases
- ❌ Creating new workflow diagrams or visualizations

## References

- Documentation Review: docs-project/current/v.0.2.0-synapse/code-review/task-4/docs-review-gemini-2.5-pro.md
- New commands to document:
  - `llm-gemini-models` - List available Google Gemini models
  - `llm-lmstudio-models` - List available LM Studio models  
  - `llm-lmstudio-query` - Query local LM Studio models
- New tool to document:
  - `bin/cr` - Code review prompt generator for development workflow