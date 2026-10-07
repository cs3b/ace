# Protected prune readiness review

Root reviewed candidate `969f793ef6c83a5193f49282e6996e67afbaab41` against current `LabHerdrNative::Installer`, `ProtectedServiceReceiver` and `LifecycleExclusion`. **Changes required; retain draft / needs_review: true.** No source implementation or installed acceptance is approved.

1. Installer currently computes the complete original/candidate maintenance inventory and uses a global inhibition marker and selected stop units. The proposed unchanged maintenance requester exemption is not existing behavior. Specify the actual descriptor/authority boundary or scoped owner changes that keep the requester outside the transaction without weakening all-root eligibility.
2. `ProtectedServiceReceiver#execute` synchronously runs the handler before importing completion. Increasing the child deadline to 300 seconds does not establish the proposed short client/status exchanges. Ground actual receiver server/client lifetime and loss behavior; no implied asynchronous execution.
3. Handler execution ends before `complete_service`. The proposed rule that inhibition is cleared only after canonical completion needs a concrete source owner and authenticated completion/recovery path. It must avoid recursive maintenance locks and repeated removal after loss.
4. Define nested request/receipt types and bounds, and the actual Git worktree capture/removal/admin repair order. Naming an atomic capture and existing Git removal separately does not prove their composition preserves replacements and Git administrative state.

The separation of obsolete target and maintenance requester, completed successor publication prerequisite, retained original evidence, explicit creator exclusion and operation-specific outcome inspection are appropriate. They do not resolve the implementation joins above. Author has been asked to revise the candidate; all success criteria remain unchecked.
