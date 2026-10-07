# Proposed exact protected review

`ace-overseer review --project ace --agent builder --assignment A --attempt T --head HEAD --candidate-generation 1 --mutation review-001 --expected-generation 12 --accept-mutation review-accept-001`

Run under the actually provisioned reviewer principal, independent of the worker. It requests original-launcher delegation, exports only its assigned exact candidate, runs the existing configured review owner and uploads actual authenticated receipt/report. Approval is only canonical accept_review; a forge PR/provider output alone cannot grant it.

After loss: `ace-overseer review --status --project ace --agent builder --assignment A --attempt T --mutation review-001`. Read-only; no reassignment/review rerun/upload. A new process may observe through the same stable principal but cannot claim the old reviewer birth. If the old reviewer died or assignment hit a generation conflict, cancel its reservation explicitly before requesting again. Cancellation revokes authority; it does not claim the old process stopped.

No --work/Lab forwarding. These forms are a proposed source interface, not delivered commands.


Proposed explicit cancellation: `ace-overseer review --cancel --project ace --agent builder --assignment A --attempt T --head HEAD --candidate-generation 1 --review-event REQUEST_EVENT --mutation review-cancel-001 --expected-generation 15`. The same provisioned requesting principal may use this after restart. The exact event is obtained from authenticated status; the command never chooses the latest review implicitly. After successful cancellation, a new explicit request uses fresh mutation IDs and the currently observed generation. A stale-generation refusal requires another status read and deliberate new command; no automatic refresh. Direct assignment cancellation requires its authenticated original launcher.
