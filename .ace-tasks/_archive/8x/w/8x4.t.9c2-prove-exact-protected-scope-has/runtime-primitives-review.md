# 9c2 runtime primitives — independent checkpoint review

Exact head: `0a53295ef00c19d42a6dbb34f875d62142547b28`. Verdict: **APPROVE this source checkpoint**. No verified actionable findings. Reviewed all five changed files in native isolated worktree `/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime`, branch `codex/review-9c2-runtime`; no tracked edits, author-worktree tests, source fixes or delegation.

SystemdScopeManager exposes fixed constructor-selected dedicated units, bounded show/start/stop operations, system-manager selection, no password prompt, sanitized environment and no stdin. It rejects malformed/duplicate/incomplete properties and placement changes. Command output is bounded across both streams; unsuccessful/unknown operations refuse without adapter retry. Its owned subprocess is killed and reaped on timeout/oversized output; successful/nonzero exits are already reaped before cleanup. No stale post-reap PID signal was found.

CgroupObservation pins the actual parent directory descriptor and records mount/type/device/inode. Observation reads cgroup.events through that descriptor, verifies the current pathname before/after, and refuses replacement, non-host unified mount, missing/malformed population or denied reads. Membership requires the exact subtree delimiter and independently supplied kernel birth/liveness checks before/after. Population zero remains a kernel observation only: neither primitive manufactures canonical seal, no-writer proof, lifecycle admission or release.

These primitives intentionally do not yet prove the full 9c2 installation boundary, manager InvocationID continuity, native readiness/connected-peer discipline, sealed effect admission, settlement, or lifecycle CAS/replay. The later owner layer must combine these checks under the approved contracts; installing or observing this checkpoint alone is not whole-task or Lab acceptance. Preadmission/read races cannot be described as a permanent seal without that layer.

## Independent executed receipts

- Candidate's two focused files: **14 tests / 82 assertions PASS**, execution `1bafc8dc-b413-41d9-bb46-ca4080a158b7`.
- Reviewer-only ordinary subprocess boundary tests: **4 / 29 PASS**, execution `22148ac7-46bd-484e-9d4b-027246d839e7`. The real Command adapter drained both streams, enforced combined output limit, refused nonzero exit, and timed out/killed/reaped its owned harmless Ruby child. Platform/file prerequisites were controlled; Process.spawn was redirected to that fixture executable. No systemctl/native/system-manager call occurred.
- Full runtime all: **189 / 567 PASS**, execution `e9401065-4b85-4121-b7ba-2d824cc35657`.

All ran through `bin/ace-test` in the reviewer worktree. Immutable receipt summaries are under its `.ace-local/test/reports/runtime/<execution_id>/summary.json`. A first reviewer-test invocation used a package-relative path incorrectly and failed to load (zero tests); rerunning with the absolute fixture path produced the receipt above. Reviewer fixture remains under `.ace-local/review/manager_command_boundary_test.rb`; no product test was altered.

No native/VM/privilege/SSH/security probes or installed tests were run. Whole 9c2 acceptance remains explicitly open under the local-code → gem-publication → Lab-tests sequence.
