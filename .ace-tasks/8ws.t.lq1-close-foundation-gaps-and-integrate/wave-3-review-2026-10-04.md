# Delivered wave review and next dispatch — 2026-10-04

## Evidence and verdict

Direction confirmed: runtime adapters remain in their wrapper packages; ace-assign owns execution evidence; scoped HITL uses verified attempt authority; provider-neutral consumers retain ace-git as their public boundary. These conclusions come from code-path review, retained delivery evidence and fresh tests, not status labels alone.

Reviewed and freshly tested source: `686abe35963349c4fe5e439e34bb0bb88c4c3412`. The source revision was unchanged before and after `bin/ace-test-suite`: **50 packages passed, 11,074 tests passed, zero failures, 24 skipped, 33,274 assertions**, exit 0 (119.03 seconds). This is the default deterministic/hermetic suite. It is not proof of installed native runtimes, actual multi-UID authorization, Telegram, publisher operation, or the final Lab scenario. No product code changed during this review.

| Scope | Reconciled state | Remaining acceptance boundary |
|---|---|---|
| `8x1.t.hym` | Delivered / done; pointer-only provenance and CLI materialization-error translation are present. | Include its scenario in native Herdr consumer acceptance. |
| `8wq.t.34i` | Delivered / done; scoped service and verified-attempt authority are present. | New lifecycle/expiry repairs below; no located executed durable multi-UID receipt, so do not claim installed acceptance. |
| `8x2.t.z78` | Delivered / done; retained disposable Forgejo 8.0.3 evidence reports 16/16 goals. | New create-provenance/uncertainty repair; deterministic response-loss tests are distinct from live transport-loss proof. |
| `8ws.t.ibk` | Closed and archived in this review after reconciling retained exact-source tests and independent review. | The archive preserves the original verification receipt; this was bookkeeping closure, not a fresh implementation. |
| `8wq.t.k86.3` | Source merged in PR #364 (`4f32bed12`); remains in-progress. | Acyclic standalone adapter installation, retained writable prepared targets, and actual Herdr callback/work-on/prune acceptance remain open. Parent k86 and dependent 1w5 are not unblocked. |

## Verified findings and owners

These are static code-path findings. This review did not execute new failing reproductions. Each repair specification requires a failing public-path regression before its fix.

- **`8x3.t.vft` — listener ownership:** `ace-hitl/lib/ace/hitl/lifecycle/service.rb:94` always reaches shutdown after refused startup; cleanup at line 150 unlinks the socket unconditionally. A rejected second service can remove the first listener's endpoint. Existing private-prepare coverage does not exercise public-run cleanup.
- **`8x3.t.vfv` — authorized OTP expiry:** `ace-hitl/lib/ace/hitl/lifecycle/otp_vault.rb:93` starts a fifteen-minute retention period at delivery; `store.rb:209` consume does not enforce the challenge deadline at locked handoff. A short authorized challenge can therefore outlive its deadline. The repair must preserve secret-free errors and current requester/attempt checks.
- **`8x3.t.vfw` — Forgejo create provenance and uncertainty:** `ace-git-forgejo/lib/ace/git/forgejo/provider.rb:709` reduces the supplied source repository to owner:branch without proving selector identity. Post-create verification at line 513 checks SHA/draft without full source/base binding. Readback failure after accepted creation also needs unknown-outcome classification, without mutation replay. Keep reconciliation in the existing assignment journal.
- **Existing `k86.3` — runtime closure:** consumers currently install tmux but not a complete standalone Herdr surface. Simply adding a dependency creates `ace-assign → ace-herdr → ace-hitl → ace-assign`. Resolve the integration/protocol boundary without duplicating protocol authority or removing HITL's verified-attempt authority. The module layout requires JIT planning and independent architecture review. Separately, `runtime_control_surface_runner.rb:127` sends `exec` into the prepared shell, while tmux keep-alive only enables remain-on-exit. A dead pane does not prove a writable retained shell. No native tmux reproduction was run here; the first disposable native test must establish it. These are closure items under the existing owner, not duplicate tasks.

## Next parallel series

Recommended initial dispatch is seven scopes. Readiness means the behavioral specification is reviewed; acceptance still observes the gates below.

