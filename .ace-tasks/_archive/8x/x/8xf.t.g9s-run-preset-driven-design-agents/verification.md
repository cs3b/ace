# Preset-driven design runner verification

## Delivered behavior

The runner uses ace-llm coding CLI agents, configurable slots/models/focus/role/extra prompts, one context snapshot and fixture, staged publication, partial-result resume, targeted revisions with history and explicit artifact/fixture-bound selection. The default is three concurrent variants. Site/app skills invoke this runner. Real browser/installed-package tests cover variable IDs and private artifact confinement. The provider capture owner handles cancellation cleanup.

## Executed checks

- Design package after review fixes: `bin/ace-test ace-design all`, **44 tests, 308 assertions, zero failures/errors/skips** (11.51s), report `.ace-local/test/reports/design/3d4164fc-2218-437d-a45a-f97d9b10badf/`. Includes installed CLI/protocols, real Node/Chromium, shared data, concurrency, resume/revision, lock/cancellation, publication and selection recovery, and command status propagation.
- Provider package: `bin/ace-test ace-llm-providers-cli all`, **460 tests, 1171 assertions, zero failures/errors, 11 existing skips** (8.93s), report `.ace-local/test/reports/llm-providers-cli/0d41d0b7-765b-4c97-bc89-e4aa6aa5c246/`. Includes a real interrupted subprocess and existing timeout/descendant checks.
- Changed handbook files: `bin/ace-lint` **four files passed**, report `.ace-local/lint/8xfh01/`. The source workflows now retain handbook metadata; the new ace-design command is registered in lint's command catalog.
- Full monorepo fast suite: **47 packages passed, four failed; 12,148 passed tests, 41 failed/error results, 39 skips** (380.31s). Same four failing packages/categories as the earlier baseline: task `/var` vs `/private/var`; hitl/hermes TLS and environment; lab macOS peer credentials and fixtures. This is not a green full suite. Baseline reproduction is recorded in the original design delivery verification; no new claim that every individual failing test was rerun on baseline.

Current suite failure reports:
- task: `.ace-local/test/reports/task/e45ccc22-6f94-4737-9cd3-eff4c4d96358/`
- hitl: `.ace-local/test/reports/hitl/b7370867-d736-4e86-b77b-94e5beedfa08/`
- hitl-hermes: `.ace-local/test/reports/hitl-hermes/88e91d2c-ea95-48fd-b8a6-6123a789eb31/`
- lab: `.ace-local/test/reports/lab/404c2c31-a1a9-4582-8b5b-eb33ae43accd/`

## Real CLI smoke and feedback

Session: `.ace-local/design/8xfggnz0/`. `generate --surface app` supplied a travel-support brief and separate A/B/C prompts. The project's `role:assign-engineer` resolved to **pi / zai/glm-5.3-flash / high / yolo**. This was a real provider run, not the deterministic test double.

The first preparation returned direction objects rather than required strings; it was rejected. An explicit schema example fixed the prompt. Preparation then succeeded in 121.766s. The initial broad worker prompts produced A in 565.156s, B in 523.838s and a C timeout at 600s. A/B were published and retained; C was reported incomplete. These initial timings were too slow for the intended loop.

Worker instructions were tightened to one screen, one focused pass, concise notes and roughly 300 total lines. Explicit `resume` retried only C, which succeeded in **82.579s**. File hashes proved A/B and shared fixtures unchanged. This is observed smoke evidence, not a statistically controlled speed benchmark or a latency guarantee.

All three variants rendered in actual Chromium, displayed all three shared customer names, and changed visible content when selecting the second customer, with **zero page JavaScript errors**. Screenshots were inspected: A is a compact queue with a drawer, B a contextual split workspace, C a spaced overview with progressive disclosure. Screenshots use disabled animations to avoid capturing a transient fade.

A real `revise --variant b` applied explicitly simulated feedback to reduce density while preserving the split view/history. It completed in **120.955s**. Hash comparison showed changes only to `b/styles.css` and `b/direction.md`; **A/C and fixture bytes were unchanged**, and the previous B was archived. All three were rendered and interacted with again after feedback. No user's final design selection was invented.

Local evidence:
- `.ace-local/design/runner-smoke/{before-resume,before-feedback,render-evidence,feedback-evidence}.json`
- Session `run.json`, exact worker prompt/result files, `feedback.md`, history, and `a-smoke.png`, `b-smoke.png`, `c-smoke.png`.

## Independent review

Review `.ace-local/review/sessions/review-8xfgm5/review-report-review-default.md`: **approve with minor changes**, no high/critical findings. It inspected the committed implementation plus on-disk cancellation hardening. An earlier run had captured an empty diff before commit completion; it was cancelled and is not counted as review evidence.

Automatic feedback extraction failed to parse the synthesizer's response. The raw independent report was preserved and findings were verified manually:

