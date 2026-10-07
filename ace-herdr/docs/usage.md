---
doc-type: user
title: ace-herdr Usage
purpose: Full CLI and configuration reference for ace-herdr: push delivery, agent bootstrap, the terminal-control surface (list, send, capture, wait, presets), and tidy cleanup.
ace-docs:
  last-updated: 2026-10-04
  last-checked: 2026-10-04
---

# Usage

`ace-herdr` is a zero-token wrapper over the `herdr` CLI. It implements the ace-hitl push-delivery contract -- `deliver(ref, answer)` -> `herdr agent prompt <pane>` -- one-command agent dispatch, noiseless waiting and pane closure, the terminal-control intents known from `ace-tmux` (`list`, `send`, `capture`, output waits, preset-driven workspace/tab creation), and dry-run-first cleanup of finished panes and delivery records (`tidy`). No LLM is consulted anywhere in the gem.

## Command Surface

- `ace-herdr deliver [OPTIONS]`
- `ace-herdr inbox enqueue|status|deliver|reconcile [OPTIONS]`
- `ace-herdr dispatch [OPTIONS]`
- `ace-herdr list [--panes|--tabs|--workspaces] [--workspace ID] [--quiet]`
- `ace-herdr send [--cmd TEXT] [--msg TEXT...] [--key NAME...] --pane ID [--quiet]`
- `ace-herdr capture --pane ID [--lines N] [--source visible|recent]`
- `ace-herdr wait --pane ID (--for output --pattern PATTERN | --for agent [--until ...]) [--timeout S] [--quiet]`
- `ace-herdr close [OPTIONS]`
- `ace-herdr tidy [--apply] [--quiet]`
- `ace-herdr workspace <preset> [--cwd PATH] [--quiet]`
- `ace-herdr tab <preset> [--workspace ID] [--cwd PATH] [--quiet]`
- `ace-herdr --list-presets [workspaces|tabs]`

## Output policy

Control commands print exactly one deterministic JSON line on stdout; `--quiet` suppresses it. Failures surface herdr's machine error codes in the CLI error message (for example `pane_not_found: pane w9:p1 not found`) and exit non-zero. The one exception is `capture`, which prints raw pane text without any JSON wrapping.

herdr *sessions* (server persistence) are intentionally not exposed; the tmux session analogue is the herdr **workspace**.

## ace-runtime adapter

Install `ace-herdr` alongside `ace-runtime`, then resolve the adapter with `Ace::Runtime.resolve("herdr")`. The contract's `session` is a Herdr **workspace**, `window` is a **tab**, and `pane` is an opaque Herdr pane ID. The adapter does not construct pane IDs. It locates the caller through `HERDR_SESSION` and `HERDR_PANE` and reads the explicit pane with `pane get`; the pane's native workspace is authoritative and a conflicting `HERDR_WORKSPACE_ID` hint is rejected instead of honored. Outside Herdr, `context` reports `in_runtime: false`; operations requiring a caller workspace raise `Ace::Runtime::RuntimeUnavailableError`.

The adapter implements `context`, `ensure_window`, `prepare_pane`, `focus`, ordered `send` and its convenience methods, `capture`, `wait_output`, `wait_agent`, `wait_lifecycle`, `close_window`, `list_windows`, and `list_panes`. `ensure_window` scopes the sanitized tab label to the caller workspace. It records the tab's root, preset, and prepared pane under `~/.ace/local/herdr/runtime-tabs/` — keyed by workspace and label, so adapter instances from any working directory or requested root share one record, create through the same lock, and serialize prepared-pane creation through it. Later instances verify an idempotent request and reject a conflicting one; a tab whose ownership cannot be proven is never closed or replaced (a failed create rolls back only tabs the same attempt created). `prepare_pane` splits a retained shell target and returns the native pane ID after verifying it exists and has a shell process.

Replacing a dead prepared pane updates only the recorded pane pointer: a foreign tab's pointer-only record stays pointer-only (no root/preset keys are invented, so it never becomes ownership evidence), and an owned record keeps its exact root and preset. A prepared-pane pointer to a dead pane is replaced by the next split; a pointer-only record never satisfies `ensure_window` by itself -- adoption still requires the tab's verified native root.

