# Remaining installed launch windows

Author HVF run74055 exited0; verify-windows.py independently parsed exactly one
complete no-failure JSON proof and checked all eight added windows, write probes
and actual native server restart. Original accepted evidence remains unchanged.
Run79689 failed a fixture assumption: a gate recorded before bind need not exit
within5s merely because its launcher died. The corrected fixture invokes the
public supervisor termination path (native close plus exact retained pidfd) and
then asserts positive exit and no issuance. Product deadlines were unchanged.
Both raw CRLF logs are preserved.

Actual cases: lost reservation reply (canonical replay, no create); launcher
crash before spawn / after create before record (reservation retained);
record-before-bind / lost-record-reply / lost-bind-reply launcher crashes
(public protected abort with no issuance); exact original-client lost record
and bind reply replay followed by one release each; process_vm_writev and
proc-mem write against actual server and original gate; actual native restart,
stale mapping refusal, installer exact birth/socket/container refresh,
missing launcher ACL refusal, new mapped public launch and unrelatedUID refusal.

Production closure is unchanged source e2d; approved later diagnostic text
change c3bd is not in the guest artifacts. The new scripts alter only the owned
fixture. A clean rerun rootfs was assembled after the author pass from the same
original installed export; windows-manifest hashes that clean rerun input,
not the mutable disk from the author run. Original installed export/gem/native
artifact provenance is retained in installed-protected-hvf/artifact-manifest.json.

Reproduction on the author machine after acquiring the heavy slot:
`cd /Users/mc/Ps/ace/.ace-wt/codex-wave5-protected-launch-final/.ace-local/09j-vm-windows`
Verify windows-manifest hashes, run boot-hvf.sh, which clones retained clean-rootfs.img with APFS `cp -c`
to disposable run-rootfs.img before each boot. Keep independent log filenames.
No NIC, host filesystem sharing or credentials are attached. Require both
QEMU successful termination and
`python3 verify-windows.py <serial-log> <proof-output.json>` successful exit.
For rebuilding offline, use build-rootfs.sh with the original installed-rootfs.tar;
only the fixture directory is mounted into the disposable Docker builder.

Observed gate memory writes occur after native layout/bind. Inherited Yama2,
empty capabilities, NNP and direct root-installed server ancestry are enforced,
but the interval before the gate's first prctl is not directly observed. This
record does not claim that interval was sampled or all literal09j cases closed.
Whole-scope issued termination and actual Lab acceptance remain separate.

Root checked the frozen fixture delta and ran both `verify-windows.py` and the
previous `installed-protected-hvf/verify-proof.py` against the retained author
attempt2 log on 2026-10-05. Both exited successfully. This verifies the retained
author evidence; it is not the pending independent clean-guest rerun. The earlier
independent 22184 run retains its original, smaller case coverage.
