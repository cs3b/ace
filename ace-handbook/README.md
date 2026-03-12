# ACE Handbook Gem

Workflow and guide governance for ACE (Agentic Coding Environment). This package owns the handbook-level workflows and guides used to create, review, and maintain handbook content across the monorepo.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "ace-handbook"
```

Or install it directly:

```bash
gem install ace-handbook
```

## Usage

Use `ace-bundle` to load handbook workflows directly:

```bash
# Guide management
ace-bundle wfi://handbook/manage-guides
ace-bundle wfi://handbook/review-guides

# Workflow management
ace-bundle wfi://handbook/manage-workflows
ace-bundle wfi://handbook/review-workflows

# Handbook maintenance
ace-bundle wfi://handbook/update-docs
ace-bundle wfi://handbook/init-project
```

Use `ace-nav` only when you need discovery or path lookup:

```bash
ace-nav wfi://handbook/*
ace-nav wfi://handbook/manage-workflows
```

## Scope

The `ace-handbook` package is the canonical home for handbook governance material:

- `handbook/workflow-instructions/handbook/` for handbook workflows
- `handbook/guides/` for development guides and handbook standards
- `handbook/skills/` for canonical provider-agent skill definitions

General documentation should point readers to `ace-bundle wfi://...` and direct `ace-*` commands. Skill documents are reserved for provider-agent integrations and `ace-assign` skill discovery.

## Key Workflows

| Workflow | Purpose |
|----------|---------|
| `handbook/manage-guides` | Create and update development guides |
| `handbook/review-guides` | Review guides for quality and standards compliance |
| `handbook/manage-workflows` | Create and update workflow instruction files |
| `handbook/review-workflows` | Review workflow instruction quality and consistency |
| `handbook/manage-agents` | Maintain handbook-managed agent definitions |
| `handbook/update-docs` | Refresh handbook-facing documentation |
| `handbook/parallel-research` | Run coordinated multi-agent research |
| `handbook/synthesize-research` | Synthesize parallel research outputs |
| `handbook/perform-delivery` | Drive delivery coordination guidance |

## Architecture

This is a handbook-governance package:

- Workflow content is authored as markdown under `handbook/workflow-instructions/`
- Guides live under `handbook/guides/`
- Canonical skill metadata lives under `handbook/skills/`
- Provider packages project those skills into provider-native folders

The normal reader-facing execution model is:

1. Load a workflow with `ace-bundle wfi://...`
2. Follow the workflow using direct `ace-*` commands
3. Use provider-agent skill wrappers only in provider integration surfaces or `ace-assign`-driven dispatch

## File Structure

```text
ace-handbook/
├── handbook/
│   ├── guides/
│   ├── skills/
│   └── workflow-instructions/
│       └── handbook/
├── lib/
├── README.md
└── CHANGELOG.md
```

## Standards

- ADR-001: workflows are self-contained
- ADR-002: embedded templates use the XML embedding architecture
- Workflow docs should default to `ace-bundle` loading, not skill chaining
- Skill references belong in provider-agent and `ace-assign` discovery contexts

## Development

After checking out the repo, run:

```bash
bundle install
```

To inspect handbook workflows during development:

```bash
mise exec -- ace-bundle wfi://handbook/manage-workflows
mise exec -- ace-bundle wfi://handbook/review-workflows
```

## License

The gem is available as open source under the terms of the MIT License.
