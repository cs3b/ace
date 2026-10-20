# Native HITL files through the existing Hermes gateway

Use this mode when ACE owns `.ace-local/hitl` events and Hermes already owns
Telegram polling. It needs no lifecycle socket, Ruby in Hermes, bot-token copy,
new daemon, or root. The packaged Python plugin runs a supervised task inside
the existing gateway and its pre-dispatch hook; the existing project wake runs
one `ace-hitl-hermes sync` pass. Installing files does not activate the plugin.

The Python adapter uses the existing Hermes live-adapter and gateway-loop
interfaces (`tools.send_message_senders._live_adapter`,
`tools.send_message_tool._dispatch_on_gateway_loop`, `adapter.is_connected`,
`adapter.send`). Adapter lookup uses `gateway.config.Platform.TELEGRAM`,
not a string: Hermes keys its scoped adapter map by a plain enum. These were inspected against Hermes 0.21.3. If those interfaces
are unavailable, do not enable the route: no standalone bot fallback exists.
Hermes cancels the task through `ctx.spawn_task` on plugin unload/reload.
Its early background plugin discovery has no event loop. The plugin registers
`ctx.register_platform_handler("telegram", ...)`; Telegram's existing async
`connect` calls that factory and starts the supervised task. An outbound-only
request therefore does not wait for an incoming message. Repeated connect
callbacks retain one running task. Reload into an already connected gateway
starts through the same guarded activation on its existing loop.

## Configuration and activation

Inventory the actual gateway, enabled plugins, all existing groups, unresolved
requests and current route ownership first. Keep one poller. Never activate
`ace-hitl-hermes serve` alongside an already polling Hermes gateway. Keep other
groups and their owners intact; switch the selected group's old hook/route and
this native hook as one coordinated cutover, so two handlers never claim it.
Pending old-protocol questions keep their original broker owner through the
optional transition adapter below; they need not be cancelled or reissued.
Native transport does not relabel or discard them.

Use an existing private shared directory visible to both processes, owned by
their mapped non-root UID, mode 0700. The path may differ on the two machines.
Native event roots must also exist, be owned by the invoking user, have mode
0700 and contain no symlink component. Do not loosen those modes to grant a
different role access. This transport uses the already approved same-UID mount;
it does not grant identities or cross an arbitrary OS trust boundary.

Example ACE `.ace/hitl/config.yml` (replace all example paths and identities
with reviewed project configuration):

```yaml
machine: lab
recipients:
  overseer:
    machine: lab
    panel: w7:p1
  captain:
    machine: lab
    panel: lab
adapters:
  routes:
    - route: coordinator
      adapter: terminal
      recipients: [overseer]
      runtime: herdr
      machine: lab
      pane: w7:p1
    - route: captain
      adapter: hermes_native
      recipients: [captain]
      machine: lab
      channel: lab
      project: ace
      folder: /lab/state/hitl-address
      event_roots: [/lab/projects/ace/.ace-local/hitl]
      worktree_roots: [/lab/worktrees/ace]
```

`event_roots` are exact absolute event roots. `worktree_roots` allow only the
shape `<configured-base>/<one-worktree>/.ace-local/hitl`; nested arbitrary paths
and `..` are refused. Add explicit roots for a different project layout. Route
selection resolves recipient names to their exact stored address before any
adapter runs. Unrelated terminal/Telegram routes are not invoked.

The gateway JSON config selected by its existing `ACE_HITL_HERMES_CONFIG`
environment variable:

```json
{
  "mode": "native-folder",
  "interval_seconds": 1,
  "channels": [{
    "name": "lab",
    "machine": "lab",
    "folder": "/opt/data/lab-hitl-address",
    "chat_id": "-1000000000000",
    "allowed_users": ["1000000000"],
    "instruction_project": "overseer-lab",
    "projects": {
      "ace": {
        "event_roots": ["/lab/projects/ace/.ace-local/hitl"],
        "worktree_roots": ["/lab/worktrees/ace"]
      },
      "overseer-lab": {
        "event_roots": ["/home/mo/Labs/overseer-lab/.ace-local/hitl"]
      }
    }
  }]
}
```

The event paths are the ACE-side paths, checked lexically by Hermes and against
the real filesystem by ACE. They need not exist inside Hermes. Never accept a
path or project supplied in Telegram text. Group IDs and user IDs above are
fixtures, not usable account configuration. A channel has exactly one chat,
folder and instruction owner; duplicate ownership fails configuration loading.

### Existing broker and host groups during cutover

When the current plugin also owns host groups or old pending questions, a
native-only replacement is insufficient. Enable the packaged transition
adapter in the **same** gateway config:

```json
{
  "legacy_broker": {
    "socket": "/run/lab-hitl/broker.sock",
    "service_uid": 0,
    "channels": "/run/lab-hitl/channels.json",
    "correlations": "/run/lab-hitl/correlations.json"
  }
}
```

Merge this object alongside `mode` and `channels`, not instead of them. Paths
and service UID must match the existing endpoint in the gateway's namespace.
The peer UID is checked using Unix socket credentials; file ownership alone is
not endpoint identity. Projection files must be regular, not symlinks, owned by
the configured service or current user, and not writable by other roles.
No bot secret, broker credential, new service or grant belongs in this config.

The single packaged pre-dispatch callback selects one owner:

1. An exact Reply to a recorded legacy question, including in the newly native
   Lab group, goes to the existing broker after the original channel/user check.
   An ambiguous correlation is refused. Old OTP questions are never recreated,
   replayed as fresh challenges, copied into native cases or automatically sent.
2. Other selected native-group events go to native transport. This includes
   native exact Replies and plain instructions for its coordinator.
