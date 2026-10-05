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
