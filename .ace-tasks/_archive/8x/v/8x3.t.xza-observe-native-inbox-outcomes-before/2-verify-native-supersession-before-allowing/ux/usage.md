# Verify native supersession before allowing delivery retry — draft usage

## Positive scenario

A trusted observer proves the old exact Codex/Pi delivery cannot still execute before a signed superseded proof permits another delivery claim.

Existing y23 superseded vocabulary (queue_evicted, queue_expired, thread_replaced) and fresh replacement_target apply. Native atomic cancellation/retirement semantics remain evidence blockers; no queue absence or elapsed-time shortcut.

## Refusal scenario

Wrong peer or stale/missing exact binding returns a classified refusal/uncertainty, invokes no retry and grants no signing authority.

## Acceptance

Race actual native dequeue with delete/retirement for each provider and retain positive native outcome evidence tied to exact IDs.
