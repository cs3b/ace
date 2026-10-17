# Execution scope ownership: bounded architecture research

Read-only research, 2026-10-05. No native launches, privilege/security probes, containers, VMs, reproduction, tests, or deployment were run. This is a recommendation and decision inventory, not a selected contract or installed proof. Existing task/spec/source files were not changed.

## Result

The smallest credible **unmodified-Herdr** design candidate is an exclusive execution slot whose protected cgroup contains its entire native Herdr server and all native children, with one active attempt per slot and no unrelated interactive panes. Completion and stop both seal the slot, end its server generation, and establish empty scope before canonical completion/release. This is conditional: deployment must close every other process-creation or write-delegation path accessible to that worker. A pane-only cgroup is insufficient under the existing socket topology.

If retaining a persistent shared native server with concurrent attempts is a requirement, this candidate is unsuitable. That requires enforced per-attempt native spawn routing and writer isolation, or an OS sandbox that prevents workers reaching external spawners. Neither is currently implemented; neither should be described as a small adapter change.

## Verified source facts

* `ace-assign/lib/ace/assign/authority/deployment.rb:197–241` strictly validates fixed launch fields and pins native executable/version, socket identity, server PID/birth/credentials/parent and workspace. Native server UID/GID/groups must equal the worker credentials. It contains no execution-cgroup identity or slot owner mapping. It requires distinct non-root authority, launcher and worker principals.
* `ace-herdr/lib/ace/herdr/molecules/protected_native_control.rb:63–110` launches a single fresh layout and preserves original native provenance. `:143–147` terminates the pane and observes the previously acquired child pidfd. No whole scope termination is present.
* `ace-assign/lib/ace/assign/authority/launch_lifecycle.rb:527–557` inspection accepts exact recorded-child exit from a retained in-memory pidfd; otherwise it checks/re-pins a live original identity. Absence after restart is not inferred. `ace-runtime/lib/ace/runtime/molecules/protected_linux.rb:70–113` implements pidfd identity and ancestor checks, not sealed descendant-scope proof.
* Current Lab units `/Users/mc/Ps/lab-config/herdr-lab@.service`, `herdr-lab-overseer@.service`, and `herdr-lab-chief.service` run persistent account-owned servers, `Restart=on-failure`, account writable homes/runtime roots and `/lab`. These are not attempt-exclusive scopes. Reusing them as whole-attempt scopes would kill unrelated panes.
* Inspected cached native source `/tmp/herdr-09j-review/src/app/api/layouts.rs:34–125` creates a fresh tab via a fixed argv branch; `src/pty/backend/unix.rs:12–34` invokes portable-pty spawning. `src/app/api.rs:510–605` and `src/persist/restore.rs:688` have respawn/restoration paths. These must belong to the ownership analysis even when fresh gated launch excludes restoration.
* [Herdr server source](https://raw.githubusercontent.com/herdrdev/herdr/v0.9.3/src/api/server.rs) creates its restrictive Unix endpoint and dispatches connections to request handlers; no peer-role admission was found in the inspected accept path. [Native layout source](https://raw.githubusercontent.com/herdrdev/herdr/v0.9.3/src/app/api/layouts.rs) creates native processes, rather than merely returning metadata. [Terminal runtime source](https://raw.githubusercontent.com/herdrdev/herdr/v0.9.3/src/terminal/runtime.rs) delegates spawning to pane runtime. Local cached source and freshly retrieved tag content have different line numbering; pin the exact native commit/artifact for implementation, rather than relying on mutable tag line numbers.

The existing `scope-exit-research.md` independently records a worker-UID client creating a second genuine native child through the real Herdr socket. That historical evidence proves the accessible spawner path; this report ran no reproduction and makes no claim of arbitrary escaped writer execution.

## OS guarantees and their limits

[Kernel cgroup v2 documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) specifies inherited membership on fork, migration permission requirements, recursive live-process population, and whole-subtree kill handling concurrent forks/migrations. Moving a parent does not collect existing descendants. Empty population is an observation, not a durable ban on future arrivals. Freeze does not seal membership. Thus scope identity, exclusive admission and no later migration/spawning remain application/deployment obligations.

[systemd delegation documentation](https://systemd.io/CGROUP_DELEGATION/) distinguishes service/scope lifecycle management from delegated subtrees and requires one manager per cgroup. Delegating a worker-owned service to that same worker is unsuitable for protected ownership. If ACE directly manages subgroups, install delegation to the trusted authority/launcher principal, not worker, and respect systemd's ownership boundary. Cross-UID movement/kill permissions must be established; delegated-directory ownership alone is not proof that a non-root principal can manage a differently owned process.

[systemd kill source documentation](https://raw.githubusercontent.com/systemd/systemd/main/man/systemd.kill.xml) supports full control-group termination and warns that process-only termination leaves processes outside manager lifecycle assumptions. This is a useful established owner candidate, but successful stop/status is not itself ACE's restart-safe proof. Avoid mixing systemd ownership and ACE writes to the same undelegated cgroup.

## Candidate contract, not implementation

1. **Exclusive admission.** Reserve a fixed installed slot in the existing canonical authority journal before native creation. The slot's native server, workspace and writable worker domain serve exactly one active attempt. Other slots/users and interactive Herdr services cannot write that attempt's files. Do not introduce a second journal or privileged domain broker.
2. **Scope before release.** The whole native server must already be inside its installed protected cgroup before it can create attempt children. Preserve existing bootstrap gate, fresh original pane and server/socket checks. An alternative gated-child migration must prove the bootstrap cannot fork before placement and must separately prevent requests to an outside server; it does not inherit this candidate's simplicity.
3. **Exact identity.** Bind assignment/attempt/mapping/reservation generation to boot identity, native server birth identity, socket generation, and cgroup filesystem/mount plus directory object identity. A path or unit name alone is reusable. Pin/open the original object during live observation; define restart revalidation of the recorded generation without adopting a replacement at the same path. Persist lifecycle evidence in the canonical journal. Do not call a path disappearance proof.
4. **Seal.** Canonically revoke release/admission first. Prevent restart, restoration, socket/service activation, new native requests and migration into that exact generation; then terminate its complete cgroup through the chosen sole owner. Include the native server so queued native spawn requests cannot survive teardown. A permanent retired generation must never be reused. Any slot reuse starts a new recorded native/scope generation.
5. **Empty and final.** Require positive empty observation of the exact original scope after sealing, and bind it to the canonical transition. Original-pane close remains a native cleanup operation, not this proof. For natural finish, worker output publication/preparation precedes sealing; completion becomes final only after descendants and server are gone. For stop, unresolved scope observation retains ownership/uncertainty and does not authorize a replacement attempt.
6. **External writers.** Inventory native socket, user/system service-manager APIs, SSH/agent facilities, containers, schedulers, other control sockets and shared worker files. Each accessible writer/spawner must either execute inside this scope, be unavailable under enforced deployment policy, or belong to an explicitly authorized service whose bounded write semantics are accounted for. A promise not to use it is insufficient. Giving each slot a distinct installed worker UID reduces same-UID sibling authority but does not block network/service-mediated delegation by itself.

## Alternatives

| Candidate | Merit | Unresolved cost / rejection reason |
|---|---|---|
| Exact child pidfd + ancestry/process groups | Existing narrow launch contract | Reparenting, daemonization and external native spawn defeat complete scope proof; cannot establish no writer after release. |
| Pane-only protected cgroup | Least disruption to native topology | Requires trusted cross-UID placement, gated race-free entry, and enforced closure/routing of all external spawners; current worker-accessible Herdr is outside it. |
| Whole dedicated native-server slot cgroup | Contains native spawn and respawn by inheritance; no Herdr patch | Must make server exclusive, seal automatic restart/activation, isolate writers, and provision new generations for reuse. Recommended investigation candidate. |
| Persistent shared Herdr with native per-attempt routing | Preserves concurrency | Requires native process creation and all command/plugin/restore routes to carry authenticated immutable attempt membership; not available in inspected 0.9.3. |
| Attempt sandbox/container/VM | Strong isolation boundary can include spawners | Larger installer/runtime boundary and native routing/identity changes; still needs exact teardown and external-service policy. No experiments run. |

## Fixed-map compatibility and remaining decisions

Existing maps can represent a dedicated preinstalled server slot's credentials and pinned native generation, but cannot express execution scope identity, exclusive ownership or sealing. Server termination invalidates their pinned server/socket generation: runtime cannot silently restart, rebind or adopt it. A schema/installer contract change or explicit new installed mapping generation is necessary. Existing persistent Lab units with automatic restart are incompatible as-is. The documented candidate does not presume authority has privileges it currently lacks.

Decide before promoting a task:

* Must one worker/native server run concurrent attempts? If yes, choose native routing or a stronger sandbox and reject whole-server slot containment.
* Which single scope owner is permitted: preinstalled systemd unit with narrowly authorized lifecycle, or authority/launcher-owned delegated subtree? Specify cross-UID permissions and read access without granting broad unrelated-process control.
* Who provisions/pins each fresh native generation after teardown, and how is that authorized without a new privileged domain broker?
* Which enforced filesystem/socket/network/service policy closes external writer delegation? Existing fixed `scratch_root` and worker UID do not establish this automatically.
* What exact durable identity can be revalidated after authority restart, scope removal or reboot? Define retained-object lifecycle, seal evidence and missing-object uncertainty explicitly; inode/path reuse must not be adopted.
* How do worker finish acknowledgement, publication preparation, sealing, empty proof and canonical completion order, so server teardown cannot lose required output?
* Which supported Linux/systemd/kernel versions and native commit provide the selected interface? Current documents are capability evidence, not minimum-version installation proof.

Search strategy: loaded `.agents/skills/as-search-research/SKILL.md` and `bin/ace-bundle wfi://search/research`; discovery with `bin/ace-search 'herdr|deployment|launch_lifecycle|protected_linux' --file --max-results 50`; attempted multi-include content search returned overly broad results, so narrowed via targeted `rg` and exact file reads. Official primary docs retrieved through web. No native execution followed any inspection.
