# Shared HITL proposal routing — source integration checkpoint

The shared authority can hold distinct canonical Assign journals for several projects.
Proposal IDs are not project selectors. The existing proposal API now requires an
explicit project for show/revise/ack/reply/reconcile/due, as create/history/wake already
did. The ordinary request read uses its retained project. Hermes uses the accepted
envelope's project and polls due proposals separately for each configured project.
Recovery enumerates the binding's accepted projects and retains current transport
authorization for each; it does not introduce an aggregate journal or a first-project
fallback. The original requester, revision, immutable retry and sixteen-hour rules remain.

This is a prerequisite of the vs3 same-authority constructor integration, not an
extension of an archived task's delivered acceptance. Public usage examples are in
ace-hitl/docs/usage.md. Consumers changed together: lifecycle client/dispatch, CLI,
Hermes relay/runtime and maintained installed-proposal consumer asset.

## Executed source checks

- [x] Actual separate Git journals refuse reading/acknowledging another project's ID
  through the selected project without changing either journal.
- [x] Request read, exact interrupted revision recovery and real Unix-socket
  transport restart/deadline flow: focused 4 tests / 39 assertions PASS,
  `19988b87-2285-4b10-8960-a5a93ecb052a`.
- [x] Complete affected proposal lifecycle and CLI files: 28 tests / 200 assertions
  PASS, `d1763fdf-a5d3-4f73-9d13-ae313ae1b8b5`.
- [x] Hermes pending publication and transport CLI: 14 tests / 104 assertions PASS,
  `ec7d864a-20bb-4e9a-be10-94c1d44d5b4e`.
- [ ] Join original LaunchLifecycle/Endcap binding and publication producer.
- [ ] Final independent review of the integrated source.
- [ ] Installed execution recorded centrally in lab-config:gad.2.

The preceding affected-file run `89d3b4f8-0518-4179-bb58-aa369440a95b` failed.
Its concrete missing project argument in Store#read was corrected using the
retained request project; the ordinary fixture also admits its existing empty
other-project history query. No permission, revision, claim or deadline gate
was relaxed. A mixed file/file:line selection was refused by the runner and is
not counted as executed evidence. The later complete run includes the new
cross-project test and supersedes the failed run only for this changed source.
No native Lab or live Telegram operation was performed; this does not close vs3.
