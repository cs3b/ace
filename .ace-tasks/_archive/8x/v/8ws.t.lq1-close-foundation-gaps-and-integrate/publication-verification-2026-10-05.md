# Publication and installation verification — 2026-10-05

## Publication accepted

The Captain reported 16 successful publications in eight waves (19.8 seconds), reusing the exact prepared artifacts. Independent RubyGems v2 metadata reads confirmed every exact version and all 16 artifact SHA-256 hashes against the prepared inventory. Evidence: `evidence/publication-2026-10-05/registry-verification.json`.

Build source remains `5a0c9e05b00fe429dc59f36445ec43507fbefae4`. Documentation changes do not change artifact identity. No republishing or version change is indicated by this verification.

## Installation evidence and limit

Executed:

```bash
ACE_RELEASE_MANIFEST=/Users/mc/Ps/ace/.ace-local/release/coordinated-installation-manifest.json bin/ace-test-e2e ace-monorepo-e2e TS-MONO-001 --timeout 1800 --verify
```

Run `8x4m8d9-monorepo-e2e-ts001` completed after 626 seconds with **pipeline ERROR**, failure phase `verifier`, not full acceptance. Both normal and full-index installs exited zero. The deterministic exact-version check recorded **PASS**, classification **SAFE**, 49 manifest package records, no findings, and consumer-edge checks for Bundle, Review and Task in both modes.

The verifier's Codex invocation `iYZVobQG` exited 1 after 4.6 seconds. Its session `01a10c94-1b77-7f43-b1c3-8a4411d0875b` records `server_overloaded`: “Selected model is at capacity. Please try a different model.” No verifier verdict was produced. The wrapper retained `uncertain_execution: true`; no replay or alternate model was used.

The same-run host finalizer was executed and returned **final: fail**. It independently retained exact-version acceptance PASS and byte-identical manifest integrity, but reported that failed pipeline metadata contains YAML Symbols which its safe parser does not accept. This is a failure-report parsing limitation, not a release-install defect and not permission to rewrite failed metadata. Even with parser support, the missing independent verifier and ERROR pipeline must remain a rejection.

The source and sandbox manifest digest is `851babb5c3bd0cb76959db015960ed5d4b48e216f500ec6e75f5fd230287189f`.

## Next action and ownership

`8ws.t.lq1` retains the unchecked current-release installation acceptance item. After provider capacity is available, execute the documented full scenario with the same immutable manifest in a fresh run and finalize that run's own reports. Preserve this failed run; do not relabel it using a later verifier or successful installation exits alone.

No product or scenario change was made: observed blocker is external verifier capacity. Failure-report Symbol parsing is recorded here as a runner diagnostic gap; no fix was attempted or claimed. Public CLI help exposes no verifier-only resume option, so no private recovery path was invented.

Raw receipts, lockfiles, consumer evidence, pipeline reports, extracted provider error and failed host finalization are retained under `evidence/publication-2026-10-05/`, with an integrity inventory. Runtime caches and full private CLI session prompts are excluded. These are release propagation results, not Lab installation or protected native-runtime acceptance. The existing 9c2/xz9/qkb and Lab gates remain open.
