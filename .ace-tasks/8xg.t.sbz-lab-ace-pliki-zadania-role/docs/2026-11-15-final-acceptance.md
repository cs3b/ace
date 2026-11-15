# Final acceptance reconciliation — 2026-11-15

Approved execution: preserve existing UTM/Forgejo, upgrade published gems, reuse
valid evidence, run only missing checks. No live GitHub mutations. No new services.

| Criterion / owner | Evidence | Remaining |
|---|---|---|
| `.4.4` Forgejo reviewer → integrator | x27 connections stage3, PR15, reviewer e2e-reviewer, full head in receipt, merge and issue14 closure | verify receipt exactness and negative-case tests |
| `.4.4` GitHub live approval | Not established by Forgejo evidence | remains unaccepted/outside authorized live scope |
| `.6.2` restart, replay, idle | connections stages1,3,5; 300s live, no extra completions/wakes | published-runtime smoke and remaining coverage reconciliation |
| `.6.2` 24h logical idle / quota100+restart | ace-wake/test/eyes.test.mjs; full wake report5c221815-2970-4936-b5bd-931b4f33dd31 passed | not 24h live evidence |
| `.9.2` released runtime | six RubyGems archives downloaded, API SHA256 matched; 400 packaged code/instruction files identical to current main | existing VM upgrade then separate fresh install |
| `.9.3` program closure | dependent on the above | stays open while mandatory acceptance missing |

Published set: overseer0.31.0, coworker0.10.0, hitl0.27.0, wake0.4.0,
herdr0.11.2, lab0.16.1. Local hashes and per-package source comparison:
`.ace-local/release/acceptance-20261115/{published,source-comparison}.json`.
Existing VM initially runs pre releases; both coordinators idle. No reset.
Disk blocker removed: authorized cleanup removed45 obsolete VM exports, preserving
metadata and live VM/base. Evidence directory now216KB; free space138GiB
(previously16GiB). Registered VM identities and running state unchanged.

Same-UID ordinary sessions are not a malicious-process isolation boundary.
Older requirements claiming that boundary must not be marked satisfied by role
configuration. Hermes/Telegram and Omarchy remain outside this acceptance.

## Added plan step — bounded VM evidence (Captain approved 2026-11-15)

Implement before creating the separate fresh acceptance VM, under existing x27
fixture scope; no new service, state store or cleanup scheduler.

- Default reset/destroy/base rebuild retain small run reports, manifests, package
  versions, VM identity and error diagnostics, not a full VM disk export.
- Full archival export requires an explicit `--export-vm` option on the existing
  helper operation. Export failure blocks that explicitly requested operation;
  never silently delete the requested diagnostic copy.
- Preserve UUID/location ownership checks and recheck stopped state before delete.
  Do not remove the temporary base integrity export used for verification merely
  because it shares the export function; temporary copies must be cleaned up.
- If diagnostics cannot be collected, preserve the VM and report the error.
  A test failure itself does not reset or destroy its VM.
- Remove obsolete assumptions that every removed VM must have a permanent export.
  Keep interrupted-operation reconciliation explicit; absence is not success.
- Update helper documentation and deterministic tests: default no permanent
  export, explicit verified export, unrelated VM untouched, failures preserve
  diagnostic state, repeated resets do not accumulate disk archives.
- Validate locally through bin/ace-test. Do not reset the preserved live VM to
  exercise cleanup. Use the separate disposable acceptance fixture only.

Then continue: published-runtime upgrade/smoke on preserved VM → missing targeted
checks → fresh RubyGems acceptance → evidence reconciliation and task closure.
Full current overseer suite:620 tests/2978 assertions, zero failures/errors,
one skipped; report7385f3ce-0b8f-456f-84aa-80f18bb2273c.

## Published deployment completed

Preserved VM upgraded to all six published versions above in7.34seconds with
one bundle install --local. Artifact SHA256 verified before installation.
Installed ExtensionProvisioner projected wake0.4.0 and reported restart_required.
Backup:/var/tmp/ace-published-before-20261115T100247. No VM/Forgejo reset.
Coordinator extension reload and smoke remain pending; installation is not
acceptance of the newly loaded sessions.

## Helper retention correction implemented locally

Default removal now preserves host reports and a small durable identity/removal
receipt; guest-only data requires explicit --export-vm. No automatic permanent
disk archives. Interrupted deletion reconciles from the existing state and
receipt; missing VM plus requested unavailable export fails visibly.
Temporary base integrity exports remain temporary. Existing VM was not reset.

