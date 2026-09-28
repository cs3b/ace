# Protect multi-user HITL state through a scoped privilege boundary: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Ask from worker role

```text
ace-hitl ask --assignment A --attempt ATT --project ace --question "Choose next scope"
```

Expected: Creates a bound request without root or direct write access to another role's store.

## Scenario 2: Reject another role's consumption

```text
ace-hitl consume --id REQUEST
```

Expected: A non-requesting identity receives a permission error; no answer is disclosed.
