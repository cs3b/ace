# Codex endpoint producer readiness review

Reviewed candidate `405ae9d2cf445e5ef759f10bcba835e14e50bf9d` in the isolated xza worktree against main `1dd4a45ae` and current Lab source. Verdict: retain draft; producer join requires correction before implementation. No native probes, source tests or task promotion were performed.

The proposed maintained Ruby transport and persist-before-send correlation address the real CLI submission gap. Preserve original client ID on uncertainty, never resend after a potentially issued add, and never manufacture consumed evidence from queue absence. These are coherent with the intended single inbox ledger.

## Required source contract repairs

- Define the actual Lab startup owner that creates the app-server and ensures the managed UI/thread uses the same instance. Current `lab*.rb` sources contain no Codex app-server/native-client producer. Naming gad.8 alone is not an executable producer contract.
- Define ordering between runtime birth/thread discovery, immutable `codex_runtime` publication, accepted context configuration and service startup. State which existing authority accepts the new reference; avoid a reference/hash cycle or silently changing accepted configuration.
- Define replacement association ownership and old-server retirement. A new pointer or same UID cannot substitute for the retained process birth or authorize repeating an uncertain submission.
- Precisely separate existing socket helpers: `ProtectedSocket.connect` supplies bounded transport, not peer authentication. `root_path!` rejects group-writable endpoints; validate protected ancestry separately from the proposed exact 0660 socket, including gid/mode/ACL checks and held Linux peer identity.

`InboxContextService.run!` also calls `with_initial_inbox_context` / `with_inbox_context_service`, whose Lab implementations remain missing. Its current configuration validates executable references only and constructs the old CLI `NativeQueueExecutor`. The final slice must connect these actual producers and consumers, not merely introduce a new selection schema.

These are engineering gaps assigned back to the author for source research and repair; no new Captain decision is requested. Whole-child readiness remains unproven. Controlled transport tests will be source evidence only; installed runtime acceptance stays in lab-config:gad.2.