Full deterministic monorepo-e2e package:124 tests/577 assertions, zero failures
or errors; report cc50e683-6623-42ba-acbc-9fcdcf402c3c. Independent review
review_vm_retention found one recovery edge case, fixed and regression-tested;
re-review reported no remaining concrete blockers. Live deletion was not tested.

## Published-session smoke — readiness gap found

Sent /reload through ace-herdr to existing w2:p8 and w3:pZ; no replacement
terminal or VM reset. Published ace-overseer0.31.0 start reuses both but returns
partial. Project session file is 89,243,486 bytes, above EyesSessionEvidence's
64MiB MAX_BYTES check. Latest eyes snapshot has all six sources healthy,
errors0 and pending empty. Long-lived session size therefore prevents readiness
proof even though observation is live. Lab rejection requires separate diagnosis.
Do not reset session/history to bypass this product condition; fix bounded
session evidence reading and regress long-lived sessions before accepting smoke.

Readiness diagnosis continued: native BoundedObservation passed an explicit
PATH-only default binary and bypassed HerdrExecutor's configured environment.
Configured start worked but readiness could not locate/bind the same native
runtime from a plain SSH shell. Fix inherits configured binary and wraps native
queries with the existing environment builder; ps remains unchanged.

Eyes session reader now streams records and keeps only readiness fields while
retaining branch validation, process birth/foreground checks and freshness.
Regression reads a valid session above64MiB and rejects malformed/truncated
records. Overseer suite:622 tests/2985 assertions,0 failures/errors,1 skipped;
report9428ba02-443e-47c4-bf70-0b4c2066a561. Independent streaming-reader review
reported no blockers. Deployment and live proof remain pending.

## Readiness repaired on preserved VM — 2026-11-15 10:17 UTC

Source de706d90015aba9f17b0a9c94c0a07b5f92b9838; local artifacts:
- ace-overseer0.31.1.pre.1 SHA256 bd213dadcdb3ea878002e1b77017b7a2e6edabcd60fe19f41e83fc1df38a6c9c
- ace-herdr0.11.3.pre.1 SHA256 60eb36af3dcf4e4f0d0dfb008caea26b3ad2cfb10ebf4397d344faddce4e372a

One bundle install --local completed in4.81seconds. Backup:
/var/tmp/ace-readiness-before-20261115T101716. No native Herdr change, VM reset,
new agent session or model goal. Public CLI from /lab returned status ready,
ready:true, project_count:1, both prompt_failed:false, project status reused,
replaced_pane:null, panes w2:p8 and w3:pZ unchanged. Both previously observed
readiness failures are resolved in the installed candidate.

Herdr full suite630 tests/2602 assertions, zero failures/errors; report
3c7d3402-d532-4d82-8fee-d1eddeebec0c. Independent review of configured native
observation reported no blockers. These two fixes are local prereleases, not
published RubyGems; fresh published-runtime acceptance remains unaccepted.

## Criteria reconciliation and release preparation — 10:20 UTC

Live readback from Forgejo PR15 confirms author e2e-worker, reviewer
e2e-reviewer, review7 APPROVED/official:true/stale:false/dismissed:false at
f6ffc23c2a247c6034260a7761a604832040d294; merger e2e-integrator, merge
 e00f33f6cadf046b06de9d17dcc19b86aeec2be8. Review URL:
http://127.0.0.1:3000/e2e-integrator/ace/pulls/15#issuecomment-90.
Release issue4 remains open. Sanitized live readback:
.ace-local/release/acceptance-20261115/forgejo-approval.json.

Targeted formal-approval deterministic verification:
- Forgejo13 tests/198 assertions, report40b58436-6d68-43ec-93d8-695e98d4af92.
- GitHub6 tests/128 assertions, report1ae4c2dd-78d3-4c63-b271-3075de707fdb.
- Neutral lifecycle/CLI18 tests/107 assertions, reportb4757b8f-9c78-415f-b261-bf28f8ec0f3b.
All passed. Covers author refusal, actor mismatch, head races, lost replies and
pending recovery/refusal. GitHub live acceptance remains absent and is not
replaced by these tests. Same-UID sessions do not prove secrecy from malicious
peer processes; that old task requirement was superseded by the Captain's
ordinary-process/explicit-env contract, not satisfied by an isolation test.

