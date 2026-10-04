# TC-003 Verify — Merge goals

### Goal 1 - A draft PR cannot be merged

- **Verdict**: PASS only if `merge-draft-refusal.exit` is nonzero with
  category `unsupported_capability` (work-in-progress refusal), and the
  fork PR remains open and unmerged in later artifacts.

### Goal 2 - Server rejects a stale head atomically

- **Verdict**: PASS only if `merge-stale.exit` records HTTP 409 and
  `merge-stale.json` contains `"head out of date"`, AND
  `merge-stale-provider.exit` is nonzero with category
  `expected_head_conflict`.

### Goal 3 - Each requested method merges with proof

- **Verdict**: PASS only if `merge-squash.json`, `merge-merge.json`, and
  `merge-rebase.json` all show exit 0, `state: "merged"`, a 40-character
  `merge_commit`, and `head` equal to the branch SHA recorded for each
  PR.

### Goal 4 - Already-merged result is reusable

- **Verdict**: PASS only if `merge-squash-replay.exit` is 0 with
  `state: "merged"` and the identical `merge_commit` as
  `merge-squash.json` (no error, no second mutation).
