# Integrate scoped HITL delivery without the Lab daemon: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Ask without labd

```text
ace-hitl ask --provider lab --assignment A --attempt ATT --project ace --question "Choose next scope"
```

Expected: Creates one scoped request without opening labd.sock.

## Scenario 2: Handle a dead requester

```text
ace-hitl pending --project ace
```

Expected: Shows an answered request awaiting deliberate recovery; answer is not silently lost or sent to another pane.

## Signed inbox reconciliation
After a send with unknown outcome, restart the supervisor: no resend occurs. A trusted observer verifies native consumption and submits an event-bound signed consumed proof; one completed delivery is visible. Signed superseded with verified non-consumption requeues the same event, optionally to its verified replacement target; it never marks the business effect successful. Wrong key/generation/attempt/target or missing observation stays uncertain. A timeout or a sixteen-hour proposal authorization is not consumption proof. Rotate keys with an unresolved event: retain the original trusted verification/signing context or defer rotation; do not rebind its fingerprint.