Wake: existing deterministic eyes tests explicitly cover24h logical idle,
quota+100 observations+restart, exact ack races, cancellation and retirement.
Live stage5 records both panes completion_seq_delta0, wakes_delta0,
observations_delta10, pending0/errors0 over300seconds. These are distinct
evidence classes. Published-runtime report/HITL live acceptance is still owed;
Nov12 local candidates and Nov15 local readiness fixes must not be relabelled
as a clean RubyGems acceptance.

Prepared from main eec974501: ace-herdr0.11.3 then ace-overseer0.31.1,
with Overseer's dependency floor advanced to herdr0.11.3. Publisher dry-run and
prepare succeeded; no push executed. Stable artifacts'140 runtime/instruction
files match the tested prerelease artifacts byte-for-byte excluding version.rb.
Checksums and comparison: .ace-local/release/acceptance-20261115/release-manifest.json.
Operator terminal handoff sent for the publisher's interactive OTP.

Remaining: publication confirmation → stable deployment/smoke → separate fresh
RubyGems fixture acceptance and live report/HITL → reconcile final task statuses.
.4.4 stays open for missing GitHub live scope; .6.2 and .9.2 not yet done;
.9.3 cannot close while mandatory acceptance remains missing.

Fixture manifest refreshed to RubyGems sources (16 archive/API checksum matches,
2 prepared releases still awaiting publication). Native Herdr pinned to verified
identity-preserving ARM64 artifact43e5390f... and selection9a7ff389... . No
fresh VM created yet; existing registered VM/base remain untouched. Manifest
checks:124 tests/577 assertions passed, report02ef4140-1163-4dfd-b67b-f3c4f2251be3.
Publication recheck still returned404 for both new versions. Full archive copies
were not recreated during this preparation.

## Dependency closure checked before publication

Loaded55 actual gem archives with the existing lab-vm/gem-graph.rb validator:
complete pinned dependency graph,7 install roots, no missing/incompatible pins.
53 archives downloaded and SHA256-checked; the2 prepared unpublished archives
were used only in a separate local closure directory. No main fixture cache
was seeded with unpublished artifacts. Install ordering is recorded in
.ace-local/release/acceptance-20261115/install-order.json.

Repeated registry readback still reports404 for herdr0.11.3/overseer0.31.1.
The concrete external dependency is the operator's interactive RubyGems OTP
publication. Queue and artifacts are prepared. No pending VM/test process is
being mistaken for a running wait; fresh published acceptance has not begun.

## Publication confirmed and stable VM smoke — 2026-11-15 10:44 UTC

Operator published herdr0.11.3 and overseer0.31.1. Downloaded both from RubyGems;
API and archive SHA256 exactly match the prepared manifest. Stable install on
the preserved VM completed in4.62seconds; backup
/var/tmp/ace-readiness-before-20261115T104407. Public start returns ready:true,
1/1 project ready; w2:p8/w3:pZ reused, no replacement sessions.

TS-MONO-001 attempted with pi:zai/glm-5.3-flash but stopped in setup before
model execution: missing .ace-local/release/installation-manifest.json (its
schema differs from the VM artifact manifest). This propagation proof remains
unexecuted. Also corrected project E2E runner/verifier/reporter configuration
to explicit Flash: CLI --provider alone did not override the verifier role,
which previously selected ordinary GLM. No ordinary-GLM verifier was launched.

Separate acceptance base DCCAF9BC-D392-46BB-8EDA-0A71E24347F0 cloned from
verified clean base2C545973-0B40-4AFF-806B-BABD53BCA155; its source fingerprint
matched before cloning. Registered via existing create_base reconciliation,
normal guest readiness checks in progress. Preserved VM A98D75CB remains
running. No permanent disk export created.60 manifest inputs verified/cached;
reuse avoids downloading/building them again. Fresh acceptance is not yet done.

## Fresh fixture preparation completed

Normal base readiness completed successfully (helper exit 0); base is clean and
stopped, fingerprint 1c68f0dcb52a03cf7e3f6c97ac839ddf6134252a7f95eef68e0860a0c129cefd.
Created separate working clone E4505D76-C9F5-42F6-942F-5C78871F1674
(ace-e2e-work-a083fa24f87cb150), currently stopped and not provisioned.
This operation used main checkout state only; preserved lab A98D75CB and its
worktree state were not reset. No retained full VM export was created.
Fresh installation and live acceptance remain pending.

## Published-session report replay and idle observation

On preserved VM A98D75CB, published overseer0.31.1/herdr0.11.3 processed34 already accepted reports twice (79.279s and42.213s). No new executor was started. The sole continuation record was action=none: manager8yb.t.mgd closed through ace-task. Exact pending revision acknowledged, all6 observation sources healthy.

