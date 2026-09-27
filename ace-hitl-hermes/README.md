# ace-hitl-hermes

Folder-as-interface HITL transport plugin for the hermes relay
(spec `8wm.t.vs1`). The shared folder between the lab and hermes **is**
the transport:

- a **message** is a file `<id>.json` in the channel folder;
- the **address** is `<machine>/<folder>/<id>`;
- **delivery** is push — the consuming side picks the validated file up
  and takes it to its target (labd pushes answers to the asking agent,
  hermes surfaces questions to the Captain);
- **ACK** is the deletion of the file after delivery.

The Captain's answer is a file `<folder>/<id>.json` with the fields
`answer` / `sender` / `received_at`, written atomically (same-directory
tmp file + rename) without root.

## Contract

- Folder contract: `ace.hitl.hermes.folder/v1` (spec `8wm.t.vs1`).
- Message schema: `ace.hitl.hermes.message/v1`; the machine-readable
  JSON Schema ships at
  `lib/ace/hitl/hermes/schemas/message.v1.schema.json`.
- State machine: write -> validate -> deliver -> ACK deletion, with
  bounded retries (collision at write time, undeleted after delivery)
  and quarantine as the terminal branch for invalid files.
- Canonical shared-contract file location/ownership is settled by A4
  (`8wm.t.vs2`); the lab-config consumer side is `8wm.t.vp9` (separate
  repository, intentional cross-repo reference).

## Surface

| Piece | Responsibility |
|---|---|
| `Hermes::Molecules::HermesChannels::Registry` | channel registry + `<machine>/<folder>/<id>` addressing, fail closed |
| `Hermes::Molecules::HermesFormats` | decode gate: UTF-8, 64 KiB bound, JSON object, known schema only |
| `Hermes::Molecules::HermesMessage` | typed envelope, fail-closed validation, canonical JSON |
| `Hermes::Molecules::HermesAtomicWriter` | same-directory tmp + rename, no root (euid 0 refused) |
| `Hermes::Molecules::HermesQuarantine` | quarantine moves + reason sidecars |
| `Hermes::Molecules::HermesRetryPolicy` | collision + undeleted-file retry decisions |
| `Hermes::Molecules::HermesNotifications` | deterministic single-line notification texts |
| `Hermes::Organisms::HermesBox` | folder interface per channel: `publish`, `poll`, `ack`, `age`, `identical?` |

## Usage

```ruby
require "ace/hitl/hermes"

registry = Ace::Hitl::Hermes::Molecules::HermesChannels::Registry.new
registry.register("inbox", machine: "lab01", folder: "/run/lab/hermes/inbox")
registry.default = "inbox"

lines = []
box = Ace::Hitl::Hermes::Organisms::HermesBox.new(
  channel: "inbox", registry: registry,
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

## Development

```sh
ace-test atoms      # fast unit tests
ace-test            # the whole package suite
```
