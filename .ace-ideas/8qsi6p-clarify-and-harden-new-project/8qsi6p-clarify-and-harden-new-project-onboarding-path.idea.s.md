---
id: 8qsi6p
status: pending
title: Clarify and harden new-project onboarding path
tags: [dx, onboarding, docs, ace-framework, ace-handbook, ace-llm, ace-assign]
created_at: "2026-03-29 12:07:28"
---

# Clarify and harden the new-project onboarding path

A real first-run setup in a fresh non-gem project exposed avoidable friction across installation, initialization, documentation, generated config quality, provider setup, handbook extensibility, and assignment defaults. ACE is powerful once configured, but the golden path is not discoverable enough and several generated/project-level defaults do not work out of the box.

This should be treated as a cross-package DX improvement initiative aimed at making a brand-new project reach a working baseline with a small, documented sequence and without manual repo archaeology.

Priority map:
- Critical: document the golden path in README and quick-start; make `ace-framework init` generate working generic presets/config; make `work-on-task` usable without missing `wfi://release/publish` failures.
- High: provide a clear Gemfile/install snippet and investigate fresh-install dependency resolution behavior; improve provider error guidance and add discoverable provider/config documentation; document `ace-handbook sync` ordering and warn on partial sync.
- Medium: document how project-specific handbook skills and workflow instructions should be added and synced; replace ACE-monorepo-specific scaffold content with placeholders or prompts tailored to the target project.

Improvement themes:
- Install/bootstrap: reduce fresh install breakage and document required ordering from `bundle install` to init to handbook sync.
- Getting started docs: add copy-paste setup steps, mention `ace-framework init` and `ace-handbook sync` as steps 1-2, and show first commands to try afterward.
- Generated templates: fix bundle preset schema, stop emitting invalid `ace-taskflow` commands, and avoid monorepo-specific text in project scaffolds.
- LLM/provider UX: explain supported providers, required env vars, and next steps directly in error output; add a discoverable providers/config reference.
- Handbook/project extension: explain where project skills live, how sync discovers them, and how `wfi://`, `guide://`, `tmpl://`, and `skill://` should be used in non-monorepo projects.
- Assignment/workflow safety: ship a generic `release/publish` workflow or make release-related preset steps optional, and unify WFI resolution behavior with nav configuration.

Expected outcomes:
- A new project can get to a working ACE baseline through a short documented flow.
- Generated files are generic, valid, and runnable immediately.
- Provider setup failures guide users toward resolution instead of crashing opaquely.
- Custom handbook/project workflow extension points are documented clearly enough for first-time use.
- Assignment presets degrade safely when optional workflows are absent.

Use the attached raw feedback as the source artifact when splitting this into concrete package tasks.
