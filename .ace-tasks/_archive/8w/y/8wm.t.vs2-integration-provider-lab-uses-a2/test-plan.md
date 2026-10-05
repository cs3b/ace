# Test responsibility and coverage

| Boundary | Deterministic owner | Cases |
| --- | --- | --- |
| Pure managed contract | ace-hitl-contract managed_envelope and dependency/installed-consumer tests | Version, exact scope/correlation, distinct nested schemas, digest, secret exclusion, incarnation, leaf graph and standalone installs |
| Active native requester | ace-assign runtime_binding_consumer tests | Accepted journal source, unchanged refs/cache, returned-value isolation, unrelated same-UID PID, changed/dead native owner, missing history |
| Authenticated create/wait | ace-hitl CLI ask/wait and lifecycle suites | Kernel peer PID, unavailable PID refusal, removed Work form, scoped answer consumption, no folder/local answer fallback, managed unscoped-resume refusal |
| Explicit live client | ace-hitl feat/live_client tests | One submission/effect, in-process watch, queue acceptance versus proof, interrupted registration/restart, wrong envelope/native owner, invalid signature/digest/generation/key, explicit supersession retry, OTP protected consume, missing signer |
| Real ingress producer | ace-hitl-hermes managed_pending_publication tests | Scoped request without manual post, registered project routing, duplicate single send, folder collision refusal, existing single polling owner |
| Shared consumer semantics | Herdr Inbox and Hermes Telegram tests | Packaged examples, immutable managed metadata, wrong version/attempt/correlation/digest, secret answers, ingress received_at and healthy/drained/unknown coverage |
| Receipt authority | Existing Herdr and accepted Assign recovery suites | Existing verifier, atomic journal registration, signed consumed/superseded, replay, native target and fingerprint checks; no duplicate journal |

Run modified package `all` targets plus the default monorepo suite. Preserve failed and successful receipts and retained installer artifacts. Existing privileged/installed tests that skip remain explicit gaps.

Actual Lab acceptance still requires a registered Telegram Reply, requester death/recovery, trusted signer and requester OS users, and actual native Codex/Pi consumption or non-consumption. Controlled transport/native fixtures and local gem installs cannot satisfy gad.2/.8/.b or SC2. No publication or task-done transition is authorized here.
