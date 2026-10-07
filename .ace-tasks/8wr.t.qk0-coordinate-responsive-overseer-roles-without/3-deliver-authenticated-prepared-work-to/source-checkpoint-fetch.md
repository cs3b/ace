# Prepared fetch source checkpoint

Candidate registration/fetch source slice for independent review. This is not
qk0.3 completion: fixed adapter activation, scoped queue/CLI consumers, installed
protected task-context entry pin and captured Bundle consumption remain separate.
The prior registration checkpoint was independently reviewed and integrated.

The existing Endcap evidence_fetch operation accepts the closed prepared_work /
original_prepared_work / prepared_bundle selector with null mutation ID and no
body. Server and Client use the existing candidate purpose (one part, 64 MiB).
Ordinary result/service/review evidence retains its existing artifacts limits;
there is no second listener, ledger, FD handoff or alternate prepared fetch path.

LaunchLifecycle.original_prepared_registration! authenticates the complete fixed
canonical inventory, issued/open attempt, original provisioning descriptor/map/
journal association, maintained native/child scope lineage, guarded original
record, and exact registration at the reservation introduction. Endcap admits
only the live original worker or its authenticated descendant, with exact original
principal, child birth and native server liveness, before artifact reads. The
returned owner projection is deeply immutable. Definition and bundle reads use
bounded Git capture at the original registration commit, not mutable projections.
Client validates closed original selectors, hashes, transfer association and
non-mutation transport metadata before consuming bytes. Uploads are forbidden.

Controlled receipts, retained under this worktree .ace-local/test/reports/assign:

| Selection | Terminal evidence | Receipt |
| --- | --- | --- |
| Initial actual gate-ready/release, original self, no-journal-effects | 2 / 17 PASS, 20.24 s | e3cd7050-7a6e-4c66-b505-5de25df70af1 |
| Original birth/role/upload/purpose refusals | 3 / 28 PASS, 31.05 s | 343dfb31-60b9-43c5-bb71-b2f6f74b6d8a |
| Actual launch Server/Client >64 KiB, descriptor refusal before body, descendant, retained current projection | 7 / 89 PASS, 99 s | c0ac8633-db9f-4f64-9c22-884de658001c |
| Codec and public fixed transport regressions | 21 / 130 PASS, 242.73 ms | 5df02890-5629-4c43-835c-a1164be564c5 |
| Ordinary actual Endcap Client result download and invalid descriptor selections | 2 / 25 PASS, 30.01 s | 6400ee31-bcab-429a-98ec-f903e3694142 |
| Real frozen original/current Deployment and retained DeploymentHistory; missing original retention refuses | 1 / 9 PASS, 12.03 s | 30ebd3ac-0f72-43d2-b753-cc5430fcfb4f |

The eight-case run ae3e8d72-d783-4b1b-958b-4baad728fd03 executed 8 / 97 with
seven passing and one fixture error. DeploymentHistory.selects? correctly refused
a stand-in descriptor before fetch. The successor uses actual held artifact
bytes and source Deployment/DeploymentHistory schemas and selection; only installed
filesystem/native checks are controlled. No validator was relaxed. A method-name
--filter attempt f0e069dc-8be1-428d-8e92-e6c467a83273 selected zero files and provides
no test evidence; the actual existing cases ran through file:line selectors.

Final merged-base verification is recorded below when terminal. No native,
installed, protected-process, provider, mount, systemd or Linux probe is part of
this checkpoint. Worker activation/queue consumption remains unimplemented.