- M1: workflow metadata — fixed and linted.
- M2: command-class `exit` — replaced with returned status; direct CLI-host regression passes.
- L1: duration masking an early save error — fixed; injected ENOSPC preserves the original error.
- L2: implicit standard-library dependencies — explicit requires added.
- L3: leading blank brief line — title now uses first nonempty line; regression passes.
- L4: prompt-file errors — include the failing ID and path.
- L5: provider dependency floor — provider source version 0.36.2 and design minimum ~> 0.36.2 carry the cancellation fix together; bundle resolution and installed-package tests pass.
- L6: rollback after selection archival — journal restores the old selection with the old variant; regression passes.
- L7: hardcoded A in missing-variant message — uses the first declared ID.
- L8: misleading timeout-only cleanup log — now says capture cleanup.

Final source-version/installed checks and delta reviews are recorded below. No publication, merge or deployment is part of this delivery.

## Final package checks

After the provider source patch bump to 0.36.2 and design dependency floor:

- Design: **44 tests, 308 assertions, zero failures/errors/skips**, 12.83s; `.ace-local/test/reports/design/5cddb396-95a4-443f-a3e8-e36d8f4744d5/`.
- Provider: **460 tests, 1171 assertions, zero failures/errors, 11 existing skips**, 7.9s; `.ace-local/test/reports/llm-providers-cli/c5d841eb-13ba-409c-932d-fa95531bef23/`.
- Lint command registration: **311 tests, 921 assertions, zero failures/errors/skips**, 1.80s; `.ace-local/test/reports/lint/a58e2970-f77a-4bd5-8b12-974daad5c929/`.

No gem publication or release tag was created.

## Delta review and follow-up

Review `review-8xfh47` examined `caa4749b6..13768c6af`: no high/critical issues, one medium diagnostic failure and low refinements. Persistent failures writing diagnostic state could mask an original error; cleanup now preserves the original exception, warns about the persistence failure and joins every sibling before releasing the lock. Added persistent preparation/revision failure and subsequent recovery regressions. Missing original project directories now produce the actionable policy message.

The suggested removal of canonical skill comments was rejected: `ace-lint/.ace-defaults/lint/skills.yml` explicitly requires `# bundle:` and `# agent:`. Handbook sync intentionally parses/re-emits YAML; a fresh sync updated only the expected two projections. The documented source `bin/` invocations are now explicitly allowed and registered in lint. Runner exit codes and the stale saved-status behavior after an ungraceful process/machine crash are documented. The optional bounded-gallery-refresh suggestion is not required for recovery: explicit resume reconciles saved work.

Follow-up lint: 311 tests / 921 assertions, zero failures/errors/skips (`.ace-local/test/reports/lint/f99c300f-165d-4e6d-a683-2999b816bc23/`). Three changed skill/workflow files passed `.ace-local/lint/8xfhcu/`.

Review `review-8xfhe0` verified the persistence fix and identified a latent `$!` leak when resume is called inside an unrelated Ruby rescue, plus transient rescue-write masking. Replaced dynamic exception lookup with explicit local capture around the worker operation, retained join-all cleanup, and used failure-preserving saves in both worker rescue branches. Additional regressions prove successful resume inside an outer rescue, cancellation despite a transient recording failure, and propagation/recovery when successful preparation cannot be persisted.

Latest design suite: **50 tests, 333 assertions, zero failures/errors/skips**, 12.44s; `.ace-local/test/reports/design/a4660f93-2ebc-4b1c-9e4f-d6753839af24/`. Latest lint suite: **311 tests, 921 assertions, zero failures/errors/skips**, 2.0s; `.ace-local/test/reports/lint/bd274440-c56c-40ea-916c-c8dafaf9c17d/`. Source implementation is at `65ec3ddb4`; subsequent task-record updates do not change executable code.

## Final independent verdict and delivery

`review-8xfhji` reviewed `749efd93e..65ec3ddb4` against full implementation context: **approve once changelog entries are added**. It confirmed the code changes are correct, scoped and adequately regression-tested, with no critical/high findings. Both design and lint changelog entries were added. No executable code changed after this approved review.

The optional dead-thread `Thread#raise` race observation was checked with an isolated Ruby standard-library probe: raising into a joined dead thread returns `nil`; no defensive exception-swallowing path was added. Per-worker cancellation logging was optional and unchanged; saved worker state and CLI interruption diagnostics remain authoritative.

The existing draft PR **https://github.com/cs3b/ace/pull/373** was updated via `as-git-pr-update` / managed assignment `8xff8u`, attempt `8xff8x`, preserving forge and branch identity. Its title/description now explain the runner, presets, per-variant caller guidance, immutable data, recovery, explicit selection, source-only dependency patch and executed verification. Remote title/body were read back and compared with the prepared description. Final delivery only refreshes that same PR and its evidence; no merge, publication or deployment.