3. Other registered host groups retain their original broker channel.
   `/hitl-reply` remains the explicit legacy broker command.
4. Unknown Replies never become plain instructions. Unauthorized senders produce
   no broker request or native file. Unknown unrelated groups keep their current
   Hermes behavior.

The adapter reads the broker's current sanitized projections and calls its
existing `reply`, `command` or `overseer-message` protocol. It does not edit the
projections or decide the broker's result. A lost broker response is not retried
and never falls back into a native case; reconcile through the existing owner.
No answer text is written to plugin logs. The broker's own state remains the
result authority; this adapter does not reproduce the former optional emoji
reaction acknowledgement.

Deploy all packaged plugin files, including `legacy_transition.py`, and disable
the former `lab-hitl` hook in the same reviewed plugin configuration change.
Keep its broker, channel table and correlation files intact. Do **not** run both
hooks: Hermes executes all pre-dispatch callbacks before interpreting `skip`,
so callback ordering cannot prevent duplicate effects. No outside Python module
is imported as a compatibility override. An owner may later remove the
transition config only after all groups and old questions have a replacement
owner and preserved evidence.

Install assets from the released gem into a fresh, user-owned staging path:

```sh
ace-hitl-hermes plugin install --path /absolute/staging/ace-hitl-hermes
```

Review the staged `plugin.yaml`, `__init__.py`, `native_transport.py` and
`legacy_transition.py` against
the installed gem, then deploy those package assets through the existing
gateway's user plugin mechanism. Point the gateway at the reviewed native
config and use its existing reload procedure after accounting for pending
messages and disabling the previous hook when using the transition adapter.
No Ruby or ACE executable is installed in the gateway. A CLI-only plugin
discovery registers the deferred factory but does not spawn a gateway task.

## Sending, Reply and owner reconciliation

Create and send the canonical event from its original worktree:

```sh
ace-hitl create "Continue with the next batch?" --to captain
ace-hitl send CASE_ID
```

The first send can report `unavailable` with detail `queued`. This means the
request file was accepted, **not** that Telegram received it. Keep the same case;
do not create a replacement request. The plugin sends through the already
connected adapter, preserving every returned message ID for split messages.
An exact Telegram Reply to any of those message IDs binds to the original
project, event root, file and case. Replies from other users are refused.
Unknown Replies are retained privately and never become instructions.

For `sync`, save the exact native route object above as a JSON file (same
`route`, `folder`, `project`, `channel`, `machine` and root lists). The owner runs:

```sh
ace-hitl-hermes sync --config /absolute/project-native-route.json
```

This is one pass, not a service. It reads transport delivery receipts, updates
the original event's existing `delivery.<route>` status, and imports exact
Replies through ace-hitl. Output contains counts, transport keys, states and
error classes only, never answer text. Nonempty errors make the CLI fail.
An exact replay does not rewrite the answer. A conflicting later answer cannot
overwrite the first answer; an explicit local answer edit remains deliberate.
No latest-question lookup, main-worktree fallback or task-ID guessing occurs.

For the coordinator's own sync route, use `project: overseer-lab`, its exact
`event_roots`, and `instruction_root` equal to its one explicit event root.
Only that owner imports plain group messages as tagged canonical HITL reports
(`hermes-instruction` plus a stable transport tag). Such a report means an
instruction was received; the coordinator still decides what to do. It is not
a task-completion or authorization result. Other project sync passes ignore it.
Native mode uses Telegram Reply, not the lifecycle `/hitl-reply ID` command.

## Failures, retention and rollback

Transport protocol is `ace.hitl.hermes.native/v1`, with a 64 KiB frame limit.
Request identity hashes `[project, original_event_file, case_id]`, so equal
case IDs in different worktrees stay distinct. Files are atomic, private 0600
in a 0700 real directory; symlinks and conflicting immutable frames fail closed.
Only ACE writes canonical HITL cases. Hermes writes delivery/ingress receipts;
the Reply and instruction ingress files are removed only after owner import.

Delivery states:

| State | Meaning and next action |
| --- | --- |
| `queued` | Request exists; no delivery receipt yet. Let the existing gateway process it. |
| `waiting_gateway` | Live adapter was unavailable before send. Its next connected pass may send. |
| `sending` | Receipt persisted before invoking the gateway adapter. |
| `delivered` | Adapter returned success and concrete Telegram message IDs. Sync records confirmation. |
| `unknown` | Send result was lost, timed out or ambiguous; restart does not resend. Reconcile Telegram before an explicit recovery decision. |
| `rejected` | Envelope failed validation before a send; correct the producer/configuration under its original owner. |

Neither a transport receipt nor an answer grants merge, publish or deploy
authority. Protected action/OTP authorization remains with its existing owner.
Short-lived answers may traverse this private transport, but must never be
copied into git, logs, task reports or plugin diagnostics.

Keep request/delivery evidence while its case remains active. Once the owner
has accepted the result and preserved the canonical evidence, it may retire
that exact case's transport files with its ordinary case cleanup; do not delete
unknown sends or unmatched Replies. Moving/deleting an original worktree while
its native transport files remain active fails reconciliation, rather than
redirecting to a different worktree. Retention policy is an owner decision, not
an autonomous plugin cleanup timer.

Rollback first stops/unloads only this plugin's task and selected-group hook,
then restores the reviewed former route ownership. Preserve all folders and
unresolved receipts; do not reset files to trigger retries. The existing
gateway remains the sole poller throughout.

Installed acceptance still required: released assets outside source overrides,
real shared mount and UID checks, existing gateway readiness, two original
worktrees, ordinary message to coordinator, exact authorized Reply, duplicate
ingress, gateway restart, no adapter before startup, and lost send response
without duplicate sends. Unit/fixture tests do not claim live Telegram delivery.
