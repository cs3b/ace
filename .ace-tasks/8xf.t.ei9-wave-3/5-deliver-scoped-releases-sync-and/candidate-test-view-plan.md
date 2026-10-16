# Canonical candidate test execution — current implementation contract

Owner: ei9.5, shared prerequisite for ei9.0/ei9.8. Base `7ed745fcd`.
This extends the reviewed nonsecret command path; publication/OTP and taskless
secrets remain open. Static installed-source commands remain supported for
installed probes, but cannot represent an autonomous newly submitted candidate.

## Authority and observable path

`ace-lab run --project P --candidate REF.json -- <configured literal selector>`
admits one command against a closed canonical candidate reference:
`assignment_id`, `attempt_id`, `candidate_generation`, `acceptance_event_digest`.
The reference contains no caller-selected path, head or bundle bytes. The same
ordinary owner resolves it under the existing assignment exclusion/current
journal prefix, authenticates the genuine running producer and retains exact
candidate head/tree/bundle digest/length/reference in the command definition.
An explicit operator grant or genuine native-agent grant is still required.

Dynamic TEST policy selects an ordinary-candidate source recipe with a trusted
retained-view root and digest-bound installed runtime profile. The immutable
definition contains concrete head/tree, original candidate reference, execution
identity, exact runtime recipe, literal request selection and actual compiled
argv/environment/cwd. Current policy must still select the same recipe at
claim, bind and historical test-proof validation. No per-candidate policy edits.

Only the authenticated root helper of the installed labd can download the
original claimed command candidate. This is a read-only operation on the same
Router/journal, using existing TransferCodec candidate framing. It does not
create a second claim or permit. Root uses CandidateTransfer's verified object
materializer and empty Git administration without evaluating source scripts,
Gemfiles, gemspecs, hooks or filters. It seals the resulting repository and
generated configuration before any gated child is created. The accepted source
is retained through evidence consumption; writable output/tmp/lock state is
outside it. Existing fresh claim/bind gate, privilege drop, bounded owned-child
cleanup, canonical terminal status and replay-never-exec rules remain intact.

## Selected test runtime

The installed, digest-bound nonsecret Ruby test profile declares exact installed
gem versions/GEM_PATHs, source package closure paths, package cwd, fixed Ruby and
public ace-test runner entrypoint/hashes/arguments. Only source-owned finite
configuration/output substitutions are permitted; no shell or arbitrary
requester template. Original public command selection and actual compiled argv
are separately retained. All changed required source producers must appear in
the selected closure; the root ACE Gemfile is not evaluated to discover it.

Root generates a minimal immutable Gemfile and runner environment configuration.
Bundler evaluates candidate gemspecs only after UID/GID/groups drop. Its adjacent
lock points into external executor-owned output; immutable declarations still
pin source packages and exact installed versions. Runner fixture overrides
explicitly carry GEM_HOME/GEM_PATH/BUNDLE_GEMFILE; TMPDIR/reports also use external
output. No ambient credentials/GEM/BUNDLE, network installation or globally added
Lab test-runner dependency. Missing installed dependencies are truthful readiness
or execution failures. Domain installation uses the maintained runtime manifest
and exact archive installer; root disposable fixture pins are separate evidence.

## Test responsibility map

| Behavior | Risk | Layer / owner |
|---|---|---|
| Closed ref/recipe/profile, no paths/head supplied by requester | High | Lab policy pure tests |
| Canonical current ref, authentic producer, replacement/revocation refusal | High | Assign real journal integration |
| Only original claimed root launcher can export exact candidate | High | Assign dispatch/transfer integration |
| Root materializes exact clean head/tree, preserves executable modes | High | Lab real Git/filesystem integration |
| Source/config sealed; output/tmp/lock writable only after drop | High | Linux distinct-UID public composition |
| Exact source package closure and installed dependency activation | High | Actual public ace-test in root fixture |
| Missing/tampered runtime/candidate and dirty view refuse | High | Filesystem integration + Linux acceptance |
| Candidate superseded/revoked between claim/materialize/bind | High | Canonical owner integration |
| Replay/lost ACK/disconnect never executes twice, detached cleanup | High | Existing kernel regressions plus dynamic fixture |
| Historical proof requires original successful exact candidate execution | High | Existing Assign reader + dynamic admission integration |

Mocks are restricted to external provider/network/native observation where
explicitly identified. Materialization, permissions, transfer bytes, Git objects,
child credentials and cleanup need real I/O; Linux acceptance proves actual
distinct UIDs and public CLI/owner/labd/helper composition. Static R3–R6 receipts
remain immutable and do not prove this new dynamic path. No broad suite until a
coherent source freeze; parent owns combined verification and independent review.
