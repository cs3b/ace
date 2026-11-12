# Preserved UTM live cycle — acceptance evidence

Status: preserved, operator-assisted delivery/recovery run complete. Parent task remains in-progress for recorded product/process follow-ups.

## Scope

One repaired run on VM `A98D75CB-E338-4EE1-B503-1BF7D4BCD752`, scenario data `27d89c111762acc3`. Local Forgejo, Pi/GLM. No VM reset or fixture reseed. This is operator-assisted acceptance, not proof of an unchanged release or two reproducible clean runs. Omarchy, Incus and Hermes are excluded.

## Delivery evidence

| Issue | Candidate approved by e2e-reviewer | Merge commit |
|---|---|---|
| 1 primitive, PR5 | 20fe7b91f7eae4748069edc7e1d4dc74b4b44a5e | 051f957972d6b6c3fd77562326a85682255811ef |
| 2 dependent CLI, PR7 | 099ad61894751ec8424088b0d02291d7cc7248d5 | f0854378a94eb4405e357b1e9bba1fd6814cecc3 |
| 3 documentation, PR6 | 6fd2fd44cb5c88b1e2c439e873a502f8b0e3a5b4 | 6aa71d99606b9184cb88202faa6242f32d341a40 |

Independent read-only API audit confirms all three PRs merged, approvals bind to their exact candidate HEADs, and merge parents establish primitive → CLI → docs. Remote main is the docs merge SHA. Main README.md, counter_cli.rb and counter.rb blobs exactly match approved candidates. Issues1–3 closed, release issue4 open. No host-created fixture code, approvals or merges.

Bootstrap: worker8yatf4, report8yatrk; verifier8yatf41, report8yau1u; lab manager8ya.t.tcy. Delivery role chains:8yaudt/8yaudt1/8yaudt2,8yavwb/8yavwb1/8yavwb2,8yavwq/8yavwq1/8yavwq2. Final reports8yay2p/8yay5w adopted; private legs completed. Detailed executed-test and review records remain in task worktrees and incident register.

## Replay and restart

Repeated public coworker report for docs integrator returns original event8yay5w. Replacement project coordinator recognizes12 already-processed reports and creates no new executors.

First restart probe was contaminated by operator bare-start calls overlapping lab automatic recovery. Extra manual session stopped. This exposed ProjectSessions incorrectly treating retained dead tabs as live ambiguity; fixed/tested/reviewed in822b69ee60ff8e2f25b1fd06fdad59bf722f9260, installed as0.30.2.pre.9. All observation sources then healthy.

Second probe: operator only sent `/quit` to projectw3:pD. Lab independently inspected dead sessions, removed dead terminal tabs, called standard reconcile and started exactly one replacementw3:pE, terminalterm_66008305f54d115, session2026-11-11T23-02-28-759Z_01a1ccd9-3288-70ba-ada2-fd8df8e14ccc.jsonl. First-turn eyes ready. Owner reconciliation completed: all12 prior reports recognized, no unmatched reports, no new workers; pending0 and healthy sources at23:07:13UTC. Lab mistakenly describes deliberate fault injection as spontaneous failure; no host failure has been demonstrated.

## Role boundaries and caveats

Original lab/project coordinator JSONL audit found no bundle/gem/apt install commands. Direct write/edit tools touched commission, prompt and task-spec files only. Additional bash audit found a raw task-record commit and one manual report move at19:56:36UTC before the report projection repair. No installation/configuration/fixture implementation edits were found, but coordinators performed implementation-level tool-source diagnostics and piped CLI outputs. These are recorded role/process deviations, not a claim of perfect instruction compliance. Successor committed pre-existing task archive/config files; did not author fixture implementation.

Question8yaycc was incorrectly marked answered during cleanup, then cancelled with explicit audited reason acknowledging that mistake. No human answer is claimed. Earlier cancelled8yaxlo was also a false escalation. Both remain historical evidence, not successful human-reply acceptance.

Provider streaming failures required several operator recovery prompts; independent reviewers and integrators performed product work. Whole-run provider quota/billed tokens are unknown. Session usage records are partial and include cached tokens. See incident register for every repair and intervention.

## Runtime and local update

Current installed candidates: ace-overseer0.30.2.pre.12 (code c4ce37d05707325c4e397db5c4fc11244026f966, gemSHA256459cdd783dd8a8b3cc0b933cd0a41303d47c2265170c354af188c40c36b9d8c4); ace-herdr0.11.1.pre.1 (gemSHA2568ba7632f424694508b8ecf800a1fab8dfb1d086da40771f3ffc8cc5dd2238ffa); ace-coworker0.9.1.pre.1; ace-assign0.73.3.pre.1; ace-hitl0.25.2.pre.1. Native Herdr source5176d899a567985490682c37eb7f0198eab159b0, binarySHA25602030a0b8fb3598a444b6af97d4b81b5b83336cf192eb4b9992029cf9f23aeb9. Manifest pins the installed bundle. Native ARM64 build, provenance verification, and live child-argument smoke passed.

Local update: build unique candidate from recorded SHA, copy gem to VM vendor/cache, one bundle install --local, update manifest, verify ordinary-user CLI. No RubyGems/OTP required. Gemfile update before bundle completion creates a brief non-atomic window; encountered and documented, not advertised as atomic deployment.

## Executed-test binding

