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
