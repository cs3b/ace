VERDICT: APPROVE

Independent review of the F1 correction at HEAD `1f1b113ab` (BASE `c5e43d391`). Read-only; source-only assessment; no installed acceptance claimed or inferred.

## F1 defect and fix verification

The RED report (`25df1b37`) reproduces the exact trap: `retained operation changed; ... recover original request result` and `... adopt-1` — constant `result` key and supervisor-only `adopt-<gen>` key made a never-accepted CAS-conflicted request unretryable at any later generation (retry params differ only in `expected_generation`, so `retain` refused forever). GREEN (`40ef5909`, 3 tests / 43 assertions) exercises the same races through the real Unix socket server and Git journal CAS and passes.

Checked against each requested dimension:

- **Races.** The status-read → mutate window is benign: server-side CAS (`ordinary_results.rb` `mutate` with `expected_generation`, "ordinary attempt already submitted its result", state-must-be-running) is the authority; the driver's pre-checks only decide key selection and refusal. Concurrent same-intent retries share one retained file and therefore one `mutation_id` → server replays, no duplicate. Changed-intent concurrency is refused by `retain`/`verify_result_intent!`.
- **Unknown outcome.** `observed = status` is mandatory before any result mutation (`ordinary_driver.rb:154`, `:166`); unavailable status aborts before `mutate` — test asserts no `result-3` directory is created. Fail-closed. ✓
- **Never-accepted vs accepted-lost-reply.** `submitted_result` presence distinguishes them. Accepted: `original_generation = accepted.fetch("generation") - 1` — arithmetically sound because CAS guarantees the result plan ran at `generation == expected_generation`, so binding generation is always `expected + 1`; the exact original input at `result-#{original_generation}` is byte-compared and replayed, never re-minted. Never-accepted with advanced generation: fresh `result-#{gen}` key permitted only when canonical state is `running` at exactly the requested generation. Both original-byte assertions and journal event counts (`result_submitted == 1`, `receipt_accepted == 1`) hold. ✓
- **No duplicate mutation/result.** Driver-side key/mutation_id sharing plus server replay semantics; event-count assertions in both new tests and the updated lifecycle test. ✓
- **Immutable same intent.** `retain` compares `except("mutation_id")`; tests assert `File.binread` unchanged across conflicts, retries and replays. ✓
- **Current authority / supervisor adoption unchanged.** `adopt_supervisor`, `supervisor-#{generation}` key, `verify_result_owner!`, stale-finish refusal and the replacement-coordinator test are untouched; the finish key now additionally scopes the attempt generation, which only prevents key poisoning, not owner bypass. ✓
- **Docs/plan/evidence** (`drive.wf.md:76-86`, plan §Review F1, evidence §, CHANGELOG) accurately describe the implemented contract, including that changed content is not a generation retry.

## Findings (non-blocking)

1. **LOW — `ace-assign/lib/ace/assign/organisms/ordinary_driver.rb:160`** — in the accepted-result branch, `Files.json(input)` raises raw `Errno::ENOENT` if `requests/result-#{original_generation}/request.json` is absent (e.g., the result was submitted through a non-driver path, or pre-F1 constant-key bytes exist). *Trigger:* retry after lost ACK with no retained generation-keyed original. *Effect:* fail-closed (no mutation, no replay) but a non-domain error surfaces. *Fix:* rescue and raise `AttemptErrors::EvidenceUnavailable` with the expected original path. Pre-1.0 no-compat makes the legacy-key case moot; this is robustness only.
2. **LOW — `ordinary_driver.rb:153` vs `:154`** — `verify_result_intent!` runs before the status read, so a changed-intent retry under unavailable status reports `ArgumentError` (intent) rather than `EvidenceUnavailable` (status). Both refuse; message attribution only. *Fix (optional):* read status first.
3. **INFO — `ordinary_driver.rb:185`** — after a lost terminal finish reply, `adopt` returns the projected status (no `settlement`/`inbox_deliveries` fields) instead of replaying the original finish reply. Terminal state is what the workflow consumes; acceptable.
4. **INFO (design, documented)** — a never-accepted result intent with *different* content remains a hard reconciliation blocker (no unbind path). This is the explicitly recorded policy (plan F1, `drive.wf.md` "Changed content ... is not a generation retry"); allowing replacement would violate original-byte immutability. Not a regression.

## Test-evidence scope

Focused owning regressions executed RED→GREEN through real client/server/Git CAS; the prior 51-package suite pass predates F1 and is honestly disclosed as such. Per the recorded merge policy (executed tests + independent reviewer verdict; CI/broad rerun advisory), this does not block. Broad-suite rerun by root integration remains outstanding as stated.

No crucial context missing — changed files, owning authority modules, and both test transcripts were sufficient to trace every claimed behavior to source.
