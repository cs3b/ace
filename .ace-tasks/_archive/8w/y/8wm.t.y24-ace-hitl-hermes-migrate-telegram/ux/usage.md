# Provide correlated Telegram transport through the Hermes package: usage

Package interfaces are implemented and locally exercised. Live Telegram/Lab acceptance remains pending; see the implementation report.

## Scenario 1: Reply to a question

```text
Telegram Reply to the request message: "Use option B"
```

Expected: Only the correlated request receives the answer; other requests stay pending.

## Scenario 2: Send a new direction

```text
Plain Telegram message in the project's channel
```

Expected: Creates a new instruction for the configured project target; does not answer an outstanding question.

## Scenario 3: Verify submission and cutoff

```sh
ace-hitl-hermes delivery --request ID --config RUNTIME_JSON
ace-hitl-hermes ingress reconcile --request ID --through UTC --format json --config RUNTIME_JSON
```

Expected: Only an acknowledged submission starts a consumer decision clock. Unknown/unhealthy/undrained ingress defers timeout approval.

## Scenario 4: Adopt one polling owner

Disable Telegram in the actual Hermes gateway configuration, restart that gateway,
and run `ace-hitl-hermes serve --config RUNTIME_JSON` as the authorized transport actor.
An enabled/unverifiable gateway configuration or competing package actor is rejected.

## Scenario 5: Reply with an OTP

Reply to the authorized OTP challenge in the registered group. The code crosses
protected HITL IPC and never becomes an ordinary answer file or public checkpoint.
If the endpoint is unavailable, recover it and request a fresh authorized code.
