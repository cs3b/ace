# Meta Documentation (`.meta`)

Internal documentation and tooling for maintaining the dev-handbook itself. This directory contains the "documentation about documentation" - guides, workflows, and templates used to create and maintain handbook content.

## Structure

### `/gds` - Guide Definition Standards

Standards and specifications for different documentation types:

- **[agents-definition.g.md](./gds/agents-definition.g.md)** - Agent structure and response format standards
- **[guides-definition.g.md](./gds/guides-definition.g.md)** - Standards for creating development guides
- **[workflow-instructions-definition.g.md](./gds/workflow-instructions-definition.g.md)** - Workflow instruction format and requirements
- **[tools-definition.g.md](./gds/tools-definition.g.md)** - CLI tool documentation standards
- **[markdown-definition.g.md](./gds/markdown-definition.g.md)** - Markdown formatting and style guide

### `/wfi` - Meta Workflow Instructions

Workflows for maintaining the handbook itself:

**Agent & Integration Management:**
- **[manage-agents.wf.md](./wfi/manage-agents.wf.md)** - Create/update agents in `.integrations/claude/agents/`
- **[update-integration-claude.wf.md](./wfi/update-integration-claude.wf.md)** - Sync Claude Code integration and commands
- **[install-dotfiles.wf.md](./wfi/install-dotfiles.wf.md)** - Install configuration files to project root

**Documentation Management:**
- **[manage-guides.wf.md](./wfi/manage-guides.wf.md)** - Create and maintain development guides
- **[manage-workflow-instructions.wf.md](./wfi/manage-workflow-instructions.wf.md)** - Manage workflow instruction files
- **[update-tools-documentation.wf.md](./wfi/update-tools-documentation.wf.md)** - Update dev-tools documentation

**Quality Control:**
- **[review-guides.wf.md](./wfi/review-guides.wf.md)** - Review and validate guide quality
- **[review-workflows.wf.md](./wfi/review-workflows.wf.md)** - Review workflow instruction quality

### `/tpl` - Templates

Reusable templates for creating new content:

- **[agent.md.tmpl](./tpl/agent.md.tmpl)** - Template for creating new agents
- **[workflow-context-loading-template.md](./tpl/workflow-context-loading-template.md)** - Standard context loading pattern
- **[workflow-execution-template.md](./tpl/workflow-execution-template.md)** - Workflow execution structure
- **[git-commit.system.prompt.md](./tpl/git-commit.system.prompt.md)** - Git commit message guidelines
- **[dotfiles/](./tpl/dotfiles/)** - Configuration file templates

## Relationships

```
.meta/ provides standards for →
  └─ .integrations/claude/agents/ (agent definitions)
  └─ guides/ (development guides)
  └─ workflow-instructions/ (workflow files)

.meta/wfi/ maintains →
  └─ All handbook content via meta-workflows
  └─ Claude integration sync and updates
  
.meta/tpl/ generates →
  └─ New agents from templates
  └─ Standardized workflow structures
```

## Usage

### Creating New Content

1. **New Agent**: Use `manage-agents.wf.md` with `agent.md.tmpl`
2. **New Guide**: Use `manage-guides.wf.md` following `guides-definition.g.md`
3. **New Workflow**: Use `manage-workflow-instructions.wf.md` following standards

### Maintaining Integration

```bash
# Update Claude integration after adding workflows
@update-integration-claude

# Create new agent
@manage-agents

# Review documentation quality
@review-guides
@review-workflows
```

### Quality Standards

All content must follow the definitions in `/gds`:
- Agents → `agents-definition.g.md`
- Guides → `guides-definition.g.md`  
- Workflows → `workflow-instructions-definition.g.md`
- Tools → `tools-definition.g.md`

## Quick Reference

| Type | Definition | Template | Management Workflow |
|------|------------|----------|-------------------|
| Agents | gds/agents-definition.g.md | tpl/agent.md.tmpl | wfi/manage-agents.wf.md |
| Guides | gds/guides-definition.g.md | - | wfi/manage-guides.wf.md |
| Workflows | gds/workflow-instructions-definition.g.md | tpl/workflow-*.md | wfi/manage-workflow-instructions.wf.md |
| Integration | - | - | wfi/update-integration-claude.wf.md |

---

*Meta-documentation maintained using its own workflows - the handbook that documents itself.*