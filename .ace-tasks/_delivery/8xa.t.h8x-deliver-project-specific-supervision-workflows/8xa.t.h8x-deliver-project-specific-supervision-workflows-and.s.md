---
id: 8xa.t.h8x
status: in-progress
priority: high
created_at: "2026-10-11 11:29:56"
estimate: 
dependencies: []
tags: [delivery, overseer, assign, bootstrap]
title: Deliver project-specific supervision workflows and validate them on ACE
---

# Deliver project-specific supervision workflows and validate them on ACE

Source task: 8xa.t.h8x.

## Role, authority and environment
You are the genuine ACE project overseer, coordinating work from your discovered ACE Herdr workspace. The Captain outranks this brief: accept new direction, preserve attributable existing work, and report scope conflicts to the host lab-config coordinator. Delegate implementation, tests and independent review; stay available for conversation. Do not block your turn polling or sleeping. Discover the current overseer-ace callback identity rather than retaining a stale pane ID.
Environment interface: /lab/install-src/bacad6231153c770bc23f2cfe31f3ee277d5051e/docs/lab-interface.md. Host lab-config owns every root operation, deployment and installation.

## Goal and accepted architecture
Deliver and publish reusable project delivery supervision in ACE, then have the host install the published package set, adapt ACE itself and demonstrate the next real task. Preserve ordinary worker behavior: implementation children and their implementation parent finish at reviewed PR-ready. Normal automatic parent closure remains. Do not introduce completion=explicit or extend work-on-task to merge/publication/deployment.

Maintain two task lists: implementation tasks at the root; delivery tasks under _delivery tagged delivery. Delivery tasks reference producer tasks; do not reparent or duplicate producer implementation work. Implement the required list/configuration support in its owning ACE package if not present. Task IDs are tool-minted. Before creating implementation tasks, reconcile and adopt existing owners and in-flight work.

Ship four reusable Assign presets: supervise-delivery, integrate-batch, deliver-release and close-delivery. Ship as-overseer-configure-project as a thin skill invoking wfi://overseer/configure-project. The adaptation workflow resolves and reviews project presets, workflows and decision guides, preserves existing customization, is repeatable without duplicates/destructive overwrite, and reports concrete changes or blockers. Generic behavior belongs to ACE packages; project-specific policy/configuration belongs to the project.

## Supervisory behavior
Use existing Assign trees, attempts, status, callbacks and canonical evidence. No second queue engine, parallel execution journal, daemon or fabricated runtime context. One running supervisory step coordinates workers, integration groups and release decisions dynamically. Worker completion order does not prescribe merge order. The project guide determines dependencies, readiness, integration groups, release cuts and demo/production delivery policy.

At every integration decision retain, in existing task/Assign evidence, the eligible ordered set, selected and deferred candidates with reasons, actor, timestamp, evidence references and policy/plan revision. Rebase or changed candidate requires fresh relevant tests and independent review. Movement of the target branch requires re-evaluation of integration readiness. Accumulating more merges versus cutting a release is an explicit project decision. Bind each release to its exact accepted source set, package versions and artifact digests; do not silently add later merges.

WAIT requires an existing durable operation reference and the exact reconciliation path. Unavailable provisioning/capability is BLOCKED with its owner, not fictitious waiting. Unknown effects remain uncertain; never blindly repeat launch, merge, publication or deployment. Keep failed callbacks visible and resume from canonical state. A transiently empty queue is not accepted completion.

## Existing owners and work to adopt
- ACE 8wr.t.qkb.1: workflow/preset adoption and delivery vocabulary.
- ACE 8wr.t.qk0.1.1: responsive project overseer charter and coordination.
- ACE 8x3.t.xz9 and its existing children: scoped protected service composition.
- ACE 8wm.t.vs3: scoped publication/HITL behavior.
- ACE 8wr.t.qjl: consume existing durable evidence, do not replace it.
- lab-config gad.8/gad.b: installed identities, authorization, transport and executors.
- lab-config gad.2: installed end-to-end acceptance.
Preserve existing qkb.1/qk0 edits, attempts and review ownership. The current lifecycle design has unadopted R2 CHANGES REQUESTED and a callback stalled at a Codex approval boundary; discover the existing review execution, own its correction/review/cleanup, and do not duplicate or treat it as accepted. Do not overwrite foreign work or create duplicate implementation tasks. Read the existing R2 review at /lab/projects/ace/.ace-local/evidence/8wr.t.qk0/lifecycle-spec-review-r2.md. It is CHANGES REQUESTED, not approval of this plan. Correct M7's inaccurate claim about --no-push threading: inspect and distinguish actual --no-push from --no-upstream behavior. Address F2 with the complete decision record specified above. Obtain fresh independent review of the resulting specifications and implementation.

## Authorization and delivery boundaries
The Captain authorizes implementing and publishing the scoped changed gems plus required dependencies for this bootstrap. Retain the exact release manifest and this authority; do not request redundant broad authorization. This does not provide missing credentials, executor identity, scoped service admission or OTP, and it does not authorize unrelated releases. The overseer selects and delegates; it does not inherit root/admin/publisher tokens. Existing ordinary and protected routes are distinct; no fallback across a refused protected boundary. A missing integrator, publisher or HITL route is reported to its existing owner. Host-provided execution receipts must be explicit; do not claim autonomous delivery when the host performed an effect.

