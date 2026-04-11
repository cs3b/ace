# ADR-016: Handbook Directory Architecture for AI Integration

## Status
Accepted
Date: October 14, 2025

## Context

With the completion of the mono-repo migration (ADR-015) and 15+ production ace-* gems, a consistent pattern emerged for AI integration: each gem needs both agents (single-purpose, composable actions) and workflows (complete, self-contained processes) for effective AI assistant integration.

### Requirements

1. **AI Integration**: Each gem must be usable by AI assistants (Claude Code, etc.)
2. **Discoverability**: Workflows and agents must be easily discoverable
3. **Self-Containment**: Workflows must follow ADR-001 principles
4. **Consistency**: All gems should use the same directory structure
5. **Modularity**: Each gem's AI integration should be independent

### Observed Pattern

Analysis of production gems (ace-search, ace-docs, ace-task, ace-git-commit) revealed consistent handbook/ usage:
- All include `handbook/` directory
- Split between `agents/` and `workflow-instructions/`
- Agents are `.ag.md` files (single-purpose)
- Workflows are `.wf.md` files (complete processes)
- Symlinked to `.claude/agents/` for Claude Code integration

## Decision

All ace-* gems **must** include a `handbook/` directory with standardized structure for AI integration:

```
ace-gem/
└── handbook/
    ├── agents/                        # Single-purpose agents
    │   ├── action.ag.md              # Execute specific action
    │   └── research.ag.md            # Multi-step analysis
    └── workflow-instructions/         # Complete workflows
        └── process.wf.md             # End-to-end process
```

### Directory Requirements

**`handbook/` (required):**
- Top-level directory within gem
- Contains all AI integration materials
- Follows ADR-003 principles (separation from guides)

**`handbook/agents/` (optional but recommended):**
- Single-purpose `.ag.md` files
- Each agent performs one focused action
- Composable and reusable
- Minimal context requirements
- Standardized response formats

**`handbook/workflow-instructions/` (required for complex gems):**
- Complete `.wf.md` files following ADR-001
- Self-contained with all templates inline (ADR-002)
- Include purpose, parameters, tools in frontmatter
- Discoverable via `ace-nav wfi://` protocol

### Agent vs Workflow Decision Criteria

**Use an Agent (.ag.md) when:**
- Single command execution
- Composable operation
- Minimal state management
- Quick, focused action
- Reusable across contexts

**Use a Workflow (.wf.md) when:**
- Multi-step process
- Decision points required
- Context management needed
- Complex orchestration
- Complete end-to-end process

### Frontmatter Standards

**Agent frontmatter:**
```yaml
---
name: agent-name
description: Single-purpose description
allowed-tools: [Tool1, Tool2]
expected_params:
  param_name: description
---
```

**Workflow frontmatter:**
```yaml
---
name: workflow-name
allowed-tools: [Tool1, Tool2, Tool3]
description: Complete workflow description
argument-hint: "[param]"
doc-type: workflow
purpose: workflow instruction
---
```

### Integration with Claude Code

Agents and workflows symlinked to `.claude/agents/` for direct access:
```bash
.claude/agents/
├── gem-agent.ag.md -> ../../ace-gem/handbook/agents/agent.ag.md
└── gem-workflow.wf.md -> ../../ace-gem/handbook/workflow-instructions/workflow.wf.md
```

## Consequences

### Positive

- **Consistent AI Integration**: All gems follow same pattern
- **Discoverability**: `ace-nav wfi://` finds all workflows
- **Modularity**: Each gem's AI integration is self-contained
- **Reusability**: Agents composable across gems
- **Maintainability**: Clear separation between agents and workflows
- **Installability**: Workflows packaged with gem functionality

### Negative

- **Directory Overhead**: Every gem needs handbook/ even if minimal
- **Duplication**: Similar patterns repeated across gems
- **Maintenance**: Need to keep frontmatter standards current

### Neutral

- **Symlink Management**: Requires symlink creation for Claude Code
- **Documentation**: Need to document pattern for gem developers
- **Migration**: Existing gems need handbook/ directories added

## Examples from Production Gems

### ace-search
```
ace-search/handbook/
├── agents/
│   ├── search.ag.md          # Single search execution
│   └── research.ag.md        # Multi-search analysis
```

### ace-docs
```
ace-docs/handbook/
└── workflow-instructions/
    └── update-docs.wf.md     # Complete documentation update process
```

### ace-task
```
ace-task/handbook/
└── workflow-instructions/
    ├── work-on-task.wf.md
    ├── plan-task.wf.md
    ├── review-task.wf.md
    └── [... 20+ workflows]
```

### ace-git-commit
```
ace-git-commit/handbook/
└── workflow-instructions/
    └── commit.wf.md          # Git commit generation workflow
```

## Related Decisions

- **ADR-001**: Workflow Self-Containment - workflows must be self-contained
- **ADR-002**: XML Template Embedding - templates inline in workflows
- **ADR-003**: Template Directory Separation - evolution to handbook/ pattern
- **ADR-015**: Mono-Repo Migration - enabled per-gem handbook/ pattern

## Implementation Guidelines

### For New Gems

1. Create `handbook/` directory in gem root
2. Add `agents/` if gem has single-purpose actions
3. Add `workflow-instructions/` if gem has complex workflows
4. Follow frontmatter standards for all files
5. Create symlinks in `.claude/agents/` for Claude Code integration

### For Existing Gems

1. Create `handbook/` directory
2. Migrate any existing workflows/agents
3. Update paths in documentation
4. Add symlinks for Claude Code

### Minimum Viable Handbook

Simple gems can start with just one workflow:
```
ace-simple/handbook/
└── workflow-instructions/
    └── use-simple.wf.md
```

## References

- **Production Examples**: ace-search, ace-docs, ace-task, ace-git-commit
- **ace-nav Protocol**: wfi:// for workflow discovery
- **Claude Code Integration**: .claude/agents/ symlink pattern
- **ADR-001**: Self-containment principles
- **docs/architecture.md**: Handbook organization section

---

This ADR establishes the handbook/ directory as the standard pattern for AI integration across all ACE gems, providing consistent, discoverable, and modular AI assistant integration.
