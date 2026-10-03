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
