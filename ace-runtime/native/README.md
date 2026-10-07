# Protected Linux worker bootstrap

The `ace-runtime` gem ships `native/worker_gate.c` and `native/build-worker-gate`.
This is a Linux executable, not a Ruby interpreter wrapper. Build on the target
architecture from the installed gem with the system compiler and json-c parser.
Supported initial architectures are Linux x86_64 and aarch64 with little-endian
ELF64. A bootstrap built on another architecture fails deployment preflight.

On Debian bookworm install the distribution's `build-essential`, `pkg-config`
and `libjson-c-dev` build packages. The executable requires the matching system
`libjson-c5`, libc and ELF loader at runtime. Use the same distribution/architecture
for build and deployment; retain package versions, source SHA, compiler version,
ELF machine, `readelf -d` dependencies and output SHA256 in installer evidence.
These libraries and their loader search directories must remain root-owned and
non-worker-writable. The pinned Herdr service starts with a clean root-controlled
environment, so no worker loader/preload environment reaches bootstrap startup.

From the installed gem directory, in a private unprivileged build directory:

```sh
native/build-worker-gate /absolute/private/build/ace-worker-gate
sha256sum /absolute/private/build/ace-worker-gate
readelf -h -d /absolute/private/build/ace-worker-gate
```

The administrator installs this exact artifact, without setuid/setgid bits:

```sh
install -o root -g root -m 0755 /absolute/private/build/ace-worker-gate /usr/libexec/ace-worker-gate
```

All installation ancestors are root-owned and non-worker-writable. The fixed
root-owned `/etc/ace/assignment-authorities.json` records `bootstrap` and its exact
`bootstrap_sha256`. ACE verifies digest, ELF architecture, executable permissions,
ownership and ancestry before reservation. The native layout uses only this
absolute executable, installed mapping ID and correlation ticket; payload argv,
cwd and environment come from the root-controlled mapping after authority release.
The map grants no UID switching and the binary is never privileged.

The root-installed authority, launcher and native server units require:

```ini
User=<their distinct mapped account>
NoNewPrivileges=yes
CapabilityBoundingSet=
AmbientCapabilities=
```

Worker children inherit the server's empty bounds and no-new-privileges policy.
ACE checks all real/effective/saved/filesystem IDs, supplementary groups, every
capability set and `NoNewPrivs` from kernel status for all mapped participants,
including the pinned server. CAP_DAC_OVERRIDE/CAP_SETUID are refused, as is an
exec context that could gain capabilities or setuid privilege. Yama=2 remains
mandatory; an empty capability set alone does not stop same-UID injection.

The bootstrap sets non-dumpable before connecting, requires enforced Yama
`ptrace_scope=2`, requires empty Inh/Prm/Eff/Bnd/Amb capability sets and NoNewPrivs=1, verifies
worker IDs/groups and its retained actual kernel parent birth, authenticates authority
SO_PEERCRED and protected socket ancestry, and waits at most 30 seconds on one
stream. It never reconnects or executes after pre-release EOF, malformed input
or timeout. A committed release whose response is lost remains potentially
executed; public inspection must retain ownership rather than resend release.

The gate accepts only the maintained `ace.assign.authorities/v2` mapping. It
captures its actual parent PID and kernel boot/start-tick birth before reading
the map, checks that same birth before and after parent credentials, and repeats
the check before authority admission and immediately before exec. The canonical
`gate_ready` authority owner associates the actual gate peer and its parent with
the original recorded child/server; the map supplies no `server_identity`.
Changed parent birth, reparenting, inaccessible credentials or changed policy
refuses. The fixed payload is exactly `[ABSOLUTE_ACCEPTED_ACE_ASSIGN, "authority",
"worker"]`.

Release is one compact JSON record containing the original ticket/assignment/
attempt/generation/commit plus `prepared_input`. That closed object pins the
original registration generation/commit, definition and original binding digest,
prepared-work reference and exact journal bundle reference/length/SHA256. The
authority verifies the original bundle before durable issue; subsequent prepared
fetch authenticates the accepted release pin before returning body bytes. The
gate validates the closed fields, digests and unchanged bounds before exec. It
does not receive inline work or propagate an input FD to providers. The worker
uses the existing authenticated original prepared fetch after release.

An ordinary Docker kernel with Yama=0 can verify compilation and fail-closed
policy rejection. It cannot demonstrate protected launch acceptance. A real
isolated Linux deployment enforcing the complete policy is required for that
positive proof; installing this gem does not change host sysctls or install OS
service/account policy. Downstream gad.8 provisions those requirements and
consumes this shipped build mechanism.
