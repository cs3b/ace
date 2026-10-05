# Usable local writer boundary — draft proposal

2026-10-05; source/document review only, no native probes, host changes or tests.
ACE main 6ec9ff8b5 and lab-config 2d03e18a4182e2fdab26bcd26c054023fb934802 were
inspected. This is a concrete required 9c2 specification slice for independent
review, not installed evidence. Task remains draft/needs_review.

## Meaning of the proof

The protected local resource set is the exact attempt's exclusive worker scratch
root, checkout including its Git metadata, writable harness/session/cache/output
roots, private temporary files and native runtime directory. Their installed
host paths, in-unit views and generation-specific directory/mount identities are
bound to the slot manifest and canonical generation before payload release.
A pathname prefix alone is not an object boundary. These roots must not alias
another slot's writable tree, canonical state, an outside mount or writable Git
common directory. Slot reuse begins only after old closure and canonical release.

closed_no_writers means the sealed exact execution generation contains no live
process that can continue writing those resources, and its installed boundary
allows no uncontrolled outside process to obtain that write authority. It does
not mean all remote effects cease, that kernel writeback has completed, that data
is durable, or that arbitrary administrator activity is prevented. Candidate/result
acceptance uses separately verified immutable bytes and provenance; scope emptiness
cannot replace those checks. Root/system manager and canonical authority remain
trusted owners; they must not act as an untracked payload-controlled spawner or
scratch writer. Any allowed external writer of these roots invalidates this profile.

Canonical journal_repository, evidence_checkout_root, assignment_root and
candidate_root are **not worker writable roots**. Existing Deployment selects
those project paths; Endcap submits untrusted candidate bundles into a clean
CandidateTransfer quarantine under authority-owned candidate_root. The worker's
checkout is a separate scratch object. No shared working repository/common Git
metadata, authority-owned candidate import or source checkout is bind-mounted
writable into the worker. Assignment instructions and required source/dependencies
are supplied read-only or copied into the private scratch before launch.

## Actual harness needs and existing deployment gap

ACE CodexClient/PiClient support subprocess working_dir and subprocess_env; Codex
writes a last-message file, both execute local subprocesses, and normal temporary
files need a writable private location. Their inner sandbox options are not the
outer protected boundary. Required shell commands, Git, builds and tests run as
scope descendants and may write private checkout/cache/temp; ordinary subprocess
fork/exec and PTYs remain usable. Installed Codex/Pi invocation must use a mode
compatible with this outer profile; any inner sandbox requiring forbidden new
namespaces must not be silently assumed compatible. CLI flags cannot weaken the
outer unit/kernel boundary, and actual provider startup remains acceptance work.

lab-config labd.py resolves provider-native auth stores and exports CODEX_HOME or
PI_CODING_AGENT_DIR for Codex/Pi. It also pins provider sessions and reads session
records for finalization. Thus auth/config input and writable native session/cache
storage must be mapped explicitly, not replaced with an empty HOME that makes the
harness unusable. The installed profile provides generation-private mutable
harness state with only that role's provider credential material, immutable startup
configuration/extensions and private output paths. OAuth renewal may write its
private auth copy; provisioning/rotation policy must not restore executable startup
content from a previous worker. Trusted finalization reads exact session records
without giving an outside process scratch-write access.

Current herdr-lab@.service and herdr-lab-overseer@.service use Type=simple,
Restart=on-failure and broad ReadWritePaths=/lab plus writable home/runtime.
labd child_environment also exports a host user bus and host credential helper.
These are actual existing contracts, **not** the protected attempt profile.
Persistent overseer services keep their separate role. Protected workers receive
no host bus address, labd/root-broker socket, container control socket, SSH agent,
outside Herdr endpoint or credential helper capable of invoking outside local
executors. A plain installed Git helper that only reads a bounded remote token
is not automatically a local spawner, but its exact implementation and credentials
must be included in the installed profile; no implicit host helper inheritance.

## Proposed default supported installation

