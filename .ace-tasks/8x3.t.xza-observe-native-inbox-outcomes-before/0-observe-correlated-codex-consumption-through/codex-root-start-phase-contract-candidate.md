# Codex root start phase: candidate contract

Status: proposed, pending Captain approval; no implementation, task promotion, native probe, or acceptance claim. This amends the existing xza.0/gad installation join rather than introducing a broker. Official rust-v0.159.3 source establishes native UID-owned `0700` daemon directory, `0600` physical socket, and advertised symlink. Existing distinct context UID cannot reconnect through normal DAC. Accepted executable provenance must still bind that source behavior.

## Existing product and required changes

`InboxContextService.run!` constructs the original context listener and `NativeQueueExecutor`. Submit/observe invoke `CodexRuntimeSelection.with_connection` per handler. One retained startup connection does not solve this consumer. Authority Serve also verifies its positive non-root installed principal; attaching a Ruby root-owner callback does not acquire root privilege.

The smallest candidate is fixed, source-verified root pre/post commands on the SAME dedicated Codex native unit, admitted by the SAME `LaunchLifecycle.complete_native_start!` winner. Amend `ExecutionUnitInstallation`'s current empty `ExecStartPostEx` contract explicitly; bind exact commands, credentials, source closure and privilege/sandbox projection in the installed profile. No caller-selected unit, generic root operation, fallback transport, group grant, default ACL, or principal collapse.

Root pre-start validates literal completed installation/intent and exact attempt input, retains startup inhibition, and removes only authenticated prior access ACLs when necessary for native bind. Upstream rejects daemon mode other than `0700` on each bind. It must never adopt an unknown socket/process or reset permissions beneath admitted consumers. Existing authenticated retirement and full parent proof remain prerequisites for reuse.

Root post-start authenticates its own exact installed ControlPID/source/UID and native MainPID, invocation, boot identity and pidfds in the admitted mapping/attempt lifetime. It grants only directory traverse to installed context UID(s), and socket write/connect to that socket's exact context UID. Proposed closed ACL: directory owner7/group0/other0, named users1/mask1 (`0710`); socket owner6/group0/other0, one named user2/mask2 (`0620`); no default or named-group ACLs. EndpointProtection must explicitly validate this exact ACL and retained inode/mount/unchanged-path evidence before and after every reconnect. Current no-ACL/0700/0600 validator must not be silently relaxed.

Root post runs while `activating/start-post`, whereas current `RuntimeProducer.server_identity!` requires `active/running`. A narrow typed phase proof is required for production inside post; canonical readiness must separately revalidate native `active/running` after post exits. Root remains publisher of immutable output in the existing root-owned `0755` ancestry/`0444` files, readable by context through PAS. No private authority output redesign is implied.

## Actual readiness channel, not a delivered Codex handoff

`ace-assign/lib/ace/assign/authority/launch_scope_admission.rb:33` implements `native_readiness!` on the original private authority transport: ONE challenge/report per admitted issuer, authenticated by `observer.readiness_peer!` as the original worker, transferred with purpose `scope_boundary_observation`. At lines153–164 that worker report is already consumed before `@codex_startup.call`. It carries no Codex stage REF today. `commit_ready_native!` at line178 stores only the existing worker payload in qjl `scope_native_bound` through `scope_native_binding`.

Required amendment: a bounded Codex phase discriminator/challenge in that SAME authority transport and issuer lifetime, authenticated against the exact admitted root post ControlPID plus native MainPID/invocation and installed source. It must not reuse the already consumed worker report or accept generic root peers. Validate a closed bounded payload containing exact installation/intent/configuration and literal published runtime-stage REF; retain the stage in the SAME qjl authority mutation before readiness. Extend the maintained event/lineage schema and replay reader coherently. Root phase supplies evidence only; authority retains canonical readiness/release/status mutation ownership. Final post exit and original worker/native checks precede commit. Actual production Owner factory and original Serve attachment remain required; source-only callbacks are not that hookup.

Literal completed installation, exact attempt binding and predecessor/runtime inputs must come from root-owned protected systemd `LoadCredential` data bound to this admitted invocation. Never select `current`, `selection.json`, latest thread or last-session as handoff authority. LoadCredential choice does not itself implement privilege, native-root observation or stage transport.

## Ordering and failure ownership

Original winner admission retains exclusion and original slot/slice/resource/source checks. Root pre/start/post completes exact native birth, ACL projection, one thread start or exact predecessor resume, and immutable publication. Context units start only after literal stage retention and successful post/native checks; original entry association and remote UI resume consume that exact stage. Replay does not spawn again.

Lost thread reply, uncertain publication or failed post verification seals the attempt and keeps ingress inhibited. Existing typed scope owner stops authenticated context/Codex units and original worker with invocation/birth revalidation. Retain lineage and original slice until the existing whole-parent `populated=0` proof; only existing released-parent retirement stops/removes the slice. Unknown surviving writers block closure. Next attempt resumes only the retained exact predecessor thread REF, with no private retry/discovery.

## Genuinely unresolved selections

* Captain approval of the exact named-context ACL and same-unit root pre/post specialization, including literal LoadCredential handoff.
* RootDirectory/mount projection: physical `/tmp/codex-daemon-UID/hash` is in native process view. Select a maintained authenticated projection or same-view privileged command; host `/tmp` lookup is not proof. Exact privilege and sandbox settings require review, not guessed systemd flags.
* Shared native UID: current Deployment requires distinct worker UIDs across mappings; preserve this check. Multiple units/contexts within one mapping can still share the daemon directory. Select closed directory UID union and inhibit all affected context ingress during ACL reset/binds, restoring it only after all corresponding outputs are ready. If accepted deployment permits cross-mapping UID sharing, an explicit common owner/exclusion selection is required before implementation.
* Exact bounded phase payload/event fields, canonical stage retention/replay, and actual original entry factory must be implemented together. They are source gaps, not an existing delivered readiness protocol.

Readiness question: approve this same-unit authenticated root pre/post phase with exact named-context ACLs, root publication, and phase-discriminated original transport/qjl retention, plus root-owned LoadCredential inputs for literal installation/attempt/predecessor refs, while preserving disjoint principals and complete attempt retirement?
