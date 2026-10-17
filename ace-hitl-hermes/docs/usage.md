# ace-hitl-hermes usage

Folder-as-interface HITL transport for the hermes relay. This package owns
transport routing and folder publication; HITL event state stays with
`ace-hitl`.

> **State owner:** none for task, assignment, or HITL-event state. This package
> keeps only its private transport state (journal/offsets) under the configured
> state directory. See [docs/lab-flow.md](../../docs/lab-flow.md).
>
> **Removed (L1):** second-commander proposal reconciliation was removed with
> the old installed authority model. The relay handles only local HITL/relay
> traffic: pending publication, delivery and ingress reconciliation.

## Configuration

A registry has no inferred default or legacy-file fallback:

```json
{
  "schema": "ace.hitl.hermes.channels/v2",
  "channels": [{
    "name": "project", "machine": "lab", "folder": "/run/hermes/project",
    "target": "project-overseer", "chat_id": "-1001234567890",
    "captain_user_ids": ["123456789"],
    "projects": {
      "project": {"hitl_service_uid": 1200, "hitl_socket": "/run/ace-hitl-project/lifecycle.sock"}
    }
  }]
}
```

A group has one instruction target and an explicit `projects` map. Each project
selects exactly one route; local routes require both an absolute `hitl_socket`
and `hitl_service_uid`. Project names are unique across the registry. Captain
IDs are numeric identities, never usernames.

Pre-create the channel instruction folder and each
`CHANNEL_FOLDER/projects/PROJECT` folder. Project question/answer files and
addresses (`machine/channel/project/request`) retain project identity even when
two routes use the same request ID in one group. Channel roots must be disjoint
after canonical path resolution; project directories and their `projects` parent
must not be symlinks. Startup verifies every folder before enabling the poller.

The closed runtime configuration is `runtime/v2`:

```json
{
  "schema": "ace.hitl.hermes.runtime/v2",
  "registry": "/etc/ace-hitl-hermes/channels.json",
  "state": "/var/lib/ace-hitl-hermes",
  "token_file": "/run/hermes-secrets/telegram-bot-token",
  "polling_owner": "ace-hitl-hermes",
  "hermes_gateway_config": "/home/hermes/.hermes/gateway.yaml"
}
```

Run the actor as the unprivileged transport identity. The state directory and
token file must belong to that identity and be private (0700/0600). Folder
writes reject root and preserve the `message.v1` 0640 mode.

Before starting the actor, disable Telegram in the actual Hermes gateway
configuration:

```yaml
platforms:
  telegram:
    enabled: false
```

Stop/restart the gateway to apply that change. `serve` validates this
configuration and refuses an enabled or unverifiable Telegram gateway. Its
state-directory polling lease excludes a second package actor. Never run the
package actor and the Hermes gateway against the same bot at the same time.

```sh
ace-hitl-hermes serve --config /etc/ace-hitl-hermes/runtime.json
```

A single-pass run reports a transient pending-publication outage to its caller;
continuous `serve` reports the unavailable channel on stderr, waits one second,
keeps its polling lease, and retries on the next cycle.

## Folders and delivery

The actor sends non-Captain question files only after correlating them to their
request. Plain Captain instructions remain question files with sender
`captain`, routed to the folder's configured target. The target consumes those
files using the folder contract and ACKs by deletion.

`HermesBox` is the folder primitive: `publish`, `poll`, `ack`, `age`,
`identical?`. Invalid files are quarantined and never delivered.

## Replies and recovery

Use Telegram Reply to the exact submitted request message, or
`/hitl-reply REQUEST_ID ANSWER`. The command names a request correlation in the
same registered group; ambiguous IDs and conflicting Reply targets are
rejected. Plain messages create new instructions and never satisfy a pending
request. Unknown Reply, missing registry, bad sender and malformed input fail
closed.

```sh
ace-hitl-hermes delivery --channel CHANNEL --project PROJECT --request REQUEST_ID --config /etc/ace-hitl-hermes/runtime.json
ace-hitl-hermes ingress reconcile --channel CHANNEL --project PROJECT --request REQUEST_ID --through 2026-10-04T22:00:00Z --format json --config /etc/ace-hitl-hermes/runtime.json
```

The `ace.hitl.hermes.delivery/v1` result carries project/request/revision/
channel/chat/message identities, status and trusted `submitted_at` only after
Telegram confirms submission. `failed` preserves the question and may retry;
`uncertain` never automatically resends. Investigate uncertain sends before any
recovery action.

Do not rewrite or reset the retained transport journal. Stop the poller first,
preserve the state directory and folders, and verify the retained route before
restoring any file.

## Planned waves

> **Planned (L2):** one unified HITL report/question/reply interface with
> configurable adapters (single or set) is not available yet. The authenticated
> service boundary, OTP scope/expiry, and multi-user protected store belong to
> L2 and are not requirements of the local file-based flow.
