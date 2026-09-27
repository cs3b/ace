---
doc-type: spec
task: 8wm.t.y21
package: ace-hitl
status: draft
created_at: "2026-09-24"
binding-inputs:
  - task brief 8wm.t.y21 (audit 8wl.t.gad.6 §3 M1 migration brief)
  - lab-config snapshot lab/m1 lab-hitl.py @ W664 (generic core + overseer outbox)
  - lab-config 8wl.t.ga9 effect-contract work brief (deployed 2026-09-22; effects row recovery)
  - spec 8wm.t.vrz (A1 adapter interface, provider=lab contract, §9 defers this migration)
---

# Spec — ace-hitl generic HITL lifecycle (M1 migration from lab-config lab-hitl)

The generic HITL request lifecycle — request store, kinds/secrets, public
projection, effect layer, reverse address, duty projection, operator
surface — moves from lab-config `lab-hitl.py` (+ broker recoveries) into
the `ace-hitl` gem as native Ruby. The migrated logic REPLACES the Python
implementation (no wrapper, no compat layer); lab-config keeps only the
Work/Attempt binding authority and the `lab_control` escalation glue, per
the audit verdict. File and record formats stay byte-compatible with the
deployed consumers (broker, plugin, labd) so the lab side keeps working
until the lab-config kosz task removes its copies.

## 1. Mapping onto the A1 adapter interface

- The generic core lives in a new `Ace::Hitl::Lifecycle` namespace,
  completely provider-agnostic: no Work/Attempt semantics, no lab
  binaries, no telegram, no herdr. A1 §8's zero-lab-hitl guard extends to
  it: `lib/ace/hitl/lifecycle/` contains zero references to `lab-hitl`.
- provider=lab consumes the core through two seams, the only places where
  lab coupling is allowed (A1 confines lab references to
  `providers/lab/`):
  - **Binding seam** — `Lifecycle::Binding` policy interface
    (`validate_request(work:, attempt:, project:, requester:)` and
    `require_active(work:, attempt:)`, both fail closed). The store
    REQUIRES a binding; none → every create fails closed. The audit's
    "stays in lab-config" verdict is honored by keeping the W647
    authority lab-side: `Providers::Lab::DaemonBinding` is the minimal
    client of labd's existing read-only `hitl_binding` socket op — the
    same encapsulation decision as A1 §7 for the transport. When labd
    grows an authoritative validate op, only this client shrinks; no gem
    API changes.
  - **Escalation spool seam** — `escalation_sink` callable on the effects
    layer. The gem records deduped escalation state (§5); the wake
    record/spool glue (`record_wake` + spool) stays in lab-config per the
    audit and wires in later via this seam (lab integration / M2). M1
    ships the seam with no default spool.
- `Providers::Lab` adapter reworked: `ask` creates the relay request
  through the native `Lifecycle::Store` (binding + effect declared),
  replacing the external-binary `Transport` invocation.
  `Providers::Lab::Transport` is DELETED (pre-1.0, A1 §7 superseded by
  this migration). `deliver(ref, answer)` stays
  `UnsupportedOperationError` until A2/8wm.t.vs0. The orphan-event error
  contract (A1 §6 step 7) is preserved for store-create failures.
- `ask` (gem 0.9.0) is EXTENDED, not duplicated: same command, same
  flags, same fail-closed order (A1 §6); only step "transport send"
  becomes "native store create".

## 2. Store layout and identity