CLI integrator receipt `/lab/ace/.ace-wt/ace-t.vu0/.ace-local/assign/8yavwb2/reports/010-integrate-candidate.r.md` records executed installed-mode primitive5/8 and CLI5/22 passing at099ad618, matching review2 receipt and merge expected-head. Docs integrator receipt under correspondingvu8 assignment8yavwq2 records primitive5/8, full-range diffcheck and byte-exact README example at6fd2fd44, matching review3 and merge expected-head. These are agent-owned receipts, independently corroborated for forge identity/content by API; the host did not rerun their implementation work.

## Idle measurements

Started23:08:28UTC: project13 assistant responses, lab403. Both counters unchanged through212seconds. Project eyes enabled, healthy, pending0, wakes2/20. Lab eyes healthy but pending1 and wakes20/20, reset due23:33:07UTC; lab silence is NOT accepted as idle proof while throttled. Remaining event is project-session transition. Observer polling continues every30s; no configuration changed to bypass the limit.

The following worker-process termination is a separate probe; provider-timeout evidence alone would not demonstrate it.

Project idle PASS:23:08:28.410–23:13:31.639UTC,303.47seconds, assistant count13→13, last response23:07:13.554. Final eyes snapshot23:13:39:enabled true,pending0,errors0,breaker null,all6sources ok,observations22,wakes2/20. Technical custom observation snapshots continued; model did not turn. Lab403→403 is NOT credited: pending1,wakes20/20,all sources ok, reset23:33:07UTC.


Lab idle PASS after wake-window reset:23:42:36.310–23:49:09.824UTC,393.514seconds across27 persisted observer snapshots. Last assistant response23:42:36.308, total418 throughout; every snapshot enabled/healthy, pending empty, errors0, breaker null, wakes6/20, maximum snapshot gap37.462seconds. This is unthrottled observation, unlike the earlier excluded window. At that measurement, worker recovery remained pending; idle proof did not mark that assignment successful.

Worker process termination: SIGTERM to verified Pi94521 at23:24:28.360UTC. Assignment8yaz1k stayed running/010active, no false completion, project observation woke coordinator. pre10 attempted same-session recovery and exposed native exec-env global option interception; see incident register. Native fix5176d899a567985490682c37eb7f0198eab159b0 deployed after verification/review; pre12 additionally handles the terminal replacement described below. Final recovery report adoption is recorded below.


Live recovery verified: public work-on resumed SAME assignment8yaz1k and Pi UUID01a1ccec-5f0d-7472-9d0f-760cc1dca26b with original transcript in NEW panew3:pG/terminalterm_66008f7634fd07. Binding state running; previous_terminal explicitly retainsw3:pF/term_660087b3f371d16. New private credentials directory/tmp/ace-session-20261111-104350-vr52zs. Native agent inventory shows exactly one coworker for that session, actively reading verification fixture. Coordinator records recovered-pre12 in private leg. Old pane untouched; no new assignment. Final verification report adoption is recorded below.


Post-recovery worker receipt010-work-on-task.r.md records a fresh fetch and detached checkout of remote main6aa71d99606b9184cb88202faa6242f32d341a40, primitive5/8PASS,CLI5/22PASS, executed README example, issues1–3closed and release4open. No product edits/push/PR/merge/publication. This is the worker's independently executed verification, not host implementation.

Known native limitation: live server handoff preserves processes/Pi sessions but regenerates terminal IDs and drops guarded-origin metadata. pre12 explicitly records old→new terminal recovery in a fresh pane after verified absence; it does not claim to repair native identity retention. Live update remains operator-assisted and was not atomic.


## Recovered worker completion

Worker assignment8yaz1k completed3/3 and published event8yb04e at2026-11-12T00:04:58Z. Public process-reports recorded processed_report=8yb04e,report_result=success,status=done on private leg8ya.t.yyg.0. Manager8ya.t.yyg is done. Executor binding is retired; fresh credential projection auth.json was independently confirmed absent; original transcript remains. No second worker assignment/executor executed. Remote Forgejo main and issues1–4 independently rechecked after completion: main6aa71d99606b9184cb88202faa6242f32d341a40,issues1–3closed,4open.

Report processing first exceeded the coordinator's60s tool timeout; retry with150s preserved progress and adopted the report. Duration/root performance cause is not diagnosed; agent piping output hid progress. Record as follow-up rather than claiming instantaneous receipt.

Two unused role assignments8yazfc(reviewer) and8yazfc1(integrator) were prepared at23:37:04 from the default three-role sequence during recovery; neither executed. These are excess prepared roles for a verification-only commission, not another worker or duplicated implementation. Strict absence of extra assignment records is therefore NOT claimed. Their records remain historical; task completion prevents normal work-on restarting the task. Host explicitly instructed coordinator not to run those roles and to cancel obsolete HITL8yazhc through its local lifecycle instead of fabricating a human answer. This extra closeout instruction is another disclosed intervention.

## Result and remaining work

The preserved run delivered bootstrap, separate execution/review/integration, correct merge ordering, queued release, idempotent report replay, automatic coordinator recovery, process-kill recovery and healthy five-minute idle windows. It required local product fixes and operator interventions; it does not establish unattended autonomy, strict role-process compliance, a clean immutable release or repeatability after reset. Parent8y0.t.x27 remains in-progress. Outstanding follow-ups: native handoff terminal identity, coordinator source-inspection/output-piping habits, unnecessary prepared roles for report-only work, and report sweep latency. No RubyGems publication was required for live iterations.


Final closeout: canonical HITL8yazhc.application.state=cancelled at2026-11-12T00:09:05UTC, audited reason links completed8yaz1k/report8yb04e; answered=false and no invented answer. Project returned idle with eyes enabled/pending0. Independent reviewer approved this qualified evidence report; it does not warrant completing the broader parent task or claiming unattended autonomy.
