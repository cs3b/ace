---
doc-type: spec
task: 8wm.t.vs1
package: ace-hitl-hermes
status: implemented
created_at: "2026-09-24"
binding-inputs:
  - task brief 8wm.t.vs1 (Kapitan dictation A3)
  - spec review findings review-8wmw3q (codex gpt-5.6-luna)
  - adapter interface contract from 8wm.t.vrz (A1, spec-adapter-provider-lab-contract)
---

# Spec — ace-hitl-hermes: folder as interface (registry, notifications, atomic answer files, folder contract)

The shared folder IS the transport between the lab and hermes: a message is
a file, the address is `<machine>/<folder>/<id>`, push delivery is the
consuming side picking the file up, and ACK is the deletion of the file
after delivery. The plugin (new package `ace-hitl-hermes`, namespace
`Ace::Hitl::Hermes`) owns the channel registry, the notification texts, and
the message formats. The Captain's answer is a file
`<folder>/<id>.json` with the fields `answer` / `sender` / `received_at`,
written atomically (same-directory tmp file + rename) without root.

## 1. Contract ownership and cross-references (binding)

- This spec pins folder contract version **`ace.hitl.hermes.folder/v1`**
  and message schema **`ace.hitl.hermes.message/v1`** as implemented by
  this package.
- The CANONICAL shared-contract file (its path in a repo, its owner, and
  its versioning policy) is settled by A4 `8wm.t.vs2` ("single
  source-of-truth spec"). This spec deliberately does NOT declare a second
  canonical file; it references A4 for canonicality.
- The lab-config consumer side is `8wm.t.vp9` — a SEPARATE repository;
  that cross-repo reference is intentional. lab-config implements the same
  contract versions against the same folder.
- Telegram/relay logic migration into this plugin is `8wm.t.y24`; generic
  HITL core migration is `8wm.t.y21`; push delivery to the asking agent is
  A2 `8wm.t.vs0` + integration `8wm.t.vs2`. None of that ships here.

## 2. Channels and addressing

- A **channel** is one shared directory ("folder") between lab and hermes,
  addressed by `machine` + `folder`:
  - `machine` — token, `[A-Za-z0-9][A-Za-z0-9._:-]{0,63}` (the host that
    owns the folder, e.g. the lab box).
  - `folder` — absolute directory path on that machine; its basename and
    the channel name follow the same token pattern.
- **Message address** = `<machine>/<folder>/<id>` where `<id>` is the
  message id token (same pattern). The address appears in notification
  texts and audit lines; it is never a path traversal vector because the
  id token forbids `/`, leading `.`, and length > 64.
- **Channel registry** (`Ace::Hitl::Hermes::Channels::Registry`): the
  plugin owns it (rejestr kanałów).
  - `register(name, machine:, folder:)` — fail-closed token validation;
    duplicate name raises; unknown name on resolve raises
    `UnknownChannelError`.
  - `resolve(name)` → `Channel(name:, machine:, folder:, path:)`;
    `address(name, id)` → `"<machine>/<folder>/<id>"`; `available` lists
    names sorted; an optional default channel is supported.
  - Token validation happens at registration; folder existence and
    writability are re-verified fail-closed at every folder operation
    (§4) — a channel registered before the folder exists stays invalid
    until the folder is usable.

## 3. Message envelope — schema `ace.hitl.hermes.message/v1`

One JSON object per file, one message per file. File name:
`<id>.json` where `<id>` matches the token pattern; the payload `id` MUST
equal the file name stem (fail-closed cross-check).

Required envelope fields (all messages): `schema`, `id`, `kind`, `sender`
plus exactly one kind body:

- `kind: "question"` → `question` (non-empty string), `created_at`.
- `kind: "answer"` → `answer` (non-empty string), `received_at` — this is
  the Captain's answer file mandated by the dictation:
  `{schema, id, kind: "answer", answer, sender, received_at}`.

Field rules (fail closed, `InvalidMessageError` naming the violation):

- `schema` — exactly `ace.hitl.hermes.message/v1`; unknown or absent
  schema → `UnknownFormatError` (the formats registry supports only v1).
- `id`, `sender` — token pattern (§2); `sender` is who produced the
  message (e.g. `hermes`, a captain handle, or the lab agent id).
- `created_at` / `received_at` — strict UTC ISO-8601:
  `YYYY-MM-DDTHH:MM:SSZ`, parsed as a real calendar date.
- `question` / `answer` — String, non-empty after strip.
- `kind` — only `question` or `answer`.

Machine-readable contract artifact: the JSON Schema (draft-07) for the
envelope ships with the package at
`lib/ace/hitl/hermes/schemas/message.v1.schema.json`; a fast test pins
that the asset exists, parses, declares the v1 schema id, and requires the
same field sets as the Ruby validation.

- **Filename validation**: only regular files named `<token>.json` at the
  folder top level are messages; dotfiles, subdirectories, and everything
  under the quarantine directory are never messages.
- **Encoding + size bounds**: file content MUST be valid UTF-8 and at most
  64 KiB (65_536 bytes); violations are invalid input, never truncated or
  transcoded.

## 4. Ownership, permissions, no root

- The plugin writes AS the invoking user; running as root (euid 0) is
  refused fail-closed (`RootUserError`) — no privilege escalation, no
  sudo, ever.
- Folder requirements (verified before every write/poll/ack):
  exists, is a directory, writable by the invoking user, and NOT
  world-writable (`ContractError` otherwise).
- Created artifacts: message files mode `0640`, tmp files `0600`,
  quarantine directory `0750`, reason sidecars `0640`; ownership =
  invoking user. The consuming side needs only read access to the folder
  and write access for its own ACK deletions.

## 5. Atomic write protocol

- Write = create a tmp file IN THE SAME DIRECTORY as the target
  (prefix `.hermes-tmp-`, mode `0600`), write bytes, `fsync`, `chmod` to
  `0640`, then `rename(2)` onto `<id>.json`. Readers never observe
  partial content; no root privileges are required or used.
- The target MUST NOT exist before the rename (pre-check; observed
  collisions raise `CollisionError` and the publish path retries with a
  fresh id, §8). Residual check-then-rename races are acceptable because
  ids are regenerated on any observed collision; tmp files are removed on
  every failure path.
- The same protocol applies to BOTH directions: the plugin writing answer
  files on the Captain's behalf and any lab-side writer producing
  question files.

## 6. State machine (per message file)

```
            write (atomic §5)        validate (fail closed §3)
  (none) ------------------> written ------------------> validated
                                   |                          |
                          invalid |                          v
                                   v                      DELIVERED  (consuming side
                             QUARANTINE (§7)                     pushed it to its target:
                                                                 answers -> asking agent (lab),
                                                                 questions -> the Captain)
                                                                   |
                                                     ACK = deletion of the file
                                                     (labd deletes after delivery)
                                                                   |
                                                             (gone; terminal)
  retry branches (§8): collision (write time, fresh id)
                       undeleted (delivered but not acked -> redeliver
                       identical content, bounded, then quarantine)
```

- `write` — file appears atomically (§5).
- `validate` — consumer runs the §3 gate; the file is either validated or
  quarantined; nothing invalid is ever delivered.
- `deliver` — PUSH: the consuming side takes the validated content to its
  target (labd pushes the Captain's answer to the asking agent's herdr
  pane; hermes surfaces the question to the Captain). Delivery changes no
  file content; it is observable only by the ACK or the retry clock.
- `ACK deletion` — the CONSUMING side deletes `<id>.json` AFTER delivery;
  deletion is the ACK and is idempotent (deleting an absent file reports
  `already_acked`, never an error). This applies symmetrically: hermes
  acks a question after surfacing it to the Captain, labd acks an answer
  after pushing it to the asking agent. ACKing the question also frees
  the name `<id>.json` for the answer, which reuses the question's id.
- `retry` — §8 policies; every retry attempt re-delivers IDENTICAL bytes
  (same id), so retries never duplicate answers.
- `quarantine` — terminal for the message (§7); never delivered.

## 7. Invalid-file handling — quarantine

- Any top-level `<token>.json` file that fails the §3 gate (bad JSON, bad
  encoding, size bound, unknown schema, field violations, id/filename
  mismatch) is moved atomically (rename) into `<folder>/.quarantine/`
  (created `0750` if absent) with a sidecar `<name>.reason.txt` (`0640`)
  recording timestamp + reason; name collisions inside quarantine get a
  numeric suffix. Quarantined content is never rewritten, re-validated,
  or delivered.
- Files whose NAMES already violate the token pattern (including tmp
  leftovers from a crashed writer) are left untouched by poll — the tmp
  prefix `.hermes-tmp-` is explicitly skipped; anything else non-message
  is ignored, not quarantined (the folder may legitimately contain
  foreign dotfiles).

## 8. Retry policies

- **Collision retries (write time)**: on `CollisionError`, publish
  retries with a fresh id, at most 3 attempts, then fails terminally with
  the original error surfaced. Each attempt emits a `retry_scheduled`
  notification. An EXPLICITLY supplied id never gets regenerated — it
  asserts correlation (the answer of question `<id>` is `<id>.json`), so
  a collision there fails loudly instead of silently breaking the
  question -> answer pairing; the answer is published only after the
  question file was acked (§6).
- **Undeleted-file retries (post-delivery)**: the delivering role tracks
  its deliveries; a delivered file that is still present (not ACKed)
  after the stale deadline is re-delivered as IDENTICAL bytes, at most 3
  attempts with exponential backoff (1s base, 60s cap); when attempts are
  exhausted the file is quarantined (§7) with reason `retry_exhausted`
  and a `retry_exhausted` notification is emitted — terminal, the answer
  is not lost (quarantine keeps content) but delivery stops retrying.
  The pure decision helper is `Hermes::RetryPolicy` (`wait` / `redeliver`
  / `quarantine`); the clock-and-loop belongs to the transport role
  (y24/A4) which composes these primitives.

## 9. Plugin surface (registry, notifications, formats)

Namespace `Ace::Hitl::Hermes`:

| Piece | Responsibility |
|---|---|
| `Channels::Registry` (§2) | channel registry + addressing, fail closed |
| `Formats` | message format registry: decode gate (UTF-8, 64 KiB, JSON, known schema) — exactly `message/v1` today; unknown versions fail closed |
| `Message` | typed value object + fail-closed validation + canonical JSON serialization |
| `AtomicWriter` | §5 protocol, no root |
| `Quarantine` | §7 moves + reason sidecars |
| `RetryPolicy` | §8 decisions |
| `Notifications` | deterministic single-line texts (no clock, no colors) for `question_received`, `answer_written`, `delivered`, `acked`, `quarantined`, `retry_scheduled`, `retry_exhausted` — each interpolating the message address |
| `Box` (organism) | the folder interface per channel: `publish` (write + collision retry), `poll` (validate + quarantine), `ack` (deletion), `age` (retry clock), `identical?` (redelivery identity) |

- Errors, all under `Ace::Hitl::Hermes`: `Error` (base), `ContractError`,
  `RootUserError`, `CollisionError`, `UnknownFormatError`,
  `InvalidMessageError`, `UnknownChannelError`.
- No CLI and no ace-hitl runtime dependency in this task: the plugin is
  the transport-side library; its wiring into the provider=lab dispatch
  is A4 (`8wm.t.vs2`). Notification emission is an injectable sink
  (default silent) so the library stays deterministic and quiet.

## 10. Acceptance (fast tests)

1. Contract constants pinned (versions, bounds, modes, quarantine paths);
   folder verification fails closed on missing/non-dir/world-writable.
2. Token + filename round-trips; every path-traversal or dotfile trick
   rejected.
3. Message validation: both kinds happy path; each violated rule named;
   id/filename mismatch rejected; canonical JSON round-trip.
4. Formats gate: unknown schema, bad JSON, over-size, non-UTF-8 → typed
   errors (quarantine upstream).
5. Atomic writer: file lands `0640` with exact bytes; no tmp leftovers;
   collision refuses and cleans up; euid-0 refused (injected euid).
6. Quarantine: move + reason sidecar + suffix dedup; poll excludes
   quarantine and tmp leftovers.
7. RetryPolicy: collision limit; undeleted wait → redeliver → quarantine
   progression with identical-content rule.
8. Channels: register/resolve/default/address; duplicates and unknown
   names fail closed.
9. Box end-to-end over a REAL temp folder: publish question → poll →
   write answer file → poll → ack → folder empty; invalid file lands in
   quarantine with reason and never in `poll` results.
10. Shipped JSON schema asset matches the implemented v1 rules (schema id
    + required fields).

## 11. Out of scope

- herdr push delivery to panes — A2 `8wm.t.vs0`
- provider=lab integration consuming this contract — A4 `8wm.t.vs2`
  (canonical contract file + shared contract tests live there)
- Telegram plugin migration (correlation, allowlist, routing data) —
  `8wm.t.y24`; generic HITL core — `8wm.t.y21`
