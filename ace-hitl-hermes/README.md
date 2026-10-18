# ace-hitl-hermes

Folder-as-interface HITL transport plugin for the hermes relay. The shared
folder between the lab and hermes **is** the transport:

- a **message** is a file `<id>.json` in the channel folder;
- the **address** is `<machine>/<folder>/<id>`;
- **delivery** is push -- the consuming side picks the validated file up and

  takes it to its target;

- **ACK** is the deletion of the file after delivery.

> **State owner:** none for task, assignment, or HITL-event state. HITL events
> are owned by `ace-hitl` in `.ace-local/hitl/`; this package owns only its
> folder protocol and private transport state (journal/offsets) under its
> configured state directory. See [docs/lab-flow.md](../docs/lab-flow.md).
>
> **Removed (L1):** the second-commander proposal surface was removed with the
> old installed authority model. Hermes now handles only local HITL/relay
> traffic (pending publication, delivery, ingress reconciliation); proposal
> reconciliation no longer runs.

The Captain's answer is a file `<folder>/<id>.json` with the fields `answer` /
`sender` / `received_at`, written atomically (same-directory tmp file + rename)
without root.

## Contract

- Folder contract: `ace.hitl.hermes.folder/v1`.
- Message schema: `ace.hitl.hermes.message/v1`; the JSON Schema ships at

  `lib/ace/hitl/hermes/schemas/message.v1.schema.json`.

- State machine: write → validate → deliver → ACK deletion, with bounded

  retries (collision at write time, undeleted after delivery) and quarantine as
  the terminal branch for invalid files.

## Surface

| Piece | Responsibility |
|-------|----------------|
| `HermesChannels::Registry` | channel registry + `<machine>/<folder>/<id>` addressing, fail closed |
| `HermesFormats` | decode gate: UTF-8, 64 KiB bound, JSON object, known schema only |
| `HermesMessage` | typed envelope, fail-closed validation, canonical JSON |
| `HermesAtomicWriter` | same-directory tmp + rename, no root (euid 0 refused) |
| `HermesQuarantine` | quarantine moves + reason sidecars |
| `HermesRetryPolicy` | collision + undeleted-file retry decisions |
| `HermesNotifications` | deterministic single-line notification texts |
| `HermesBox` | folder interface per channel: `publish`, `poll`, `ack`, `age`, `identical?` |

## Usage

```ruby
require "ace/hitl/hermes"

registry = Ace::Hitl::Hermes::Molecules::HermesChannels::Registry.new
registry.register("inbox", machine: "lab01", folder: "/run/lab/hermes/inbox")
registry.default = "inbox"

lines = []
box = Ace::Hitl::Hermes::Organisms::HermesBox.new(
  channel: "inbox", registry: registry,
  answer_authorizer: ->(id) { authenticated_hitl_client.read(id) },
  notifier: ->(line) { lines << line }
)

# Write the Captain's answer (atomic, no root, collision-safe):
message = box.publish(
  kind: :answer, id: "m-123", body: "Ship it.",
  sender: "captain", timestamp: "2026-09-24T10:00:00Z"
)

# Consume (fail closed; invalid files are quarantined, never delivered):
result = box.poll
result.messages.each do |msg|
  deliver(msg)             # push to the target
  box.ack(msg.id)          # deletion IS the ACK
end
```

## Telegram transport

The `ace-hitl-hermes serve` actor is the Telegram polling adapter: it maps
registered groups to configured project folders, publishes questions,
correlates replies, and ACKs by deletion. Configure it with an explicit
channels registry and runtime file; see
[configuration and recovery](docs/usage.md).

## HITL delivery adapter

`lib/ace/hitl/adapters/hermes.rb` registers the `hermes` adapter for
`ace-hitl send` (route config under `hitl.adapters.routes`: `channel`,
`machine`, absolute `folder`, optional `sender`). Both HITL questions and
reports are published as the outbound `question` kind — the shared
rendering's `[HITL question]` / `[HITL report <result>]` prefix preserves
the type; only questions carry `Reply-To:`. Identical resends are
idempotent; different-bytes collisions fail without overwriting; a missing
channel folder is `unavailable` (never a silent reroute).

## Planned waves

> **L2 status:** the `hermes` adapter for `ace-hitl send` is available.
> Retention and redelivery of undelivered messages across adapters are
> planned with the remaining L2 leaf. The old authenticated service
> boundary, OTP handling, and multi-user protected store are not
> requirements of the local file-based flow.

## Development

```sh
bin/ace-test ace-hitl-hermes all
```
