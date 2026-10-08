# Protected attempt consumer checkpoint

Source-only implementation of the reviewed remaining-consumer contract: actual
Client/Server bodyless `bind_inbox`, `finish`, and `recover` reach the maintained
Endcap, original LaunchLifecycle proof owners and canonical JournalMutation CAS.
No task status or whole-family acceptance changes are made here.

Binding selects the original registration/key from the fixed admitted Inbox
context and authenticates the live original worker. Fresh binding shares the
scope seal CAS gate; exact live replay creates no second registration.

Finish consumes the actual imported normalized result, requires independent
accepted review for succeeded results, and authenticates prior positive scope
closure, lifetime input inhibition and all service/Inbox settlement. It does not
stop or close the scope. Accepted receipt, legal terminal transition and reply
are one canonical commit. Historical replay uses original proof/settlement owners
without requiring a live worker or reacquiring current Inbox admission.

Recovery authenticates original prepared registration and scope facts, selects
one attempt only, and records an observation plus legal uncertainty transition
when needed. Exact replay retains its original result without new observation.
Terminal recovery authenticates original terminal/release metadata and is a pure
read: no reply event, generation increment, native effect or implicit restart.
Failed receipts may have empty artifact arrays; succeeded receipts still require
artifacts, and all supplied failed artifacts remain canonically verified.

## Executed controlled evidence

- `bin/ace-test ace-assign/test/feat/protected_attempt_consumers_test.rb`:
  PASS 5 tests / 69 assertions, 2m 27s, report
  `1e68438c-8bc4-43c6-8c7c-36d646d3eb62`. Five actual public socket/Git paths:
  original Inbox bind/replay/dead-worker refusal; failed finish/proof/replay and
  repeated unchanged-ref terminal recovery; succeeded finish requiring actual
  independent accepted review; original live prepared-owner adoption with held
  scope OS observation injected; dead-owner uncertainty/replay/role and changed
  input refusals. Production source unchanged during this final run.
- Earlier combined consumer and complete ReceiptVerifier file: PASS 22/123,
  report `b22f1b6c-0717-4c9c-b317-5503d152261a`, before later recovery additions.
  Includes failed empty/nonempty, changed artifact, succeeded empty and malformed
  artifact-array regressions. ReceiptVerifier bytes unchanged since that run.
- Intermediate actual terminal recovery: PASS 1/23, 37.46s,
  `c9a1f5ad-454e-4506-93c5-f42c60dd7943`.
- Intermediate dead-owner recovery: PASS 1/16, 23.97s,
  `96f55fc7-b41a-4b30-a90a-159295b83ffa`.

Retained failures: `a9238910` was fixture duplicate result-owner attachment,
repaired by constructing a fresh maintained lifecycle; `a631364e`, `76d28216`
and diagnostic `2014a98e` exposed historical failed-empty receipt rejection,
repaired in the shared ReceiptVerifier while retaining succeeded/nonempty rules;
`4909014a` asserted a local Conflict rather than the existing public sanitized
EvidenceUnavailable conflict response, repaired as assertion-only.

## Limits and pending verification

All OS/kernel/native observation effects are injected; ordinary temporary Git,
RSA Inbox signatures and public sockets are real. No installed/root/systemd or
native probe was executed. Registration uses the maintained Router fixture,
not a new public launch demonstration. The terminal recovery positive here is
terminal-but-unreleased; existing original release verifier remains reused, but
an additional actual released recovery composition is still required for full
family acceptance. Unknown Inbox/effect classification and release composition
remain review/coverage obligations. This checkpoint is not whole xz9 completion.

Current main's approved Server event-read-operation wrapper must be preserved
when joining this branch's bodyless-operation list; no duplicate wrapper is added.
Independent reviewer verdict is required before integration.
