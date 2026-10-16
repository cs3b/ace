# Inspiration workflow scenario walkthrough

Executed by the implementing agent on 2026-10-16 against the shipped workflow and local, explicitly simulated source observations. This is a manual workflow acceptance exercise, not an automated research service test or a live visual-quality benchmark.

| Scenario input | Decision made by following the workflow | Retained evidence |
| --- | --- | --- |
| Previously checked source revision `fixture-r1`; current observation also `fixture-r1`; prior proposal rejected as duplicate | No new proposal; update check time only and preserve the prior rejection | Unchanged source does not imply useful new guidance |
| Source changes from `fixture-r1` to `fixture-r2`; candidate says to ban gradients universally | Reject: conflicts with contextual use/avoid guidance and has no task-specific evidence | Record candidate/revision and reason; repeating `fixture-r2` must not reopen it without new evidence |
| One source fetch unavailable; last successful revision is `fixture-r1`; other sources readable | Keep `fixture-r1`, record failed check separately, continue readable sources | Partial source coverage, never a fabricated latest revision |
| A useful candidate lacks before/after artifacts or independent review | Prepare a concrete proposed diff plus proposal metadata, mark experimental/review-pending; do not merge or publish | Unexecuted comparison cannot be labeled validated |

The first three scenarios exercise the no-change, changed/rejected and partial-failure branches without requiring paid services. The fourth checks the promotion boundary. Live baseline/candidate generation across all six packaged briefs was not executed; fixtures and the reporting protocol are provided for future inspiration proposals. The separately executed exploration smoke generated three site and three app mockups and verified a targeted B-only feedback round, but is not a comparative efficacy benchmark.
