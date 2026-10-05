# xz9.0 implementation notes

The accepted authority contract and family test-plan.md govern implementation.
Status remains in-progress; no installed or distinct-UID proof is claimed.

## Historical missing cross-user gated launch boundary

This section records the implementation-discovered gap before 09j selection.
The reviewed 09j contract at 58188ef12 supersedes its unresolved transport choice;
09j implementation and actual protected native/policy acceptance remain required.
The observations and failed planning receipts below are retained as history.

The authenticated launcher and worker must use distinct OS identities: giving
the worker the launcher UID would also let it reserve/register attempts.
Current native runtime adapters launch commands under the caller's UID. An
unprivileged launcher cannot directly spawn the configured worker UID. The
accepted contract forbids introducing UID switching, a root broker or a domain
daemon; it currently does not specify the existing cross-user launch channel.

Root integration is inspecting deployment-controlled native runtime endpoint
ownership before selecting the mechanism. A protected native endpoint capable
of creating a gated worker-account child is a candidate only if its actual
installed authentication/ownership and exact PID/birth binding are proved.
Otherwise a generic ACE runtime launch receiver would require an explicit scope
and design amendment. Same-UID role collapse, sudo and fabricated child facts
cannot satisfy this boundary. Reserved attempts cannot dispatch before verified
bind; inability to obtain the exact gated child must fail closed.

Read-only source inspection confirms `lab-config/herdr-lab-overseer@.service`
runs as `lab-overseer-%i`, sets its own runtime directory and
`NoNewPrivileges=true`. `lab-config/lab.py:437` `project_herdr_argv` permits root
through runuser or the exact scoped user directly and rejects other UIDs. Its
docstring explicitly says another user cannot reach this user's native socket.
ACE's `ace-herdr/organisms/runtime_adapter.rb` composes native CLI calls and
exact process/session observations; `HerdrExecutor` currently accepts a binary,
not a protected cross-user endpoint/authentication map. None of these sources
proves the proposed trusted-launcher connect ACL or gated child channel. A
narrow native socket ACL with authenticated peer/endpoint checks is therefore
a proposed source/deployment amendment, pending actual backend capability proof.

Local host identity is UID 504. Executed sudo -n true refused because a password
is required. Local tests may exercise real same-UID sockets and immutable Git
storage, but cannot count as installed multi-UID acceptance. Root owns all Lab
SSH/installation; this worker performs no duplicate Lab action.

`bin/ace-task plan xz9.0` stalled without output for over three minutes and was
stopped. The bounded retry `bin/ace-task plan xz9.0 --timeout 30` failed with
"Codex CLI execution exceeded its 30.0s deadline". The accepted family contract,
test map and concrete responsibility map below supply the current plan; this
does not change unresolved behavioral decisions or count as implementation proof.

## Implementation/test responsibility map

| Behavior | Owner/source | Verification |
|---|---|---|
| Atomic imported bytes, chained provenance, mutation replay and CAS | EvidenceJournal + JournalMutation | Real Git feature tests; original reply after restart, changed params, rejected callback, immutable blob, binary bytes and traversal |
| Canonical blob/provenance reads across service/review/recovery | Shared import verifier + existing verifier readers | Corruption through every independent reader; projections deleted/replaced |
| Root configuration, role/schema and peer authentication | Assign authority transport/config | Pure schema tests plus real socket/filesystem integration; Linux multi-UID/macOS kernel peer smoke separately |
| Consume 09j registration/reserve/record/bind/release/abort and driver launch origin | Accepted 09j authority/runtime/driver APIs; xz9.0 endcap integration | Preserve exact admitted child and canonical launch state through the public origin APIs; no reconstructed or manually seeded origin |
| Candidate/review import and protected service endcap | Assign authority + coordinator/driver and Lab receiver | Object closure/symlink/config adversaries and distinct-user export/review/effect proof after accepted 09j origin |
| Protected request, dispatch ticket and handler staging/completion | Lab receiver + authority client | Real fixed fixture effect; duplicate/reply loss/revocation; preserved worker caller UID and actual separated accounts |
| Finish/recover/inbox byte transport | Assign coordinator + fixed inbox client | Current expected_registration/exact proof replay, both stores' crash windows, no private shared paths |

No mocked UID/stat/peer identity qualifies as a positive boundary test. All
package checks use bin/ace-test; final fast suite uses bin/ace-test-suite.
