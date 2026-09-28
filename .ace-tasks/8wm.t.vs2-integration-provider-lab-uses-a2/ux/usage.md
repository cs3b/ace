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
