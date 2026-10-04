# Protect multi-user HITL state through a scoped privilege boundary: usage

All lifecycle operations run through the authenticated boundary service
(`ace-hitl serve`); identity is the kernel peer uid, never a flag or
environment variable.

## Scenario 1: Ask from worker role (managed binding)

```text
ace-hitl ask "Choose next scope" --assignment 8x3abc --attempt a1b2c3 --project ace
```

Expected: creates a request bound to the caller's exact active managed
attempt, verified under the assignment exclusion. A stale, ended,
replaced, or unproven attempt fails closed as a `BindingError`.

## Scenario 2: Reject another role's consumption

```text
ace-hitl consume REQUEST
```

Expected: only the requesting identity may consume; a foreign peer
receives `PermissionError` and no answer bytes are disclosed. Store
files stay service-owned (`0700`/`0600`); foreign uids get `EACCES`
from the filesystem and classified permission errors from the boundary.

## Scenario 3: Captain answers through the configured transport

```text
ace-hitl deliver REQUEST <<< "approved"     # as a grants-authorized transport uid
```

Expected: delivery requires the trusted transport identity
(`hitl.transport_uids` + principals project visibility); duplicate
deliveries are idempotent and never re-run an effect; liveness is
re-verified under the lock.

## Scenario 4: OTP for exactly one authorized operation

```text
ace-hitl ask "Publish otp" --assignment A --attempt T --project ace \
  --kind otp --otp-operation gem-push --otp-result-ref publisher:otp-required \
  --otp-input-digest <sha256> --otp-expires-at <ts>
ace-hitl consume REQUEST --operation gem-push
```

Expected: the challenge exists only with its OTP-required publisher
evidence; the secret transfers exactly once for the named operation;
retries replay the receipt WITHOUT the bytes; expiry/rejection prompts
again; the value appears in no file, log, projection, or argv.

## Scenario 5: Transport failures stay visible

```text
ace-hitl pending        # with the boundary service down
```

Expected: a classified `TransportError` (unavailable/untrusted
endpoint, deadline) — never a silent state change; retries recover
once the service returns.
