# Wake Pi agents through in-process loops and file watches: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Install a duty wake

```text
/loop add duty --interval 30 --message "Check task queue and HITL"
```

Expected: UI shows one subscription; each due event queues a wake without running business logic.

## Scenario 2: Watch durable state

```text
/watch add decisions --path /configured/decisions --message "Reconcile pending decisions"
```

Expected: A state change queues one bounded wake; repeated writes coalesce.
