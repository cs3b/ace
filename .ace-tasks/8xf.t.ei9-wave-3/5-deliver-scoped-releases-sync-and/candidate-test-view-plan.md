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

Concrete policy source: `{kind: ordinary-candidate, root: ABSOLUTE,
runtime_path: ABSOLUTE, runtime_sha256: SHA256}`. The closed installed JSON profile
has `schema: ruby-test-runtime/v1`, `gem_paths`, `gems` (name → exact
`version`/archive `sha256`), `source_gems` (name → contained relative package
path), `package` (one selected source path), `argv` (absolute Ruby and runner,
then fixed runner arguments), `executable_sha256`, and `entrypoint_sha256`.
Exactly one `--config-path @configuration` and `--report-dir @output` pair is
required. Root compiles those two placeholders and inserts Ruby
`-rbundler/setup`; explicit generated fixture `RUBYOPT` preserves activation in
test children. It disables Bundler auto-install/version switching and ignores
ambient configuration. Only the UID-dropped executor evaluates that Gemfile.

Root generates a minimal immutable Gemfile and runner environment configuration.
Bundler evaluates candidate gemspecs only after UID/GID/groups drop. Its adjacent
lock points into external executor-owned output; immutable declarations still
pin source packages and exact installed versions. Runner fixture overrides
explicitly carry GEM_HOME/GEM_PATH/BUNDLE_GEMFILE; TMPDIR/reports also use external
output. No ambient credentials/GEM/BUNDLE, network installation or globally added
Lab test-runner dependency. Missing installed dependencies are truthful readiness
or execution failures. Domain installation uses the maintained runtime manifest
and exact archive installer; root disposable fixture pins are separate evidence.

Runtime verification establishes root-owned, non-group/world-writable expanded
GEM_PATH trees, contained root-owned aliases, a closed installed
specifications/cache/gems inventory, exact selected archive hashes, and exact
Ruby/runner hashes. Installed copies of explicitly source-overridden package
names are allowed; undeclared installed packages are refused. This trusts the
maintained installer's expansion of those root-owned bytes; it does not claim a
fresh archive-to-expanded-file byte comparison or evaluate gemspecs as root.

`candidate_reference` is a null-mutation, no-transfer read through the existing
ordinary assignment request interface, with only assignment/attempt selectors.
It returns the current four-field reference before any review assignment. The
candidate submit durable record stays unchanged. Command dispatch holds its
candidate lifecycle scope before entering journal CAS. A thread/lifetime-bound
reader revalidates each current prefix without acquiring lifecycle locks under
the journal writer. Exact registered task/assignment/attempt and shared/exclusive
rights are retained; a shared scope cannot be promoted to exclusive by reuse.
Historical merge proof uses the already held merge scope and additionally
requires exact candidate reference equality; static probe proof cannot satisfy
ordinary merge.

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

## Current gates

The source-only root fixture explicitly controls installed policy/runtime and
uses a tiny test script. It exercises real Git/filesystem, dropped UID, Bundler
activation after drop, writable external lock/output and alias/runtime refusal.
It creates no owner admission or canonical successful-test proof and is not
installed ace-test acceptance. Host skips this Linux/root-only case truthfully.
The maintained domain test-runtime packaging task encountered an external
automatic approval block; it is not retried or replaced by this source fixture.
The actual public dynamic pipeline and installed acceptance remain OPEN.

Next independent iy6 source increment, after this freeze/review: resolve scoped
secret references only inside the already dropped child, with bounded regular
reads and generic failure/exit126, no root/daemon/journal resolved values. Existing
combined-service grants and interactive TTY path remain the authorization/input
boundaries; no new taskless HITL or publication envelope is implied.
