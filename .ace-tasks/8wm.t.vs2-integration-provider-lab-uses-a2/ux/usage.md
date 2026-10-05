# Integrate scoped HITL delivery without the Lab daemon: usage

Source interfaces below are implemented; actual installed Telegram/Lab acceptance remains open.

## Scenario 1: Ask without labd

```text
ace-hitl ask --provider lab --assignment assign685 --attempt attempt685 --project ace --question "Choose next scope"
```

Expected: Creates one scoped request without opening labd.sock.

## Scenario 2: Handle a dead requester

```text
ace-hitl pending --project ace
```

Expected: Shows an answered request awaiting deliberate recovery; answer is not silently lost or sent to another pane.

## Signed inbox reconciliation
After a send with unknown outcome, restart the supervisor: no resend occurs. A trusted observer verifies native consumption and submits an event-bound signed consumed proof; one completed delivery is visible. Signed superseded with verified non-consumption requeues the same event, optionally to its verified replacement target; it never marks the business effect successful. Wrong key/generation/attempt/target or missing observation stays uncertain. A timeout or a sixteen-hour proposal authorization is not consumption proof. Rotate keys with an unresolved event: retain the original trusted verification/signing context or defer rotation; do not rebind its fingerprint.

## Explicit live agent and pane-less consumer

```ruby
client = Ace::Hitl::LiveClient.new(root: checkout_root)
watcher = client.watch(request: request_id) { |queue_result| observe(queue_result) }
watcher.value
client.status(request: request_id)
client.reconcile(request: request_id, receipt_path: signed_receipt_path)
```

```text
ace-hitl wait --request hitl001 --timeout 30
ace-hitl wait --request otp001 --operation gem-push
```

The watcher belongs to its requesting process. Pane-less wait consumes through
authenticated IPC and does not claim native or business completion. A trusted
supervisor's signed native observation is required for reconciliation; explicit
verified supersession retry uses `retry_delivery: true`. OTP has no native inbox
event, answer file or payload digest in the shared envelope.

Configured `ace-hitl-hermes serve` publishes created requests for its registered
project channel and owns Telegram polling after Hermes gateway polling is
explicitly disabled. No manual folder post or Lab daemon is required in source.
Projects without a registered authorized channel remain visibly pending.

Actual gad.2/.8/.b verification still needs installed requester/signer OS users,
a real registered Telegram destination and actual native consumption/death
recovery. Local controlled fixtures are not that acceptance evidence.