## Acceptance and closure
1. Executed package tests and fresh independent review demonstrate both lists, all four presets, the adaptation skill/workflow and decision guides; worker PR-ready/parent closure remains correct without a new explicit-completion feature.
2. Exercise dependency-based integration ordering, late target/candidate movement, selection/defer records, stable release cuts, callback/restart continuation, capability BLOCKED, durable WAIT and uncertain-effect non-retry using existing testing facilities. No synthetic live Lab is required.
3. Authorized integration and actual publication produce exact PR/head/reviewer, operation and package/version/artifact receipts. Local version preparation or PR-ready is not publication.
4. Host installs the exact published set and returns installed-version/configuration evidence. Overseer applies the reviewed adaptation workflow to ACE, verifies resolution and idempotence, and reports remaining gates.
5. The next real task flows through the adapted project worker and delivery plans with real review, authorized integration and only project-required release/deployment stages. Store the outcome in the existing gad.2 checklist through its host owner, with precise evidence links.
6. close-delivery preserves accepted evidence and work before cleanup, verifies no surviving writers and closes only the accepted delivery scope. Root installation/deployment stays host-owned. All intended outcomes must be accepted before this supervisory task is closed.

## Observed source defect to adopt
The public task create command with --in delivery created task 8xa.t.h8x and then failed at create.rb:122 because manager.move is undefined. The host recorded this partial-effect defect and successfully recovered the existing task through public update --move-to delivery; do not retry create. Adopt repair under an existing applicable owner first; create a tool-minted bug deliverable only if no existing owner covers it. Require a regression proving create with list placement succeeds once and does not leave an unreported partial creation or duplicate on recovery. Preserve the minted task identity.

## Required adaptation and delivery semantics
Adapt ACE for real. Exercise a Cloudflare project only as a configuration fixture/test; no actual Cloudflare deployment is authorized by this bootstrap. Multiple implementations may contribute to one release; the same implementation may be referenced by separate preview and production delivery tasks. Do not automatically create one delivery task per PR. Archive preserves the delivery tag and producer references, so delivery remains discoverable after normal task closure.

The adaptation skill configures the project; it neither grants permissions nor publishes. Validate canonical assign-capable skill registration and actual ace-nav/ace-bundle resolution, including the skill-to-workflow entrypoint and selected presets/guides. Repeating adaptation preserves customization and produces no duplicate tasks/configuration. Retain the existing sixteen-hour policy unchanged: the window begins only after confirmed HITL delivery and execution requires the existing healthy resolver and exact scope; elapsed time alone grants nothing. Add no new engine or timer service.

## Installed acceptance groups — mandatory before bootstrap closure
All four groups below are installed acceptance gates, not source-test claims. lab-config gad.2 is the single evidence checklist owner; send attributable results there rather than creating a parallel acceptance ledger. The host performs every root effect. Discover and preserve current assignment/attempt/process identities before any controlled interruption.

1. Published runtime and real flow: verify actual installed gem versions and paths outside source binstub/path overrides. Source bin/ace-* is correct for development but does not prove released-gem behavior. Read back the actual created supervisory assignment and confirm task_id=8xa.t.h8x and project_id=ace; do not assume an older installed CLI honors the YAML fields. Verify real ACE adaptation, repeat idempotently, and complete the next real task through the adapted worker and selected delivery plans with exact review/integration/outcome evidence. On actual Lab candidates, exercise workers finishing out of dependency order: the overseer records the eligible ordered set and selected/deferred candidates with reasons, waits for actual prerequisite integration evidence, delegates rebase of an invalidated candidate with fresh tests and independent review, and selects an integration batch and release cut. Prove that the implementation parent may complete while its delivery remains open. Use genuine candidates and an authorized release when needed; do not create an artificial release for this test.
2. Failure recovery F1/F2/F3: interrupt a real worker and verify interrupted status plus preserved work; restart the overseer and verify adoption of the same existing attempt without duplicate launch; interrupt a merge or publication response and verify durable uncertainty with reconciliation of the original operation, never blind retry. Choose an actually authorized operation; no dummy release merely for testing. Missing prerequisites leave the corresponding gate open.
3. Communication and authority: exercise a real correlated HITL request and exact Telegram Reply, showing that the answer resolves the intended request/operation; verify a callback wakes the idle actual overseer and resumes canonical state; execute an operation without the required permission and verify refusal without effect. Existing confirmed-delivery/resolver/scope rules remain enforced. A host-only Telegram exchange does not substitute for the required project communication path.
4. Concurrent isolation and accepted cleanup: run two real task executions with distinct attributable worktrees, attempts and results, proving commands/callbacks/evidence remain with the correct task. Preserve work and durable results before cleanup, verify no surviving writers, and reconcile the single gad.2 checklist. Close only after every required installed gate has an accepted receipt; source tests, worker completion or one happy-path task cannot substitute.