The initial backend is Linux, system systemd with the reviewed v257 semantics,
unified cgroup v2, functioning pidfd/kernel birth observation, POSIX ACL support,
mount/IPC/network namespaces and enforceable syscall/namespace restrictions.
09j currently requires Yama ptrace_scope=2 and zero inherited/permitted/effective/
bounding/ambient capabilities with NoNewPrivs=1; 9c2 preserves these requirements.
This review does not change kernel security settings. macOS, Windows, cgroup v1,
user-manager-only ownership, missing restrictions or merely similar service
configuration return unsupported/unverifiable. No fallback to PID/group/UID kill.
A newer systemd installation needs verified equivalent behavior, not a version
string assumption. These are capability requirements, not a claimed host inventory.

Root/system manager installs the fixed minimal root, native/unit/profile artifacts,
exact slot User/Group, retained slice/service, namespace and scoped authority
StartUnit/StopUnit permissions. Authority has no arbitrary root command, transient
unit/property permission, sudo credential or cgroup delegation. Workers receive
none of those OS-owner permissions. Installation must show effective properties
and kernel restrictions; settings silently omitted/unsupported do not qualify.

The fixed profile uses RootDirectory and explicit read-only tool/runtime/CA/DNS/
configuration inputs; ProtectSystem=strict; explicit bounded writable mounts;
NoNewPrivileges; empty capability sets; RestrictNamespaces; ProtectControlGroups;
PrivateDevices; private IPC and preinstalled NetworkNamespacePath. It permits
AF_UNIX/AF_INET/AF_INET6 needed for control and providers, not AF_PACKET/AF_NETLINK.
It does not use MemoryDenyWriteExecute or a speculative syscall denylist that
breaks Node/JIT/build tooling. Exact syscall enforcement must prevent namespace,
mount, privilege and process-control escapes while permitting ordinary harness
subprocesses. [systemd execution documentation](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.exec.xml)
explains that read-only path views do not constrain outside processes, namespace
settings depend on kernel support, and address-family restrictions do not close
already inherited sockets. Therefore unit directives alone are insufficient:
mounts, credentials and initial descriptors are inspected as part of admission.

