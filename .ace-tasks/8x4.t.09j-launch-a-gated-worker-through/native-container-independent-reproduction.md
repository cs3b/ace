# Independent fixed-container reproduction

The root integrator reran the committed probe from the repaired 09j worktree
(source head `5549f19cab5dce3ff8ffea621c49b14aa7fc54e2`, evidence amendment
`b462ff5e05c318ded09451487698d677996ad62b`) using the pinned fixture image
`sha256:f80837d9cd2fa588d1ee190e5a2d77a44c8446e711434b22488efb20908083de`.
The container mounted the committed fixture and native Herdr read-only, and a
fresh dedicated output directory; it mounted no credentials. Command exit 0.

Observed Herdr 0.9.3, protocol 22; launcher UID 13002, server/child UID 13001.
Configured w1 remained nonfocused while w2 was active. workspace.get(w1)
returned exactly w1. layout.apply created one test bootstrap (PID 51), with
original pane identity and process_info matching it. The two installer-created
shells (PID 39/43) remained unchanged. Exact exit returned the child inventory
to that baseline. Closing w1 caused both its preflight and layout operation to
refuse with workspace_not_found and zero new children. Deliberately discarding
one later layout response produced exactly one bootstrap (PID 75), with no
retry. The bootstrap counter was two for the two explicit layout requests.

Fresh machine-readable output is local at
`.ace-local/lab-readiness/09j-fixed-container-independent/native-shape.json`.
The committed fixture and author evidence retain the reproducible recipe.

This independently confirms the corrected workspace.get API-shape evidence
and the absence of an additional launch-created default shell. Yama was 0 and
the bootstrap was a test executable: **this is not protected-launch acceptance,
an installed product-gate proof, or actual Lab acceptance**. Final specification
and source reviews, plus the isolated Yama2 installed-artifact proof, remain
separate gates.
