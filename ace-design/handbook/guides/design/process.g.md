---
doc-type: guide
title: Design stages and evidence
purpose: Explain the shared site/app design process
ace-docs:
  last-updated: 2026-10-16
  last-checked: 2026-10-16
---

# Design stages and evidence

Exploration selects direction quickly: one brief, one fixture, three default variants, one language, targeted feedback. The ace-design runner launches one coding agent per declared preset slot, with a separate workspace and optional caller-supplied prompt. Use explore, recreate or reimagine to start a session, then revise, status, resume and select through the CLI; do not duplicate orchestration in the calling skill. Render once to catch an unusable preview; defer full reviews and production integrations.

Selection is an explicit user decision. A fixture hash binds that decision to the data seen during comparison. `ace-design validate SESSION` checks artifact structure and selection integrity; it cannot prove semantic distinctness or enforce how arbitrary JavaScript uses data. The coordinator must verify those obligations.

Engineering then uses the real project stack, data, required languages, states, tests and independent review. Browser inspection reports automatic evidence and manual gaps separately. Clean automatic checks do not certify accessibility or visual quality.

Inspiration changes are tested proposals. They do not become universal style rules and do not automatically update installed skills. Native platforms are a separate future family.

Project assumptions live in inherited `.ace-config/design/` contexts, each with defaults.md, user.md and effective design.md. The adjust skills refresh installed defaults and preserve explicit user decisions; normal generation uses a frozen effective snapshot. Views and components have distinct assumptions and output scopes. See `wfi://design/adjust`.
