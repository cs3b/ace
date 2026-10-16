<div align="center">
  <h1> ACE - Design </h1>

  Fast interactive design directions for websites and web applications, with production handoff and browser evidence.

  <img src="../docs/brand/AgenticCodingEnvironment.Logo.XS.jpg" alt="ACE Logo" width="480">
  <br><br>

  <a href="https://rubygems.org/gems/ace-design"><img alt="Gem Version" src="https://img.shields.io/gem/v/ace-design.svg" /></a>
  <a href="https://www.ruby-lang.org"><img alt="Ruby" src="https://img.shields.io/badge/Ruby-3.2+-CC342D?logo=ruby" /></a>
  <a href="https://opensource.org/licenses/MIT"><img alt="License: MIT" src="https://img.shields.io/badge/License-MIT-blue.svg" /></a>

</div>

> Works with: Claude Code, Codex CLI, OpenCode, Gemini CLI, pi-agent, and more.

[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md)

`ace-design` turns a short brief into three comparable, interactive design directions, then carries the selected direction into production engineering. Sessions, gallery preview, targeted revision, pinned Playwright/axe inspection and the preset catalog are owned by the `ace-design` CLI; skills and workflow instructions guide the agent conversation around it. Each direction runs in its own coding agent through [ace-llm](../ace-llm), with concurrency controlled by the design preset.

## How It Works

1. **Choose an intent** — `explore` generates new directions from a brief, `recreate --from SOURCE` faithfully reproduces a source, and `reimagine --from SOURCE` replaces appearance while keeping function. Sources are images, URLs or earlier session variants. Every command creates an immutable session under `.ace-local/design/<token>/` with one shared fixture and one coding worker per variant.
2. **Compare and revise** — `status` shows worker progress, `preview` serves a loopback gallery of ready variants, and `revise --variant b --prompt "…"` replaces only that variant across feedback rounds. `select` binds the choice to both artifact and fixture hashes.
3. **Engineer and verify** — `/as-design-site-implement` and `/as-design-app-implement` start production work from an explicit selection; `/as-design-site-audit` and `/as-design-app-audit` report browser and source evidence. `inspect` captures pinned Playwright screenshots and axe findings at three viewports; `doctor` reports browser runtime readiness.
4. **Personalize with profiles** — `profile adjust/show/refresh` keeps inherited project design assumptions in `.ace-config/design/` and freezes them into every session.

## External design skillsets

The preset catalog integrates four popular outside design skillsets alongside ACE's native `fast` process. Every preset is a ready-to-use process selected with `--preset`; original skill repositories are pinned to full commits and frozen per session, with no instructions rewritten.

| Preset | Skillset | Scope | Requires |
| --- | --- | --- | --- |
| `impeccable` | Impeccable | Site/app, view/component, explore/recreate/reimagine | Its launcher and rendered browser checks |
| `taste-v2` | Taste v2 | Site views, explore/reimagine (upstream excludes app UI) | Node.js, browser and image tools |
| `ui-ux-pro-max` | UI UX Pro Max | Site/app, view/component, explore/recreate/reimagine | Python 3, rendered browser verification |
| `superdesign` | Superdesign | Site/app canvas via its CLI, explore/recreate/reimagine | Node.js, Superdesign service access |
| `ace-vs-taste` | ACE fast vs Taste v2 | Comparison: three ACE directions plus one original Taste v2 direction | Node.js, browser and image tools |

```sh
ace-design preset list
ace-design preset show taste-v2
ace-design explore --surface site --preset taste-v2 --prompt "Our product page"
```

External workers follow the original skill's required checks and stack choices — the workflow is not shortened to ACE fast mode — and can emit HTML, image or URL artifacts. A slot of any preset can also mix skillsets through an explicit variants file (`--preset path.yml`). All four integrations are `candidate`: upstream instructions were inspected, and complete ACE integration smoke is still pending — see [the runner catalog contract](docs/runner.md#choose-a-preset).

## Use Cases

**Compare real directions before committing** - run `/as-design-site` or `/as-design-app` to get three interactive mockups sharing one dataset, then pick with evidence instead of static images.

**Run an outside skillset against ACE's process** - use `--preset ace-vs-taste` or a single external preset to compare how Impeccable, Taste v2, UI UX Pro Max or Superdesign approach the same brief under the same session contract.

**Turn a selected mockup into production work** - start `/as-design-site-implement` or `/as-design-app-implement` from a hash-bound selection, then verify results with `/as-design-site-audit` and `inspect`.

**Keep project design decisions consistent** - use `/as-design-site-adjust` and `/as-design-app-adjust` to record team and user preferences once, and let every session inherit them as frozen assumptions.

**Feed a reviewed improvement back into the process** - use `/as-design-look-for-inspiration` to research contextual cards and prepare a tested package change for review.

## Testing Contract

Package tests make no network or model calls; missing browser dependencies are a failure, not a skipped pass.

```bash
ace-test ace-design       # deterministic fast lane (test/fast)
ace-test ace-design all   # fast plus real Node/browser feature tests (test/feat)
```

The feature lane provisions an isolated browser cache; setup steps are in [Getting Started](docs/getting-started.md#browser-runtime). Verification details live in [docs/testing.md](docs/testing.md).

---
[Getting Started](docs/getting-started.md) | [Usage Guide](docs/usage.md) | [Handbook - Skills, Agents, Templates](docs/handbook.md) | Part of [ACE](https://github.com/cs3b/ace)
