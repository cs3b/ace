# Resume attributable agent work after process or session failure: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Inspect a failed session

```text
ace-assign resume --assignment ASSIGNMENT --dry-run
```

Expected: Shows verified surviving process or the exact restart/reconciliation requirement; changes nothing.

## Scenario 2: Adopt existing execution

```text
ace-assign resume --assignment ASSIGNMENT
```

Expected: A verified live attempt is adopted once; an uncertain external operation remains blocked on evidence.

## Signed inbox reconciliation
After a send with unknown outcome, restart the supervisor: no resend occurs. A trusted observer verifies native consumption and submits an event-bound signed consumed proof; one completed delivery is visible. Signed superseded with verified non-consumption requeues the same event, optionally to its verified replacement target; it never marks the business effect successful. Wrong key/generation/attempt/target or missing observation stays uncertain. A timeout or a sixteen-hour proposal authorization is not consumption proof. Rotate keys with an unresolved event: retain the original trusted verification/signing context or defer rotation; do not rebind its fingerprint.

Managed runtime ownership: the agent invokes `ace-assign attempt start` inside its tmux/Herdr pane. ACE records the adapter's exact native binding and OS owner birth identity, then `ace-assign resume --assignment ID --dry-run` compares both without writes. `adopt` preserves that attempt and never relaunches it. A retained shell with a dead agent, reused PID/pane/thread, inaccessible process information, or a CLI with no native owner is `reconcile-required` and keeps resources. Process observation supplies liveness only; configured actor/service authority and signed effect receipts remain separate requirements.

The read-only runtime adapter operation is `process_binding(pane:, caller_pid:)`. It returns string-keyed runtime/session/pane and shell/process identities (PID, UID, start time, host); Herdr includes terminal and immutable agent-session identity. Insufficient identity returns nil, while native execution failures remain typed runtime errors. No command lines, private keys or OTPs enter the journal.

Use `ace-assign inbox-reconcile --attempt ID --event ID --receipt proof.json` when the accepted signed Herdr proof must also enter assignment recovery history. The JSON/FILE.sig vocabulary and configured verifier are identical to `ace-herdr inbox reconcile`; no new signature dialect or business authorization is introduced.