Idle window after assistant completion:361.683s,12 additional observations, wakes1→1, pending0, no new assistant turn or compaction, same process generation. Evidence: `.ace-local/release/acceptance-20261115/published-report-replay.json` and `published-idle-observation.json`. This proves the observed window, not general autonomy.

The overseer used an explicit worker credential path to inspect issues instead of its own role environment. No secret value was exported in the evidence. Record as a role-boundary violation, not a passed autonomy condition.

## Fresh installation resumed in place — candidate acceptance

VM E4505D76-C9F5-42F6-942F-5C78871F1674 now has the installed runtime and verified native Herdr. No disk/Forgejo reset. Ruby3.4.8 reused; native SHA43e5390f4f8c7ffe9d18aef0ec29cfcdcf801db061695a4684671cae4f23f918 reused from cache.

Published ace-lab0.16.1 failed fresh installation (Gem::Source serialized as object identity). Local candidate0.16.2 from ff2f830f26fd9ff22826850182f94992beccb683 fixes the URI and shared runtime permissions. SHA256 ae05fd1e26938b45526f0922ea8619a10d4f4af593fedc3c9e7cb272a9b721f9. This candidate is NOT published. Older provisional artifact retained only under local superseded evidence; active manifest points to corrected hash.

Installer/verify:59 pass,0failed/unknown. Locked runtime:55 declared artifacts activated exactly; Ruby defaults come from pinned Ruby. As unprivileged mo, actual ACE CLIs, Pi0.86.1 and Herdr0.9.3 load successfully. Provision helper exit0. `ace-lab` suite771tests/3655assertions/0failures/4skips; E2E deterministic suite132tests/611assertions/0failures.

## Current HITL continuation

Actual format-choice case8yehss exists; manager8ye.t.hsx, advisor task8ye.t.hsy, assignment8yehtj. No Captain answer has been fabricated. Pre-start extension ownership drift fixed after comparing12 packaged files;17 paths restored to root:root. Operator resumed same goal. It exposed stranded launching recovery; paused the active model with Esc after no useful progress, preserving all session/task data. Product fix under local tests/review. Full report/HITL acceptance remains open.

## Refused-launch correction deployed — 12:20 UTC

Local candidate source94ea1b9514a92d92fd844cb7d500b2a5a00f738f: ace-runtime0.4.3 SHA256bf2bd576023de8bf644b2a0b8fb2c7a7de3cadc55ba0d895e3e95ee0b919655d; ace-overseer0.31.2 SHA256a81715d756920673b57cf3650a8d474bc7fce684d67bae4c46d1a1cf849922d1. Alongside ace-lab0.16.2 above, installed on preserved VM via product installer using verified local gem repository. Final install Result:ok,11.634s, existing repository/overseer/registry/grants preserved. Backup `/var/tmp/ace-resume-before-20261115T122007`.

Operator correction: root Git refused mo-owned `/lab/ace` as dubious ownership. Added root-only exact `safe.directory=/lab/ace`; did not change repository ownership or trust wildcard paths. Installer had misleadingly classified this as foreign directory.

Paused the stuck model with Esc; delivered one continuation goal for same HITL8yehss/advisor8ye.t.hsy/assignment8yehtj after deployment. No process/session/assignment success manually written. Review confirms recovery checks surviving session children as well as shell generation before a replacement process. Live result still pending.

## Live same-assignment recovery confirmed — 12:21 UTC

Public `work-on --task 8ye.t.hsy --manager 8ye.t.hsx --runtime herdr` completed in11.5s: existing assignment8yehtj bound and started. Native owner independently reports coworker-8yehtj interactive_ready:true, working, cwd `/lab/ace/.ace-wt/ace-t.hsy`, pane w3:p18, terminal term_6604fb194281519. New session01a1df27-5428-7001-b35c-1e559d8c82f8 uses zai/glm-5.3-flash (model_change12:20:59.232Z). Old orphan was retired by the product, no manual binding edit. HITL8yehss still pending, no human answer yet.

At12:23:12UTC the actual Second Captain wrote `Suggestion` on8yehss, author second-captain, proposal A (short result with evidence links), preserving empty Answer and answered:false. Operator independently read the case and presented A/B to the human via HITL bridge. Decision pending; this is not release approval.

## Human decision and automatic completion — 2026-11-15 15:25–15:28 UTC

