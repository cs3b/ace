# ace-design

Fast interactive design directions for websites and web applications, followed by production engineering and evidence-based review.

## Skills

| Skill | Outcome |
| --- | --- |
| `/as-design-site` | Three lightweight website directions using one shared fixture |
| `/as-design-app` | Three lightweight web application directions using one shared fixture |
| `/as-design-site-adjust` / `/as-design-app-adjust` | Personalize and refresh inherited project design assumptions |
| `/as-design-site-implement` | Production site implementation from an explicit selection |
| `/as-design-app-implement` | Production app implementation from an explicit selection |
| `/as-design-site-audit` | Site audit with explicit browser/source coverage |
| `/as-design-app-audit` | App audit with explicit browser/source coverage |
| `/as-design-look-for-inspiration` | A researched, tested change prepared for review |

Mockup sessions live at `.ace-local/design/<base36-token>/`, using `ace-b36ts encode --format ms`. The session directory contains all variants, shared fixtures, gallery, feedback and selection. Gallery refresh reflects saved progress, not worker liveness; after a crash use `status` and explicitly `resume`. Embedded variants run without same-origin access to the gallery; the preview server exposes public mockup assets with CORS so shared-fixture requests still work. This is parent-page isolation, not a network security sandbox.

Explore → compare A/B/C → targeted feedback → select → engineer → verify. Exploration uses one language, mock data and minimal HTML/CSS/JS. Each direction runs in its own coding agent through ace-llm, with concurrency controlled by the design preset. Full review, real integrations, translations and production tests start after selection. Native platforms are intentionally separate future work.

## Install and discover

The source package is not yet published. In this monorepo use `bundle install` and `bin/ace-design`. After publication, consumers can install `ace-design`, plus `ace-handbook` and `ace-bundle` for skills, and `ace-search` for knowledge retrieval. Runtime CLI depends only on its declared Ruby dependencies and Node for preview/browser work.

Register installed skills explicitly in the consuming project at `.ace/nav/protocols/skill-sources/ace-design.yml`:

```yaml
name: ace-design
type: gem
priority: 10
config:
  relative_path: handbook/skills
  pattern: "*/SKILL.md"
  enabled: true
```

Then run `ace-handbook sync --provider agents`. Canonical sources ship in `handbook/skills`; generated skills belong in `.agents/skills`. The package also ships protocol registrations for `wfi://design/*`, `guide://design/process` and `tmpl://design/*`. In this checkout use `bundle exec ace-handbook sync --provider agents` (no handbook binstub is committed).

## Project assumptions

Use `ace-design profile adjust --surface app --prompt "Keep routine actions visible"` to create inherited project contexts in `.ace-config/design/`. Each context has defaults.md, user.md and effective design.md. `profile refresh` brings in installed library changes without rewriting user decisions. `ace-design profile show --surface app --kind component` reads the effective assumptions. See [contexts and adjustment](docs/contexts.md) for named scopes, conflicts, dry-run and recovery.

## Generate and iterate

```sh
bin/ace-design explore --surface app --prompt "Customer support workspace" \
  --preset fast --input docs/product.md \
  --variant-prompt 'a=Fast, keyboard-friendly queue' \
  --variant-prompt 'b=Prominent customer history' \
  --variant-prompt 'c=Calm overview'
bin/ace-design status .ace-local/design/SESSION
bin/ace-design preview .ace-local/design/SESSION
bin/ace-design revise .ace-local/design/SESSION --variant b --prompt "Reduce density"
bin/ace-design select .ace-local/design/SESSION --variant b --decision "Keep split layout"
```

`--kind view|component` selects a representative screen or a component in a minimal interactive host. `--profile app/component/data-table` selects a named project context; generation freezes its effective assumptions for every worker and later revision.

Commands return concise text by default; `--json` returns structured output. `--dry-run` resolves inputs without models or a session. `resume SESSION` retries unfinished workers. Exit 0 means success or a valid dry-run, 1 means invalid inputs/configuration, and 2 means incomplete execution. Ctrl-C preserves completed results and records interruption.

