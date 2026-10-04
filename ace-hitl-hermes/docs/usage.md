# Correlated Hermes Telegram transport

Install `ace-hitl-hermes` and configure the supervised `ace-hitl-hermes serve` actor as the only Telegram polling owner. Lab provides identities and deployment paths; the package owns routing, folder publication, protected IPC, correlation and checkpoint production.

## Configuration

A registry has no inferred default or legacy-file fallback:

```json
{
  "schema": "ace.hitl.hermes.channels/v1",
  "channels": [{
    "name": "project", "machine": "lab", "folder": "/run/hermes/project",
    "target": "project-overseer", "projects": ["project"], "chat_id": "-1001234567890",
    "captain_user_ids": ["123456789"]
  }]
}
```

Every project, group, folder and instruction target maps to exactly one channel. Captain IDs are numeric identities, never usernames. Topics within a group share that registered channel; separate authority requires separate registered groups.

A runtime file supplies concrete deployment configuration:

```json
{
  "schema": "ace.hitl.hermes.runtime/v1",
  "registry": "/etc/ace-hitl-hermes/channels.json",
  "state": "/var/lib/ace-hitl-hermes",
  "hitl_socket": "/run/ace-hitl/lifecycle.sock",
  "hitl_service_uid": 0,
  "token_file": "/run/hermes-secrets/telegram-bot-token",
  "polling_owner": "ace-hitl-hermes",
  "hermes_gateway_config": "/home/hermes/.hermes/gateway.yaml"
}
```

Run the actor as the unprivileged transport identity authorized by the `ace-hitl` service. The state directory and token file must belong to that identity and be private (0700/0600). Folder writes reject root and preserve the existing message.v1 0640 contract. `ace-hitl` authenticates both Unix socket peers and independently enforces project/actor authorization, liveness, OTP scope and expiry.

Before starting the actor, disable Telegram in the actual Hermes gateway configuration:

```yaml
platforms:
  telegram:
    enabled: false
```

Stop/restart the existing gateway to apply that change. `serve` validates this configuration and refuses an enabled or unverifiable Telegram gateway. Its state-directory polling lease excludes a second package actor. A Telegram 409/conflicting poll failure invalidates ingress coverage rather than pretending it is connected. Never run the package actor and Hermes gateway against the same bot at the same time.

```sh
ace-hitl-hermes serve --config /etc/ace-hitl-hermes/runtime.json
```

The actor sends non-Captain question files only after authenticating their corresponding lifecycle request. It uses the lifecycle attempt as the immutable transport revision. Plain Captain instructions remain question files with sender `captain`, routed to the folder's configured target. The target consumes those files using the existing folder contract and ACKs by deletion.

## Replies and recovery

Use Telegram Reply to the exact submitted request message, or `/hitl-reply REQUEST_ID ANSWER`. The command names an immutable request correlation in the same registered group; a conflicting Reply target is rejected. Plain messages create new instructions and never satisfy a pending request. Unknown Reply, missing registry, bad sender and malformed input fail closed.

```sh
ace-hitl-hermes delivery --request REQUEST_ID --config /etc/ace-hitl-hermes/runtime.json
ace-hitl-hermes ingress reconcile --request REQUEST_ID --through 2026-10-04T22:00:00Z --format json --config /etc/ace-hitl-hermes/runtime.json
```

The `ace.hitl.hermes.delivery/v1` result carries request/revision/channel/chat/message identities, status and trusted `submitted_at` only after Telegram confirms submission. Submission is not a read receipt. `failed` preserves the question and may retry; `uncertain` never automatically resends and starts no decision clock. Investigate uncertain sends before taking any recovery action.

The `ace.hitl.hermes.ingress-checkpoint/v1` result carries `healthy`, `drained`, checkpoint cutoff/sequence and unresolved correlated ingress metadata. Receipt time is stamped by the actor, not copied from Telegram. The actor journals receipt before delivery and advances its durable Telegram offset after processing. Only an empty update batch proves backlog drainage; poll failures, retention gaps, queued replies, uncertain submission and unresolved delivery produce unknown or undrained results. Each coverage break creates a durable generation and retains the prior epoch evidence. A recovered empty poll starts healthy coverage for fresh requests; requests submitted in an older generation remain unknown and cannot gain silence approval across the gap. A silence-based approval consumer must defer on those results and revalidate the checkpoint inside its decision transition.

The private journal retains correlation, ingress and terminal transport metadata for at least 24 hours. Authoritative lifecycle receipts remain in `ace-hitl` beyond that window. A resumed ordinary reply recovers from its protected folder answer; the lifecycle service prevents a repeated effect. Unresolved records remain visible and block drainage.

OTP answers bypass ordinary answer files. The low-level `HermesBox` answer publisher requires an authenticated request-classification callback and rejects OTP/sensitive classification before any file creation. The relay sends the value directly to `ace-hitl` authenticated IPC and records only a sanitized status. No OTP value or derived hash enters the journal, checkpoint, preview logs or target instruction folder. If the endpoint is unavailable or the actor crashes after journaling a secret receipt, `secret-unavailable` discards the transient value and disables further delivery on that original challenge; recover the endpoint and request a fresh authorized challenge/code. Telegram's third-party message history is outside this erasure guarantee.

## Gateway guard plugin

```sh
ace-hitl-hermes plugin install --path /home/hermes/.hermes/plugins/ace-hitl-hermes
```

Configure the gateway process with `ACE_HITL_HERMES_CONFIG` pointing to the runtime file, and put the installed executable on PATH (or set `ACE_HITL_HERMES_EXE` to its absolute path). The guard registers `/hitl-reply` and `pre_gateway_dispatch`, intercepting replies before inbound preview logging even when IPC/configuration fails. Its subprocess sends input through stdin and suppresses child output. The guard alone does not prove polling drainage; the supervised actor is the checkpoint producer. Package polling ownership still requires disabling the gateway's Telegram adapter.

## Exit codes and acceptance

Successful commands return 0 and JSON. Rejected input/configuration returns 1 with a sanitized error. SIGINT returns 130. OTP is never accepted as an argument: `receive` takes a bounded JSON event from stdin.

Local acceptance exercises registered controlled identities, real message folders, fsynced state, a real authenticated Unix socket and installed guard assets. Live Telegram channel acceptance and the Lab transport smoke/removal of `hermes-lab-hitl`, `lab-hitl-broker` and `lab-hitl-channels` remain explicit `lab-config:gad.2` delivery gates; local tests do not claim those deployment results.