Captain selected exactly `A — krótki wynik z dowodami`. Delivered to the same8yehss through `ace-hitl reply --stdin` at15:25:20. No manual resume prompt: eyes emitted the case revision at15:25:47.053 (27seconds later). Overseer applied the decision15:26:57 and atomically closed it with accepted lesson15:27:16. Independent public owner reads confirm application.state=closed and manager8ye.t.hsx plus direct child8ye.t.hsx.0 done, still under private `_overseer`.

Report A delivered15:28:06; a subsequent manager-state wake was acknowledged,35 accepted-report duplicates caused no new executor. Final assistant15:28:50.355; eyes snapshot15:28:50.367 healthy, pending empty, six sources healthy. This confirms reply→wake→apply/lesson/close→manager completion on the local candidate.

Compact local evidence: `8yehss-closed.hitl.s.md` and `hitl-decision-applied.json` under `.ace-local/release/acceptance-20261115/`. No VM export or full transcript copy.

Report-quality correction: model initially titled its report acceptance on published packages and positive acceptance without the local-candidate/operator-intervention qualification. Operator provided exact versions and requested correction of report wording only; no test replay or state repair. Whole-program/RubyGems acceptance remains open.

The corrected report A explicitly identifies ace-lab0.16.2/runtime0.4.3/overseer0.31.2 as unpublished local fixes, operator interventions, assisted-run scope, and open release/program acceptance. The agent ended its turn; native terminal view shows eyes pending0. No tasks or test effects were repeated for this documentation correction. Root Git change was an exact safe.directory setting, not a repository ownership change.


## Upgrade documentation readiness check — 2026-11-15

Read-only recheck before the Captain upgrades an older lab:

- RubyGems API still exposes lab0.16.1/runtime0.4.2/overseer0.31.1/herdr0.11.3.
  Lab0.16.2/runtime0.4.3/overseer0.31.2 remain local candidates, not published acceptance.
- Preserved VM responds over SSH; installed CLI reports lab0.16.2/overseer0.31.2.
  Project `/lab/ace` is mo:mo0755; runtime bundle and extension root are root:root0755.
- Herdr lists lab w2:p8 and project w3:pZ as done; historical empty panes remain.
  This is terminal visibility, not a new proof of healthy eyes or idle acceptance.
- Forgejo HTTP listener answers on127.0.0.1:3000 and refuses unauthenticated API access.
  The generic system unit named forgejo is inactive; no service restart was attempted.
- Public `ace-lab verify --format json` from the noninteractive operator SSH context
  exits1: role checks cannot find ruby, gem checks cannot find gem, and extension
  inventory differs from ace-wake0.4.0. Diagnostic-context versus actual-session
  readiness needs resolution; do not mark this lab ready or reinstall everything.
- Three task files remain modified in the project; preserved without reset.
- Updated docs/lab-setup.md correct unsupported command flags, bundle location,
  published-versus-candidate distinction and non-destructive upgrade procedure.

Older Omarchy lab was not accessed or changed. Its readiness is not inferred from UTM.


## Publication confirmed after the readiness check

The Captain published fresh artifacts; version-specific RubyGems API confirms:

| Gem | Version | Published SHA256 |
|---|---|---|
| ace-runtime | 0.4.3 | a8bb324faa3a61a6a9d2f791cda2596068c8a1b577122f1e4fbc43157932ebc2 |
| ace-lab | 0.16.2 | 64d5d419b8c7b6337d96046c7dcd4f2ed9bf9b8720d59b5a9373b4be6d805d52 |
| ace-overseer | 0.31.2 | 043ee5cd2e5df5a63efb73b16fe205e571652429dc65cb00e73ee0821774f277 |

These replace the publication blocker, not the remaining readiness blockers.
The preserved VM still has earlier local builds with different artifact hashes.
The generic latest API was stale; concrete version endpoints confirmed publication.

Extension failure reproduced: the receipt lists each of12 source files11 times.
ExtensionProvisioner retained already-expected names and then appended expected.keys.
Fix excludes already-expected paths from retained obsolete paths. Regression fails
before the fix (12tests/53assertions/1failure), passes after (12/55/0), with an
additional test covering repair of an existing duplicate receipt. No VM files
or package versions were changed in this diagnosis.

Full ace-lab regression after the receipt fix:772tests/3661assertions,0failures,0errors,4skips; report `.ace-local/test/reports/lab/fb718379-a56a-497e-96ff-1b23068089ff/`. Source correction is not yet deployed or released.
