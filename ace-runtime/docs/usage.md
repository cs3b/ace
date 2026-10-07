# ace-runtime usage

Runtime-neutral terminal intent contract. This document covers the
`ace-runtime send` callback CLI, direct API send shapes, runtime
selection, and adapter authoring against the shared contract suite.

## CLI: the neutral callback passthrough

The gem ships exactly one command (Fork Callback Rule decision,
2026-09-27). It resolves the configured runtime and delegates to
`runtime.send` with the normative matrix semantics.

```bash
# Submit a command (typed + Enter once) on the current pane's runtime
ace-runtime send --pane %1 --cmd 'bundle exec rake test'

# Callback form: submits exactly once on BOTH adapters
ace-runtime send --pane %1 --msg 'Reply with exactly: pong' --key Enter

# Explicit runtime selection
ace-runtime send --runtime herdr --pane w1:p1 --msg 'hello'

# Keys-only (valid; no implicit submission)
ace-runtime send --pane %1 --key C-c

# Command with post-submission keystrokes
ace-runtime send --pane %1 --cmd 'vim .' --key C-w
```

Rules enforced before any transport call:

- `--pane` is required; at least one of `--cmd`, `--msg`, `--key` is
  required (none = usage error).
- `--key` before `--cmd` is a usage error — `--cmd` must be declared
  before every key. Keys declared after `--cmd` are post-submission
  keystrokes.
- The CLI builds direct-API items as all supplied messages followed by
  all supplied keys. Direct Ruby callers use `send(items:)` when they
  need arbitrary interleaving (for example `msg, key, msg` on plain
  panes).
- On agent panes (`:agent_aware` profile) the callback shapes submit
  exactly once: `--msg ... --key Enter` becomes one self-submitting
  prompt with the trailing Enter dropped and reported; interleaved
  items, multiple Enters, `--cmd` with messages, and `--cmd` with
  non-Enter keys are rejected.

Exit behavior: contract errors (`UnknownRuntimeError`,
`RuntimeUnavailableError`, `TargetNotFoundError`, `SendRejectedError`,
`SendStalledError`, ...) surface as CLI errors with their message;
`--quiet` suppresses the success line.

## Direct API

```ruby
runtime = Ace::Runtime.resolve(:tmux)   # or let selection resolve for you
Ace::Runtime.detect(env: ENV)           # => :tmux | :herdr | nil (no side effects)

# Ordered items preserve interleaving (plain-pane example)
runtime.send(pane: handle, items: [
  {message: "switch to the topics tab"},
  {key: "C-c"},
  {message: "then restart the worker"}
])

# Convenience shapes
runtime.send_command(pane: handle, command: "bundle exec rake test")
runtime.send_text(pane: handle, text: "plain text, no submission")
runtime.send_keys(pane: handle, keys: %w[Enter C-c])

# Waits: timeouts in SECONDS (adapters convert internally)
runtime.wait_output(pane: handle, pattern: "1 example, 0 failures", timeout: 30)
runtime.wait_agent(pane: handle, states: %w[idle working-done], timeout: 600)
runtime.wait_lifecycle(condition: "pane-exited", target: handle, timeout: 60)

# Windows and panes
handle = runtime.ensure_window(name: "work fs", root: "/repo", preset: nil)
pane = runtime.prepare_pane(window: "work-fs")   # split when needed, retained
runtime.focus(window: "work-fs")
runtime.list_windows
runtime.list_panes(window: "work-fs")
runtime.close_window(window: "work-fs")
Ace::Runtime.sanitize_name("my work!")           # => "my-work"
```

`ensure_window` identity is `(resolved session/workspace, sanitized
name)`; an existing window with an incompatible root or preset raises
`WindowConflictError` instead of silently reusing the wrong worktree.

`wait_lifecycle` accepts only `window-exists`, `window-active`,
`pane-exists`, `pane-exited`. It reports the condition only — never
authorizes completion, receipts, or pruning. `pane-exited` in
particular is an observation, not assignment success or safe prune
evidence.

## Runtime selection order

1. explicit name (`--runtime tmux|herdr` / programmatic explicit)
2. `ACE_RUNTIME` (consumer forks set this plus target context to the
   caller backend)
3. configured `runtime:` key under the `ace-runtime` config namespace
   (`.ace/runtime/config.yml`, `~/.ace/runtime/config.yml`)
