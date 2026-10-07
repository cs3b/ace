# Proposed exact protected review

`ace-overseer review --project ace --agent builder --assignment A --attempt T --head HEAD --candidate-generation 1 --mutation review-001 --expected-generation 12 --accept-mutation review-accept-001`

Run under the actually provisioned reviewer principal, independent of the worker. It requests original-launcher delegation, exports only its assigned exact candidate, runs the existing configured review owner and uploads actual authenticated receipt/report. Approval is only canonical accept_review; a forge PR/provider output alone cannot grant it.

After loss: `ace-overseer review --status --project ace --agent builder --assignment A --attempt T --mutation review-001`. Read-only; no reassignment/review rerun/upload. A new process may observe through the same stable principal but cannot claim the old reviewer birth. If old reviewer died, a separately explicit fresh request requires fresh mutation/generation and the actual current candidate; no automatic recovery rerun.

No --work/Lab forwarding. These forms are a proposed source interface, not delivered commands.
