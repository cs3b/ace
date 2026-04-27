# Goal 3 — Watch Sequential Continuation Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/03/`.
3. Use debug evidence only as fallback.

1. **Assignment created** — `create.exit` is `0` and `assignment-id.txt` contains a non-empty assignment ID.
2. **Baseline shows runnable work** — `status-before.stdout` exists and shows pending or active watcher-relevant fork work before the watch command runs.
3. **Watch command captured** — `watch.stdout`, `watch.stderr`, and `watch.exit` all exist.
4. **Sequential continuation surfaced** — `watch.stdout` shows watcher-visible continuation across more than one fork root (for example multiple `Launching next fork subtree ...` messages, or equivalent evidence that multiple roots were handled in order).
5. **Terminal boundary is explicit** — the watcher output ends in either:
   - a success/complete summary, OR
   - a stop summary naming the remaining inline/manual boundary.
6. **Post-watch state is coherent** — `status-after.stdout` exists and reflects forward progress from the baseline rather than a reset or unrelated mutation.

## Verdict

- **PASS**: The retained suite proves whole-assignment watcher continuation with raw captures.
- **FAIL**: Missing artifacts, no multi-root continuation evidence, or incoherent post-watch state.

Report: `PASS` or `FAIL` with evidence from `status-before.stdout`, `watch.stdout`, and `status-after.stdout`.