Sends probe for a live agent. Plain panes receive raw text and keys in order; agent panes receive one self-submitting `agent prompt`, with one trailing Enter dropped and reported. Agent waits use native `agent wait` states (`idle`, `working`, `blocked`, `done`). Contract timeout values are seconds and are converted to Herdr milliseconds. Lifecycle waits observe `tab get`, focused tab state, `pane get`, and `pane process-info`; a missing pane keeps `pane-exists` waiting but immediately satisfies `pane-exited`. A pane with only its retained shell also satisfies `pane-exited` because no submitted foreground command remains. This observation does not prove assignment success or authorize cleanup.

Native `agent_blocked` becomes `SendRejectedError`; `agent_prompt_stalled` becomes `SendStalledError` and must not be automatically resent. Native wait timeouts become `WaitTimeoutError`, missing targets become `TargetNotFoundError`, and an unavailable binary or socket becomes `RuntimeUnavailableError`.

## Durable agent inbox

Use a stable event ID for one message and the assignment attempt that owns it. The reverse-address JSON contains `session` and `pane`, as with `deliver`.

Reverse references use the shared `ace.hitl.ref/v1` pair contract. Herdr token names
remain valid; the codec also preserves paired native tmux IDs (`$0`/`%0`) when
carried by managed metadata. Mixed native/token or cross-field IDs refuse.
Wire and persisted references must be canonical. Syntax acceptance does not add
tmux execution to this Herdr controller or replace its exact native ownership,
target and signed receipt checks.

```bash
ace-herdr inbox enqueue --event inb-12345678 --attempt ATTEMPT --ref ref.json --file prompt.txt
ace-herdr inbox status --event inb-12345678 --format json
ace-herdr inbox deliver --event inb-12345678
```

`enqueue` checks the live pane, durable terminal, agent kind, and native thread identity. Managed API callers must supply `expected_target`, projected from the accepted runtime owner with `Inbox#target_from_owner`; the live observation must equal that original session/pane/terminal/agent/thread identity under the event lock. The immutable `origin_target` survives retries and signed replacement of the current target. Managed payloads are checked for secret shapes before persistence, including envelopes without a nested message. Repeating the same event, attempt, target, and payload returns its existing record; a changed value is an error. `deliver` claims the record once. Idle and busy Codex or Pi agents receive an exact-session native queue submission. After an accepted idle submission, Herdr sends a generic wake prompt without the inbox payload. A pane replacement can receive at most that generic wake, never the payload. The JSON result includes `state`, `claim_generation`, `binding`, `last_error`, and any submission receipt.

`queued` can be retried after a proven pre-submission rejection. `delivered` means native submission was accepted; it does not mean the agent consumed the message. A crash after claim, changed target identity, or a native result without a verified acceptance receipt is `uncertain`; another `deliver` call does not resend it. A `completed` record has a positively verified consumption receipt. A superseded uncertain record can return to `queued` only after positive nonconsumption proof.

```bash
ace-herdr inbox reconcile --event inb-12345678 --receipt proof.json
```

The receipt is a file supplied from an operator or supervisor observation of the native outcome. Codex and Pi expose submission but no queryable consumption or eviction proof, so `reconcile` never polls the native queue or infers an outcome from age. Before enqueue, the supervisor sets `inbox_receipt_public_key` in `.ace/herdr/config.yml` to the absolute path of its trusted RSA public key. Each event pins that key's fingerprint; a later process cannot substitute a different key. Protect this configuration from delivery requesters. The receipt file must have a detached SHA-256 RSA signature at `FILE.sig`. The private key stays with the operator or supervisor. Its JSON must include the recorded event, attempt, claim generation, payload digest, and complete binding, plus an outcome (`consumed` or `superseded`), an identified observer, and a native observation reference:

```json
{
  "event_id": "inb-12345678",
  "attempt_id": "ATTEMPT",
  "claim_generation": 1,
  "payload_sha256": "<digest from inbox status>",
  "binding": {"session": "<exact binding from inbox status>"},
  "outcome": "consumed",
  "observer": {"role": "operator", "id": "operator-id"},
  "evidence": {"kind": "consumed_acknowledged", "native_reference": "session-log:42", "observation": "message consumed and acknowledged"}
}
```

