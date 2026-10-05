# Fixed native container readiness amendment

This repairs review finding 8x43kfh7 on source f2a6affd694d51e64e93747b898090e13badf767.
Workspace creation starts an ungated default shell in Herdr0.9.3. The chosen
source-owned operation is therefore layout.apply only, targeting the fixed
root-installed native.workspace_id on the pinned server birth/socket generation.
The existing container supplies no worker or completion evidence. Newly created
original tab/pane/child provenance remains mandatory; no current/focus/search,
restored pane, workspace creation or fallback is admitted. The reply must echo
the installed workspace ID. Closed or stale containers refuse before any child.

Executed actual Herdr0.9.3 binary with distinct launcher UID13002 and server/child
UID13001, empty capability bounds and NoNewPrivs in an isolated Docker fixture.
The corrected preflight uses workspace.get with the configured ID, because
layout.export ignores workspace_id in Herdr0.9.3. Configured w1 remained
nonfocused while w2 was active; workspace.get(w1) echoed w1. The two
pre-existing installer-created shells were measured before launch (PID39/43).
One layout.apply created exactly one new direct child (PID51), whose executable
was the fixed root-owned test bootstrap; no extra shell appeared. Original
workspace/tab/pane and pane.process_info shell_pid matched that child. Exact
pidfd exit after pane.close returned child inventory to the unchanged baseline.
Closing the installed container while another workspace remained active made
workspace.get and another layout.apply return workspace_not_found
with zero new children. An intentionally unread create reply produced exactly
one test bootstrap (PID75); it was not retried. Retained bootstrap counter was2
for the two explicitly requested layout calls, not an extra default shell.

Evidence: evidence/native-fixed-container/{native-shape.json,probe.py,bootstrap.c,Dockerfile}.
Image sha256:f80837d9cd2fa588d1ee190e5a2d77a44c8446e711434b22488efb20908083de.
The fixture executable is a test process for API shape, not the product gate.
Kernel Yama0 means this does not prove protected launch acceptance or actual Lab
installation. The shipped product gate still requires Yama2 and refuses here.
The corrected native schema/spec remains needs_review until independent review.
