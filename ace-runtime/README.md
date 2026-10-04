# ace-runtime

Runtime-neutral terminal intent contract for ACE (spec 8wq.t.k86.0). One
duck-typed intent API that terminal runtimes implement and all consumers
call — the structural change that makes herdr an equal partner to tmux
instead of a side gem.

Adapters live INSIDE the existing wrapper gems: `ace-tmux` and `ace-herdr`
gain a dependency on `ace-runtime` and ship an adapter entrypoint. This
gem depends on neither (ADR-033 stability rationale; Captain decision
2026-09-27).

## The contract

Eleven operations, keyword-arg surfaces mirroring today's consumer calls:

| Operation | Surface |
|-----------|---------|
| Context | `runtime.context` → `{in_runtime:, session:, window:, pane:}` |
| Ensure window | `runtime.ensure_window(name:, root:, preset: nil)` — idempotent by normalized name; conflicting root/preset raises `WindowConflictError` |
| Process identity | `runtime.process_binding(pane:, caller_pid:)` → verified owner/native binding or nil (unknown); read-only, no authorization |
| Prepare pane | `runtime.prepare_pane(window:)` — splits when needed; target stays alive after a submitted command exits |
| Focus | `runtime.focus(window:)` |
| Send | `runtime.send(pane:, command: nil, items: [])` — ordered `{message: String}` / `{key: String}` entries |
| Capture | `runtime.capture(pane:, lines: 40)` → text |
| Wait output | `runtime.wait_output(pane:, pattern:, timeout:)` |
| Wait agent | `runtime.wait_agent(pane:, states:, timeout:)` |
| Wait lifecycle | `runtime.wait_lifecycle(condition:, target:, timeout:)` — `window-exits`/`window-active`/`pane-exists`/`pane-exited` observations only |
| Close | `runtime.close_window(window:)` |
| List | `runtime.list_windows` / `runtime.list_panes(window:)` |

Convenience shapes: `send_command(pane:, command:)`,
`send_text(pane:, text:)`, `send_keys(pane:, keys:)`.

Target identity is opaque adapter-owned handles at every boundary — the
contract never predicts or formats pane ids (tmux `%id` and herdr
`w1:p1` stay adapter-internal). Window operations take the (sanitized)
window name; pane operations take the handle returned by the adapter.

Timeouts at the contract level are SECONDS; adapters convert to native
units internally.

## Resolution and selection

```ruby
runtime = Ace::Runtime.resolve("tmux")   # fail-closed; unknown name raises
                                         # UnknownRuntimeError (available: ...)
name = Ace::Runtime.detect(env: ENV)     # :tmux | :herdr | nil, no side effects
```

CLI/runtime selection precedence (highest wins):

1. explicit name (`ace-runtime send --runtime herdr`)
2. `ACE_RUNTIME` environment (consumer forks set this plus target context)
3. configured runtime — `.ace/runtime/config.yml` key `runtime`
4. auto-detection from the environment (`TMUX` / `ACE_TMUX_SESSION`, or
   `HERDR_SESSION` + `HERDR_PANE`). When both are live, tmux wins
   (existing default). Only assign auto launch mode selects headless
   outside any runtime; that decision lives above this contract.

An explicitly selected runtime that turns out unknown or unavailable
fails closed — never a silent switch or headless downgrade.

## Send matrix

`send` is the only submission primitive; the granular ops are shapes of
it. `items` is an ORDERED list — the only shape that preserves
message/key interleaving. When `command` is present, `items` holds
exclusively post-command keys; leading keys are a usage error before any
transport call (the CLI enforces `--cmd` before every `--key`).

- **Plain-pane adapters** (`send_profile == :plain_pane`, e.g. tmux):
  messages are raw text (no implicit submission), keys are keystrokes,
  each Enter submits pending text; `command` submits once, then trailing
  keys deliver.
- **Agent-aware adapters** (`send_profile == :agent_aware`, e.g. herdr):
  `command` or the concatenated messages become ONE prompt that submits
  itself (message-only input DOES submit once on agent panes — intended
  divergence); at most one trailing Enter is dropped and reported via
  the result; keys-only sequences go to agent keys; every other
  interleaving is rejected before any transport call.

An invocation with no send content at all is a usage error on both
profiles.

## Error model

All failures subclass `Ace::Runtime::Error`:

- `UnknownRuntimeError` — with the sorted available list
- `RuntimeUnavailableError` — known runtime, unusable right now
- `TargetNotFoundError` — window/pane target does not exist
- `WindowConflictError` — same normalized name, incompatible root/preset
- `SendRejectedError` — pre-send rejection; terminal, no transport call
- `SendStalledError` — submission accepted but the target never started
  processing; OUTCOME UNCERTAIN, callers must not auto-resend
- `WaitTimeoutError` — a wait exceeded its deadline (seconds context)

`pane-exited` is a runtime observation only — never assignment success,
receipt confirmation, or prune authorization.

## Adapter contract

Adapters are duck-typed (no base class, ace-hitl provider-registry
pattern). To register:

```ruby
# lib/ace/runtime/adapters/<name>.rb in the adapter package
Ace::Runtime.register(:<name>, -> { Ace::Tmux::RuntimeAdapter.new })
```

The contract resolves an unregistered known name by attempting to load
that entrypoint lazily — no gem dependency in either direction.

The packaged shared suite `Ace::Runtime::Testing::AdapterContract` is
the acceptance bar for ANY adapter. See `docs/usage.md` for the
adapter-authoring walkthrough.

Note: adapters intentionally define `send` (the intent operation),
which overrides `Object#send`. Use `__send__` for reflective dispatch
on adapter objects.

## Recoverable process ownership

`process_binding(pane:, caller_pid:)` identifies a caller's owner below the exact native retained shell. The returned string-keyed object binds `runtime`, `session`, `pane`, `shell_identity` and `process_identity`; each OS identity carries PID, UID, start time and host. Herdr additionally binds durable terminal ID, agent kind and immutable native agent session, and corroborates the owner against foreground process information. No command line arguments are stored.

An absent or non-native caller, retained shell without its owner, inaccessible OS facts, zombie or mismatched process returns nil. Native transport failures keep the standard typed error model. Consumers must compare the complete binding on each recovery observation. A process binding proves liveness only and grants no actor, service, effect or HITL authority. Unknown observation preserves resources; it does not prove all descendants stopped.

Process birth uses Linux boot ID with `/proc` start ticks or Darwin libproc microsecond birth. Whole-second `ps lstart` is never identity evidence. Unsupported/unreadable exact birth facilities return unknown. Capture brackets process metadata with birth reads, and native ownership revalidates the whole ancestor chain before returning it.
