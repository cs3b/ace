# Cleanup owner slice alignment

Independent review of Lab's direct cleanup producer found two default manager
construction failures: an unsupported `slice:` keyword and use of the explicitly
forbidden shared `system.slice`. Injected manager fixtures had hidden both.

The corrected contract selects `lab-workspace-cleanup.slice` in Lab's generated
unit and both manager constructors. ACE's generic cleanup identity observer now
requires an explicit dedicated `slice_unit:` and verifies typed `Service.Slice`
against that immutable selection on every snapshot. No fallback or new scope
manager is introduced. Lab owns the producer changes and their composed tests.

Root authored the ACE observer, test and changelog change; independent reviewer
`wave_412` inspected all three paths and returned **APPROVE**. Executed from
`ace-lab`: `../bin/ace-test test/molecules/protected_cleanup_owner_identity_test.rb`.
Raw report `f2d81dec-b560-47b0-9ed4-0bbaba267a4e`, seed 46688: **14 tests, 97
assertions, zero failures/errors/skips**. Wrong/shared/missing observed slices
refuse before pin acquisition; malformed/shared selected slices refuse construction.

This closes the generic observer alignment only. Lab's full producer successor,
physical preview/apply, installed effectiveness and whole qk0 acceptance remain
open. No native/systemd/root probe was performed.