Default `fast` has three slots and concurrency three. Model selection defaults to `role:assign-engineer`, respecting the existing ace-llm configuration and execution policies. It requires a configured coding CLI and credentials. Use design `model`, `--model`, or per-slot selectors to customize it. This is an agent-capable CLI workflow; API-only text models are not supported as primary workers.

Preparation creates one shared dataset and differentiated briefs; `--fixtures FILE` preserves supplied JSON bytes instead. Explicit `--input` references are rendered once through ace-bundle with commands and model compression disabled. There is no implicit full-project bundle. `--language` chooses one language (default `en`). Only successful, validated worker artifacts are published; failed revisions keep the previous mockup. Browser inspection remains an explicit later step.

See [runner configuration and lifecycle](docs/runner.md) for custom variants, model assignments, extra prompts, evidence and recovery.

## Local commands

```sh
bin/ace-design --help
bin/ace-design validate
bin/ace-design validate .ace-local/design/8xff3p3z
bin/ace-design preview .ace-local/design/8xff3p3z --port 0
bin/ace-design doctor
bin/ace-design inspect http://127.0.0.1:3000 --surface app --out .ace-local/design/check-1
```

Use unprefixed commands for an installed consumer outside this monorepo. Preview binds only `127.0.0.1`, prints a free port by default, serves session assets and stops on Ctrl-C. It needs Node 22+, but no npm packages or Playwright. Browser inspection needs the separate pinned runtime below. The explore/recreate/reimagine/revise commands launch coding agents through ace-llm. Skills guide the brief, variant-specific prompts, feedback and engineering handoff; the runner owns repeatable execution and artifacts.

Inspection returns 0 for clean automatic checks, 1 for findings and 2 for incomplete execution. Invalid inspect input also returns an error; no existing evidence is overwritten. Other commands return 0 on success and nonzero on error. `doctor` is read-only and reports missing setup. A clean report does not establish full accessibility, task completion, visual quality, performance or source correctness.

## Browser setup

From this checkout:

```sh
mkdir -p .ace-local/design/runtime
cp ace-design/browser/package.json ace-design/browser/package-lock.json .ace-local/design/runtime/
npm ci --ignore-scripts --prefix .ace-local/design/runtime
npx --prefix .ace-local/design/runtime playwright install chromium
bin/ace-design doctor
```

For an installed gem, `ace-design doctor` reports `manifest_dir` and `runtime_dir`; copy package.json and package-lock.json from the reported manifest directory to the runtime directory, run npm ci there, and install Chromium there with the local Playwright command. Node 22.12+ is required for inspection. Linux hosts may additionally require Playwright system dependencies. Dependencies are pinned; mismatched versions fail explicitly.

Configuration follows the standard ACE cascade in `.ace/design/config.yml`:

```yaml
design:
  node: node
  runtime_dir: .ace-local/design/runtime
  run_root: .ace-local/design
  timeout: 45
```

Timeout is 1–300 seconds per viewport; the parent bounds the complete run. Runtime/run paths are relative to the invoking working directory. Inspect uses 390, 768 and 1440 pixel viewports, screenshots, axe WCAG-tagged checks, document overflow, image loading and JavaScript/page-load errors. It saves JSON and Markdown with coverage limitations. Image checks observe a bounded loading window: an image still loading is a finding, not proof of a permanently broken asset. A timed-out browser operation may leave partial screenshots; only artifacts listed in the final report are evidence. It has no authenticated-session injection: use an accessible local/test URL or report inaccessible states and verify them separately with an authorized browser session.

## More

- [Session and feedback contract](docs/usage.md)
- [Inspiration sources and weekly prompt](docs/inspiration.md)
- [Verification and benchmark protocol](docs/testing.md)
- [Shared workflows](handbook/workflow-instructions/design/)
- [Curated cards](handbook/catalog/)

## Intent and presets

Use `explore` for new directions, `recreate --from SOURCE` for faithful reproduction, and `reimagine --from SOURCE` for a different appearance with the same functions. Sources can be images, URLs or session variants. `preset list` and `preset show NAME` expose original external skills and comparison presets, requirements and verification evidence. See [runner](docs/runner.md). `--dry-run` is model-free and creates no session; `--json` gives machine-readable results.
