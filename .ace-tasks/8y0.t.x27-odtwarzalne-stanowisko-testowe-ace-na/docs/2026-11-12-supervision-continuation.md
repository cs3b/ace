# Supervision continuation — 2026-11-12

Status: in-progress. Approved one preserved UTM/Forgejo/Pi-GLM run; no reset or reseed.

## Implementation and acceptance

- [x] Native live handoff retains terminal identity and guarded origin; new terminals remain unique.
- [ ] Observation wakes the responsible owner only: lab commissions/project availability/escalations; project commissions/reports/failures/integration transitions. Routine progress is visible without waking.
- [ ] Exact revision acknowledgement, restart/replay idempotence and visible wake budget remain.
- [x] Explicit role sequences; no implicit worker/reviewer/integrator for report-only commissions.
- [ ] One HITL case: advisor recommendation before Captain delivery, safe failure delivery, no forged consent; secrets bypass advisor.
- [ ] Report stage timings, one-pass owner reads, accepted-before-retired-before-continued recovery.
- [x] Local tests, independent review, SHA-bound gems/native artifact installed locally.
- [ ] Preserved live run: bootstrap readiness, base/dependent/docs merges, release open, worker interruption/replay, real Captain choice, unthrottled five-minute idle.

## Evidence

Baseline main a84d2eae19a5395a57f6adb382d0f51d7d808c05. Published five gems are not assumed deployed. Earlier evidence remains in 2026-11-11-live-cycle-acceptance.md. Record stage durations and model usage only where measured; unknown otherwise.

### Local implementation evidence

Native source `84753e6b9955fac56a316e1e99d3cbe7219fad9b`, source tree
`e948aca926f1511806e03bbea4933c32630122b8`: schema 2 transfers terminal ID,
guarded origin and original Linux pidfd. Descriptor adoption is RAII and
CLOEXEC precedes shell restoration. Parent reparenting after handoff is expected;
birth and kernel handle remain authoritative. 58 handoff tests pass on macOS
(nextest 3635979c-278e-4a7a-a022-e24beabaf8f8). Linux-only probes and real live handoffs remain pending.
The old schema 1 VM needs a controlled first restart; it cannot export identity
it never recorded in its handoff payload.

ARM64 binary SHA256 `43e5390f4f8c7ffe9d18aef0ec29cfcdcf801db061695a4684671cae4f23f918`;
provenance SHA256 `d524bba67f31798263262f6cd644e75ec2e1fba293382e1e6ef71aa6cba25201`.

Package runs: overseer 600/2889 (one skip), HITL 411/2116 (six skips),
Herdr 629/2600, coworker 424/2012 and wake JS wrapper 2/7, all zero failures.
Latest additional guards: overseer targeted 43/284 (445a8a84-2bd8-45f2-a1e9-f3b03dd31ee7),
lab targeted 48/350 (5043b889-c1df-4d74-8ef3-1990e232a1a2), zero failures.
These are component evidence, not live autonomy acceptance.

Final component reruns after review corrections: overseer 593 tests / 2841
assertions, 0 failures/errors, 1 skip (e4de91c7-2850-46da-bfda-3231c3f661f1);
lab 771 / 3652, 0 failures/errors, 4 skips
(ea50e3c5-9b41-4403-8867-f003ca30a24e). Different overseer count reflects
replacing recursive projection tests, not a newly disabled suite. Independent
Ruby/workflow reviewer PASS binds to 87dc65e6ae1abfcb63e909cabb616b2f55c37d5a;
native reviewer found no remaining code blocker, with Linux acceptance pending.

### Preserved VM deployment and first live repairs

Initial six gems plus published ace-assign0.73.3 installed from candidate manifest
in4.91seconds; backup `/var/tmp/ace-supervision-before-20261112T121059` on VM.
Installed extension projection corrected after an operator mode omission (retro).
Native-source verify accepted exact ARM64 artifact and provenance. Two successive
live handoffs retained `term_660133db49e562`, shell230601 and full guarded origin
(runtime incarnation fac0ae21-3852-4808-a74b-9c93468c8c3c), after prior server exits.
Evidence local `.ace-local/simple-runtime-start/supervision-candidate/handoff-shell.json`.
This initial proof is a shell, not yet an assignment/agent session.

