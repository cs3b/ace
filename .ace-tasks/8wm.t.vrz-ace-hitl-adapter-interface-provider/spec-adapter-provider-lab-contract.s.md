---
doc-type: spec
task: 8wm.t.vrz
package: ace-hitl
status: implemented
created_at: "2026-09-24"
binding-inputs:
  - task brief 8wm.t.vrz (Kapitan dictation A1)
  - spec review findings review-8wmw3q (codex gpt-5.6-luna)
---

# Spec — ace-hitl adapter interface + provider=lab contract

`ask` is ONE operation (local HITL event + transport send). The asking
agent's reverse address (herdr session + pane) is captured from the herdr
environment, persisted on the event, and is what `deliver(ref, answer)`
targets. `wait` stays available only as the pane-less script path. Every
lab transport invocation is encapsulated in the provider=lab adapter;
agent-facing ace-hitl code contains zero direct lab-hitl references
(guard-tested).

## 1. Adapter interface

Provider adapters are duck-typed classes under `Ace::Hitl::Providers` (no
forced base class). The protocol pins exactly two required operations and
one optional:

### 1.1 `ask` (required)

```
ask(question:, title: nil, ref:, work:, attempt:,
    project:, harness:, plan:, effect: {}) -> Providers::AskResult
```

- `question` (String, non-empty), `title` (String or nil; defaults to the
  question inside the operation).
- `ref` — `Providers::Ref` reverse address of the asker (§3). REQUIRED,
  validated by the caller before the operation is entered.
- `work`, `attempt` (Strings; lab relay request contract), `project`
  (default `"ace"`), `harness` (default `"lab-admin"`), `plan` (default
  `"ace-hitl ask"`).
- `effect` — hash with keys `match`, `effect_args`, `effect_cwd`,
  `effect_timeout` (client-side bounds are validated by the CLI before the
  call; values pass through verbatim).
- Semantics: creates the local HITL event AND sends the relay transport
  request in ONE operation, then persists §4 fields on the event.
- Returns `AskResult(event_id:, request_id:)`.
- Failure: if the transport send fails after the event was created, raises
  `ProviderUnavailableError` whose message embeds the orphan event id.
  The adapter never retries: asking is side-effectful and re-asking is the
  caller's explicit decision.

### 1.2 `deliver` (required by the interface; support is per provider)

```
deliver(ref, answer) -> Providers::DeliverResult
```

- Meaning: push `answer` to the asker addressed by `ref` (herdr session +
  pane, §3).
- Returns `DeliverResult(ref:, state:)` with `state` one of `:delivered`,
  `:retryable` (target agent not reachable now; safe to re-push identical
  content), `:failed`.
- Retry/idempotency: `deliver` is idempotent per `(ref, event)` for
  identical answer content; callers may retry freely.
- provider=lab in this task (A1) raises `UnsupportedOperationError`
  pointing at ace-herdr push delivery (8wm.t.vs0) and the provider=lab
  integration (8wm.t.vs2). No herdr invocation ships in A1.

### 1.3 `wait` (optional)

Providers that do not implement polling raise `UnsupportedOperationError`.
The CLI `ace-hitl wait` command remains the answer path for scripts
without a pane and does not go through a provider.

## 2. Error model

All under `Ace::Hitl::Providers`, base class `Error < StandardError`:

| Error | Meaning |
|---|---|
| `UnknownProviderError` | provider name not in the registry |
| `InvalidRefError` | reverse address absent/invalid; fail closed before any state change |
| `ProviderUnavailableError` | transport send failed (binary missing, non-zero exit, unparseable output) after the local event may exist |
| `UnsupportedOperationError` | the provider does not implement the requested operation |

## 3. `ref` semantics — versioned reverse address