- Root: `ACE_HITL_STORE_ROOT` env, default `/run/lab/hitl`.
  Subdirectories: `requests/` `secrets/` `answers/` `public/`
  `effects/`. Overseer channel root: `ACE_HITL_OVERSEER_CHANNEL_ROOT`,
  default `/lab/state/overseer-channel` (outbox only — inbox/wakes are
  the generic queue, M2's target).
- Directory modes 0700 (`public/` 0755); request records 0600 root;
  public projection 0440; answers/secrets answer files 0400 owner =
  requester; effects log 0600 root.
- Identity gateway: `Lifecycle::Identity` (euid, username, pwd/grp
  lookups, privilege drop) — the single stub point for tests, mirroring
  the faithful-fixture discipline of the Python suite.
- Atomic JSON writes: O_EXCL|O_NOFOLLOW tempfile in the target
  directory, fsync, chmod, chown, `rename`. Ownership transitions go
  through an injectable `ownership:` strategy (production: real
  `File.chown`; tests map every name to the current uid/gid — never a
  silent fallback).

## 3. Lifecycle operations (`Lifecycle::Store`)

Contract ports of `request`/`pending`/`states`/`deliver`/`consume`/
`cancel` — same inputs, outputs, error messages, and file effects:

- **create** (requester): validates id (`[A-Za-z0-9_-]{6,64}`), work
  (`W[0-9]+`), attempt (`A-[0-9a-f]{24}`, param or `LAB_ATTEMPT_ID`),
  project/harness labels (`[A-Za-z0-9_. -]{1,48}`), plan/question
  1..240 chars, options ≤8 × 1..80. `sensitive` or kind `secret` →
  rejected ("secret HITL must use the approved otp kind"). Kinds:
  text/choice/confirm/review/question/decision/verification/otp
  (`secret` never). otp: no options, binding ALWAYS validated, answer
  shape enforced later. Non-secret: binding validated for every
  requester except the store's `admin_user` (default `lab-admin`).
  Duplicate id → "HITL request already exists". Persisted record: id,
  work, attempt, project, harness, kind, sensitive, plan, question,
  options, ace_hitl_id, requester, created_at (+ `effect` block §5).
  NO expiry field is ever recorded (W651); the legacy `--ttl` flag is
  dropped, not carried.
- **pending / states** (root-only): answerable requests (no answer
  file) / all public records. Neither purges nor cancels anything.
- **deliver** (root-only "respond"): stdin answer 1..4096 chars, no
  NUL, stripped; `check_answer` gate (§4); per-request `flock` critical
  section (shared with the lab-side stop protocol): re-read record,
  re-check no answer, re-verify `binding.require_active` — on liveness
  failure the projection is marked `cancelled`, the request is removed
  (public kept), fail closed. Answer written 0400 owner=requester into
  `secrets/` (otp) or `answers/`, relay unchanged ALWAYS. Then the
  effect callback executes under the same lock (§5). Projection →
  `answer-delivered`. Result never contains the answer.
- **consume** (requester exactly; root has no bypass): poll loop (1 s)
  under the per-request lock; re-verifies liveness every iteration
  (failure → cancelled + removed + raise); returns the answer exactly
  once (request + answer file removed, public kept → `consumed`).
  Optional positive `--timeout` bounds ONLY the local wait and never
  cancels: timeout → "timed out waiting for HITL answer; the request
  remains pending". Without timeout, waits indefinitely.
- **cancel** (requester or root; the ONLY way to abandon): audited —
  `cancelled_by` + `reason` (default "unspecified") merged into the
  public projection; request + answer removed, public kept. A late
  answer to a cancelled request fails closed ("unknown or invalid HITL
  request").

## 4. Kinds, secrets, OTP

- OTP answers: exactly six ASCII digits (`\A[0-9]{6}\z`), else
  "exactly six ASCII digits".
- Non-OTP answers: secret-shape scrubbing — `github_pat_*`, `gh[pousr]_*`,
  `sk-*`, PEM private-key markers, `otp|token|secret|password: value`,
  and bare six-digit runs are rejected ("secret-shaped content is
  forbidden in HITL answers"). Sensitive requests answer into
  `secrets/` and never appear in any projection or result.

## 5. Effect layer (`Lifecycle::Effects`)

Recovered from the deployed 8wl.t.ga9 contract (post-dates the local
lab-hitl.py snapshot; work brief + acceptance evidence are binding):

- **Declaration** at create: `{argv:, cwd:, match:, timeout_s:}`
  persisted verbatim on the request record. Client bounds are validated
  by the existing `Atoms::HitlEffectValidator` (REUSED — no duplicate
  mirror): match ≤200 compiles; argv 1..16 × 1..512; cwd absolute +
  existing; timeout 1..600 (default 120).
- **Execution** inside deliver's locked critical section, after the
  answer relay: exec-style argv (never a shell), `{answer}` substituted
  once per element as a plain string replace, fullmatch regex gate
  (`match` → no execution + recorded match-failed), bounded timeout
  (TERM then KILL), executed AS THE REQUESTER — root drops
  setgroups/setgid/setuid to the requester's uid/gid; a non-root
  deliverer facing a foreign requester fails closed.
- **States**: public projection gains `effect_state` for
  effect-declaring requests: `callback-ok` or `callback-escalated`
  (callback failure or match-failure). Full attempts live ONLY in the
  root-only effects log `effects/<id>.json` (attempts, outcomes,
  escalation marker) — redacted: never the answer, never the substituted
  argv, never the raw answer content in any log.
- **Escalation**: deduped — one escalation per request, recorded in the
  effects log and projected via `effect_state` + duty; never retried in
  a loop. The spool goes through the `escalation_sink` seam (§1); with
  no sink wired, state is recorded and nothing leaves the host.

## 6. Reverse address: overseer response channel

Ports of `overseer-send` / `overseer-pending` / `overseer-ack` (outbox
records `msg-<hex>` with response, reply_to_message_id, created_at,
requester): bounded response 1..1200 chars from stdin, sender must be
the overseer user (default `mo`), **type-tag policy**: the response must
carry a leading type tag `[decyzja]`, `[pytanie]`, or `[info]`
(supersedes the older mobile-sections check, per the audit row); and the
rewrite gate — full SHAs, Attempt/Work/task-ID references, or the word
"SHA" are rejected ("rewrite for Captain without SHA, Work/Attempt/task
IDs, hashes, or internal references"). `overseer-ack` (root-only)
removes one outbox record; `overseer-pending` (root-only) lists them.
Response buffers are cleared after use.

## 7. Duty projection (`Lifecycle::Duty`)

Root-only projection `{"pending": [...], "escalated": [...]}` — the
contract of the deployed `hitl_status`/`duty`: `pending` lists
answerable requests with `has_effect`; `escalated` lists public records
whose `effect_state` is `callback-escalated`.

## 8. CLI surface (`ace-hitl`)

Thin commands over the store (names match the migrated Python surface so
the E2E scenario maps 1:1): `deliver ID` (stdin answer), `consume ID
[--timeout N]`, `cancel ID [--reason S]`, `pending`, `states`, `duty`,
`overseer-send [--reply-to S]` (stdin), `overseer-pending`,
`overseer-ack ID`. No new `request` command: requester-side creation is
`ace-hitl ask` (extended, A1 §6 unchanged otherwise). Existing
create/show/list/update/wait commands are untouched.

## 9. Error model

`Ace::Hitl::Lifecycle::Error` base with `BindingError`,
`PermissionError` (root-only operation), `StateError` (unknown/expired
transition), `AnswerError` (shape/secret-shape). Store failures surface
through the provider as `Providers::ProviderUnavailableError` (A1 §2
preserved for the ask path).

## 10. Test successors (re-homed into the gem)

- `test/fast/lifecycle/store_test.rb` — REAL filesystem (tmpdir), REAL
  flock: exact-attempt binding, OTP admin/builder/daemon-release shapes,
  fail-closed matrix (stale/mismatched/terminal/unknown attempt, missing
  pane evidence, wrong owner, unknown work, replayed id — nothing
  persisted), deliver/consume/cancel races via lock gating, W651
  no-expiry (backdated legacy `expires_at` record stays pending and is
  answered), indefinite consume resuming on a late answer, audited
  cancel + late-answer fail closed, duplicate/foreign-requester fail
  closed, root delivery preserving requester ownership (chown 0400),
  secret-shape and OTP-shape gates, secret isolation from projections.
- `test/fast/lifecycle/effects_test.rb` — REAL filesystem: {answer}
  substitution, match gate (ok / match-failed), timeout kill, exit-fail
  escalation, `effect_state` transitions, effects-log redaction (no
  answer/argv), dedup, privilege-drop sequence (identity mapping +
  fail-closed foreign requester), sink seam called at most once.
- `test/fast/lifecycle/overseer_test.rb`, `duty_test.rb` — §6/§7
  contracts including the type-tag and rewrite gates.
- `test/fast/providers/lab_daemon_binding_test.rb` — REAL AF_UNIX socket
  serving the labd `hitl_binding` reply shape (successor of the
  `LabdBindingSocket` fixture): narrow projection, exact queries,
  unreachable daemon fails closed without creating a request.
- Provider tests: argv-contract successors become store-contract tests
  (stubbed binding, stubbed sink); orphan-event contract preserved; the
  A1 §8 guard test extends to the lifecycle namespace.

## 11. Acceptance

1. `ace-test ace-hitl` green (all successors above).
2. `ace-test-suite` green; no new lint offenses.
3. Guard: zero `lab-hitl`/external-binary references under
   `lib/ace/hitl/`; `Providers::Lab::Transport` gone.
4. File-format compatibility spot-checks: request/public/answer/outbox
   record shapes byte-compatible with the deployed broker/plugin.

## 12. Explicitly NOT migrated (stays in lab-config)

- W647 binding authority: labd's `hitl_binding` op, Work/Attempt record
  semantics, the stop-side `cancel_pending_attempt_hitl` protocol.
- `lab_control` escalation glue: wake record creation + spool (seam only,
  §1/§5).
- Overseer inbox/wakes queue discipline (enqueue/claim/bind/reconcile,
  turn readiness, broker generations) — generic queue, M2/8wm.t.y23.
- Telegram/Hermes correlation broker + plugin (reply matching, tombstones,
  chat policy) — M3/8wm.t.y24.
- labd, lab_control, all lab Work/Attempt domain files.
