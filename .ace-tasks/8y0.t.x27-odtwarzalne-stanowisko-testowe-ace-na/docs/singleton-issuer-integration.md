# Singleton issuer integration — 2026-11-04

This supersedes the per-connection `Accept=yes` design recorded in earlier
component probes. It is source integration, not UTM acceptance.

The fixed unit graph now uses `Accept=no`, `ace-lab-auth.service`, one invocation
ID, startup recovery before each service start, and invocation cleanup through
ExecStopPost. Forked connection handlers remain in this service's control group.
Request, status, exec and revoke authenticate every connection with SessionPeer.
The CLI selects this transport when ACE_LAB_SESSION=1 and refuses an unavailable
installed Linux endpoint. No client identity fields or credential values are
accepted or returned. Exec transfers stdio descriptors after authentication;
the existing SessionRunner still drops credentials and confines execution.

Issued requests retain supervision until session exit, expiry, or confirmed
consumption. Supervision slots are separately bounded from connections so live
leases cannot exhaust all exec/status/revoke slots. The parent acknowledges the
transition before a successful issuance response. A failed supervisor stops
the service; existing LeaseStore records drive cleanup and restart recovery.
No additional persisted state owner was introduced.

Independent review identified connection starvation, blocking recv_io despite
a readiness timeout, and a test cleanup rescue that could mask failed assertions.
The changes separate capacities, use bounded nonblocking ancillary receipt, and
preserve assertion failures. Regression tests cover these paths.

Validation before those review fixes: full ace-lab suite, 873 tests, 3950
assertions, no failures/errors, 13 skipped. Subsequent targeted tests cover the
changed supervision/IPC paths; final report paths remain in local test artifacts.

## Installed singleton readiness and supervised issuance

Commit `338cd3f92c5f08e6e99b7b84c4fa8d70cb0a472b` replaces the installer
placeholder refusal with actual Linux kernel-policy checks. Full protected
runtime and mapped-library verification remain mandatory; effective systemd
properties must confirm Accept=no, root service identity, control-group kill
and persistent recovery completion before socket activation.

Built ace-lab 0.14.2.pre.utm65 (SHA-256
`30e6c5bd46b99062e3ebef4ee8d26584906747680fa09484b831e34b19e6b17b`)
passed default dry-run and actual installation on the diagnostic VM. An ordinary
mo process was refused by the activated singleton. Observed issuer MainPID
21248, invocation `b6cbe370f5f24cce8e64cf3f4fb58636`; socket Accept=no and active,
recovery oneshot active/exited, issuer root/simple/control-group and running.

Session issuance now requires the trusted handler's supervision contract and
an available parent supervision callback. Direct unsupervised session Service
calls still refuse. Independent review found and fixed a failure window: remote
issuance can precede a failed request return. Such failures now raise
UnresolvedIssuanceError and stop the singleton for canonical recovery, even if
the handler has not received a lease object. Real Service regression exercises
provider issue followed by failed credential handoff. Reviewer approved commits
338cd3f92, 3829acc32 and 52f71ef97; independent rerun 110 tests, 411 assertions,
zero errors/failures. Installer tests: 12 tests, 46 assertions, all passed.

Diagnostic runtime utm67, source `52f71ef9741b299a41ddbd62242a3f0623fdaf08`,
SHA-256 `40b82042f4c3ae4d8e64e6af77152451076313c21f9e49ae1847a4557c0ccd9c`,
replaces only the diagnostic issuer units; utm65 units are archived under its
diagnostic directory. A root-owned diagnostic auth profile uses a root-only
Forgejo admin password reference. The earlier authorization document is backed
up in `/opt/ace/diagnostic/utm67/authorization-before.yml`. No secret was emitted.
The pinned acceptance manifest remains unchanged.

## Public CLI session cycle on local Forgejo

The first utm67 probe reached real lease issuance and exec, but Git returned
128: the generated askpass script was on the session's noexec `/run` mount.
Cleanup still returned revoked. A bounded permission probe confirmed the
script's correct UID/mode but failed executable access and noexec mount flags.
Commit `321ad118275dbb0fe64d3ae5fe0cc694a5a2b433` moves the unchanged askpass
logic into the protected installed package; ephemeral credentials remain data
and the mount remains noexec. Targeted verification: 144 tests, 576 assertions,
zero failures/errors.

Artifact ace-lab 0.14.2.pre.utm68 from that commit, SHA-256
`4034f0479d41a68873f05edcdff03844beddefba696588dfe7a9ffab99b66137`,
was installed with its full dependency closure under the diagnostic gem home.
The default installer verified and activated its singleton units. Earlier
utm67 units remain archived under that diagnostic directory.

`probe-session-project.rb --forgejo` passed with actual public `ace-lab auth`
request, exec (git ls-remote), and status. It required Git's main ref, exit 0,
confirmed revocation and revoked status. Observed unit
`ace-auth-session-worker-7544e47114910c14.service`, invocation
`7ff1980e9d30465d99fdc2e76f67fda7`, UID 63847, backing UID 1001. Existing
barrier, write, private-file/rename denial and sibling-project checks passed.
Host verification of canonical record `lease-ed5f4f931660e549` confirmed
revoked/cleanup=revoked; authenticated Forgejo token inventory confirmed the
remote token was absent. No credential value was emitted. Successful temporary
project and session transport were cleaned; failed probe directories remain
available for diagnosis.

Still outstanding: integration with the normal install flow, isolated native
Herdr terminal/lifecycle integration, live fault/restart/expiry cases,
TS-MONO-003/004, and two clean acceptance runs. This diagnostic cycle starts
through the installed SessionLauncher, not native Herdr. Task remains in-progress.