`Ace::Hitl::Providers::Ref` — value object, `SCHEMA = "ace.hitl.ref/v1"`,
fields `session` and `pane` (the asking agent's herdr session and pane).

- Captured from the herdr environment: `HERDR_SESSION`, `HERDR_PANE`
  (ace-herdr exports both at agent bootstrap; A2 consumes this contract).
- Validation, fail closed (`Ref.from_env`): both variables required after
  strip; 1..128 characters; must match `/\A[A-Za-z0-9._:-]+\z/`. Any
  violation raises `InvalidRefError` naming the variable and the rule.
- `Ref#to_h` → `{schema:, session:, pane:}` — the persisted, versioned
  shape (flat frontmatter keys, §4).
- `ref` identifies WHERE the answer goes; it carries no answer content.

## 4. Persisted event fields

Written by the provider after a successful ask (flat metadata keys,
consistent with the existing `lab_request_*` fields):

| Field | Value |
|---|---|
| `provider` | `"lab"` |
| `ref_schema` | `"ace.hitl.ref/v1"` |
| `ref_session` | herdr session token |
| `ref_pane` | herdr pane token |
| `lab_request_id` | relay request id (existing) |
| `lab_request_state` | `"created"` then observed states (existing) |
| `lab_request_effect` | `declared` / `none` (existing) |

## 5. Provider selection and configuration

- CLI: `ace-hitl ask --provider <name>`; default order: `--provider` flag
  → `ACE_HITL_PROVIDER` env → `"lab"`.
- Registry: `Ace::Hitl::Providers.resolve(name)` returns an adapter
  instance; `Providers.available` lists known names (currently `lab`).
  Unknown names raise `UnknownProviderError`.
- provider=lab environment: `ACE_HITL_LAB_BIN` (relay transport binary,
  default `/usr/local/bin/lab-hitl`), `ACE_HITL_LAB_PUBLIC_DIR` (read-only
  projection observation used by `wait`). `--attempt` defaults to
  `LAB_ATTEMPT_ID` at the CLI layer.

## 6. Order of operations in `ace-hitl ask` (fail closed early)

1. effect-callback validation (client-side bounds; unchanged)
2. `--work` / `--attempt` validation (unchanged)
3. provider resolution (unknown → error, nothing created)
4. `ref` capture from herdr env (absent/invalid → error, nothing created,
   no transport call)
5. transport request id generation
6. local event creation
7. transport send (on failure → `ProviderUnavailableError` with orphan
   event id; no auto-retry)
8. persist §4 fields on the event
9. output: event id, provider + ref, lab request id

## 7. Disposition of the legacy Lab adapter code

`Molecules::LabRequestSubmitter` is DELETED (pre-1.0, no compatibility
shim). Its implementation is re-homed unchanged in behavior as
`Ace::Hitl::Providers::Lab::Transport` and raises the provider error model
(`ProviderUnavailableError`). It is retained ONLY as the provider=lab
adapter's transport and is referenced by no other ace-hitl code.

## 8. Acceptance hardening (automated)

1. **Zero-lab-hitl guard (fast test):** no `.rb` file under
   `lib/ace/hitl/` OUTSIDE `lib/ace/hitl/providers/` may contain the
   substring `lab-hitl`, reference the transport class
   (`LabRequestSubmitter`), or name `ACE_HITL_LAB_BIN`. Zero occurrences
   = zero direct invocation from agent-facing paths.
2. **Provider-dispatch acceptance tests (fast):**
   - default and explicit `--provider lab` ask dispatches through the
     registry into the lab adapter: event created + transport sent +
     §4 fields persisted (stubbed transport);
   - unknown provider → non-zero exit, error names the provider and the
     available list, no event created, no transport call;
   - missing/invalid `HERDR_SESSION`/`HERDR_PANE` → non-zero exit
     (fail closed), error names the variable, no event created, no
     transport call;
   - transport failure → orphan event id surfaced (existing behavior,
     preserved);
   - `deliver`/`wait` on the lab adapter raise `UnsupportedOperationError`.

## 9. Out of scope (later tasks)

- herdr push delivery implementation — A2 (8wm.t.vs0)
- hermes folder-as-interface provider — A3 (8wm.t.vs1)
- shared folder contract + provider=lab integration — A4 (8wm.t.vs2)
- generic HITL core migration from lab-config — 8wm.t.y21
