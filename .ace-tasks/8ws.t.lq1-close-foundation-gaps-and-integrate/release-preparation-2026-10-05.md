# Prepared coordinated source release — 2026-10-05

## Result and exact source

All source changes for this bounded release are integrated on main. Build and tested release source: `5a0c9e05b00fe429dc59f36445ec43507fbefae4`, pushed to origin and fg before preparation. Later task/evidence commits do not replace this artifact build identity.

The release metadata has independent APPROVE. `bin/ace-test-suite --timeout 300` on this exact revision completed all 51 configured entries in 171.62 seconds: **11280 passed, 24 skipped, 34658 assertions, zero failures/errors**. The immutable child report manifest preserves both Lab entries separately and all 51 unique execution IDs.

Affected Runtime all (240/866), Herdr all (476/1641) and Assign fast (820/3030) passed on the accepted source. Additional Assign deterministic feature coverage is composed from 26 executed files and reviewed fixture corrections; there is no successful actual Assign all claim. Two native/installed edge files were not executed. Original errors/timeouts and their corrections remain in 9c2/connected-parent-cap-verification.md. Independent review accepted the bounded source and fixture corrections.

## Prepared package set

| Package | Version |
| --- | --- |
| ace-runtime | 0.2.0 |
| ace-hitl-contract | 0.2.0 |
| ace-herdr | 0.4.0 |
| ace-tmux | 0.19.0 |
| ace-assign | 0.64.0 |
| ace-hitl | 0.12.0 |
| ace-hitl-hermes | 0.2.0 |
| ace-lab | 0.4.0 |
| ace-git | 0.29.0 |
| ace-handbook | 0.34.0 |
| ace-git-worktree | 0.26.0 |
| ace-review | 0.59.0 |
| ace-overseer | 0.20.0 |
| ace-test-runner | 0.28.0 |
| ace-test-runner-e2e | 0.43.0 |
| ace-demo | 0.26.2 |

The tested publisher dry-run and prepare selected exactly these 16 gems in eight dependency waves, each at most five pushes. Prepare built all 16 anew, reused zero files and performed no gem push. Archive inspection verified all 1110 payload files against the exact source, embedded versions and complete runtime dependency declarations. Required direct and minimum dependencies are explicit; no external lockfile versions changed. See evidence/local-release-2026-10-05/artifact-verification.json and release-dependency-audit.md.

No new ace-llm release is included: the inspected redaction source is already published in 0.42.0. The Pi wake code is already published in 0.5.0; its unrelated documentation difference does not expand this release.

## Publication handoff

The prepared queue is `.ace-local/rubygems-publish/pending-queue.yml`. From the primary ACE checkout, the Captain runs:

```bash
.ace-bin/ace-rubygems-publish --interactive
```

The publisher reads the short-lived OTP directly in the operator terminal. No OTP was requested or captured during preparation. Do not change the release source or rebuild under the same versions between this handoff and publication. Archive hashes and exact build source are retained in the artifact manifest. Publication is still **not performed** by this checkpoint.

## After publication

The new installation manifest is `.ace-local/release/coordinated-installation-manifest.json`; its byte-identical durable copy is evidence/local-release-2026-10-05/installation-manifest.json. It has 49 package records: these 16 new records plus 33 explicitly retained historical records, including prior supersession and consumer-edge requirements. Historical build/context distinctions remain explicit in installation-provenance.md. The old default manifest is not this release's proof input.

```bash
ACE_RELEASE_MANIFEST=/Users/mc/Ps/ace/.ace-local/release/coordinated-installation-manifest.json bin/ace-test-e2e ace-monorepo-e2e TS-MONO-001 --timeout 1800 --verify
```

Retain the same-run runner/verifier and host finalizer evidence before claiming installation acceptance. This command has not been executed for these unpublished versions. Publication and installation proof do not establish Lab readiness.

## Remaining owners

- 9c2 remains in progress: actual native/network readiness integration, admitted/post-native closure, original/candidate historical maintenance, and non-abort terminal release still require source implementation and their separate installed proof.
- xz9.0 owns remaining finish/recover/inbox/full composition; xz9.1 owns resilience. xz9.2's terminal-versus-PID guarantee remains an unanswered decision, not silently accepted by this release.
- qkb.1's neutral vocabulary source is accepted; protected role adoption and fresh installed resolution remain open. qk0, then complete qkb, R2/R3 and qkc/gad.2 remain the downstream program.
- Domain installer and final Lab scenarios remain lab-config:gad.8/gad.b/gad.2. No native/privileged probe or Lab deployment was performed during this local release preparation.

This report closes only the bounded source release preparation. Whole 9c2, xz9, qkb, lq1 and the Lab program remain open.
