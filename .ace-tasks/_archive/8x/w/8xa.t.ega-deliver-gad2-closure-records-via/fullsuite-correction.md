# CORRECTION — fullsuite failures/stall status (host standing correction, 2026-10-11)

The monorepo full-suite failures and the ace-assign stall recorded during the
8x9.t.x3o repair verification (bin/ace-test-suite --target all; package
failures across ace-herdr, ace-hitl-contract, ace-test-runner-e2e,
ace-review, ace-overseer, ace-lab, ace-git + 442s zero-test ace-assign
stall; interrupted >7 min, exit 130; facts in
.ace-local/assign/8x9xcv/reports/012-verify-test-suite.r.md and preserved in
pr36-review-r1.md section 5) are:

**UNRESOLVED and NOT proven unrelated.**

Earlier phrasing in some records ("unrelated package failures") is
CORRECTED by this note: the failures are unresolved; whether they relate to
the repair track or to platform/runtime is undetermined. Facts are preserved
as-is. Stall/failure diagnosis belongs to host/platform. No monorepo
full-suite pass was obtained or claimed for gad.2 deliveries.
