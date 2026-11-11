# Runtime correction during the preserved UTM run — 2026-11-11

Task remains in progress. No reset, fixture reseed, provider request or autonomous
acceptance has been performed during this correction.

## Observed failure

Updating the prepared VM invoked full `ace-lab install`. At 30m57s the installer
was still executing per-package dependency probes. Measured single probes cost
0.501s (`gem dependency ace-wake`) and 0.647s (`gem list ace-support-core`). Source
showed fresh dependency traversal per declared gem plus automatic final Verify.
The exact historical number of subprocesses was not measured. The QEMU helper
stopped waiting at 120s while installation continued; eventual exit status was
not recovered. The process has now exited. SSH is working.

## Product correction

- One Bundler installation of the complete declared runtime, with a persistent
  Gemfile/lockfile/configuration and self-contained binstubs.
- Failed resolution restores previous bundle inputs; real offline regression
  confirms the old executable still starts without inherited Ruby/Bundler env.
- Installation does not automatically invoke diagnostic Verify.
- New `ace-herdr start` uses native configuration and terminal lifecycle.
- Herdr executor uses the same configured binary/socket/toolchain. Managed Pi
  extension selection receives that effective environment.
- Overseer selects installed mode from configuration; child socket comes from
  session runtime configuration, not an operator's sourced shell profile.

## Local evidence

- ace-lab full suite: 770 tests, 3645 assertions, 0 failures/errors, 5 skips;
  report `05379d82-c30f-4c6f-88e7-ef09f83e5451`.
- ace-herdr full suite: 627 tests, 2593 assertions, 0 failures/errors;
  report `09b97696-cffc-4d3c-86b5-268f5d74cdbd`.
- ace-overseer subprocess suite: 568 tests, 2653 assertions, 0 failures/errors,
  1 skip; report `898d7098-5be1-4e64-bf39-7c8523bdb784`.
- Independent reviewer identified failed-update rollback, configured extension
  selection, and lock-aware diagnostics. All corrected; implementation approved.
  Final release SHA binding and post-review focused checks follow.

## Existing VM, next actions

Preserve run `27d89c111762acc3`, VM UUID
`A98D75CB-E338-4EE1-B503-1BF7D4BCD752`. Forgejo is active AND enabled at boot.
Build/publish from reviewed main. Install the accepted artifacts as one bundle;
update declarative role/runtime configuration and native artifact. Use public
ace-herdr/ace-overseer startup via SSH, without manually sourcing a profile.
Continue bootstrap, issue/review/merge, then recovery and idle checks. Do not use
`repeat`, reset, or replace project/Forgejo data.

No GLM usage during this correction; account quota has not been independently
measured. Human elapsed time and exact whole-run token accounting remain unknown.

## Live continuation and local candidate policy

PR405 was merged as `2d0eb676a5cf1053345dab667973bf5a1011c487`; its three published gems were installed on the existing VM using one bundle installation (39 seconds). No reset was performed. Native Herdr and Pi started through public commands.

The first live start exposed the nested native workspace-response mismatch and an eyes fixture-path mismatch. PR406 (`fd62cebb5d940c1dc857cf8bd65f50e254a09bf9`) fixes both; independent review approved `64a0a595829d23bd5bbcba3c76b730f3bdc35d30`. Local verification: overseer568tests/2659assertions, zero failures/errors, one skip; monorepo-e2e119tests/471assertions, zero failures/errors.

Published ace-overseer0.30.1 download matches SHA256 `ba298cb6e38677cfcdf4bf688d10e99563c19b8f4f817017a6271720c1d9b5dc`. Installed from the copied gem with one `bundle install --local`; configured manifest now selects0.30.1. Same Pi pane `w2:p2` resumed with the corrected first-turn prompt. Live autonomy acceptance remains pending.

Captain explicitly authorized subsequent test iterations using local candidate gems, without RubyGems publication. For each candidate: local tests, concrete source commit, unique prerelease version, built artifact checksum, copy into VM bundle vendor/cache, update Gemfile and deployment manifest, one bundle install --local. Resume existing work and restart only processes that must reload code. Final public release still comes from main. RubyGems metadata may lag: in this iteration the version list omitted0.30.1 while its downloadable gem was already available and matched the prepared artifact.
