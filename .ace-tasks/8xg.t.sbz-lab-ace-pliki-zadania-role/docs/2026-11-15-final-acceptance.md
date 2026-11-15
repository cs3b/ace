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
