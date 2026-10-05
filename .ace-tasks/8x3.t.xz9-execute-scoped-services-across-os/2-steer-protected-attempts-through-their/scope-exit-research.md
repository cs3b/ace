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
