# Project design context verification

## Delivered behavior

- Three files per inherited context in `.ace-config/design/`: pinned defaults, verbatim user decisions, effective generated assumptions with source/body hashes.
- Branch or named-context adjustment through the configured ace-llm coding provider; explicit refresh, conflict reports, proposal/diff, optimistic concurrency and recoverable transactional publication.
- Fresh ancestors remain byte-identical during local adjustments. Candidate and previous trees remain as recovery evidence. Manual generated-body changes require deliberate resolution.
- View/component generation consumes one frozen effective design snapshot; resume/revise never reload project assumptions.
- Nine packaged design skills, including app/site adjust, with shared workflows and installed discovery.

## Deterministic checks

`bin/ace-test ace-design all`: **61 tests, 498 assertions, zero failures/errors/skips**. Latest report `.ace-local/test/reports/design/46b1f1d4-e0b0-4fe4-a7bc-7f51b63728f3/`. Only the paid model boundary is substituted in context/generation feature tests; real files, locks, hashes, publication and recovery execute. Installed-gem checks run isolated executable/protocol/skill discovery.

Coverage includes inheritance, custom contexts, view/component selection, user-byte preservation, defaults removal/replacement, conflicts/manual edits, stale dependencies, fresh ancestor reuse, dry-run, malformed outputs, concurrent edits, interrupted composition, injected publication failure, crash-journal recovery, immutable resume/revision snapshots and actionable rejection of incomplete sessions.

Handbook lint: initial nine changed files passed (`.ace-local/lint/8xflke/`); subsequent three adjust files passed (`.ace-local/lint/8xflru/`). Final documentation/skill lint passed without warnings (`.ace-local/lint/8xflza/`). Explicit `ace-handbook sync --provider agents` projects all nine design skills into `.agents/skills/`.

`bin/ace-test-suite`: **47 packages passed, four failed; 12,148 passed tests, 41 failed/error results, 39 skips**. Same package/count outcome as the preceding runner baseline. Failure reports inspected:

- `task/c9d3d006-3b57-4f39-b89c-1b348219b37a`: `/var` versus `/private/var` macOS path assertion.
- `hitl/83c3be19-31e0-4b8a-b578-70696ef882c4`: unavailable lab-control group and TLS error wording.
- `hitl-hermes/2023f749-9c6f-48c5-ac89-9be26aff31bd`: TLS hostname resolution/expectations and installed activation.
- `lab/5f2678d1-d6bb-43d6-908d-071ba388594e`: unsupported macOS PEERCRED, missing fixture/process-binding fields and related transport expectations.

These reports are under `.ace-local/test/reports/`; the monorepo suite is not green. No unrelated code was changed to hide these failures.

## Real provider smoke

Project: `.ace-local/design/context-smoke/`. All operations use the source CLI from this project directory, configured `role:assign-engineer` → `pi`, `zai/glm-5.3-flash`, high thinking, provider preset `yolo`.

1. Seeded a simulated older local component defaults copy (spacious rows, actions hidden until expansion), with valid source metadata. This represents an older installed-library snapshot; no package upgrade was installed.
2. Actual `adjust --surface app --kind component --design-context app/component/customer-table --prompt ...` composed root/app/component/named context in **104.225 s**. The named table adopts compact rows and always-visible inline actions while inheriting relevant parent rules. Report `adjust/8xfllstw/` beneath the smoke project's `.ace-local/design/`.
3. Actual `adjust ... --refresh` loaded current packaged defaults in **67.639 s**. Four user files remained byte-identical; root/app generated documents were reused unchanged. Historical defaults were removed, keyboard/focus guidance added, and explicit compact/visible-action intent retained. Report `adjust/8xflqge3/`; independent byte/hash checks in `refresh-verification.json`.
4. Actual `generate --kind component` used supplied customer fixtures and distinct A/B/C extra prompts. Session `.ace-local/design/8xflrubn/` under the smoke project. Preparation **40.803 s**, parallel workers A **84.243 s**, B **142.424 s**, C **88.704 s**. All three completed first attempt. These are observed timings, not a latency guarantee.
5. Chromium rendered all three component hosts, with all three shared customer names and no JavaScript errors. Row action feedback, row selection and empty/restore states worked in B/C. A's first generated mockup could not uncheck a selected checkbox; recorded in `render-before-feedback.json` and routed through a targeted A-only `revise`.

6. A-only checkbox feedback completed in **34.249 s**; a second narrow visual-feedback round corrected column/header alignment in **78.877 s**. Final Chromium assertions passed for all three: names, select/deselect, local action feedback, empty/restore and A's column alignment, with zero JavaScript errors (`render-evidence.json`). Screenshots were inspected as minimal component hosts.
7. `revision-verification.json` verifies B/C artifacts, fixtures and design snapshot stayed byte-identical through both feedback rounds; all generation/revision workspaces received exactly the shared fixture/design bytes. The original fixture file is unchanged. Older A artifacts remain in session history.

Live comparison gallery: `http://127.0.0.1:64818/` while its local preview process runs. The complete smoke evidence remains under the local smoke project; it is not package source.

## Independent review

Initial code-valid review of `1743dea13..2f49afda6`: `review-8xflls`, actual reviewer `pi/zai/glm-5.3`, provider preset `ro`. Verdict: no blocking issues; approval contingent on executed evidence. Three low findings: omit empty authoritative-decision section, preserve proposal evidence across rollback, and actionable incomplete-session errors. All addressed in `a1feeb014` and `f617bb8cf` with regression checks. Feedback synthesis was disabled; raw independent reports were read and findings verified directly.

Delta review `2f49afda6..a1feeb014` (`review-8xflsj`): **Approve**, no blocking findings. Verified dirty propagation, unchanged-parent injection and crash-window behavior. Documented report fields and clarified manual-recovery skill permissions in response to low notes; inert failed-run staging is intentionally retained as local evidence.

Delta review `a1feeb014..f617bb8cf` (`review-8xflv3`): **Approve**, no critical/high/medium findings. Remaining low suggestions are splitting an already actionable combined error message and pre-existing absent-file error handling; neither affects valid sessions or the requested context contract. Changelog wording was narrowed to the exact newly guarded missing fields. All production-code deltas have independent review.

## Scope limits

Hash checks establish source provenance, not a formal guarantee of semantic merging. User decisions are retained verbatim and reports require inspection. Browser smoke is lightweight interaction evidence, not production accessibility/security certification. Production engineering and explicit selection remain separate. No design was selected and no package was published, merged or deployed.
