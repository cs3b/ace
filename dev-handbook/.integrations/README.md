# Integrations (`.integrations`)

AI assistant integrations for the dev-handbook. Currently focused on Claude Code integration with plans for broader AI assistant support.

## Current Integration: Claude Code

The `claude/` directory contains a complete Claude Code integration system with agents, commands, and configuration.

### Directory Structure

```
claude/
├── agents/           # 10 specialized agent definitions
├── commands/         # 34 command definitions
│   ├── _custom/     # 7 hand-crafted commands
│   └── _generated/  # 27 auto-generated from workflows
├── templates/       # Claude-specific templates
├── install-prompts.md      # Installation instructions
├── metadata-field-reference.md  # Field documentation
└── README.md        # Claude integration guide
```

### Agents

Single-purpose agents following `.meta/gds/agents-definition.g.md` standards:

**Task Management:**
- **[task-finder](./claude/agents/task-finder.ag.md)** - Find and list tasks
- **[task-creator](./claude/agents/task-creator.ag.md)** - Create new task files

**Git Operations:**
- **[git-all-commit](./claude/agents/git-all-commit.ag.md)** - Commit all changes
- **[git-files-commit](./claude/agents/git-files-commit.ag.md)** - Commit specific files
- **[git-review-commit](./claude/agents/git-review-commit.ag.md)** - Review before commit

**Development Tools:**
- **[lint-files](./claude/agents/lint-files.ag.md)** - Lint and fix code issues
- **[create-path](./claude/agents/create-path.ag.md)** - Create files/directories
- **[search](./claude/agents/search.ag.md)** - Search code patterns
- **[feature-research](./claude/agents/feature-research.ag.md)** - Research missing features
- **[release-navigator](./claude/agents/release-navigator.ag.md)** - Navigate releases

### Commands

Commands map to workflow instructions and custom operations:

**Custom Commands** (`_custom/`):
- `/commit` - Enhanced git commit workflow
- `/load-project-context` - Load project documentation
- `/draft-tasks`, `/plan-tasks`, `/review-tasks`, `/work-on-tasks` - Task workflows
- `/create-task-based-on-plan` - Task creation from plans

**Generated Commands** (`_generated/`):
Auto-generated from `workflow-instructions/*.wf.md`:
- All 27 workflow instructions have corresponding commands
- Examples: `/draft-release`, `/fix-tests`, `/create-adr`, `/update-blueprint`

## Installation & Setup

### Quick Install

```bash
# From dev-tools directory
bundle exec handbook claude integrate

# This creates:
# - .claude/agents/ → symlinks to .integrations/claude/agents/
# - .claude/commands/ → copies from .integrations/claude/commands/
# - Updates CLAUDE.md with agent documentation
```

### Manual Setup

1. **Create symlinks for agents:**
   ```bash
   ln -s dev-handbook/.integrations/claude/agents/*.ag.md .claude/agents/
   ```

2. **Copy command files:**
   ```bash
   cp -r dev-handbook/.integrations/claude/commands/* .claude/commands/
   ```

3. **Update CLAUDE.md** with agent recommendations

## Relationships & Dependencies

### Managed By

- **[.meta/wfi/manage-agents.wf.md](../.meta/wfi/manage-agents.wf.md)** - Create/update agents
- **[.meta/wfi/update-integration-claude.wf.md](../.meta/wfi/update-integration-claude.wf.md)** - Sync integration

### Uses Templates From

- **[.meta/tpl/agent.md.tmpl](../.meta/tpl/agent.md.tmpl)** - Agent creation template

### Follows Standards From

- **[.meta/gds/agents-definition.g.md](../.meta/gds/agents-definition.g.md)** - Agent structure standards

### Generates Commands From

- **[workflow-instructions/*.wf.md](../workflow-instructions/)** - Source for generated commands

### Creates Symlinks In

- **`.claude/agents/`** - Project root agent directory
- **`.claude/commands/`** - Project root command directory

## Usage in Claude Code

Once installed, use commands directly in Claude Code:

```
/load-project-context
/draft-task "Add user authentication"
/work-on-task
/commit
```

Or invoke agents:

```
@task-finder next --limit 5
@git-all-commit
@lint-files **/*.rb
```

## Adding New Integrations

To add support for other AI assistants:

1. Create new directory: `.integrations/[assistant-name]/`
2. Follow the Claude structure as a template
3. Create meta-workflow for management
4. Document in this README

## Maintenance

### Update Commands After Adding Workflows

```bash
# Regenerate commands from workflows
bundle exec handbook claude update

# Or use the workflow
@update-integration-claude
```

### Create New Agent

```bash
# Use the management workflow
@manage-agents

# Agent will be created in:
# .integrations/claude/agents/[name].ag.md
```

### Review Integration Health

```bash
# Check command status
bundle exec handbook claude list

# Verify symlinks
ls -la .claude/agents/
```

---

*Integration system designed for extensibility - Claude Code today, more assistants tomorrow.*