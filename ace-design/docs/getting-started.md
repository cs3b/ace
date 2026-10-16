---
doc-type: user
title: Getting Started with ace-design
purpose: Installation, skill registration, first session and browser runtime setup
ace-docs:
  last-updated: 2026-10-16
  last-checked: 2026-10-16
---

# Getting Started with ace-design

`ace-design` generates interactive design directions for sites and web applications, serves them in a local gallery, and carries the selected direction into production engineering with browser evidence.

## Prerequisites

- Ruby 3.2+
- A configured coding CLI with credentials (Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and similar) — exploration workers are agent-capable CLIs through [ace-llm](../../ace-llm); API-only text models are not supported as primary workers
- Node.js 22.12+ for preview (no npm packages needed) and for browser inspection (see [Browser runtime](#browser-runtime))
- For skills: [ace-handbook](../../ace-handbook) with [ace-bundle](../../ace-bundle)

## Installation

From RubyGems:

```bash
gem install ace-design
```

In this monorepo the gem is not installed; use the binstubs instead:

```bash
bundle install
bin/ace-design --help
```

## Register the skills in your project

Canonical sources ship in `handbook/skills`; generated skills belong in `.agents/skills`. Register the installed gem explicitly at `.ace/nav/protocols/skill-sources/ace-design.yml`:

```yaml
name: ace-design
type: gem
description: Design skill resources
priority: 10
config:
  relative_path: handbook/skills
  pattern: "*/SKILL.md"
  enabled: true
```

Then sync the skills to your harness:

```bash
ace-handbook sync                        # neutral projection to .agents/skills/
ace-handbook sync --provider claude      # or codex, gemini, opencode, pi
ace-handbook status --provider codex     # verify projection coverage
```

The synced skill set is identical across harnesses; invoke `/as-design-site`, `/as-design-app` and the other `/as-design-*` skills as usual in your agent CLI. In this checkout use `bundle exec ace-handbook sync --provider agents` (no handbook binstub is committed).

The package also ships protocol registrations for `wfi://design/*`, `guide://design/process` and `tmpl://design/*`, resolvable through `ace-bundle`.

## Your first design session

```sh
ace-design explore --surface app --prompt "Customer support workspace" \
  --preset fast \
  --variant-prompt 'a=Fast, keyboard-friendly queue' \
  --variant-prompt 'b=Prominent customer history' \
  --variant-prompt 'c=Calm overview'
ace-design status .ace-local/design/SESSION
ace-design preview .ace-local/design/SESSION     # loopback gallery, Ctrl-C stops
ace-design revise .ace-local/design/SESSION --variant b --prompt "Reduce density"
ace-design select .ace-local/design/SESSION --variant b --decision "Keep split layout"
```

- Sessions live at `.ace-local/design/<base36-token>/` and contain all variants, the shared fixture, gallery, feedback and selection. Tokens come from `ace-b36ts encode --format ms`.
- `preview` binds only `127.0.0.1` and prints a free port by default. The gallery reflects saved progress, not worker liveness; after a crash use `status` and explicitly `resume`.
- `--kind view|component` selects a representative screen or a component host; `--profile app/component/data-table` selects a named project context (see [contexts and adjustment](contexts.md)).
- `--dry-run` resolves inputs without models or a session; `--json` returns structured output. Exit 0 means success or a valid dry-run, 1 invalid inputs, 2 incomplete execution. Ctrl-C preserves completed results.
- To try an external skillset, add `--preset taste-v2`, `--preset impeccable`, `--preset ui-ux-pro-max`, `--preset superdesign` or the comparison preset `--preset ace-vs-taste`. See [External design skillsets](../README.md#external-design-skillsets) and [the runner preset contract](runner.md#choose-a-preset).

Continue with `/as-design-app-implement` (or the site equivalent) for production engineering, or `/as-design-site-audit` for review. The full session and feedback contract is in [usage.md](usage.md).

## Browser runtime

`inspect` uses a separate pinned Playwright/Chromium runtime. From this checkout:

```sh
mkdir -p .ace-local/design/runtime
cp ace-design/browser/package.json ace-design/browser/package-lock.json .ace-local/design/runtime/
npm ci --ignore-scripts --prefix .ace-local/design/runtime
npx --prefix .ace-local/design/runtime playwright install chromium
bin/ace-design doctor
```

For an installed gem, `ace-design doctor` reports `manifest_dir` and `runtime_dir`; copy `package.json` and `package-lock.json` from the manifest directory into the runtime directory, run `npm ci` there, and install Chromium with the local Playwright command. Linux hosts may additionally require Playwright system dependencies. Dependencies are pinned; mismatched versions fail explicitly.

## Configuration

The standard ACE cascade applies through `.ace/design/config.yml`:

```yaml
design:
  node: node
  runtime_dir: .ace-local/design/runtime
  run_root: .ace-local/design
  timeout: 45
```

`timeout` is 1–300 seconds per viewport; the parent bounds the complete run. Runtime and run paths are relative to the invoking working directory. Preset overrides live in `.ace/design/presets/NAME.yml`; `--preset path.yml` accepts an explicit experiment file. Precedence and custom presets are covered in [runner.md](runner.md#configuration-and-precedence).

## Next steps

- [Usage Guide](usage.md) — session, feedback, selection and inspection contracts
- [Runner](runner.md) — intents, presets, models, prompts and lifecycle
- [Contexts](contexts.md) — project design profiles
- [Inspiration](inspiration.md) — inspiration sources and the weekly prompt
- [Handbook reference](handbook.md) — skills, workflows, templates and curated cards
