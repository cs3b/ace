---
update:
  update_frequency: weekly
  max_lines: 100
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-12-27'
---

# ACE (Agentic Coding Environment)

## What We Build

ACE packages development capabilities as Ruby gems for AI coding assistants. Each gem includes CLI tools, agents, and workflows - making it a complete, reusable capability. Whether it's documentation management, code review, or task orchestration - ACE turns it into an installable gem that works with Claude Code, Codex, OpenCode, and other AI environments.

## Current Capabilities

- **ace-core**: Configuration management and shared utilities
- **ace-context**: Project context loading with smart caching
- **ace-docs**: Documentation management with frontmatter-based tracking
- **ace-git**: Unified Git operations (status, diff, branch, PR context)
- **ace-git-commit**: Smart git commit generation with LLM integration
- **ace-git-secrets**: Token detection and security remediation
- **ace-git-worktree**: Git worktree management
- **ace-lint**: Code quality linting (markdown, YAML, frontmatter)
- **ace-llm**: Multi-provider AI model integration with CLI-based providers
- **ace-nav**: Resource discovery and navigation with wfi:// protocol
- **ace-prompt**: Prompt workspace with LLM enhancement and task integration
- **ace-review**: Preset-based code review with LLM-powered analysis
- **ace-search**: Unified file and content search with intelligent pattern matching
- **ace-taskflow**: Task, release, and idea management with presets
- **ace-test**: Test execution and CI integration
- **ace-test-support**: Testing infrastructure and helpers

## Coming Soon

- **ace-handbook**: Workflows, guides, and templates as a gem

## The Vision

Every development capability becomes an installable Ruby gem. Prompts, agents, and workflows are embedded within thematic gems rather than generic bundles. Install with `gem install ace-*` and use immediately - whether you're a human developer or an AI agent.

---

*ACE: Making AI-assisted development as simple as `gem install`.*
