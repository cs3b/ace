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
