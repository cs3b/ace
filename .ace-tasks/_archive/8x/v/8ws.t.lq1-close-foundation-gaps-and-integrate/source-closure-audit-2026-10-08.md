# Read-only source closure audit

Reviewed current main `7ed68fff3`; no metadata changes or tests. Installed gad.2 and known physical cleanup, qkb adoption, R2/R3 are excluded.

| Criterion | Maintained source evidence / remaining behavior |
| --- | --- |
| xz9.0 SC11–14 | `AttemptCoordinator#finish`, `#bind_inbox`, recovery exist locally. `LaunchLifecycle::OPERATIONS` and `Endcap::OPERATIONS` omit protected public finish/recovery/bind routes; attempt CLI constructs the local coordinator. Compose these existing owners through protected admission, terminal review and no-writers proof. |
| xza.0/.1 SC1–5 | `NativeQueueExecutor` supplies submission ACKs, not retained authenticated consumption/turn correlation. Actual Codex/Pi observer→signer→canonical Inbox import producer remains absent. |
| xza.2 SC1–3 | Actual positive eviction/expiry non-consumption and replacement-target producer remains absent. Never equate missing observation with non-consumption. |
| xza.3 SC1–4 | Context owner/client/store/rotation APIs and Assign canonical completion are integrated. Direct `cli/commands/inbox.rb`→`Inbox.from_config` does not enter context admission; actual domain signer and paired-key install/readback/rollback consumers remain required. |
| xz9.2 / 9c2 | Prompt/status/drain/stop/original Driver lifetime and generic history/retirement/network/accessors delivered. Lab `Installer` calls `Startup#configure!`, which consumes held interpreter FD4 and selected entry bodies through clean runuser environment. Older unchecked startup notes need reconciliation, not duplicate generic implementation. Final combined criterion review remains unclosed; installed proof is separate. |
| qk0.3 / qk0.1.1 | Prepared registration/fetch/queue/original worker and public all-eight-leaf source composition delivered (`source-checkpoint-public-worker-consumption`, receipt `2a145464`). Remaining family closure includes known delivery/role adoption; old absent-fetch/gate prose is stale. |
| xz9.1 | Generic settlement/recovery source delivered. Each configured operation still needs actual operation-specific inspection and caller recovery composition; missing inspectors cannot become no-effect proof. |

Concrete newly observed cleanup preview gap: `with_execution_slots` takes blocking slot flock, authority mutex and retained Inbox inventory/event flocks. Its existing call cannot uphold a five-second admission deadline under contention. This is next authorized source correction.

## Subsequent verified checkpoint — main `03731ddc5`

The table above retains the original audit, not a claim that all gaps remain byte-for-byte unchanged.

- Bounded maintenance lock admission has landed (`632118d62`, `eb276218c`, `9e198ce34`); the final paragraph above is historical. Full physical cleanup remains open.
- Protected merge-result consumption, exact canonical imports, lost-reply/replay and negative controls are integrated through `50862d43e`, with post-integration tests recorded in qkb.1's `source-checkpoint-protected-merge-consumer.md`.
- Original cleanup preview now passes the actual immutable receiver peer to the same Installer (`6a3fea301`); this is internal transport proof, not proof of the Lab held reauthentication or physical effects.
- Protected finish/recovery/bind handlers exist only in unintegrated `938fe2344`. Independent review requested changes: historical succeeded finish must revalidate the actual independent accepted-review proof at the accepted prefix. Its controlled five-case result does not cover this missing proof.
- Public `ace-assign attempt` CLI still constructs local `AttemptCoordinator` in `cli/commands/attempt/base.rb`; finish/reconcile consume local receipt paths. No maintained role driver for the new protected operations was identified in the source audit. Handler delivery alone cannot close public adoption.
- Public `ace-lab service request/status` still selects the local service owner. Its protected merge request/status amendment has independent specification approval (`f74c36a5d`, recorded on main `03731ddc5`); implementation remains open and must preserve truthful claim-versus-completion results.
- R2 specification readiness is approved, but `campaign_execution`, the guarded `with_verified_result!` owner, and separate `report_models` are not implemented in the reviewed source. R1's presence does not satisfy R2/R3.

No whole-task status, installed acceptance, final-suite result or publication readiness follows from these checkpoints. Public adoption and physical source behavior remain implementation work before the central `gad.2` run.
