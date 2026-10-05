# Independent architectural proposal review — 9c2

Candidate: `bbe8c961b19e2990a51b32377a78b6aaae952652`, based on `85c9704fe7e27a02dfd1ea12165093b6a3d2355a`. Scope: the three changed task documents only.

**Verdict: APPROVE integration as a truthful draft proposal. This is not implementation readiness, architecture approval, installed acceptance, or permission to promote.** Task 9c2 must remain `draft` / `needs_review: true`.

No verified defect requires blocking integration of this draft. The proposal consistently labels new operations, map v2, canonical events and OS authorization as proposed work. Its dedicated worker Herdr server assumption remains unanswered by the Captain. Root's working assumption is not product approval.

## Assessment

- Sustainable generation/reuse is explicitly specified: reserve before start, hold ambiguous start without duplicate activation, pin actual generation, seal before stop, require positive retained-parent emptiness, canonical release before retirement/reuse, and reject historical proof for a newer incarnation. It does not require manual reinstall per attempt.
- Ownership remains in the existing system manager and Assign lifecycle/journal. The authority gains explicit narrow installed StartUnit/StopUnit permissions; callers do not gain arbitrary unit names, transient units, property writes or privileged argv. The readiness/ACL action remains an unresolved installer contract, rather than a delivered new privileged broker.
- The parent slice is the proposed observation object, rather than service inactive status or original child exit. Reopening compares boot, manager invocation and kernel object identity. Missing/replaced objects retain uncertainty. The canonical seal is correctly described as admission closure, not a kernel permanent-empty primitive.
- The outside-writer requirement covers more than descendants: other native sockets, abstract sockets, buses, container/SSH control surfaces, reachable process-control services, mutable startup state, inherited descriptors, mounts and network filesystems. A dedicated UID alone is not claimed sufficient. This is a complete requirement boundary, not a proven usable installed profile.
- Client examples match the existing framing: `Client#call` injects mapping ID in params and project ID in the envelope. Existing Server identifies mapped kernel peers and rejects unexpected transfer descriptors. Existing LaunchLifecycle has closed operation/parameter sets, mutation replay/CAS and exact original-child validation. The proposed scope calls/events are absent today and are honestly labeled absent.
- Deployment currently accepts map v1 and a fixed native server/socket identity. The proposed v2 deliberately replaces that static contract with generation observations, and explicitly assigns the required 09j adaptation to 9c2 without weakening the original-child gate.

## Readiness obligations that remain blocking

1. Captain decision on exclusive attempt-specific worker servers, dedicated principals/parallel slots, and required SSH/container/host-terminal capabilities.
2. Exact installed OS authorization, including unauthorized verbs/units, indirect activation, non-root manifest/native verification and cgroup read access. Source availability of polkit unit/verb details is not allow/deny evidence.
3. A bounded auditable per-activation native readiness/socket ACL action, with immutable inputs and endpoint replacement/symlink handling. Review whether the selected action complies with the prohibition on a new privileged helper/broker.
4. Fresh fixed native workspace readiness without worker-writable session/plugin/rc restoration, while retaining the actual 09j fresh child gate. No existing setup hook is delivered by this draft.
5. Actual active-parent object retention, service metadata retention, authority/manager restart reattachment and stop/reuse behavior on a declared supported Linux/systemd configuration.
6. A usable enforced filesystem/network/socket profile closing all local and delegated writer routes. Broad current Lab writable roots cannot substantiate this claim.
7. Executed permitted native acceptance evidence for origin placement, fork/reparent descendants, seal/closure races, restart, ambiguous jobs, isolation and automatic reuse, plus registered canonical event/API changes and consumer verification.

These are technical results of the same task, except the explicitly identified Captain product decisions. None can be discharged merely by approving this proposal.

## Evidence and limits

Read repository AGENTS.md, `.agents/skills/as-task-review/SKILL.md`, its task-review workflow source, all three candidate documents, and current `ace-assign/lib/ace/assign/authority/{client,deployment,server,launch_lifecycle}.rb`. The normal review workflow's mutation/promotion steps are outside the explicitly authorized draft-only review; no task files or status were changed.

Primary source reads: [systemd v257 slice.c](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/slice.c) shows a fresh invocation ID and cgroup realization on slice start and active state until stop; [dbus-util.c](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/dbus-util.c) is the proposed authorization source; [Herdr pinned native socket server](https://raw.githubusercontent.com/herdrdev/herdr/7b116c05bfda646af39d2524c54e70c751f57ee8/src/api/server.rs) and [kernel cgroup v2 documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) were consulted. These reads establish source-level context only. They do not prove the installed primitive or native readiness.

No tests, native/security/host-policy probes, executable experiments, deployment, authorization changes or filter retries were performed. The prior automatic-filter restriction remains in force. This verdict approves documentation integration only; any merge gate's executed checks remain the integrating owner's responsibility.

## Follow-up review — 3daca65d210dca6f9545f0232d1a9fe247f83779

**Verdict: APPROVE integration as draft research only. No architecture selection, implementation readiness or installed acceptance is approved.**

Read the exact three-file commit diff, including all of native-readiness-acl-feasibility.md, and checked the relevant current ProtectedNativeControl/ProtectedSocket source and cited primary native/systemd/ACL documentation. No integration-blocking factual defect was identified.

The follow-up accurately distinguishes an immutable root-installed executable from root execution. A same-User post-start process can change its owned socket's ACL; this does not make application readiness or atomic endpoint binding automatic. systemd post-start failure/timeout semantics and exclusion of privilege/failure-ignore prefixes are appropriate requirements. The ACL manual confirms owner authority and the limited final-component protection of physical symlink mode.

The existing verifier calls root_path! on the native socket parent with owner defaulting to zero and rejects group/other writable ancestry. Its separate socket-object and connected-kernel-peer checks are present. Thus an unchanged non-writable root-owned parent cannot provide ordinary unprivileged dynamic socket creation, and worker write ACLs or a worker-owned RuntimeDirectory do not silently satisfy the current contract. The report correctly identifies this incompatibility.

Pinned Herdr bootstrap starts its API listener before App construction, seeds a workspace, prints readiness, runs startup hooks, then enters the application loop. Its pathname socket preparation/removal and bind operations do not supply the missing atomic replacement guarantee. The report correctly treats a responsive exact-workspace request, clean startup inputs, contained baseline processes and authority generation/peer checks as required results rather than delivered support.

The generation-specific worker-owned-parent verifier is explicitly conditional and unselected. Its path/object replacement, continuing control-peer validation, ACL target binding and per-command mount-object visibility obligations remain concrete unresolved work. Draft integration need not choose either architecture alternative; selection and permitted installed evidence must precede readiness/promotion. The prior review's Captain product questions, complete outside-writer boundary, retained-parent/restart and authorization obligations also remain open.

Source links: [systemd service semantics](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.service.xml), [setfacl manual](https://man7.org/linux/man-pages/man1/setfacl.1.html), [pinned Herdr bootstrap](https://raw.githubusercontent.com/herdrdev/herdr/7b116c05bfda646af39d2524c54e70c751f57ee8/src/server/headless/bootstrap.rs), [pinned Herdr IPC](https://raw.githubusercontent.com/herdrdev/herdr/7b116c05bfda646af39d2524c54e70c751f57ee8/src/ipc.rs). No probes, tests, source/spec mutations, delegation, deployment or permission changes occurred. Task remains draft / needs_review.
