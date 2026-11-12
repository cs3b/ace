---
name: overseer-queue
description: Run the private overseer queue in .ace-tasks/_overseer with ace-task list --in _overseer - record work as managing tasks with lifecycle subtasks, gate starts on integrated results, keep one active executor per worktree, and process ace-hitl reports
allowed-tools: Bash, Read
doc-type: workflow
title: Overseer Queue Workflow
purpose: Binding process contract for the L6 private overseer queue on the file-based lab model (ADR-034, docs/lab-flow.md) without a second queue engine, journal, lease registry, or role guards in delegation tools.
ace-docs:
  last-updated: '2026-10-18'
  last-checked: '2026-10-18'
---
# Private coordination tasks

Use `.ace-tasks/_overseer/` through ace-task, never another queue or journal.
Keep it Git-ignored. An executable commission is a separate ordinary task. Create
the private manager and commission text, then use `work-on --manager` to bind them.
The product writes role children and references. Do not copy allocation fields.
Use explicit role sequences and dependencies; a predecessor unlocks work only after
its required integration is accepted. Reuse existing tasks on restart.

`ace_eyes` action `process-reports` owns the receipt/cleanup/continuation/ack order.
For terminal inspection `ace-overseer process-reports --json` returns the same receipts
without acknowledging the observer. Questions, mismatches and failed continuation
remain pending. No report receipt substitutes for tests, independent review or merge.
Managers remain private after completion. Bootstrap's confirm-start condition requires
first-turn and eyes evidence; pending decisions and missing integration keep work open.

## Decision outside the mandate

1. Reuse the decision's existing private manager and HITL case. If absent, create the
   manager and `ace-hitl create --kind decision --to captain`; record `hitl_case` on
   the manager. Creation is local publication, not external delivery.
2. Create an ordinary advisor commission with `role: second-captain` and that same
   `hitl_case`, the precise choices and references. Delegate with
   `ace-overseer work-on --task <advisor-task> --manager <decision-manager> --runtime herdr`.
   Keep a separate direct decision child open until the human answer is applied.
   End the turn and continue unrelated work.
3. Receive the advisor report through `ace_eyes process-reports`. Read the same case.
   The Captain reads it directly on the VM with `ace-hitl list` / `ace-hitl show CASE`
   and answers with `ace-hitl reply CASE --stdin`. Do not fabricate a reply or claim
   that local publication was delivered by an external adapter. If the advisor fails,
   record the missing recommendation and expose the same question; do not retry forever.
   A human answer wins over a late recommendation.
4. Apply the actual decision through its effect owner. Record `ace-hitl apply CASE
   --ref <verified-effect-reference>`. Prepare the factual lesson (by, relation,
   takeaway, optional refs) when a suggestion exists; close with
   `ace-hitl close CASE --lesson-file <path>`. The owner writes lesson and closure
   atomically. Never invent a lesson or reopen a closed case.
5. Accept the decision child only after the effect is proven. Resume dependants;
   unrelated commissions do not wait. Secrets and OTP bypass Second Captain entirely.
