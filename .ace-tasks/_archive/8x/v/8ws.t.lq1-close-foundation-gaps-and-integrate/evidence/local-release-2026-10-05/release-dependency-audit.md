# Final candidate release audit

Read-only audit: main `3eb814971a37554f3bed495a83f0de52d7ce0b39`, approved scope `580248fdafaa257801ecbef87e0ef30cef9d2ebf` (implementation e36718703), approved qkb vocabulary `f29c72e3a45a7f3715ac93a8ab9fc7a806b2ed6b`. Candidates must be merged into one final release tree before versions/artifacts/receipts are frozen. No bumps, builds, publication, credentials or native/Lab probes occurred.

## Recommended coherent set

Versions are proposed pre-1.0 semver choices: minor for new public capabilities or deliberately changed workflow/schema contracts; patch for fixes/followers/docs. This is a release recommendation, not a completed release.

| Package | Current → recommended | Grounded reason |
|---|---|---|
| ace-runtime | 0.1.1 → **0.2.0** | Protected Linux/socket, scope/unit/cgroup, ProcessIdentity ownership, network installation verifier and protected artifact APIs. |
| ace-hitl-contract | 0.1.0 → **0.2.0** | New managed envelope codec, SecretGate, incarnation-bound inbox identity and proposal contract. |
| ace-herdr | 0.3.2 → **0.4.0** | Protected native control/inbox construction, signed retained reconciliation and complete inventory, managed envelope delivery. |
| ace-tmux | 0.18.0 → **0.19.0** | Published payload lacks the ownership-aware native backend/adapter behavior. |
| ace-assign | 0.63.1 → **0.64.0** | Canonical service/result/inbox consumers, protected launch and bounded scope lifecycle, neutral delivery. |
| ace-hitl | 0.11.1 → **0.12.0** | Proposal and managed envelope/native reverse-owner public behavior; follows Assign/Herdr/Contract. |
| ace-hitl-hermes | 0.1.0 → **0.2.0** | Managed envelope transport/proposal and ingress changes in actual published-payload delta. |
| ace-lab | 0.3.1 → **0.4.0** | Protected service receiver/composition/policy public entrypoints; full startup remains closed. |
| ace-git | 0.28.1 → **0.29.0** | Neutral PR lifecycle/source vocabulary and deliberate removal of old GitHub instruction names. |
| ace-handbook | 0.33.0 → **0.34.0** | qkb perform-delivery mode/gates workflow rewrite and normal projections; published provider_syncer already matches, so do not attribute that as new. |
| ace-git-worktree | 0.25.1 → **0.26.0** | Neutral cleanup workflow vocabulary and required Herdr constraint follower. |
| ace-review | 0.58.1 → **0.59.0** | Neutral independent-review workflow vocabulary (qkb named consumer). |
| ace-overseer | 0.19.1 → **0.20.0** | Recovery/proposal/status source behavior and required Assign/Herdr/GitWorktree follower. |
| ace-test-runner | 0.27.1 → **0.28.0** | New invocation-bound mandatory completion/evidence interfaces plus explicit-config fix. |
| ace-test-runner-e2e | 0.42.0 → **0.43.0** | New exact release installation manifest validation API. |
| ace-demo | 0.26.1 → **0.26.2** | Dependency-only follower: current ~>0.3.2 excludes Herdr0.4. |

Optional docs-only `ace-handbook-integration-pi 0.5.0 → 0.5.1`: public gem source comparison shows only docs/usage.md differs among inventory runtime/extension paths; all wake code is already shipped. Include only if shipping that documentation correction, with a meaningful changelog. It is not required for scope/qkb coherence.

Do not release ace-llm merely from version-file baseline: its inventoried execution_evidence.rb is byte-identical to public0.42.0. Do not infer releases for Docs, support-core/markdown/models, CLI LLM provider or Claude/Codex/Gemini/OpenCode integrations from test-only/inventory baseline differences. ace-task is unchanged by f29 and does not consume a newly introduced Ruby API here; current neutral source is not a reason by itself to bump it.

