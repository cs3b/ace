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

Still outstanding: real host installation readiness, isolated launcher and
native Herdr terminal/lifecycle integration, actual public CLI lease cycle on
Forgejo, TS-MONO-003/004, and two clean acceptance runs. The production installer
and session issuance guards remain active. Task 8y0.t.x27 remains in-progress;
the diagnostic VM and pinned runtime manifest are unchanged.