Foreground Pi start exposed stripped native terminal context. Fixed in
9ed6b08aa +4e1ecb33dce866df7d0618ce84cbd938d568a17a, real-child regression
failed before; 22tests108assertions passed after (e63e6107-8033-4cf0-94ec-7e4abd6048a4).
Independent reviewer PASS binds to4e1ecb33d. New ace-overseer0.31.0.pre.2
SHA2564d4c6a8bbfbb2dee52605f449750ea142bd88467431871e11097303e48b311d8
installed locally in4.35seconds; no other gem/native/server restart.
Standalone installed rehearsal loads all six candidate packages from installed
gem directories outside checkout bundle; new sequence and role are packaged.


Two further live handoffs with real Pi231234 and wrapper231230 retained the same
terminal and guarded origin, with identical Pi session
01a1cfb2-29c2-7661-a4cf-f0057a70c5ff. Evidence handoff-pi.json and native agent
readback confirm ongoing turn; this is stronger than shell-only proof. Agent
assignment binding continuity still awaits the worker stage. Foreground startup
now registers session through native integration; initial reconciliation is live.

Test goals: additive local Forgejo issues8(reset primitive),9(dependent --start
CLI),10(independent contribution docs), existing release4 stays open. No previous
issues/merges were removed or reopened. Main before this stage remains
6aa71d99606b9184cb88202faa6242f32d341a40. This manual preserved-run extension follows
the user's current acceptance plan; it is not reported as a fresh automated
TS-MONO-003 bootstrap case. Existing TC-001 required new worker/verifier; the
current explicit instruction permits reusing their accepted prior readiness.

Lab independently ran `ace-overseer start --reconcile` and launched project
w3:pH /term_660135db9f4524 /session01a1cfb5-b3f4-748a-a344-88dd08d4e2f0.
Initial result explicitly withheld readiness pending first turn and active eyes;
no false success credited. Project first turn in progress.

Lab's actual reconcile receipt at2026-11-12T12:23:27.290Z is success:
`1/1 project overseers ready`, projectace reusedw3:pH without duplicate.
The first attempt at12:22:37.455Z correctly returned partial while initializing.
Delivered next goal forissues8/9/10 after reading this receipt. Operator also
supplied factual maintenance context when lab misclassified the intentional
upgrade stop as a spontaneous third crash. No HITL answer was supplied; this
assistance is disclosed and will be assessed separately from autonomy.


### Active assignments, handoff and unthrottled lab silence

A fifth live handoff preserved both real worker bindings and processes:
8ybis5 / w3:pJ / term_6601383a0e5c86 / Pi235592 and
8ybisn / w3:pK / term_6601384a79a5e7 / Pi235847. Each worker.yml execution
binding, native origin, terminal, pane and transcript were identical before/after.
Evidence: handoff-workers.json in the local candidate evidence directory.
Native independent review PASS at84753e6, including actual Linux reparenting and
no pidfd inheritance; Linux negative child-exit/origin-rejection tests remain unrun.

Lab silence was measured over569.082seconds while project workers were active:
assistant messages25→25, completed turns2→2, total tokens571664→571664;
observation count20→38, wakes1→1 of20, pending0, all sourceshealthy. Same Pi
session and terminal. This proves relevant lab silence, not yet final project idle.
Evidence: lab-idle-before.json and lab-idle-after.json.

Controlled SIGTERM to docs Pi235847 at2026-11-12T12:36:18UTC occurred during
initial preparation, before implementation. Project Overseer detected missing
session, dry-ran existing assignment resume and used work-on to restart8ybisn
in the same pane/terminal and transcript; new Pi237557, no second assignment.
Evidence: worker-fault.json plus native process-info and coordinator transcript.
Do not describe this as a mid-implementation fault or host-directed recovery.

Measured actual process-reports sweeps: lab collect0.196s/readtasks0.032s;
project collect0.083s/readtasks0.097s for16events, closed-history cleanup each
0–0.071s. No fixed60second wait. These stage timings exclude CLI startup;
fresh report verification/continuation measurements remain pending.


Follow-up285ee3a82a7aa167068adfebceef58a43a728c87: fixture Ruby PATH and explicit
deadline tool units. Independent reviewer PASS. Tests wake2/7 and monorepo119/471,
zero failures (1749045d-fa7b-4db8-9647-590d90670166,
9ba05740-71cd-41bd-932e-06bc12af7467). ace-wake0.3.1.pre.2 SHA256
4a65ec9ad4a2867e55a57fe86505fd9b1aa28760bd08b0f4380fc1525382aea5 installed
locally in6.3s and extensions projected through installed ExtensionProvisioner.
Both idle coordinators received Pi /reload, keeping their processes/transcripts;
no worker was restarted. Standalone outside-checkout gem loading also passed.
Existing tools briefly saw GemNotFound while Bundler was replacing selection;
worker observed this and retried successfully after installation. This is a
maintenance-window limitation of an in-place bundle update, not an assignment
failure or a reason to reset the lab.