Each protected worker root sits below a root-owned non-writable host ancestor
whose search ACL admits only this slot UID and explicitly trusted read/owner roles;
other worker, reviewer, overseer and executor principals have no traversal/write
access. The worker can chmod its own descendants, but cannot grant search through
that immutable ancestor. [Linux path resolution](https://man7.org/linux/man-pages/man7/path_resolution.7.html)
and [ACL permission evaluation](https://man7.org/linux/man-pages/man5/acl.5.html)
provide this access boundary. The same UID has no login, SSH, cron, user manager
or other outside process entrypoint; supplementary groups provide no broader
write/control authority. Dedicated UID alone is insufficient without ancestor,
mount, descriptor and spawner restrictions.

Writable backing is local kernel-managed storage with validated ownership/ACLs;
no writable NFS/CIFS/FUSE/network-backed directory or outside userspace filesystem
writer. No shared writable hardlinks/aliases, bind mounts, .git common directories,
open foreign directory/file descriptors, or inherited listener/control descriptors.
Only stdio/PTY/journal channels and declared scope-native descriptors are inherited;
the authority gate uses its authenticated connection, not a leaked host descriptor.
Logs handled by journald outside the scope are outside the protected local set.
Runtime private directories needed by native readiness are the same objects seen
by server and post-start action, as required by the readiness report.

## Sockets, routed providers and external effects

Filesystem sockets visible to the worker are its own native endpoint and the
existing authenticated canonical authority endpoint, plus any explicitly declared
in-scope local tool sockets. An in-scope tool server must inherit this scope and
cannot transfer work to an uncontrolled outside writer. Host abstract Unix sockets
are absent from the private network namespace; IPC/shared-memory surfaces likewise
cannot connect to an outside worker. No system/user bus, Docker/Podman/Incus,
labd, root/HITL broker, host terminal or SSH control endpoint is mounted.

The preinstalled namespace retains routed DNS/TLS/provider egress. LLM requests,
remote read/fetch and ordinary Internet responses are usable: receiving bytes and
running tools locally writes through contained processes. Routed networking is
not automatically an escape. Deny routes/credentials to host or internal executors
that can mutate the protected local roots, including host SSH/container daemons
and shared-storage control endpoints. Incoming access to the slot is denied;
loopback tool services remain in the slot network namespace. Provider/remote Git
credentials have no host-login/control or protected local storage authority.
A host route that reaches a harmless provider endpoint need not be prohibited
solely because it is routed; the installed endpoint/credential contract must show
it cannot command an uncontrolled protected-root writer.

Remote Git pushes/API actions, CI jobs and service receivers are separate effects,
not presumed local writers. They require the existing operation-specific
canonical authorization/claim/receipt policy whenever their effect contract calls
for it. No claim is made that cgroup teardown cancels a remote request already
accepted. Receiver staging/targets must remain separate from protected worker and
authority roots; Deployment already checks receiver staging overlap. A receiver
that can directly mutate worker scratch cannot qualify under this selected profile.
Use verified byte transfer and separately owned staging/output instead.

At canonical seal, serialize with existing service and local-write admission:
no new request/claim/begin_dispatch may authorize an effect for that old generation.
Previously dispatched work may still complete; its completion/settlement remains
accepted through its existing owner so sealing cannot strand it. Buffered requests,
lost replies and receiver work already in flight cannot be treated as canceled
because the worker/socket died. Before finish or terminal stop releases ownership,
all such canonical requests must be succeeded or failed-settled with verified
completion/no-effect evidence, and bound inboxes must be reconciled. This is the
existing xz9 endcap condition, independently checked in the same terminal CAS;
9c2 adds the required scope-seal admission guard, not another effect ledger.
A receiver may outlive worker scope while settling its separate authorized target;
its state never turns a populated scope into closed_no_writers or vice versa.

## Remaining decisions and acceptance

This specifies a usable contained shell/build/Git/Codex/Pi/provider profile, not
installed validation. 9c2 must deliver the declared manifest, effective permissions,
mount/FD/socket/route inspection and positive refusal/continuous-operation evidence.
Lab-config owns actual fixed runtime/dependency/auth/provider installation and
routing; generic ACE owns admission, exact resource/generation identity and seal
checks. Installation failure refuses before release; later loss of boundary
identity makes fresh proof unverifiable and holds ownership.

The engineering baseline uses bounded separately authorized services for host
capabilities outside this profile and separate persistent overseers. Arbitrary
worker host SSH/admin/container/shared-write access is not requested by the
program and creates no new permission gate. The optional earlier preference
question can steer the design, without treating silence as approval. A later
request for broader access changes the declared specification; it is not a
current undefined contract.

## Inspected source pointers

* [ACE deployment paths and receiver overlap checks](../../ace-assign/lib/ace/assign/authority/deployment.rb),
  [candidate admission](../../ace-assign/lib/ace/assign/authority/endcap.rb) and
  [isolated candidate transport](../../ace-assign/lib/ace/assign/authority/candidate_transfer.rb).
* [09j kernel policy](../../ace-runtime/lib/ace/runtime/molecules/protected_linux.rb),
  [Codex CLI client](../../ace-llm-providers-cli/lib/ace/llm/providers/cli/codex_client.rb)
  and [Pi CLI client](../../ace-llm-providers-cli/lib/ace/llm/providers/cli/pi_client.rb).
* lab-config at the pinned revision above: herdr-lab@.service,
  herdr-lab-overseer@.service; labd.py native_provider_auth_env (1254),
  child_environment (1764), host agent launch (15115) and native finalization
  (14754); docs/lab-interface.md. Configuration source only was inspected;
  credential material and installed host state were not read.
* [Existing xz9 finish/stop independent settlement contract](../8x3.t.xz9-execute-scoped-services-across-os/protected-authority-contract.md),
  especially terminal admission's service/inbox requirements. The new seal
  guard is a 9c2 required integration result, not claimed current Endcap behavior.
* [Kernel cgroup population semantics](https://docs.kernel.org/admin-guide/cgroup-v2.html)
  establish live-process absence recursively; they do not define remote-service
  cancellation or filesystem durability.