| Lane / owner | Start now | Integration or acceptance gate |
|---|---|---|
| ACE / HITL lifecycle | `8x3.t.vft` | Separate worktree; serialize merges with vfv, then rerun combined HITL tests. |
| ACE / OTP boundary | `8x3.t.vfv` | Separate worktree; serialize merges with vft. Publisher authorization stays with the publisher. |
| ACE / Forgejo provider | `8x3.t.vfw` | Must land before qkb.0 acceptance; preserve public ace-git contracts. |
| ACE / runtime consumers | Close `8wq.t.k86.3` | Acyclic installed graph plus actual native runtime acceptance before parent k86 and 1w5. |
| lab-config / topology and trust | `gad.8` preparation | Source/bootstrap work may start; service listener acceptance requires vft. |
| lab-config / live Pi wake | `gad.9` | qjy source is delivered; prove installed live-agent wake and retain distinct death/recovery policy. |
| lab-config / domain services | First setup-project slice of `gad.b` | Identity/grants integration follows gad.8; publisher/OTP slice waits vfv and its own authorization contract. |

One primary writer per Lab checkout; use isolated worktrees for parallel implementation. Shared installer changes and deployments are integrated serially. Independent coding does not imply independent deployment.

Optional additional consumer preparation: y24 can develop against the reviewed contract, but acceptance waits vft and vfv. qkb.0 can develop against the provider contract, but acceptance waits vfw. qkb.0 and qkb.1 retain atomic installed delivery: no published mixture of old/new workflow vocabulary. Do not dispatch 1w5 as unblocked before k86 closure. Reconcile l2d.3/.4/.5 against retained evidence rather than reimplementing generic ACE behavior. Existing ibl/lq8 and hygiene tasks 3zi/4gy remain separately owned; this audit does not invent completion evidence for them.

After these gates: recovery plus HITL → qk0 → completed qkb → R2 (`ig3`) → R3 (`ig4`) → qkc and lab-config:gad.2. R1 (`ig2`) remains delivered. Pilot ig5 remains optional. vs3 additionally requires the installed publisher and concrete release authorization. Final legacy-disabled acceptance precedes gad.3 removal and gad.4 cold-start proof.

## Independent readiness review

The boundary auditor authored vft/vfv/vfw after code inspection. A separate runtime reviewer checked those specifications and UX against the actual service/vault/provider interfaces, then reviewed the root metadata/checklist changes and both domain repositories. Verdict: **APPROVE, no open P1/P2 readiness findings**. Root also checked the cited code paths. This verdict covers specification readiness and progress reconciliation, not repaired implementation correctness or installed Lab acceptance.

The review preserved delivered task history and retained original k86.3 acceptance. New producer-repair dependencies gate y24 and qkb without adding an R3 cycle. Repository validation and commit identities are reported with delivery of this review; historical doctor warnings are not newly introduced acceptance failures.

## Implementation dispatch — 2026-10-04

Captain authorized implementation in independent worktrees using `gpt-6.1-sol`. Three active worker slots are available, so seven scopes are dispatched as three automatic sequential queues; this is not a claim that seven executors run simultaneously.

| Worker | Active first scope | Automatically queued next scopes |
|---|---|---|
| wave3_runtime_lane | ACE vft | ACE k86.3 closure |
| wave3_otp_services_lane | ACE vfv | lab-config gad.b setup-project slice |
| wave3_forge_topology_lane | ACE vfw | lab-config gad.8, then gad.9 |

Each scope has a separate branch `codex/wave3-<name>` and worktree `<repository>/.ace-wt/wave3-<name>`: ACE names `vft`, `vfv`, `vfw`, `k86-3-close`; lab-config names `gad-8`, `gad-9`, `gad-b-setup`. ACE base is b06d0aee9; lab-config base is 76d8e4b. Workers mark their own task in-progress when beginning it, commit and test only in their own worktrees, and report exact heads for independent review. Main integration, release and live deployment are separate gates. Queued work is not marked implemented or accepted.

Dispatch setup note: lab-config worktree creation initially refused because `.ace-wt` did not exist; created that directory and retried successfully. No task or product behavior was changed to work around the failure.