4. auto-detection: `TMUX` or `ACE_TMUX_SESSION` → tmux;
   `HERDR_SESSION` + `HERDR_PANE` → herdr; both live → tmux
   (documented default); neither → nil

Explicit selections never downgrade: unknown names fail closed with
the available list (`UnknownRuntimeError`); a selected-but-unavailable
runtime raises `RuntimeUnavailableError` — no headless fallback, no
silent switch. The assign auto launch mode is the only consumer that
selects headless outside any runtime, and it does so above this
contract.

## Adapter authoring

Adapters are duck-typed — no base class (ace-hitl provider-registry
pattern). An adapter package:

1. declares a dependency on `ace-runtime` (never the reverse),
2. ships an entrypoint `lib/ace/runtime/adapters/<name>.rb`:

   ```ruby
   Ace::Runtime.register(:herdr, -> { Ace::Herdr::RuntimeAdapter.new })
   ```

3. implements the full published intent API (context, ensure_window,
   prepare_pane, focus, send, send_command, send_text, send_keys,
   capture, wait_output, wait_agent, wait_lifecycle, close_window,
   list_windows, list_panes) and exposes `send_profile`
   (`:plain_pane` or `:agent_aware`),
4. normalizes public send input through
   `Ace::Runtime::Atoms::SendContract.normalize!` BEFORE transport so
   rejection never reaches native calls,
5. translates native failures at the boundary: unknown target →
   `TargetNotFoundError`, unreachable runtime →
   `RuntimeUnavailableError`, accepted-but-not-processing →
   `SendStalledError` (never auto-resend), deadline exceeded →
   `WaitTimeoutError` with seconds context.

Non-negotiables enforced by the contract suite:

- target handles stay opaque at every public boundary,
- `prepare_pane` yields a writable live shell/agent target retained
  after a submitted command exits (bare command panes do not satisfy
  preparation),
- `detect` and adapter availability checks are side-effect-free; an
  unavailable explicit runtime never becomes headless,
- installed tests must verify both runtimes; never assert untested
  behavior.

### The acceptance bar

`Ace::Runtime::Testing::AdapterContract` is the shared contract-test
suite and the acceptance bar for ANY adapter. In your adapter's test
helper:

```ruby
require "ace/runtime/testing"

class TmuxAdapterContractTest < AceTestCase
  include Ace::Runtime::Testing::AdapterContract
  include Ace::Runtime::Testing::AdapterContract::PlainPaneSendMatrix

  def build_fixture
    Ace::Runtime::Testing::ScriptedRuntime.new
  end

  def build_adapter(fixture)
    Ace::Tmux::RuntimeAdapter.new(fixture: fixture)  # thin bridge to your transport
  end
end
```

The suite drives your adapter over `ScriptedRuntime` — an in-memory
terminal (windows, panes, raw text writes, named keys, capture, agent
state) that records every mutation op so the suite can assert delivery
ordering and rejection-before-transport. Wire your adapter's native
transport to the fixture's primitive ops and translate its fixture
signals at the boundary:

| Fixture signal | Contract error |
|----------------|----------------|
| `Testing::FixtureUnavailable` | `RuntimeUnavailableError` |
| `Testing::FixtureStall` | `SendStalledError` |
| `Testing::FixtureTargetMissing` | `TargetNotFoundError` |

The reference implementation is `test/support/fake_runtime_adapter.rb`
in the ace-runtime gem; the in-gem suite
(`test/contract/adapter_contract_test.rb`) proves the battery against
it for both send profiles.

## Root-produced network installation evidence

The source-only `Ace::Runtime::Molecules::NetworkInstallationEvidence` consumer
checks the protected content selected by the installed scope owner:

```ruby
result = Ace::Runtime::Molecules::NetworkInstallationEvidence.verify!(
  selection: boundary_manifest.fetch("network_installation"),
  expected: {
    "slot_id" => slot_id,
    "namespace_path" => installed_namespace_path,
    "boot_id" => current_boot_id,
    "namespace_identity" => {"device" => pinned_device, "inode" => pinned_inode},
    "installer_artifact_sha256" => installed_producer_sha256
  }
)
```

