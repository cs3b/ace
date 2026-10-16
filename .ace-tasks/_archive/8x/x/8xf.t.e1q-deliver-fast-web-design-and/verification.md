# ace-design delivery verification

## Delivered behavior

- Seven canonical source skills and generated `.agents/skills` projections: site/app explore, implement and audit, plus inspiration maintenance.
- One shared exploration workflow: immutable shared fixture, three disjoint variant workers, partial-result gallery, one language and mocked interactions, targeted feedback, explicit hash-bound selection before engineering.
- Production workflow requires actual project data/languages/states, executed tests, browser/manual evidence and independent code review. Audit distinguishes source, automatic and manual coverage.
- Local Ruby CLI: doctor, preview, inspect and validate. Node preview needs no npm dependencies; separate locked Playwright/axe runtime produces 390/768/1440px evidence with clean/findings/incomplete outcomes.
- Twelve contextual knowledge cards, six reproducible benchmark inputs, provenance and a weekly-compatible inspiration workflow that prepares reviewable changes without auto-merge/publish.
- Native scope remains draft `8xf.t.e1x`.

## Executed package checks

`bin/ace-test ace-design all` after the final review corrections: **28 tests, 180 assertions, zero failures/errors/skips**, 9.05 seconds.

Report: `.ace-local/test/reports/design/b25f66e7-f9ea-4392-a757-c921a30b621a/`.

Includes real Node server confinement, real Chromium/axe good/broken/unavailable pages, viewport switching in the gallery, missing/mismatched dependency diagnostics, timeout process termination, preservation of evidence on cleanup errors, dangling links, output collision prevention, installed CLI errors/config cascade, and isolated gem installation/protocol discovery/skill projection. Installed checks include guide and all five template protocol resolutions.

`bin/ace-design doctor`: ready, Node v25.2.1, Playwright 1.64.1, axe-core/playwright 4.14.0. `bin/ace-design validate`: 12 cards, zero errors. Source `ace-bundle wfi://design/explore`, template and guide resolution succeeded. `bundle exec ace-handbook sync --provider agents` projected all seven design skills.

## Executed interactive smoke

Three subagents each produced one direction for both `site-course` and `app-support` initially under the smoke fixture directory, then moved to the requested Base36 session paths: site `.ace-local/design/8xff3p3z/` and app `.ace-local/design/8xff3p40/`. Actual browser rendering verified all six load the shared record without JavaScript errors. A/B/C visually differ in hierarchy/composition (site schedule/editorial/outcome; app queue/split detail/board). Each demonstrated a local button interaction with a visible response.

A simulated feedback round requested a less dense B while keeping its hierarchy. File hashes proved that only B index.html and direction.md changed in each session; A/C and fixture bytes stayed identical. Both sessions validate. No real user selection was invented; smoke feedback is explicitly labeled simulated. Gallery screenshots were inspected and led to aligned scaled previews, a width selector and collapsed notes.

Local evidence: `.ace-local/design/smoke/{render-evidence,interaction-evidence,before-feedback,feedback-evidence}.json`, session feedback.md and gallery.png files in the Base36 directories (mapping: `.ace-local/design/smoke/session-paths.json`). This is a functional smoke exercise, not a measured baseline/candidate aesthetic benchmark. The full six-brief comparative benchmark remains a protocol for future inspiration proposals, not a claimed result.

Inspiration branches were manually walked through with simulated source observations; see `inspiration-walkthrough.md`. No scheduler was activated and no external service is mandatory.

## Independent review

Full code review: `.ace-local/review/sessions/review-8xfera/review-report-review-default.md`, verdict **approve with minor fixes**, no high/critical findings.

- F1 dangling symlinks: fixed with actionable domain errors and regressions.
- F2 same-second output collision: fixed with a unique suffix and fixed-clock regression.
- F3 browser cleanup failure suppressing evidence: fixed; incomplete report is preserved and tested through a browser dependency boundary.
- F4 missing script claimed to raise Ruby ENOENT: rejected after verification. A missing script is a child-process error with stderr/nonzero exit, not a missing executable; regression added.
- Same-origin iframe limitation: documented.
- Extra mapping-only unit tests: declined in favor of real installed-CLI negative coverage; package checks exercise the actual boundary.

Corrections and gallery/template improvements are in `32efb51a1`; final delta review `.ace-local/review/sessions/review-8xfezq/review-report-review-default.md` approved once the changelog entry lands. The changelog is now updated. The optional cyclic-symlink regression and real rendered-frame fit assertion were also added and passed. No high/critical issues or unresolved actionable review findings remain. The later Base36 session clarification is documentation-only, with both example sessions moved and validated.

## Monorepo baseline limitations

`bin/ace-test-suite` was executed: **47 packages passed, 4 failed; 12,140 passed tests, 41 failed/error results, 39 skips**, 363.64 seconds. The suite is not green and is not represented as such.

Failing packages and worktree reports:

- ace-task: `task/cad41281-4ce6-44c7-a5ac-e1f71a4dca3a`, `/var` versus `/private/var` path expectation.
- ace-hitl: `hitl/abf7d528-0b05-4535-9319-097fcaa2ea4b`, TLS error-message expectation and unavailable `lab-control` group.
- ace-hitl-hermes: `hitl-hermes/9404ffb0-0329-4c4e-8f27-c0667fba3b72`, local TLS DNS resolution/activation.
- ace-lab: `lab/0525887e-0896-4808-b50e-4709d6e4b753`, unsupported PEERCRED on macOS and publication/authorization fixture failures.

These packages and their shared ace-assign fixtures have no source diff against the pre-implementation base. Runs on the original checkout at `c42deec66` also failed in all four packages. Reports under `/Users/mc/Ps/ace/.ace-local/test/reports/`: task `405fc392-564a-4dde-84c3-9a8ebdf98898`, hitl `20dc832a-118e-4dff-ae92-0bc11b2a0397`, hitl-hermes `acc63ffc-f5cf-426f-a516-c74eecfda4c0`, lab `8577e8e2-c359-4c81-9ae0-ff8331df9c39`. Baseline runs stop on a failed lane, so they reproduce representative failures, not every one of the suite's 41 results. No unrelated production code was changed.

No RubyGems publication or deployment is claimed.
