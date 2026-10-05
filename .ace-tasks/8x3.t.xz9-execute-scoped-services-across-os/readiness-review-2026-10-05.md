# Independent readiness review — 2026-10-05

Reviewer: independent GPT-6.1 Sol `wave4_boundary_rereview`. Exact reviewed specification head: `0626be04580e35fc976562382be8fb535a3ad188`. Children reviewed before parents.

| Scope | Verdict | Outcome |
|---|---|---|
| xz9.0 | APPROVE | Protected transfer, authenticated lifecycle, launch gating, evidence provenance and handler transition specified. |
| xz9.1 | APPROVE | Replay, late completion, challenge-bound no-effect proof and crash/corruption behavior specified. |
| xz9 | APPROVE after child promotion | Both children promoted and validated before parent promotion. |
| xza.3 | APPROVE | Shared/exclusive admission, generation checks, restart reconstruction and rollback ownership specified; still depends on xz9.0. |
| xza.0 | REJECT | Choose actual bound-runtime endpoint access and verify busy/duplicate/equal-text/lost-reply correlation. Controlled Codex fixture is capability evidence, not current Herdr integration. |
| xza.1 | REJECT | Specify provider-owned exact Pi enqueue/dequeue identity; TUI sendUserMessage lacks metadata. Verify target GPT-6.1 Sol configuration. |
| xza.2 | REJECT | Choose and prove exact atomic cancellation or positive old-runtime retirement separately for both providers. |
| xza | DEFERRED | Three children remain draft/needs_review. |

Only approved scopes are promoted. All implementation and installed acceptance criteria remain unchecked. Linux/macOS multi-user execution, Lab native/signing integration, domain handler installation and R2/R3 are not delivered by this review. Implementers consume recovery semantics accepted in `dab0dbeea`, integrated on main.

Root integration followups: qkb.1 requires xz9 protected mode and parent qkb reflects it; qkc requires xz9/xza and installed lab-config:gad.8/gad.b evidence, without introducing reverse source/install or R2/R3 cycles. See `consumer-dependency-map.md` in xz9.

## Implementation-discovered readiness gap

The initial verdict above is historical. During xz9.0 implementation, the author found that an unprivileged launcher under a different UID cannot use current adapters to start the gated worker under the required worker UID. Existing lab-config per-user Herdr units correctly run as that worker, but `lab.py` currently restricts cross-user control to legacy root/runuser or the exact account. No reviewed trusted-launcher transport is delivered.

xz9.0 remains in-progress for independent canonical journal/import work, with needs_review:true; parent also needs review. Its protected endcap cannot be accepted until an explicit native launch/control prerequisite is specified, reviewed and delivered. The author is drafting that real task, including ACE endpoint selection/authentication/gated-process binding and lab-config installation. Narrow kernel-enforced socket ACLs or existing authenticated runtime forwarding require actual capability evidence; neither is presumed installed. No new arbitrary UID-switch/root broker or same-UID impersonation is authorized by this note. Existing implementation acceptance remains open.