Copy the **entire** `binding` object from `inbox status`; the shortened object above only illustrates the field. `consumed` requires `evidence.kind: consumed_acknowledged`. `superseded` requires `queue_evicted`, `queue_expired`, or `thread_replaced`, with an observation that the old queue entry cannot be consumed. A matching receipt changes `uncertain` to `completed` for consumption, or to `queued` for proven supersession. The original target binding stays pinned. To authorize a replacement native session, include `replacement_target` in the signed receipt with the complete target identity from a fresh Herdr pane observation; reconciliation verifies its session, pane, terminal, agent, and thread against that live replacement address before saving it. Without that field, a new claim can only use the original target. A missing or mismatched receipt returns JSON with unchanged `state: uncertain` and `reconciliation_refusal`; it does not resend. Keep the observation record with the receipt. Signature validation authenticates the configured key; the operator or supervisor remains responsible for checking the cited native outcome before signing.

After inspecting the native outcome and writing `proof.json`, the trusted operator signs the exact bytes:

```bash
openssl dgst -sha256 -sign operator-private.pem -out proof.json.sig proof.json
ace-herdr inbox reconcile --event inb-12345678 --receipt proof.json
```

The command verifies the detached signature against the configured public key before any transition. Missing, malformed, or self-signed receipts leave the event uncertain and return a machine-readable refusal. Keep the signed receipt and source observation for audit.

## tmux-intent ↔ herdr-command parity

Every common terminal-control intent available through `ace-tmux` is available through `ace-herdr` (herdr 0.9.1). Parity is of INTENT and FLAG VOCABULARY, not byte-format: ace-herdr keeps one-line JSON where ace-tmux renders human tables.

| ace-tmux intent | ace-herdr command | Native herdr call |
|---|---|---|
| `list` (panes) | `list` / `list --panes` | `pane list` |
| `list --windows` | `list --tabs` | `tab list` |
| `list --sessions` | `list --workspaces` | `workspace list` |
| `send --cmd` | `send --cmd` | `pane run` (plain) / `agent prompt` (agent pane) |
| `send --msg` / `--key` | `send --msg` / `--key` | `pane send-text` / `pane send-keys`; `agent prompt` / `agent send-keys` |
| `capture` | `capture` | `pane read` |
| `wait --for output` | `wait --for output --pattern` | `pane wait-output` |
| `wait --for agent` | `wait --until` (agent state) | `agent wait` |
| `start <preset>` | `workspace <preset>` | `workspace create` + tabs/panes |
| `window <preset>` | `tab <preset>` | `tab create` + splits |
| `--list-presets` | `--list-presets` | -- (config cascade) |
| `attach` / `detach` | ❌ out of scope | human-facing; no automation equivalent |
| layout strings / `select-layout` | ❌ out of scope | herdr has split/resize only |

## `ace-herdr list`

Inspect live state. Panes are the default scope; `--workspace <id>` scopes panes and tabs.

```bash
ace-herdr list                          # panes across all workspaces
ace-herdr list --workspace w1           # panes in one workspace
ace-herdr list --tabs --workspace w1    # tabs in one workspace
ace-herdr list --workspaces             # workspaces
```

Output: `{"panes":[{"id":"w1:p1","tab":"w1:t1","workspace":"w1","title":"~","cwd":"/tmp","focused":true,"agent_status":"idle"},...]}` -- `{"tabs":[{id, workspace, title, number, pane_count, focused}...]}` for `--tabs`, `{"workspaces":[{id, title, number, tab_count, pane_count, focused}...]}` for `--workspaces`. Empty results are a success with an empty array, never an error.

## `ace-herdr send`

