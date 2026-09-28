# Isolate package tests from ambient Lab and user configuration: draft usage

Target interfaces, not claims of implementation.

## Scenario 1: Run on a live Lab host

```text
ace-test ace-hitl all
```

Expected: Uses fixture identities/store/socket; live LAB_* settings cannot redirect the test.

## Scenario 2: Opt into a live check

```text
Configured ace-test-e2e scenario with explicit target
```

Expected: Runs against the named test target only; absent config errors instead of discovering production.
