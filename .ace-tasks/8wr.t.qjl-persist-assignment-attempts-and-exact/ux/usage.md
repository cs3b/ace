# Persist assignment attempts and exact execution evidence: draft usage

Target interfaces; these examples do not claim current implementation.

## Scenario 1: Create one attributable attempt

```text
ace-assign attempt start --assignment ASSIGNMENT --step STEP --project PROJECT
```

Expected: Returns a stable attempt ID; a repeated identical start does not duplicate execution.

## Scenario 2: Inspect uncertainty

```text
ace-assign attempt status --assignment ASSIGNMENT --format json
```

Expected: A lost external receipt is shown as uncertain with required reconciliation evidence, not as success or a retry.