Send a command, raw text, or named keys. Input reaches the pane in **declaration order** (an intentional divergence from ace-tmux's msgs-then-keys; order is expressive here, so it is preserved, not normalized). At least one input token is required -- none is a usage error before any transport call.

```bash
ace-herdr send --pane p5 --cmd 'bundle exec rake test'
ace-herdr send --pane p5 --msg 'continue with option 2' --key Enter
ace-herdr send --pane p5 --key Esc --cmd 'reset'     # rejected -- see rules
ace-herdr send --pane p5 --key enter
```

### Plain pane (raw input, declaration order)

- `--cmd TEXT` is exactly one `pane run` submission (text + Enter). It must be declared before every `--key`; trailing keys are sent after the submission (post-submission keystrokes such as `y`/`n` confirmations). Leading keys (`--key Esc --cmd run`) are rejected before any transport call.
- `--msg a --msg b` types raw text without submitting, concatenated in order.
- `--key K...` sends named keys in order; each `enter` submits pending text.
- `--cmd` combined with `--msg` is a usage error before any transport call (fail closed, nothing sent).
- Multi-Enter sequences submit per Enter.
- Output: `{"pane":"p5","sent":"cmd"}` for command-led sends, `"text"` for message-led sends, `"keys"` for key-only sends.

### Agent pane (prompt semantics)

When the target pane hosts a live agent (`herdr agent get`), the same flags route to agent transport -- replacing ace-tmux's INTERACTIVE_CLI_COMMANDS/busy-pattern heuristics with native agent state:

- `--cmd T`, or concatenated `--msg` texts (joined with newlines), becomes **one** agent prompt that submits itself -- message-only input submits once on an agent pane (intended divergence from plain panes).
- At most one trailing `--key Enter` is dropped and reported: `{"pane":"p5","sent":"prompt","dropped_keys":["Enter"]}` -- this guarantees exactly-one submission instead of erroring.
- `--key`-only sequences go to `agent send-keys` (`esc`, `ctrl+c`, ...); at most one `enter` total.
- Submission is gated natively: a blocked agent rejects pre-send with a CLI error carrying `agent_blocked` (never silently dropped); a stalled prompt surfaces `agent_prompt_stalled`.
- Rejected before transport: keys interleaved between or after messages other than the single trailing `enter`; multiple `enter` keys; `--cmd` with non-Enter keys; `--cmd` combined with `--msg`.

## `ace-herdr capture`

Print pane content as raw text (no JSON wrapping). Read-only -- agent routing rules do not apply.

```bash
ace-herdr capture --pane p5                     # last 40 lines of history
ace-herdr capture --pane p5 --lines 40 --source recent
ace-herdr capture --pane p5 --source visible    # the agent screen
```

## `ace-herdr wait`

Wait for an agent state or matching pane output.

```bash
ace-herdr wait --pane p5                                  # agent: idle, done, or blocked
ace-herdr wait --pane p5 --until done --timeout 120       # agent: one state
ace-herdr wait --pane p5 --for output --pattern 'tests? OK' --timeout 30
```

- Agent form (default; unchanged): `--until idle,working,blocked,done,unknown`, output `{"pane":"p5","state":"ready"}`.
- Output form: `--for output --pattern PATTERN` (literal substring, matching ace-tmux's observable contract). herdr checks existing pane content immediately, then polls; `--timeout` is seconds (gem converts to milliseconds). Output `{"pane":"p5","matched":true}`; a timeout is a CLI error (non-zero exit).
- The modes are mutually exclusive: `--pattern` requires `--for output`; `--until` requires the agent form.

## `ace-herdr workspace` / `ace-herdr tab` (presets)

Declare a workspace or tab layout in YAML and create it in one command -- `workspace <preset>` mirrors `ace-tmux start`, `tab <preset>` mirrors `ace-tmux window`.

```bash
ace-herdr workspace development
ace-herdr workspace development --cwd /path/to/project
ace-herdr tab agent --workspace w1
ace-herdr --list-presets               # merged inventory, both types
ace-herdr --list-presets workspaces
```

### Preset cascade (ADR-022)

Presets load nearest-wins and the `--list-presets` inventory reflects the merged set:

1. project `.ace/herdr/{workspaces,tabs}/*.yml` (highest)
2. user `~/.ace/herdr/{workspaces,tabs}/*.yml`
3. gem `.ace-defaults/herdr/{workspaces,tabs}/*.yml` -- ships `workspaces/development.yml` and `tabs/agent.yml`

A project file with the same name overrides a gem/user file; names unique to a level still appear in the merged listing.

### Schema

```yaml
# .ace/herdr/workspaces/development.yml
label: development          # workspace label (defaults to the preset name)
cwd: /workspace/project     # root cwd (tab/panes inherit; ~ expands)
focus: true                 # pass --focus to workspace create
tabs:
  - preset: agent           # a tab may inherit a tab preset (recursive; overlay wins)
    label: work             # ...and override any field
  - label: editor
    cwd: /workspace/project # tab cwd overrides the root cwd
    focus: false
    panes:
      - label: shell        # the FIRST pane is the tab's root pane
      - label: agent
        cwd: /workspace/project
        agent:              # declares an agent pane
          kind: pi          # default: config default_agent_kind
          name: development-agent
          prompt: Review the current task.
    splits:                 # every pane after the first must be placed by a split
      - direction: right    # herdr-native right|down; horizontal|vertical accepted
        target: shell       # pane label to split from (default: the root pane)
        pane: agent         # the declared pane placed by this split
        ratio: 0.5
```

```yaml
# .ace/herdr/tabs/agent.yml -- a tab preset uses the tab-level fields directly
label: agent
panes:
  - label: agent
    agent:
      kind: pi
      name: task-agent
```

Creation is deterministic and ordered: the workspace is created first, then tabs/panes in declared order (root pane from `tab create`, further panes from `pane split`, panes renamed to their labels), then pane `command`s run, then declared agents start readiness-gated (`agent start` blocks until the pane is interactive; vs0 bootstrap order: reverse address exported into the pane shell, agent start, optional prompt). herdr seeds every new workspace with an initial tab; once the preset's declared tabs exist that seeded tab is closed, so only declared tabs remain (a preset with no `tabs:` keeps the seeded one). All layouts are validated before any herdr call -- an unplaced pane, a duplicate split placement, an unknown split target, or an unknown direction fails closed and creates nothing.

Output: `{"workspace":"w2","tabs":[{"tab":"w2:t1","panes":["w2:p1","w2:p2"],"commands":1,"agents":["development-agent"]}]}`; the tab command reports the single tab object. `--cwd` overrides the resolved root/tab cwd (CLI > tab > root > pane inheritance).

Unknown preset: CLI error listing the available names (ace-tmux `--list-presets` parity), for example `Error: Unknown workspace preset 'nope' (available: development)`.

Failed tab materialization: when a preset's native tab is created but a later materialization step fails (split, command, or agent start), both `ace-herdr tab` and `ace-herdr workspace` report a standard CLI error -- the process exits non-zero with the underlying failure on stderr, prints no success payload on stdout, and shows no stack trace in ordinary mode. These entrypoints never close tabs (rollback of the failed tab is the runtime adapter's exact-id policy).

## `ace-herdr deliver`

Push an answer to an agent pane.

```bash
# Answer from a file, explicit ref
ace-herdr deliver --session ws-1 --pane p5 --event-id evt-1 --answer-file answer.md

# Answer from stdin, ref from the environment (inside the asking pane)
echo 'the answer' | ace-herdr deliver

# Bootstrap a specific agent kind if the pane has none
ace-herdr deliver --session ws-1 --pane p5 --kind codex --label 8wm.t.vs0 --answer-file a.md
```

Options: `--session`, `--pane` (default: `HERDR_SESSION` / `HERDR_PANE`), `--event-id` (default: derived from the ref and content digest), `--kind`, `--label`, `--answer-file` (default: stdin), `--resume <event-id>` (re-deliver the stored answer from the record; no ref or answer input needed).

Output: one JSON line `{"ref":{...},"state":"delivered|retryable|failed"}`. Exit code is non-zero unless the state is `delivered`.

### The delivery contract

`ace-hitl ask` captures the asker's reverse address fail-closed from the environment (`HERDR_SESSION` / `HERDR_PANE`, schema `ace.hitl.ref/v1`). `ace-herdr deliver` pushes an answer back to that address:

1. A write-ahead delivery record carrying the full answer is persisted under `.ace-local/herdr/deliveries/<event-id>.json` (mode 0600, atomic rename) before any herdr contact, so a crash can never lose the answer. A crashed run is recovered with `--resume <event-id>`.
2. Delivery is idempotent per event id and serialized by a per-event lock: concurrent deliveries prompt once. Re-delivering identical content after a `delivered` record short-circuits without contacting herdr; different content or a different destination for the same event id fails closed.
3. If the target pane has no agent, one is bootstrapped (`herdr agent start`), the reverse address is exported into the pane shell (`export HERDR_SESSION=... HERDR_PANE=...`; values are token-validated and shell-escaped), and delivery waits for the agent to become idle before prompting.
4. Transient failures (readiness timeout, `agent_prompt_stalled`, socket/binary unavailability -- at the probe as well as the prompt) persist their history and report `retryable` within `delivery.max_attempts`.
5. Terminal failures (`agent_blocked` pre-send rejection, missing pane, agent start failure) report `failed` immediately with the error persisted in the record history.
6. An interrupted run whose last recorded event is a prompt submission without an outcome is ambiguous: the answer may already have been delivered. Re-running reports `failed` ("previous run crashed after submitting") instead of silently resending.

Result states follow the ace-hitl contract (spec 8wm.t.vrz §1.2): `delivered`, `retryable` (safe to re-push identical content), `failed` (terminal).

## `ace-herdr dispatch`

Start an agent in one command: tab + `herdr agent start` + prompt, all with deterministic defaults.

```bash
ace-herdr dispatch --label 8wm.t.vs0 --kind pi --prompt-file prompt.md
ace-herdr dispatch --label review --pane p7 --cwd /path/to/project
ace-herdr dispatch --label 8wm.t.vs0 --no-prompt
```

Defaults: the caller's herdr workspace (flag `--workspace` > `HERDR_WORKSPACE_ID` > `herdr pane current`), the label as agent and pane name, the prompt from `--prompt-file` or stdin (`--no-prompt` skips submission). The new agent's environment receives `HERDR_SESSION` (workspace id) and `HERDR_PANE` (pane id) so its own `ace-hitl ask` calls carry a working reverse address.

Output: one JSON line `{"workspace":...,"pane":...,"agent":...,"kind":...,"tab_created":...,"prompted":...}`.

## `ace-herdr close`

Close out a finished agent pane; optionally rename first.

```bash
ace-herdr close --pane p5 --rename done       # rename, then close
ace-herdr close --pane p5 --keep --rename wip # rename only
```

## `ace-herdr tidy`

Report cleanable agent panes and delivery records as one deterministic JSON line; **dry run by default** -- nothing is closed, moved, or removed without `--apply`.

```bash
ace-herdr tidy            # dry run: report candidates, zero side effects
ace-herdr tidy --apply    # close eligible panes, archive old delivered records
ace-herdr tidy --quiet    # suppress the report
```

Output: `{"apply":false,"retention_days":7,"panes":{"candidates":[...],"preserved":[...],"closed":[...],"excluded":[...]},"deliveries":{"candidates":[...],"protected":[...],"archived":[...],"preserved":[...]}}`. Entries are ordered by pane id / event id; every bucket is always present (an explicit empty array means "nothing to do", never an error).

### Pane closure: positive evidence only

A pane qualifies as a `candidate` solely on positive completion evidence:

- the agent in the pane was **observed** in state `done` (`agent get`), or
- the pane has **no foreground process** (`pane process-info` reports an empty process list).

`unknown` or unreadable evidence is preserve-only: `unknown` status, a missing field, a malformed response, or a probe failure puts the pane in `preserved` with the reason (`active` / `unknown` / `unreadable`) -- no proof is never treated as dead. Panes whose process could not be read are reported, not closed.

With `--apply`, every candidate is **re-probed immediately before mutation**: only a second positive reading closes it (rename to `done`, then close -- the `close` semantics). A candidate that revived in between (`idle`/`working`) or whose fresh probe turned uncertain or failed is moved to `excluded` with the reason and never mutated. A pane that vanished in the meantime is `excluded` as `gone` -- there is nothing left to close.

### Delivery record retention

Delivered records under `deliveries_dir` whose `updated_at` is **strictly older** than `tidy.delivered_retention_days` (default 7; an exact-threshold record stays) become `candidates`; with `--apply` they are atomically moved to `deliveries_dir/archive/<event-id>.json` (mode 0600 preserved) and reported in `archived` with the archive path. Age parsing is RFC 3339 only; a delivered record with a missing or invalid `updated_at` is `preserved` (`invalid_updated_at`), never guessed.

`pending`, `retryable`, and `failed` records are **never touched** (they are audit/recovery state) and are listed in `protected`. Malformed or unreadable record files are `preserved` as `unreadable`, never removed. Lock files, temp files, and the archive directory itself are ignored. Before each archival the record is re-loaded under its per-event lock: a record that changed after discovery (no longer delivered or no longer old enough) is left in place and reported as `preserved` (`changed`); one that turned unreadable is `preserved` (`unreadable`) without aborting the run. Archival never breaks delivery idempotency: `deliver`/`--resume` consult the archive copy, so re-delivering an archived event still short-circuits (identical content) or fails closed (conflicting content) instead of re-prompting.

Errors: if the herdr runtime is unreachable, `tidy` fails with an explicit CLI error before reporting anything (no partial report, no mutation). No LLM is consulted anywhere; the report costs zero tokens.

## Configuration

Defaults (`.ace-defaults/herdr/config.yml`), overridable in `~/.ace/herdr/config.yml` or `.ace/herdr/config.yml`:

```yaml
default_agent_kind: pi          # herdr agent kind used for bootstrap/dispatch/preset agents
delivery:
  max_attempts: 3               # prompt attempts per delivery sequence
  backoff_seconds: [1, 2, 4]    # fixed deterministic backoff, no jitter
timeouts:
  agent_start: 60               # seconds to interactive readiness (also preset agents)
  prompt: 30
  wait: 30                      # readiness gate / ace-herdr wait (both wait modes)
deliveries_dir: .ace-local/herdr/deliveries
tidy:
  delivered_retention_days: 7   # archive delivered records strictly older than this (tidy)
```

## Delivery records

Records are JSON, one file per event id under `deliveries_dir` (relative to the working directory, mode 0600): event id, reverse address, SHA-256 answer digest, the full answer (so a crash never loses content), state (`pending` / `delivered` / `retryable` / `failed`), attempt count, and an append-only history of bootstrap, readiness, and prompt events with errors. Records are written atomically and guarded by a per-event lock. Re-running `deliver` with the same event id and content resumes or short-circuits; with different content or a different destination it fails closed.

## Error semantics

Commands raise a CLI error (non-zero exit) carrying herdr's machine code where one exists:

- Unknown pane/tab/workspace: `pane_not_found: ...`, `tab_not_found: ...`, `workspace_not_found: ...`
- herdr binary or socket unavailable: explicit CLI error, no partial output
- Blocked agent: `agent_blocked: ...` (terminal -- never silently dropped); stalled prompt: `agent_prompt_stalled: ...` (transient)
- Output wait timeout: `timeout: ...`
- Failed tab materialization: CLI error carrying the underlying failure (`ace-herdr tab`, `ace-herdr workspace`); never a false success or a stack trace
- Unknown preset: usage error listing the available preset names
- Invalid send shapes: usage error **before any transport call** (nothing is sent)

Exit `0` means success (including an explicit empty `list` result or a satisfied wait).

An identical signed reconciliation receipt may be verified again after a consumed/superseded settlement, without another transition. This lets an assignment consumer recover a crash before journaling its verified observation reference. Re-verification preserves the original pinned key, complete binding and generation checks; a later claim's generation rejects the old proof. It never resubmits the payload. Runtime recovery additionally exposes the read-only `process_binding(pane:, caller_pid:)` adapter operation, which requires OS ancestry under the native shell, a matching foreground owner and immutable agent-session identity.

Recovery consumers with a separately accepted journal registration pass `expected_registration:` to `Inbox#reconcile`. The exact `event_id`, `attempt_id`, `payload_sha256` and `receipt_key_sha256` map is checked inside the event lock before signature verification or settlement. A prior `status` call alone does not establish this precondition. A mismatch raises `ValidationError` without settling the event.

## Packaged guarded native source

`ace-herdr native-source selection` describes the source selection and patch shipped by this gem. These assets live under `lib/ace/herdr/native_source`; installed consumers do not need task directories. This source retains native version 0.9.3 and protocol 22; its exact source commit and patch digest identify the guarded producer. No upstream release or publication is implied.

An explicit nonroot build owner can run:

```sh
ace-herdr native-source build --source /absolute/clean/local/herdr-checkout --output /absolute/new/artifact-directory --target x86_64-unknown-linux-musl
ace-herdr native-source verify --artifact /absolute/artifact-directory
```

The build requires a matching native Linux host (x86_64 or aarch64), the selected Rust and Zig versions, and a native `musl-gcc` toolchain already provisioned by the build owner. Cross builds are unsupported. The output must be new. The builder reproduces the exact baseline plus shipped patch in an isolated checkout, checks the commit/tree/lock/toolchain bytes, pins resolved Rust/Zig/linker paths, invokes the locked release build, and records observed executable/tool digests. It never runs the resulting Herdr binary, changes global tool defaults, contacts a running Herdr server, or publishes an artifact. Locked dependency fetching by Cargo may require network access. Failed builds retain their output claim; a partial directory does not verify.

Verification checks bounded strict provenance against this gem's source selection and the observed ELF bytes/architecture. It provides byte provenance, not deployment authorization. The trusted Lab deployment owner separately selects the gem, source selection, artifact and receipt digests before installing the fixed Lab binary. Protected runtime replacement must also use the canonical maintenance admission/release owner. That operational installer join remains required source work; these commands alone do not activate the producer or complete installed acceptance.
