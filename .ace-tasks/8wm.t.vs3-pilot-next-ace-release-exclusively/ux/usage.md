# Prove release publication through scoped HITL and the tested publisher: draft usage

Target interfaces, not claims of implementation.

## Scenario 1: Publisher asks for OTP

```text
Run the approved scoped release workflow for an exact package/version
```

Expected: Only an OTP-required publisher response creates a secret HITL request.

## Scenario 2: Avoid duplicate publication

```text
Inspect service status after uncertain publisher termination
```

Expected: Verify registry result and reconcile the receipt; do not blindly republish.
