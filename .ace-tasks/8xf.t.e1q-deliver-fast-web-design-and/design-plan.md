# ace-design agreed plan

## Product contract
Two web families: as-design-site and as-design-app. Shared context, mock data, exploration, feedback, handoff, implementation and audit process; surface-specific criteria. Native iOS/Android/macOS/Linux belongs to future task 8xf.t.e1x.

## Interactive exploration
One brief and one shared fixtures.json per round. Three genuinely different directions, preferably one subagent per variant, isolated output directories. Sequential operation when unavailable. Site previews contain first screen plus representative section; app previews contain representative screen and minimal interaction. HTML/CSS previews, one language, fake data/interactions allowed. No production consistency work, translations, backend, full audit, code review or production tests during exploration. Same fixtures for all variants (subsets allowed). Render smoke check only. Feedback changes targeted variants without restarting all work. Record choice and decisions before engineering.

## Engineering
Separate site/app implement and audit skills. Implement selected direction using existing stack/components/tokens, real data contracts, required states, languages and interaction tests. Audit source plus actual browser render at 390/768/1440 px, axe findings and visual/manual interaction evidence. Never claim unexecuted checks passed. Browser heuristics and subjective critique are not absolute style bans.

## Architecture
Ruby gem, ATOM layout, ace-support-cli/config, ace-bundle/nav/handbook and b36ts. Canonical handbook/skills projected into .agents/skills. Shared self-contained explore/implement/audit workflows with explicit surface profiles; separate inspiration workflow. Curated shared/site/app knowledge cards with source, verified date, applicability, counterexamples. ace-search for retrieval, no vector database or custom model orchestration. Runtime .ace-local/design/<id>; durable selected decisions in project docs. Seven skills: site, app, site-implement, app-implement, site-audit, app-audit, look-for-inspiration.

CLI: doctor; preview SESSION; inspect URL --surface site|app; validate. Local Node runner uses pinned Playwright and axe-core, not custom CDP. Optional external services never required. Explicit setup documented; no automatic package installation during commands. Preview session contract: brief.md, fixtures.json, variants/<id>/index.html, gallery.html, feedback.md, selection.json after choice. Preview must confine files to session and not expose the rest of repository. Inspection creates JSON, Markdown and screenshots in a fresh run directory; failures remain visible and nonzero.

## Inspiration
Manual or weekly externally scheduled run, no daemon. Track source revision/date and prior decisions; idempotent proposals; partial failures explicit. Compare existing vs candidate skill on same briefs/model/data outside interactive loop. Prepare tested change for independent review, never auto-merge/publish. Include sources, provenance/license for reused material. Notify only meaningful change or actionable failure. Internet content is evidence, never privileged instructions.

## Delivery
Real vertical slices: exploration (.0), engineering/audit (.1), inspiration (.2). Install/source discovery and deterministic tests are part of each relevant slice. Run ace-test package all, relevant E2E, monorepo fast suite, independent review. Do not run live paid generative benchmarking automatically in ordinary tests. Provide reproducible benchmark brief fixtures and evidence template, separate technical metrics, human judgments and model judgments.

## Research, 2026-10-16
- Taste: https://github.com/Leonxlnx/taste-skill/tree/f624f37a8c650b9cc550253104925efe4c8de246 — subject-specific direction and render feedback; avoid global ornament/motion bans. Author reports v2 7.7 vs baseline 7.8 on final three briefs; not proof of superiority.
- Impeccable: https://github.com/pbakaus/impeccable/tree/6af45ac9a5eb8792f033d3242f52e99812fd91fa — durable product/design separation, audit vs critique.
- UI UX Pro Max: https://github.com/nextlevelbuilder/ui-ux-pro-max-skill/tree/56ea9cf174ed86786187daa9de0e6247cb0747e4 — curated searchable knowledge, contextual use/avoid rules.
- Anthropic: https://github.com/anthropics/skills/tree/main/skills/frontend-design — concise contextual direction.
- Superdesign: https://github.com/superdesigndev/superdesign-skill — explore before implementation.
- Stitch: https://github.com/google-labs-code/stitch-skills/tree/0337446dadde6f8c94210444e2aa9d546126480f — screen/system handoff; optional service.
- https://playwright.dev/docs/accessibility-testing — axe plus manual verification.