`selection` is exactly `{profile,policy_export,report,installer_artifact}`; each
reference is exactly `{path,sha256,bytes}`. All keys are strings, paths canonical
and absolute, SHA256 lowercase, and lengths positive integers. There is no
caller-uploaded evidence or caller-selected trust root. The namespace identity
above must come from the owner's actual held, authenticated nsfs network object;
the owner validates its type/current boot and keeps the namespace pinned through
admission. This verifier reads content artifacts and never opens/substitutes the
namespace, probes traffic or grants runtime networking privilege.

Successful output contains exactly `report_id`, `boot_id`, `slot_id`,
`namespace_path`, `namespace_identity`, `profile_sha256`, `policy_export_sha256`,
`report_sha256` and `installer_artifact_sha256`, deeply frozen. It authenticates
installation content, not actual enforcement from a summary boolean. Missing,
unreadable, malformed, conflicting, oversized or context-mismatched evidence
raises `Ace::Runtime::RuntimeUnavailableError`; the authority boundary exposes
that refusal as `evidence_unavailable` and retains public `invalid_input`
classification for malformed public selectors. No absent-evidence fallback.

The reader pins regular-file and directory descriptors for the complete graph,
checks exact lengths/digests and revalidates original objects/modes at completion.
It uses root ownership and no group/other write on supported Linux POSIX local
filesystems (`ext2`, `ext3`, `ext4`, `xfs`, `btrfs`, `tmpfs`): group mode bits
represent the access ACL mask, so named non-root ACL users/groups cannot obtain
write through it. Unknown filesystem models refuse. All ancestors are checked;
no symlink, untrusted writable ancestor or mutable worker artifact qualifies.
Content bounds are 1MiB per artifact, 16MiB aggregate and 256 distinct artifacts.
The profile's 256-entry bound counts its four outer collections only; nested
ranges, ports and helper/configuration refs are bounded by the profile bytes and
separate artifact graph limits. Strict JSON parsing requires the declared
`json >= 2.20, < 3` dependency to reject duplicate keys and comments explicitly.

The trusted domain installer owns complete effective policy/topology comparison,
independent correlated flow checks, immutable digest-bearing evidence filenames
and publication that preserves historical artifacts. The generic reference
schema specifies no basename grammar: this consumer checks selected content and
protection, and cannot establish publication history. Raw policy/topology/setup
and correlated observations remain required; unsupported or incomplete domain
checks must never produce a passing report. Domain source/installed review proves
those obligations. For each loopback tool, the fixed domain procedure inspects
the actual selected executable against its profile `artifact_sha256` and retains
the observation in the exact tool-target trace. The schema provides no executable
path/ref: generic ACE authenticates the trace/raw refs and digest format; it does
not compare a tool executable digest with observation bytes or invent a ref.
Domain acceptance must exercise tool-executable mismatch refusal.

Root installation lifetime, private admission CAS, stage joins,
namespace containment and maintenance ordering belong to their respective
installed owners; this verifier does not implement them or supply native,
packet-filter or installed acceptance by itself.

### Original boot proof and fixed live readiness views

`ExecutionBootBaseline#select!(expected:)` authenticates the fixed protected
per-slot publication pointer at provisioning and returns its immutable proof
reference. `#verify!(selection:, expected:)` reads only that original reference,
joining whole-file bytes, slot, original boot, mapping digest, root PID1 birth
context and exact original network installer artifact. It never discovers an old
namespace or substitutes a current pointer. Proof JSON is closed and at most
16KiB. Trusted host capture, per-boot refresh and cold-start admission inhibition
remain domain gad.8/gad.b producer obligations.

`ServerResourceObservation` uses the same-UID native server's pinned root and
namespace descriptors without entering or changing a namespace. It reports the
complete mount table (at most256 rows), fixed API/tmp view mount IDs obtained from
contained O_PATH descriptors, server/hook IPC identities and the exact authority
socket identity. The private report shares a65,536-byte ceiling. Mount path
prefixes, typed isolation flags and filesystem names alone do not prove live
isolation. `KernelViewTopology` verifies the fixed supported profile, read-only
API views, private IPC host difference and exact writable original backing;
unknown writable aliases and even declared writable API descendants refuse.

The fixed unit exposes only the selected read-only source-equals-view authority
socket and has `BindLogSockets=false`. Protected endpoint type/owner/incarnation,
contained view identity and authenticated peer remain separate required joins.
These observations supply admission evidence, not terminality or installed
effectiveness.
