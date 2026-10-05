# Source review round 2

Frozen source `5549f19cab5dce3ff8ffea621c49b14aa7fc54e2` received two verified
correctness findings in independent Sol 6.1 review session
`09j-5549-source-round2` (terminal exit 0). Source acceptance is **REJECT** until
repairs and subsequent review; positive protected installed acceptance is also
still open. The separate fixed-container specification review approved the
amended contract with zero findings; that is not a source verdict.

- **8x44lo5s, high:** Linux/Yama preflight does not probe actual pidfd support.
  Launcher handle acquisition follows canonical reservation commit, allowing a
  failed acquisition to strand a reservation without its observation. Probe
  capability and acquire the exact handle before fresh reservation CAS; close
  on rejection/replay.
- **8x44lo5t, medium:** status ignores a retained exited child and reports bound
  while the launcher remains alive. Project uncertainty and required recovery
  while retaining canonical ownership until accepted abort/reconciliation.

Reviewer existing targeted tests: 57 tests, 425 assertions, no failures. Both
review reproductions failed. Root independently inspected the affected paths
and reran the reproductions: runtime/8x44ms (1 test, 1 assertion, 1 failure) and
assign/8x44mu (1 test, 4 assertions, 1 failure). Both feedback items are verified
valid/pending. Initial relative-path invocations failed to load and are not
claimed as reproductions.

Author exact-source full Assign pass remains valid baseline evidence:
assign/8x44jr, 884 tests, 3927 assertions, zero failures/errors, two existing
edge skips, 15m14s. It does not negate the independently demonstrated gaps.
