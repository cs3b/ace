# Dev-Handbook Context Configuration

Context configuration for the dev-handbook submodule, focusing on workflow instructions, guides, and templates.

## Overview

The dev-handbook contains the structured workflow instructions and development guides. This context configuration helps when working on documentation, workflows, or templates.

<context-tool-config>
files:
  - dev-handbook/workflow-instructions/*.wf.md
  - dev-handbook/guides/**/*.md
  - dev-handbook/templates/**/*.md
  - dev-handbook/.integrations/claude/agents/*.ag.md

commands:
  - find dev-handbook/workflow-instructions -name "*.wf.md" | wc -l
  - find dev-handbook/guides -name "*.md" | head -10
  - ls -la dev-handbook/.integrations/claude/agents/

format: yaml
embed_document_source: true
</context-tool-config>

## Usage

```bash
# Load handbook-specific context
context docs/context/dev-handbook.md

# This will return the full document with embedded processed context
# in YAML format (as specified in the configuration)
```

## What This Includes

- **Workflow Instructions** - All .wf.md files for AI agent workflows
- **Development Guides** - Best practices and standards documentation
- **Templates** - Reusable project and document templates  
- **Agent Definitions** - Claude agent configurations with <context-tool-config> tags

This configuration is ideal for:
- Working on workflow instructions
- Updating development guides
- Managing Claude agent configurations
- Understanding the handbook structure