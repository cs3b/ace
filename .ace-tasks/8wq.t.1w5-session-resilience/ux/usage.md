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