## Required dependency changes

| Consumer | Required lower bound / direct declaration | Source evidence |
|---|---|---|
| Assign | Runtime `~>0.2`; Herdr `~>0.4`; retain direct json `>=2.20,<3` from scope candidate | ProtectedLinux/Socket, SystemdScopeManager, CgroupObservation, LinuxMountInfo, network selection; Endcap ProtectedInbox.build/verify_reconciliation/retained_events; strict failure JSON flags. |
| Herdr | Runtime `~>0.2`; HitlContract `~>0.2` | protected_native_control.rb, protected_inbox.rb, runtime_adapter.rb#owner; inbox.rb ManagedEnvelope/SecretGate unavailable in published Contract0.1. |
| Tmux | Runtime `~>0.2` | native_runtime_backend.rb/runtime_adapter.rb ProcessIdentity ownership API. |
| Lab | Assign `~>0.64`; **add direct Runtime `~>0.2`** | authority_composition.rb and protected_service_receiver.rb directly use protected runtime types; transitive Assign dependency is insufficient packaging declaration. |
| HITL | Assign `~>0.64`; Herdr `~>0.4`; HitlContract `~>0.2` | live_client.rb and providers/lab/assignment_binding.rb coordinator/reverse/proposal behavior; Inbox.from_config and managed signed reconciliation; managed envelope and SecretGate. Also old Assign/Herdr constraints exclude coordinated minors. |
| Hermes | HITL `~>0.12`; **add direct HitlContract `~>0.2`** | runtime.rb:103 and transport/relay.rb:226 directly use ManagedEnvelope; relying on HITL's transitive Contract leaves this undeclared. |
| GitWorktree | Herdr `~>0.4` | Current ~>0.3.2 excludes producer minor; workflow consumer belongs to qkb set. No new Runtime method use found here, so no forced Runtime floor solely from producer bump. |
| Overseer | Assign `~>0.64`; Herdr `~>0.4`; GitWorktree `~>0.26` | recovery/proposal canonical coordinator consumer; old constraints exclude coordinated Assign/Herdr/GitWorktree minors. Existing ordinary Runtime calls do not justify new Runtime floor. |
| Demo | Herdr `~>0.4` | Dependency-only follower; no new Runtime API consumer found, so existing Runtime floor may remain. |

For qkb workflow consumers which directly declare ace-git (Review, GitWorktree, Overseer), raise their minimum to `~>0.29` when preparing the coordinated vocabulary set: their shipped instructions now require the same neutral PR source/API installation rather than allowing old0.24/0.26 packages. This is the installed vocabulary floor, separate from Ruby method ABI. Handbook should not acquire invented Ruby dependencies merely to enforce handbook composition; the exact installation release manifest carries its matching workflow package set. Assign DOES directly consume ace-git and must declare that dependency, as corrected below.

`~>0.1` permits old0.1.x and later0.x until1.0; it does not prove new producer API availability. Conversely `~>0.3.2`, `~>0.63.1` and `~>0.25.1` exclude the proposed next minors and force the identified follower changes. Preserve the dependency graph as acyclic and regenerate Gemfile.lock after finalized version/gemspec edits.

## Source and publication gates

No additional verified source safety blocker was found for publishing these reviewed fail-closed partial capabilities. Required packaging corrections above are blockers to a coherent resolvable release as currently versioned. Scope's unavailable positive native admission and Lab's closed full startup guard are intentional refusals, not fabricated completion; publishing them does not accept full9c2/xz9 or installed policy enforcement. User sequencing remains local convergence → publication → installed/Lab acceptance, with no invented Lab-before-release gate.

qkb0/1 installed atomicity is a coherent installation set across Assign, Git, Handbook, GitWorktree, Review and named existing consumers, plus normal source-owned projection removal. RubyGems cannot atomically publish multiple gems; dependency waves alone do not certify the qkb gate. Freeze/select the complete set, then use its exact versions/manifest for installation. Do not install an intermediate mixed vocabulary closure or claim fresh installed registrations have already passed.

