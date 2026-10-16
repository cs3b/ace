---
doc-type: user
title: ace-design Handbook Reference
purpose: Skills, workflow instructions, templates, curated cards and benchmarks shipped by ace-design
ace-docs:
  last-updated: 2026-10-16
  last-checked: 2026-10-16
---

# ace-design Handbook Reference

## Skills

| Skill | What it does |
|-------|-------------|
| `as-design-site` | Generate preset-driven design variants with shared mock data for a web site |
| `as-design-app` | Generate preset-driven design variants with shared mock data for a web application |
| `as-design-site-adjust` | Personalize and refresh inherited project design assumptions for sites |
| `as-design-app-adjust` | Personalize and refresh inherited project design assumptions for apps |
| `as-design-site-implement` | Production site implementation from an explicit selection |
| `as-design-app-implement` | Production app implementation from an explicit selection |
| `as-design-site-audit` | Site audit with explicit browser/source coverage |
| `as-design-app-audit` | App audit with explicit browser/source coverage |
| `as-design-look-for-inspiration` | Research design evidence and prepare a tested package change for review |

## Workflow Instructions

| Protocol | Purpose |
|----------|---------|
| `wfi://design/explore` | Direction exploration with shared fixture and per-variant briefs |
| `wfi://design/adjust` | Project design assumption adjustment and refresh |
| `wfi://design/audit` | Browser/source evidence audit for a URL or project |
| `wfi://design/implement` | Production engineering handoff from a selected direction |
| `wfi://design/look-for-inspiration` | Inspiration-to-reviewed-change workflow |

## Guide

| Protocol | Purpose |
|----------|---------|
| `guide://design/process` | The shared explore → compare → feedback → select → engineer → verify process |

## Templates

| Template | Purpose |
|----------|---------|
| `tmpl://design/brief` | Session brief: audience, action, constraints, A/B/C composition |
| `tmpl://design/feedback` | Append-only feedback rounds |
| `tmpl://design/proposal` | Inspiration proposal for a tested package change |
| `tmpl://design/benchmark-result` | Benchmark brief/fixture comparison result |
| `tmpl://design/source-ledger` | Source capture provenance for recreate/reimagine |

## Curated cards and benchmarks

- Catalog cards in `handbook/catalog/` — `site/` (hero, links, critique), `app/` (task-first density, status feedback, error recovery) and `shared/` (context before style, bounded exploration, focus visible, responsive reflow, a11y boundary).
- Six benchmark brief/fixture pairs in `handbook/benchmarks/` for comparing presets and external skillsets; pass the brief as the prompt and the JSON through `--fixtures`.

## Source Paths

- Skills: `ace-design/handbook/skills`
- Workflow instructions: `ace-design/handbook/workflow-instructions/design`
- Guide: `ace-design/handbook/guides/design`
- Templates: `ace-design/handbook/templates/design`
- Catalog cards: `ace-design/handbook/catalog`
- Benchmarks: `ace-design/handbook/benchmarks`
