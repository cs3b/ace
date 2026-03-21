# ace-bundle Handbook Reference

Skills, workflows, and presets shipped with ace-bundle.

## Skills

| Skill | What it does |
|-------|-------------|
| `as-bundle` | Load project context from preset names, file paths, or protocol URLs |
| `as-onboard` | Load full project context bundle for onboarding to the codebase |

## Workflow Instructions

| Protocol Path | Description | Invoked by |
|--------------|-------------|------------|
| `wfi://bundle` | Load context from presets, files, or protocols with auto-detection | `as-bundle` |
| `wfi://onboard` | Run preset, read output, summarize project state | `as-onboard` |

## Built-in Presets

ace-bundle ships 11 default presets in `.ace-defaults/bundle/presets/`. Override or extend via `.ace/bundle/presets/`.

### Core Presets

| Preset | Description |
|--------|-------------|
| `base` | Minimal context: README.md, CHANGELOG.md |
| `project` | Full project context: docs, git status, architecture, tasks |
| `project-base` | Lightweight onboarding context |
| `development` | Extends base with architecture, blueprint, git info |
| `team` | Extends development with 120s timeout, decision docs |

### Review Presets

| Preset | Description |
|--------|-------------|
| `code-review` | XML-formatted: files, style, diff, tests, project context |
| `security-review` | XML-formatted: vulnerabilities, secrets, dependencies, policies |
| `documentation-review` | XML-formatted: content, style, structure, validation |

### Composition Examples

| Preset | Description |
|--------|-------------|
| `project-context` | Demonstrates preset-in-section: combines base/development/testing |
| `simple-project` | Simple preset-in-section: project files + testing |
| `section-example-simple` | Basic section usage: main files + system info |
| `mixed-content-example` | Advanced: combines review presets with files, commands, diffs |