Publisher preflight remains applicable: `.ace-bin/ace-rubygems-publish --dry-run <explicit packages>` plans; `--prepare <explicit packages>` builds all pending artifacts before OTP; live publish consumes prepared queue. Its cached artifact check binds name/version, not source digest: remove/rebuild stale same-version artifacts and invalidate prior prepared queue when final source changes. No stale artifact was proven in this audit. Final candidate versions must be new unpublished versions and all artifacts must come from the final reviewed release tree, including follower edits. Fresh release-source tests/review remain required; previous candidate receipts are historical.

## Published payload evidence and limits

Downloaded public RubyGems .gem payloads read-only to `.ace-local/release/published-payload-comparison/`; no install or execution. `comparison.json` records per-package inventoried source/docs/config byte comparison against its current public version. This resolves LLM/provider_syncer/wake overcount but is not a complete all-files release manifest: removed/new qkb sources and scope candidate additions were reviewed separately. Inventory source_revision a33 predates main3eb and the two candidates; do not treat inventory as an exhaustive final selection. Empty Handbook/Pi Unreleased sections need meaningful entries if selected, while scope author owns its pending bounded changelog. No version edits/builds/publication were performed.

## Corrective direct-dependency scan

The first audit omitted **Assign → Git `~>0.29`**. This is required, not invented: `ace-assign/lib/ace/assign/organisms/delivery_coordinator.rb:3` requires pull_request_lifecycle, builds `Ace::Git::ResolvedServer` and consumes resolved_identity/review_metadata_snapshot/create/update/ready/reconcile_create/review_snapshot; `atoms/delivery_parameters.rb:2` requires server_url. The new delivery behavior and coherent qkb producer source require the coordinated Git minimum. Add its direct runtime dependency to Assign.

Assign → Review should rise to `~>0.59` for the coherent qkb consumer release: Assign's catalogs/workflows require the corrected neutral independent-review source from Review0.59. The campaign Ruby call itself (`molecules/receipt_verifier.rb:242–259`, CampaignManager#status with accepted/current_head/result_identity/round approval joins) does not alone prove0.59 is first implementation: public0.57.0 and0.58.1 both contain campaign_manager.rb. Do not claim that producer bump alone justifies the floor. The exact qkb source vocabulary is the supported reason.

Scanned literal internal runtime `require "ace/..."` edges across the selected16 packages, mapping each required file to its actual owning package rather than guessing namespace. In addition to newly consumed Git and already documented Lab Runtime/Hermes Contract, found historical undeclared direct edges in selected packages:

| Consumer | Missing declaration | Exact source | Recommendation |
|---|---|---|---|
| Assign | ace-support-fs | lib/ace/assign.rb:5; molecules/evidence_calculator.rb:5 | Declare existing `~>0.3`; no new FS API/minor or FS release inferred. |
| Assign | ace-llm-providers-cli | molecules/fork_session_launcher.rb:244–245, lazy SessionFinder.call(provider:,working_dir:,prompt:) | Declare existing `~>0.36.1` to pin the inspected shipped SessionFinder API; no provider release inferred. |
| Review | ace-support-fs | molecules/prompt_resolver.rb:4; organisms/review_manager.rb; cli/commands/feedback/session_discovery.rb | Declare existing `~>0.3`; no new producer API inferred. |
| TestRunner | ace-support-fs | molecules/package_resolver.rb:4 | Declare existing `~>0.3`; no new producer API inferred. |

These are packaging corrections in already selected consumers, not feature expansion or additional producer releases. Literal-require scan did not show other undeclared internal edges across selected packages; separately documented constant-only Lab Runtime and Hermes Contract references remain required. Transitive resolution currently supplies these packages, which can conceal missing declarations. This scan is not a complete dynamic Ruby dependency proof. No source/version edits occurred.
