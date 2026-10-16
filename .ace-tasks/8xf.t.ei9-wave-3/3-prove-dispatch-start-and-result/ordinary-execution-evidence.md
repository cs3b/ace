# Ordinary execution source verification

Source base: `31c386ecd`, isolated branch `codex/ei9-ordinary-execution`.
Implementation follows the source-grounded ordinary-execution-plan.md recorded
before code. No version bump, publication, main integration or Lab mutation.

## Implemented boundary

- Explicit Overseer `ordinary prepare/launch/status/resume` reuses worktree,
  window, native pane and interactive provider owners. Explicit checkout must
  belong to installed common-dir; task preparation and provider resolution use
  that project/worktree context, even if the coordinator cwd is another project.
- Assign OrdinaryDriver owns retained requester inputs, not accepted state.
  Lab composes it with the installed ordinary client. Bootstrap/queue/results
  come from canonical snapshots; start comes from actual native worker ancestry.
- Filesystem watch is a nonauthoritative hint; status/adopt read canonical data.
  Unconfigured inbound Inbox remains fail-closed for nonempty references.
- Coordinator adoption records binding old→new under original definition-chain
  generation/digest CAS. The new native coordinator must be selected for the
  project and the old process generation positively ended. Old live/unknown
  generations refuse. Worker attempt/request bytes survive unchanged.

## Executed checks

All commands use repository ACE test tooling. Paths below are reports in this
worktree's `.ace-local/test/reports/`.

| Check | Result | Report |
|---|---|---|
| Initial integrated runtime/entry/client/ordinary lifecycle | 38 tests, 311 assertions, PASS | runtime/30b7cdf4-3cd3-44bc-8e17-2d8c090e6a2d |
| Final ordinary lifecycle, real socket and Git CAS | 21 tests, 236 assertions, PASS | assign/b02fab0a-35fe-44ed-a400-d441c4ffe634 |
| CLI/native admission/provider integration | 16 tests, 91 assertions, PASS | overseer/035035ef-a611-4b81-bac5-9fe055000494 |
| Final entry delta with explicit project cwd and real provider builder | 4 tests, 41 assertions, PASS | overseer/80a67403-2116-433e-b121-adcd4e42f5a1 |
| Positive process-generation observer | 9 tests, 23 assertions, PASS | runtime/088156be-291e-4d45-99f4-2c4e191ece52 |

The lifecycle test exercises two independent worker bindings and starts before
completion, lost result reply for the first while the second remains running,
canonical adoption without a hint, and repeated adoption without a second start
or result. Another case uses a real child PID alive→reaped, denies live/unknown
old supervisor, records replacement and rejects stale finish/replay. The Lab
admission test additionally runs the real bounded process observer with actual
native ancestry fixtures. Native endpoint/project policy are injected only at
their owning integration boundaries; this is not an installed dual-UID receipt.

The initial real-provider test correctly refused a missing thinking preset under
hermetic config; it now explicitly loads real shipped config through the existing
test helper and tests the actual Pi model/thinking argv without launching Pi.
Public CLI help and diff whitespace checks pass. Tracked `.bundle/config` has
been restored; test dependencies are an ignored local symlink to the existing
workspace bundle, not a product edit.

The required default 51-package suite is running as session 2778. All completed
packages pass so far. Its entry delta was verified separately after an ambient-cwd
issue was found during self-review. Final suite outcome and independent reviewer
verdict must be appended before integration; no full-suite PASS is asserted here.

## Outstanding installed acceptance

Publish/install the reviewed cut with exact dependency graph first. Preserve
legacy sessions, original unknown attempt and historical transport records.
Prepare two safe new leaf tasks from the actual canonical supervisor; install
returned native watches once, persist and verify exact-session restoration.
Capture actual worker starts, queue reports and canonical results. Replace the
coordinator process only after recording its original binding, then adopt from
the selected new native coordinator without any worker relaunch. Verify repeat
wake/lost reply reads one accepted result. Complete independent review and two
serial ordinary merges through the existing receiver and decision authority.

Effective installed project overrides and guide/preset path/digest context still
need live acceptance; no generated prompt or source test proves installed work.
