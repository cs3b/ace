# SC1 Diagnosis — actual failure boundary in the reported macOS run (2026-09-29)

Evidence source: retained run `8wskfgw-monorepo-e2e-ts001` (TS-MONO-001), report dir
`8wskfgw-monorepo-e2e-ts001-reports`, plus effective `.ace/llm/config.yml` and
`.ace/e2e-runner/config.yml` at e45679c1e. Observation only; no rerun performed for
this record (SC4 covers the live reproduction).

## Observed facts (from retained artifacts)

1. **Runner phase succeeded.** `runner.command.json`: phase=runner,
   provider=`role:e2e-runner`, timeout **1800s**, recorded 13:37:29Z.
   `runner-output.md` contains the complete final runner message ("All four goals
   are complete…") written at 14:41:20 WEST (~231s into the session). All four TC
   evidence trees exist; `results/tc/02/install.exit` and `tc/03/fullindex.exit`
   are both `0`.
2. **Verifier phase failed 7s after starting.** `verifier.command.json`:
   phase=verifier, provider=`role:e2e-verifier`, timeout 1800s, recorded 13:41:20Z.
   `verifier-prompt.md` is **24,791,310 bytes (~24.7 MB)**. `summary.r.md` records
   `Ace::LLM::ConfigurationError: Preset 'ro' not found for provider 'zai'` at
   13:41:27Z. `metadata.yml`: status=error, duration 238s, tcs 0/0/0.
3. **Effective config** (`.ace/llm/config.yml`): `e2e-runner` =
   `[codex:sol:low@yolo, gemini:flash-latest@yolo, claude:haiku:low@yolo]`;
   `e2e-verifier` = `[codex:sol:low@ro, gemini:flash-latest@ro, claude:haiku:low@ro]`;
   global fallback `max_total_timeout: 60.0`, `chains: codex: [pi]`,
   `providers: [zai:glm-5]`. `.ace/e2e-runner/config.yml`: `execution.timeout: 600`
   default (the run recorded 1800 for both phases).

## Conclusions

- **The "~230s" number is the runner's wall time (231s) plus 7s of verifier
  failure — not a timeout boundary.** Both phases had a 1800s configured deadline;
  no configured deadline fired.
- **The runner codex session was not dropped.** Its final message exists verbatim;
  the release-proof's "wrapper dropping the session during the idle window of long
  bundle install" did not happen in this run.
- **The recorded ERROR is a verifier-stage fallback exhaustion**: the 24.7MB
  verifier prompt defeated the fallback chain (codex failed fast; gemini/claude
  ineligible; `zai` died on the unresolved `@ro` preset → ConfigurationError).
  Every provider attempt failed before any verifier execution began, so the
  terminal diagnostic was correct in substance — but it surfaced only as prose.

## Hypotheses explicitly disproven (or unsupported) by evidence

- "230s configured deadline / wrapper timeout at ~230s" — deadlines were 1800s.
- "Idle-stream drop at the codex transport layer" — runner completed and wrote its
  final message; no drop occurred.
- SafeCapture killing the session mid-install — contradicted by runner-output.md.

## Structural gaps that remain (the reason this task exists)

1. `ErrorClassifier` classifies by message prose (`message.include?("timeout")` →
   FALLBACK_IMMEDIATELY); a nonzero exit that merely mentions "timeout" (or a
   successful run whose tool output contains it) is classified by that prose.
2. `SafeCapture` raises a plain `ProviderError` with only text — no structured
   outcome (deadline vs transport vs nonzero exit), no elapsed/exit/correlation
   evidence for downstream consumers.
3. E2E suite auto-retry (`--retry-failures-once` default on full runs) replays any
   non-pass scenario, including ones whose provider session began executing and
   then ended uncertainly (side-effect replay risk).
4. Pipeline verdict integrity: an incomplete verifier verdict set (fewer verdicts
   than selected test cases) can still yield status "pass".
5. Metadata reconciliation (`read_agent_result`, suite metadata reconcile) can
   upgrade a fresh pipeline ERROR to PASS from a stale metadata.yml.

Cross-check run `8vcowty` (retained): runner phase failed with
`ProviderError: Codex CLI failed: Reading prompt from stdin… 401 Unauthorized` —
the nonzero-exit/transport class; classified TERMINAL by prose today, no
structured exit evidence retained.