Recovery transcript receipt records dry-run12:38:03.384, successfulwork-on
12:38:29.206, assignment8ybisn unchanged; elapsed130.944seconds from injectedexit.
The coordinator did not execute ace-test: read-only transcript audit found zero
such commands. A worker incorrectly inferred otherwise from the process tree.


### First real worker→reviewer transitions and replay

Project coordinator independently corrected missing role metadata and accepted
8ybj75 fromworker8ybis5; process-reports retired its process and launched
reviewer8ybis51 at12:50:59UTC inw3:pM/term_66013c356f4a64. Docsworker8ybisn
reported8ybjbc, accepted with reviewer8ybisn1 launched at12:53:32UTC in
w3:pN/term_66013cc6864e55. Both original workers no longer appear as live agents.
PR11baseHEAD90a07e53271c0e2f44f478cc5d5823460cc14abf;
PR12docsHEADa784ab304c20769f1a315e5d7d8ec8342bc10581. Neither is merged yet.

Operator replay via public ace-coworker report reused event8ybj75. Read-only
process-reports --dry-run recognizes both reports as duplicates, accepts no
new work and starts nothing.18events:16duplicate,2unmatched readiness events;
collect0.094s/private taskread0.206s, current allocation verify2.022s/2.323s.
Closed historical reports skip expensive verification. Project's original docs
acceptance+next executor took25.8s (tool walltime); its piped tail discarded
individual stage lines, so those exact accept/start durations are unknown.
No claim that the dry-run proves continuation mutation; actual agent inventory
and stored private legs prove the two original transitions.

Diagnostic candidate149a118c70fa3a00eb07acfb0b5e6dcc4a381e8c independently
approved; full overseer594tests2855assertions,0fail/errors1skip
(cace7a82-0ea3-41ab-ba54-fff9836393d0). ace-overseer0.31.0.pre.3 SHA256
b0105d88ff1b85a4be8b8105202b12927d195c3dbbb00de076765abf5430fc97 installed
in3.72s, standalone gem load passed. Public CLI gets the new diagnostic;
existing actor instructions were not forcibly restarted mid-review.


### Coordinator restart fault and all-dead-panel correction

Idle project Pi232138 was deliberately terminated after both reviewers started
(receipt coordinator-fault.json). Lab woke for project unavailability, but product
mistook zero live agents among retained old panels for multiple-live ambiguity.
Both projection and start fixed at30c41a30072ee76e0afd896402c2855d4b52658f;
92tests496assertions,0fail/errors1skip; independent review PASS.
ace-overseer0.31.0.pre.4 SHA256
2d75beff3a05ed22e36166363876f45903e6098ab403ba0e1c12cba6ad661146
installed locally in5.87s; standalone installed load passed.

Healthy source revision woke lab without operator retry. Its own reconcile
started projectw3:pP /term_66013edf4717d6 at13:02:55UTC,
session01a1cfda-a4f9-7594-9344-9d1680dff810, with active eyes on first turn.
No workers/VM/Forgejo reset. This is a genuinely new process, hence a new terminal;
live native handoff preservation remains separately proved. No duplicate reviewer
assignment was created. Formal ready receipt still being observed.

Lab inferred that an operator deleted stale panels. Explicit factual correction
was sent: no panels removed; product zero-live handling was fixed. This maintenance
message is another disclosed operator intervention, not Captain consent or a
workflow-step hint. Lab had discussed escalation but transcript audit found no
ace-hitl command after the fault; no actual new decision case is credited here.
Both reviewer processes have installed mode and the corrected Ruby path natively
(pid244651,246258), without sourcing shell scripts.


### Readiness confirmation after coordinator replacement

Live restart exposed a missing observation transition: project working/idle/done
are intentionally normalized, but the lab then received no confirmation when the
new first turn and eyes became ready. A sampled ready boolean was rejected in
independent review because concurrent transcript writes can temporarily make the
proof inconclusive. The corrected projection emits a stable project-ready event
bound to native terminal and Pi session identity, rechecked after proof. Existing
eyes acknowledgements suppress its reappearance; no new state owner is added.
This confirms readiness only, not continuous observation health. The lab still
reconciles actual start readiness before recording success.

Focused regression:16tests/56assertions; ace-wake wrapper2tests/7assertions
executes the JavaScript suite including ack/disappearance/restart. Independent
read-only review PASS; reviewer did not independently rerun tests. No VM reset.
