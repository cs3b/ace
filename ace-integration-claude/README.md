# ACE Integration Claude Gem

Legacy Claude integration package for ACE. This package remains useful for historical and maintenance contexts, but the active provider-specific replacement is `ace-handbook-integration-claude`.

## Status

- Replacement package: `ace-handbook-integration-claude`
- Canonical skill ownership: package-local `handbook/skills/`
- Shared projection and sync runtime: `ace-handbook`

Use this README as a compatibility reference, not as the primary onboarding surface for new Claude integration work.

## Usage

Load the integration workflow directly with `ace-bundle`:

```bash
ace-bundle wfi://integration/update-claude
```

Use `ace-nav` only when you need discovery or the resolved path:

```bash
ace-nav wfi://integration/update-claude
```

## What This Package Contains

- Claude-specific workflow instructions under `handbook/workflow-instructions/`
- Integration assets under `integrations/claude/`
- Legacy command and template packaging for Claude-facing surfaces

## Current Model

ACE now separates the layers this way:

1. Canonical workflows are consumed through `ace-bundle wfi://...`
2. Canonical skill definitions live in the owning package under `handbook/skills/`
3. Provider packages project those skills into provider-native folders such as `.claude/skills/`
4. `ace-assign` may discover assignment-capable skills through that canonical skill inventory

That means generic markdown docs should not route users through skills; skill references in this package are intentionally provider-specific.

## Migration Guidance

For new Claude integration work:

```bash
mise exec -- ace-bundle wfi://integration/update-claude
```

Then prefer the newer provider package docs in `ace-handbook-integration-claude` for current ownership boundaries and runtime behavior.

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

## License

The gem is available as open source under the terms of the MIT License.
