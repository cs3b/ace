# Installed .0 readiness verification — 2026-10-16, after wave-3 adoption

Read-only verification that the installed ordinary execution surface is complete
on the new cut (service release 2a900667…, owner PID 597187). No assignment,
attempt or merge was executed in this pass; this records the verified surface
and the composition boundary for the first delivery attempt.

## Verified installed surface

- Public CLI on the selected service graph: `ace-lab assignment
  {prepare,request,drive}`, `ace-lab service {listen,request,status}`,
  `ace-lab run`/`run-status`, `projects`, `route`, `resolve` — all present in
  ace-lab 0.9.0. Drive operations: status, supervisor, adopt-supervisor,
  bootstrap, next, start, step-start, step-finish, fail, result, adopt, replay.
- Request operation set documented in ace-lab/docs/usage.md: register_assignment,
  registration_status, start_attempt, assignment_snapshot, queue_start/finish/fail,
  submit_result, result_status, result_snapshot, finish, submit_candidate,
  assign_review, export_candidate, accept_review, cancel_review, review_status,
  merge_evidence.
- Receiver config `/etc/lab/ace-lab/ace-receiver.yml`: project ace, receiver
  lab-merge-ace UID966, principal mo UID1000, repo /lab/projects/ace, execution
  identity ace-canonical/main, forge + policy paths bound.
- Dedicated forge credential `/etc/lab/ace-lab/ace-forge-merge.yml` (root:964
  0640) present with base_url/owner/repo, merge timeout 900s, review attachment
  enabled. No credential values recorded here.
- Owner selection `/etc/lab/ace-lab/assign-owners.yml`: participant mo UID1000,
  workspace w1, supervisor pane w1:pS, herdr runtime; worktrees root
  /lab/projects/ace/.ace-wt; native receipt generation 48ebd7dc… (peer herdr
  0.9.1/protocol 22) still the live session (PID 514709).
- Native session `lab` workspaces: w1 (overseer, pS = idle Pi session
  01a144bd…, plus one free terminal p1F) and w6 (legacy ace coordinator,
  untouched). Fresh worker panes for w1 must be created for the two delivery
  attempts and the independent reviewer (distinct process generation, session
  UUID and pane per usage.md).
- Lab project `/lab/projects/ace` at 32f1dd59d (deliberately stale, no blind
  sync), Forgejo origin configured, branch config references origin.

## Composition boundary (next concrete action)

`ace-lab assignment prepare --task` requires a composed assignment graph:
task status pending/in-progress, leaf, `needs_review: false`, and a steps
directory whose files parse as StepFileParser markdown (frontmatter name/status
plus `context: fork` + `taskref` on exactly one fork root; queue steps share its
numbered scope) with job.yaml. The Lab project currently contains NO `.st.md`
step files or job.yaml — the graph for delivery attempt 1 must be composed
first via `ace-assign create`/`add` (present in the selected coordinator graph,
ace-assign 0.71.0), then registered from pane w1:pS.

Eligible content: the two serial PRs are real Lab-project deliveries
culminating in one authorized release per .7; host-side ACE development stays
out of Lab workers per the environment contract. The Lab mirror task tree
(8xf.t.ei9-wave-3 in /lab/projects/ace) is the natural backlog source; its
records/doc deliveries do not conflict with host-side canon.

## Negative-proof plan (from the spec)

After the first green path: missing grant, wrong UID, wrong project, stale
base/head, wrong reviewer, expired/revoked decision refusals; head change
between GET and POST refuses before merge; injected nil/404 after attempted
merge stays uncertain (never settle_no_effect or replay); caller/receiver
restart after lost response recovers the same effect once; untrusted config
refresh refuses. PR2 decision is created and admitted AFTER the first merge
with the receiver still running (no restart, no preloaded pair).
