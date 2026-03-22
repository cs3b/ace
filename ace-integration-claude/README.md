---
doc-type: user
title: ace-integration-claude
purpose: Documentation for ace-integration-claude/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-integration-claude

Claude Code integration workflows and templates for ACE.

## Purpose

`ace-integration-claude` is a legacy integration package kept for compatibility and maintenance
history. New provider integration work should target `ace-handbook-integration-claude`.

## Status

- Replacement package: `ace-handbook-integration-claude`
- Canonical skill ownership: package-local `handbook/skills/`
- Shared projection and sync runtime: `ace-handbook`

Use this README as a compatibility reference, not as the primary onboarding surface for new Claude
integration work.

## Installation

Add to your Gemfile:

```ruby
gem "ace-integration-claude"
```

Or install directly:

```bash
gem install ace-integration-claude
```

## Usage

Load the integration workflow directly with `ace-bundle`:

```bash
mise exec -- ace-bundle wfi://integration/update-claude
```

Use `ace-nav` only when you need discovery or the resolved path:

```bash
mise exec -- ace-nav wfi://integration/update-claude
```

## Integration Assets

- Claude-specific workflow instructions under `handbook/workflow-instructions/`
- Integration assets under `integrations/claude/`
- Legacy command and template packaging for Claude-facing surfaces

## Architecture

This is a pure integration package with no CLI interface. It provides Claude-facing integration
assets while relying on shared runtime behavior from other ACE packages.

## Current Model

ACE now separates the layers this way:

1. Canonical workflows are consumed through `ace-bundle wfi://...`
2. Canonical skill definitions live in the owning package under `handbook/skills/`
3. Provider packages project those skills into provider-native folders such as `.claude/skills/`
4. `ace-assign` may discover assignment-capable skills through that canonical skill inventory

That means generic markdown docs should not route users through skills; skill references in this
package are intentionally provider-specific.

## Integration Setup

For maintenance or migration checks, run the integration workflow:

```bash
mise exec -- ace-bundle wfi://integration/update-claude
```

Then prefer the newer provider package docs in `ace-handbook-integration-claude` for current
ownership boundaries and runtime behavior.

## File Structure

```text
ace-integration-claude/
├── handbook/workflow-instructions/
│   └── integration/
├── integrations/claude/
├── lib/
├── README.md
└── CHANGELOG.md
```

## Standards

- [ADR-001: Workflow self-containment](../docs/decisions.md#workflow-self-containment)
- [ADR-002: XML template embedding](../docs/decisions.md#xml-template-embedding)

## Part of ACE

Part of [ACE](../README.md) - Modular CLI toolkit for AI-assisted development.

## License

The gem is available as open source under the terms of the MIT License.
