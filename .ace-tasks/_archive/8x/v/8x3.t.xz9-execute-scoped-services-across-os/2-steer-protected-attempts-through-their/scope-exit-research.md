# Execution-scope exit research — candidate, not readiness approval

Primary source checked 2026-10-05:
[Linux kernel cgroup v2 documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html).

The documented cgroup.events populated field covers live processes throughout
a subtree. cgroup.kill terminates a non-threaded subtree and handles concurrent
forks/migration. Migration requires write access at the destination and common
ancestor. Moving a parent does not move already-existing descendants.

Inference for review: a launcher-managed, worker-nonwritable execution scope,
established while the native bootstrap is still gated, could supply stronger
exit evidence than a child pidfd. This is not an implemented or selected ACE
contract. Required checks before selection include actual nonroot delegation,
no worker escape/repopulation or namespace bypass, exact scope identity across
restart, restricted control of unrelated processes, and native gated placement
without a race. Prove descendant/reparent/fork behavior in the isolated guest;
do not change shared host policy or introduce a privileged domain broker.

This research does not change 09j launch scope or count as positive installed
evidence. Readiness must compare this candidate with existing supported native
mechanisms and specify the smallest complete owner/installer contract.

Additional readiness constraint from the current native topology: containment
must include creation through accessible native control sockets or other allowed
spawners. A worker requesting another pane/process from a server outside its
execution scope can create a writer outside the observed subtree. An empty
subtree then cannot prove absence of all writers attributable to the attempt.
This is a threat-model requirement, not an executed exploit or selected solution.
Review must establish actual socket access, external-spawner restrictions and
what prevents later repopulation before accepting scope-exit evidence. Killing
all processes of a shared worker UID would also affect unrelated attempts and
is not an acceptable implicit substitute for exact scope ownership.

## Executed native-spawner evidence

The independently replayed 09j installed HVF fixture now supplies concrete
evidence for part of that constraint. In the
[retained independent proof](../../8x4.t.09j-launch-a-gated-worker-through/evidence/installed-independent-hvf/proof.json),
`worker_native_gate_mimic` records a worker-UID client connecting directly to
the real Herdr socket and creating another native child with `layout.apply`.
The probe uses the genuine installed gate and the original launch ticket; the
new PID differs from the canonical child. The authority correctly grants it
no permission and the payload count remains unchanged.

This proves accessible out-of-attempt native process creation in the current
fixture, not an escaped arbitrary writer or a cgroup exploit. The latter were
not tested. Therefore an eventual cgroup-based proof must also close or account
for this creation path; merely collecting descendants of the original child
cannot establish complete scope ownership. The accepted 09j exact-child
contract and its safe refusal remain unchanged.


## Ownership extraction, 2026-10-05

Draft 8x4.t.9c2 now owns selecting and delivering the generic exact-scope
no-writer capability above. xz9.0 finish and xz9.2 stop consume it; both retain
uncertainty until positive proof exists. This research selects no mechanism and
provides no positive readiness or installed acceptance.
