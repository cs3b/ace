All context verified. Here is the structured review.

---

# Code Review: Canonical Candidate Test Execution (7ed745fcd..5488862bc)

**Scope**: 22 files — ace-assign authority (command dispatch, review evidence, merge evidence), ace-lab (policy, runtime profile, candidate view, executor, CLI), tests, task documentation.

## Review Summary

| Severity | Count | Summary |
|---|---|---|
| 🔴 Critical/Blocking | 0 | — |
| 🟡 High | 0 | — |
| 🟢 Medium | 4 | Late refusal asymmetry, leftover view dir on failure, verification-loop inconsistency, missing CHANGELOGs |
| 🔵 Low | 5 | Descriptor duplication, error classification, argv bound, lock-before-grant, requester-liveness note |

✅ **Overall**: The security architecture is sound and well-executed. The lifecycle-scope → journal-writer lock ordering, thread/lifetime-bound candidate views, shared→exclusive promotion refusal, and the root-only privilege boundary (gemspecs evaluated only after UID drop, proven by the Linux probe) are all correctly implemented and tested, including a real concurrency race test. No correctness-blocking defects found. Medium findings are robustness/process items.

📝 **Diff vs. working-tree drift**: `ace-lab/lib/ace/lab/molecules/command_test_runtime.rb` on disk contains hardening absent from the supplied diff (`Find.find(path, ignore_error: false)` and `rescue SystemCallError` in `verify_installed!`). Confirm which cut is the merge candidate; findings below reference the diff state.

## Deep Diff Analysis

### 1. Candidate-scoped command dispatch (`ace-assign/lib/ace/assign/authority/command_execution.rb:24-67`)
- **Intent**: Hold the candidate's lifecycle scope (exclusion locks) around every command mutation that touches a candidate, and add a read-only, launcher-bound `command_candidate` download.
- **Impact**: `dispatch` resolves the reference *before* `dispatch_scoped` — from the request for `command_admit` (requester-supplied, fully validated later against the journal digest in `resolve_candidate_reference!`) and from the stored projection for claim/bind/complete. `command_candidate` is phase-gated to `claimed`, requires `mutation_id.nil?` + `role == :worker` + original launcher, performs no journal write (verified: `test_candidate_download...` asserts prefix unchanged), and is correctly excluded from the lifecycle-ordering check (`MUTATIONS.take`, line 199).
- **Alternatives**: Scoping inside each operation would spread lock handling; the wrapper approach keeps ordering centralized. ✅ Good choice.

### 2. Candidate reference view + scope reentrancy (`ordinary_review_evidence.rb:15-137`, `ordinary_lifecycle.rb:30-31`)
- **Intent**: A closed 4-field reference; a thread- and deadline-bound view that re-resolves the current journal prefix without reacquiring lifecycle locks; a reentrancy registry so nested `with_scope`/`with_merge_scope` calls don't self-deadlock or silently upgrade shared→exclusive.
- **Impact**: `ordinary_evidence_scope`/`with_ordinary_evidence_scope` keyed by `Thread.current` with mutex; mismatched associations raise; `with_merge_scope` refuses exclusive promotion of a shared scope (tested). `resolve_candidate_reference!` revalidates acceptance digest, generation, association, and producer binding on every read — this is what makes the concurrent-candidate-change race test produce `Conflict` instead of a stale admit. Verified no inverted lock order: review mutations take shared locks and journal CAS serializes writers.
- **Alternatives**: Relying on lock exclusion alone would either deadlock the race test or admit stale candidates; prefix revalidation is the correct mechanism.

### 3. Merge evidence reference binding (`ordinary_merge_evidence.rb:12-73`, `command_execution.rb:125`)
- **Intent**: Historical merge proof requires the executed test's `definition.candidate.reference` to equal the canonical candidate reference; `candidate_reference.nil?` keeps the direct `test_evidence_at!` API testable.
- **Impact**: Intentional breaking change — static (non-candidate) test commands can no longer satisfy ordinary merge (dig returns `nil` ≠ reference → `ReceiptRejected`). This matches the plan's "static probe proof cannot satisfy ordinary merge" and is covered by the new negative assertion in `command_execution_test.rb:93-98`. ✅ Documented and intended.

### 4. Runtime profile + materialization (`command_test_runtime.rb`, `command_candidate_view.rb`, `command_owner_admission.rb`, `command_executor.rb:43-49`, `command_policy.rb:65-76,92-111`)
- **Intent**: Closed, digest-bound runtime profile; root compiles argv/env/Gemfile; only the dropped executor evaluates gemspecs; source sealed; output/tmp/lock writable only by the executor.
- **Impact**: Verified placeholder/argv contract (`--config-path @configuration` / `--report-dir @output` adjacency + uniqueness), `-rbundler/setup` insertion at argv[1] without mutating `@document` (so `verify_installed!` hashing `argv[0..1]` stays correct), RESERVED-env policy keys blocking ambient GEM/BUNDLE injection, and the `Gemfile.lock` symlink → executor-owned output trick (config sealed 0555, lock writable through the link — proven by the probe's `config_owner == 0`, `lock_owner == uid`, `lock_bytes > 0`). `prepare!` recompiles from current policy and compares against the journal definition before touching the filesystem — root independently re-derives, no trust in the passed definition. `Dir.mkdir` with EXCL semantics prevents view reuse.
- **Alternatives**: Fresh archive→expanded-byte comparison was explicitly rejected in the plan (trusts the maintained installer) — reasonable and documented.

### 5. CLI/client plumbing (`run.rb:32-40`, `command_run_client.rb`, `ordinary_assignment_client.rb`, `ordinary_authority_composition.rb`)
- **Intent**: `--candidate FILE` as bounded retained JSON (16 KB, duplicate-key rejection, object-only); `scratch_root` download client; `candidate_reference` read classification; circular lifecycle↔command-admission dependency via `-> { lifecycle }` closure.
- **Impact**: All referenced APIs verified to exist with matching signatures (`RetainedInput.json`, `OrdinaryClient#call(download:, purpose:)` → `Reply#parts`, `TransferCodec#descriptor`, `CandidateTransfer#materialize_repository`, `Router#transfer_binding` → roles/limits validated). Negative CLI inputs (`"null"*5000`, `{invalid`, `null`, `[]`) correctly collapse to `usage_error`.

### 6. Tests and probe
- **Intent**: Layer-appropriate coverage per the responsibility map; mocks confined to admission/policy doubles; real Git/journal/transfer I/O.
- **Impact**: The Linux-root probe genuinely proves: dropped-UID gemspec evaluation, sealed-source write denial, external TMPDIR writability, contained alias preservation, dangling/escaping-symlink refusal (via `CandidateTransfer`), writable/undeclared runtime refusal. Host skip is truthful. ✅ Excellent fidelity for a source-only fixture.

## Code Quality Assessment

- **Complexity**: `CommandExecution#dispatch`/`dispatch_scoped` and `CommandOwnerAdmission` have grown dense (long conditional chains), but each guard is load-bearing and commented. `verify_context!` at ~50 lines with three modes (`static`, `dynamic pre-materialization`, `materialized`) is the highest cognitive-load spot — see Refactoring.
- **Maintainability**: The `materialized:` flag on `verify_context!` creates a three-way behavior surface that is easy to misuse on future call sites; the new scope registry is small and well-encapsulated.
- **Test coverage delta**: Strongly positive. New coverage: policy candidate-reference closure, runtime profile mutations matrix, candidate download authorization/phase/launcher/immutability, reference resolution (thread escape, digest/generation/replacement/binding revocation), merge race without reversed locks, CLI input bounds, plus the Linux kernel probe. No coverage removals detected; existing merge tests updated for the candidate-bound contract.

## Architectural Analysis

- **Pattern compliance**: ✅ ATOM layering respected — `CommandTestRuntime` (molecule, data-only recipe + verification), `CommandCandidateView` (organism, I/O orchestration), no logic added to models. Flat test placement followed (`test/molecules/`, `test/organisms/`, `test/feat/`, `test/support/`).
- **Dependency changes**: `ace-lab` gains a source dependency on `Ace::Assign::Authority::RetainedInput` and `CandidateTransfer` (already transitively required) — consistent with existing coupling; no new gems. `CommandExecution`'s admission contract gains `with_command_scope`/`command_candidate!`; all production admission implementations verified updated.
- **Component boundaries**: The `candidate_owner: -> { lifecycle }` late-binding closure in `ordinary_authority_composition.rb:44-49` resolves the construction cycle; `candidate_owner` fails closed (`InvalidConfigurationError`) if invoked before assignment. Acceptable, but it is an implicit invariant — a brief comment on the assignment ordering already exists via code shape; consider one line stating "lifecycle must be assigned before serve".

## Documentation Impact Assessment

- **Required updates**:
  - 🟢 **Missing CHANGELOG entries and version bumps for `ace-assign` and `ace-lab`** (ADR-020: "Update CHANGELOG.md with every change, bump versions according to semver"). New operations (`command_candidate`, `candidate_reference`), a new CLI flag, and an intentional merge-evidence breaking change all qualify. *Suggested fix*: add Keep-a-Changelog entries (MINOR bumps; the static-evidence merge exclusion deserves an explicit "Changed/Breaking" note).
  - The new `candidate-test-view-plan.md` is accurate against the code (I verified the profile schema, argv contract, lock ordering, and gates it describes all match implementation) — ✅ good.
- **API changes**: Breaking (documented): ordinary merge no longer accepts static test evidence; `command_request!` gained `execution_id:` keyword (all callers updated: verified admit/claim/child/candidate/evidence paths).
- **Migration notes**: Consumers of `merge_evidence`/`test_evidence_at!` relying on static commands must move to candidate-bound dynamic executions — stated in the plan, should be echoed in CHANGELOG.

## Quality Assurance Requirements

- **Test scenarios to add**:
  - 🔵 `command_candidate` on a *non-candidate* command definition (currently refused only via `definition["candidate"]` nil-check inside `command_candidate!` — untested at the assign layer).
  - 🟢 **Large-tree candidate refusal point**: a candidate with >20,000 entries passes admit → claim → full materialization → seal, then fails at `command_child!`'s `verify_context!` ("command source exceeds verification bound"). The 20k cap is only enforced post-materialization (it was a deployment-controlled static-dir guard before). *Suggested fix*: enforce an entry-count bound during `CandidateTransfer#materialize` (ls-tree entry count) or declare `max_entries` in the runtime profile, so refusal happens at submit/admit rather than after root I/O.
  - Retry-after-crash behavior between `Dir.mkdir(root)` and seal (see M2 below).
- **Integration points**: installed `labd` ↔ owner socket download as the real launcher ancestor (probe covers composition as source-only; installed acceptance remains OPEN per the plan — correctly not claimed).
- **Performance benchmarks to monitor**: `resolve_candidate_reference!` re-reads and SHA256s the bundle (≤64 MB) on *every* `command_request!` — admit runs it twice (plan + authenticate), plus claim, bind, candidate download, and each evidence read; `merge_evidence_at!` reads the blob via `candidate_at!` twice and `candidate_reference_at!` once. `verify_installed!` walks ≤8×100k entries and hashes every declared archive on each `command_request!` as well. All deadline-bounded and correctness-safe, but per-execution cost is several multiples of the bundle size — worth measuring once the installed pipeline runs.

## Security Review

- **Attack vectors**: 
  - Requester-supplied `candidate` on `command_admit` is fully revalidated against the journal (digest/generation/association/binding) before any bytes move; the reference carries no path/head. ✅
  - Root never evaluates candidate code: materialization is object-level (`cat-file`), `bundle verify`/`fsck` in an empty bare repo, gemspecs evaluated only post-drop (probe asserts `evaluated_uid != 0`). ✅
  - Sealed source (0444/0555, root-owned), contained aliases only, escaping/dangling rejected. ✅
  - 🔵 **Low — lock-before-grant ordering**: any uid holding *any* command grant can send `command_admit` with a well-formed `candidate` naming any registered assignment, causing brief shared task/assignment lock acquisition (and a `NotFound`/`Conflict`) before `policy.select` denies the grant. Read-only, shared, deadline-bounded — acceptable, but moving grant validation ahead of scope acquisition would eliminate the vector.
  - 🔵 **Low — observation**: `command_candidate!` re-runs `command_request!` with the stored requester peer, so the download additionally requires the originating requester process to still be alive (`OrdinaryPeer#live!` pid/started_at match). Consistent with the pre-existing claim-time check (not a regression), but the plan describes the export as launcher-owned; if executor-autonomous retry after requester disconnect is ever desired, this is the line that will refuse it — document the intent either way.
- **Data flow**: candidate bytes travel only through the authenticated owner socket into root-private scratch (`PrivateDirectory.verify!`); descriptor digests verified end-to-end by codec; no secret values involved (`secret_references` must be empty for the executor path — enforced in `command_executor.rb:37-39`).
- **Compliance**: N/A (internal tooling); ADR-025/031 alignment (no shell interpolation, structured argv, explicit env/cwd) verified in `launch` and the probe's `exec(environment, ...)`.

## Refactoring Opportunities

- 🟢 **M2 — `CommandCandidateView#prepare!` failure hygiene** (`command_candidate_view.rb:42-63`): if any step fails after `Dir.mkdir(root, 0o755)` (e.g. bundle digest mismatch, transfer error), the partially-created view remains, and any retry with the same `execution_id` crashes with a raw `Errno::EEXIST` instead of a classified error. *Suggested fix*: rescue `SystemCallError` around the body, remove the freshly created `root` on failure (it is provably this call's creation — EXCL), and convert `EEXIST` on retry to `SecurityError, "candidate view already exists"` — still fail-closed, but truthful and idempotent-safe.
- 🟢 **M3 — verification-loop inconsistency** (`command_owner_admission.rb:228-244` vs `command_test_runtime.rb` `verify_installed!`): the diff's `verify_installed!` traverses with default `Find.find` semantics and lets `File.realpath`/`Dir.children` `SystemCallError`s surface unclassified; the working tree already hardens it (`ignore_error: false`, `rescue SystemCallError → InvalidConfigurationError`). `verify_context!`'s identical loop was *not* given the same treatment in either state. *Suggested fix*: mirror `ignore_error: false` + `SystemCallError` classification in `verify_context!` so both trust-boundary loops behave identically.
- 🔵 **L1 — duplicate transfer descriptor**: `CommandExecution#command_candidate` (line 66-67) embeds `descriptor` in `data`, then `SocketServer#dispatch_request` (socket_server.rb:189-191) re-derives and merges it again. Harmless (equal values) but redundant; keep the server-side derivation as the single authority and drop the handler-side embed.
- 🔵 **L2 — error classification**: `CommandExecution#dispatch` (lines 26-31) `fetch`es `params.execution_id`/`selection` before `strict!`, so a missing key now raises `KeyError` → server classifies `evidence_unavailable` where the previous path produced `ArgumentError` → `invalid_input`. Use `request.dig("params", "execution_id")` + explicit `ArgumentError` to preserve classification.
- 🔵 **L3 — argv receipt bound**: `test_evidence_at!` rejects `JSON.generate(argv)` > 2048 bytes at evidence-read time, while profile validation permits argv up to ~128×4096 bytes at admission. A deployment-controlled profile could admit a command whose evidence later can't be read. Consider validating the bound at `compile` time.
- **Future consideration (not an action item)**: extracting `verify_context!`'s three modes into named private methods (`verify_static_source!`, `verify_materialized_source!`, `verify_runtime_config!`) would reduce the flag-driven complexity.

## Action Items

| # | Severity | Location | Action |
|---|---|---|---|
| 1 | 🟢 Medium | `ace-assign/CHANGELOG.md`, `ace-lab/CHANGELOG.md` | Add Keep-a-Changelog entries + semver bumps; note the static-evidence merge exclusion as breaking (ADR-020) |
| 2 | 🟢 Medium | `command_candidate_view.rb:42-63` | Clean up/reclassify failed view creation; convert retry `EEXIST` to `SecurityError` |
| 3 | 🟢 Medium | `command_owner_admission.rb:228-244` | Harden `verify_context!` traversal to match `verify_installed!` (`ignore_error: false`, `SystemCallError` → `InvalidConfigurationError`) |
| 4 | 🟢 Medium | `candidate_transfer.rb` / `command_test_runtime.rb` | Bound candidate entry count at materialization (or profile `max_entries`) so >20k-file candidates refuse at admit, not at bind |
| 5 | 🔵 Low | `command_execution.rb:66-67` | Drop handler-side transfer descriptor (server re-derives it) |
| 6 | 🔵 Low | `command_execution.rb:26-31` | Preserve `invalid_input` classification for missing params keys |
| 7 | 🔵 Low | `command_test_runtime.rb` `compile` | Enforce the 2048-byte argv receipt bound at compile time |
| 8 | 🔵 Low | tests | Add assign-layer test: `command_candidate` against a non-candidate definition |

✅ **Verdict**: No blocking issues. The Medium items are robustness/process hardening appropriate to land with (or immediately after) this freeze; recommend resolving #1–#3 before merge given this cut explicitly gates an independent review.