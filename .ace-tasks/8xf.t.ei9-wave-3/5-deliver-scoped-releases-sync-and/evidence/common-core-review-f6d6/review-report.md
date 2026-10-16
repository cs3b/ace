# Independent Adversarial Review — f6d6f518 (base 2922e2a5)

**Tooling constraint up front:** this review session was provisioned with read-only tools (read/grep/find/ls) only — no shell, no file-write. I therefore could not personally execute `bin/ace-test` nor write the report file to `.ace-local/ei9-common-core-review/f6d6/`. Instead I (a) verified the referenced executed-test reports exist with matching numbers and internally consistent stack traces, and (b) performed full source-level verification of every moved guard. Details under "Checks executed" / "Limitations".

## VERDICT: APPROVE

The commit is a faithful mechanical extraction. Protected authorization, evidence admission, replay/lost-ACK, current-policy and immutable-payload semantics are preserved verbatim; module visibility, constant resolution and require order are correct; no new callback or hook bypasses protected guards; the test-fixture correction is legitimate and fully evidenced.

## Scope confirmation (no overclaiming)

- Only `Endcap` includes `FixedServiceLifecycle`/`FixedPublicationLifecycle` (`ace-assign/lib/ace/assign/authority/endcap_service_context.rb:9-10`; grep over whole repo confirms no other includer). No ordinary service privilege, no source-selected ordinary journal authorizer, no ordinary origin is added. The spec/plan docs (`.../8xf.t.ei9.5-...s.md`, `ordinary-publication-plan.md`) state exactly this and keep taskless secret/publish OPEN. The commit does not claim the ordinary boundary exists.

## Findings

**F1 — INFO — design note for next phase — `fixed_service_lifecycle.rb:142,251,258,421,431,443,530-531`**
The extracted modules route `@launch`/`@deployment`/`protected_journal!`/origin/review/worker through the nine private hooks, but still reference `@kernel` and `@service_policy` ivars directly. Fine today (only Endcap includes them; `service_policy!` fails closed with `ArgumentError` when nil), but a future ordinary includer must supply these ivars — the module is not yet purely hook-composable. No action needed for this commit; flag for the ordinary-composition review.

**F2 — INFO — doc drift — `ordinary-publication-plan.md:19`**
The "Grounded gaps" section still says the transitions "live in endcap_services.rb and endcap_publication.rb"; the same commit renames/moves them, and the later "First extraction verification" section names the new modules. Internally inconsistent snapshot-in-time wording only; no functional impact.

**F3 — INFO — naming — `endcap_publication.rb:11`**
After extraction this file contains only `with_worker_hitl!` (protected worker HITL, correctly retained in the protected Endcap file per scope). The filename is now misleading; harmless.

No LOW/MEDIUM/HIGH/CRITICAL findings.

## Verified in detail

**1. Guard semantics unchanged (focus: protected checks).** Every substitution in `endcap_services.rb → fixed_service_lifecycle.rb` and `endcap_publication.rb → fixed_publication_lifecycle.rb` maps 1:1 to the adapter in `endcap_service_context.rb:14-22`:
- `with_service_scope(**, &block)` → `@launch.with_assignment` (block forwarded; all call sites pass `params:`/`map:` kwargs)
- `service_journal!` → `protected_journal!` (`endcap.rb:219`, still enforces `evidence_mode == :protected`)
- `service_mapping!`/`service_project!` → `@deployment.mapping/project`
- `service_scope_open!` → `@launch.scope_open_for_effect!`; `service_preview_events!` → `@launch.preview_attempt_events!`
- `service_origin!` → `active_origin` (`endcap.rb:250`, launch-phase/liveness checks untouched); `service_worker!` → `worker_or_launcher!` (kwargs incl. `launcher_only:` forwarded); `service_review!` → `approved_review!` (`endcap.rb:351`, incl. `service_operation:` kwarg).

Check **order** preserved line-by-line in `publication_record!` (executor → ticket → events → exact_candidate! → origin → worker → review → scope_open → policy.authorize! → ServiceEvidence.context), `authorize_service_update!` (publication early-return branch, executor/owner-binding immutability, origin triple-compare, receiver/credentials, review exemption only for `create/update`), `service_authorization`, `service_claim_plan`, `service_begin_plan`. No check dropped, reordered, or re-scoped.

**2. Replay / lost-ACK / current policy.** `with_replay: true` + `already_issued`/`already_started`/`claim: retained` merges identical (`fixed_publication_lifecycle.rb:120-128,168-176`; `fixed_service_lifecycle.rb:324-347,486-499`); admission re-runs both outside and inside the mutate callback; `service_replay_binding!` and native-descendant replay checks unchanged; `service_policy!` still fails closed without an installed policy owner.

**3. Immutable payloads.** `SERVICE_IDENTITY` slice equality ("service request immutable identity differs"), `PUBLICATION_FIELDS`-except transition comparison, `settlement_immutable` deep-freeze, `Atoms::EvidenceDigest` executor/owner-binding pinning — all verbatim. `ServiceEvidence`/`ServicePublicationEvidence`/`EvidenceJournal` untouched by this diff.

**4. Visibility / constant resolution / require order.** `endcap.rb:437-439` requires both modules before `endcap_service_context` performs the include; hooks are `private` on Endcap, called with implicit self from the modules (valid). New modules nest in `Ace::Assign::Authority` — identical lexical nesting to old `class Endcap`, so `AttemptErrors`, `ServiceEvidence`, `ServicePublicationEvidence`, `CandidateTransfer`, `Molecules::*`, `Models::*`, `Atoms`, top-level `SecureRandom/Digest/JSON/Time` all resolve as before; nothing references Endcap-only constants (`OPERATIONS` etc.). No method-name collisions between the two modules; cross-module calls (`authorize_service_update!` → `authorize_publication_update!`, `publication_record!` → `service_executor!`/`service_ticket!`, `with_publication_hitl!` → `settlement_immutable`) resolve via the include. No code references the removed `endcap_services` filename. External callers (`ace-hitl/.../service_publication_binding.rb:53,88`, `ace-lab/.../protected_cleanup_owner_admission.rb:78`, `launch_scope_release.rb:596`, `endcap_attempts.rb:68`) all use instance-level calls that resolve through the includes.

**5. No new bypass.** The only new "hooks" are nine private 1:1 delegates on Endcap. The journal lower-writer callback is still wired in `ace-lab/.../authority_composition.rb:52` to `endcap.authorize_service_update!`, which still opens with `service_journal!` → protected-mode enforcement. No operation was added to `OPERATIONS`; server routing unchanged.

**6. Fixture correction is legitimate.** Evidence chain in `.ace-local/test/reports/assign/`:
- `fbf0452e` (candidate pre-fix): 23 tests / 69 assertions / **23 setup ERRORs**, all `AttemptErrors::EvidenceUnavailable: canonical service evidence binding is incomplete` raised from `service_evidence.rb:77` (`ServiceEvidence#context` rescue) via `atomic_service_mutation_test.rb:37` — the fixture's `owner.context(binding)` with `operation="publish"` hits the publish branch (`record["operation"] == "publish" && record["dispatch_phase"] != "issued"` → `record.fetch("executor_process_binding")` → KeyError). The fixture never supplies publication dispatch/receiver facts. `service_evidence.rb` is untouched by this commit, so the unchanged base must fail identically (the referenced base run dd3bc3ed is not in this worktree, but the involved files are byte-identical pre-fix).
- `c9752c1d` (fixture changed, stub not yet): 1 ERROR `RuntimeError: wrong original operation` at the old stub — proves the assertion change is the mandatory lockstep counterpart, not an independent weakening.
- `fe2d7bf4` (both changed): 23 tests / 249 assertions / 0 failures.

No product guard weakened: the change is fixture-data + matching stub expectation only; `ServiceEvidence#context` publish validation, `publication_result!`, and publication flows remain covered by dedicated tests (`protected_publication_authority_test.rb`, `protected_publication_flow_test.rb` incl. replay counts/`already_issued`, `publication_composition_test.rb` incl. HITL principal binding) which passed in lab run `079d7b55` (24 tests / 186 assertions / 0 failures — verified report + raw output).

## Checks actually executed

- Read in full: `endcap_service_context.rb`, `fixed_service_lifecycle.rb`, `fixed_publication_lifecycle.rb`, `endcap_publication.rb`, `endcap_service_settlement.rb`, `service_evidence.rb` (context/challenge sections), `endcap.rb` (dispatch routing + primitives), `atomic_service_mutation_test.rb`, `endcap_service_replay_test.rb`, `authority_composition.rb`, `service_publication_binding.rb` (call sites), `service_publication_evidence.rb`.
- Greps: module includers, hook definitions (no duplicates/overrides), old filename references, `SERVICE_IDENTITY` external use, `authorize_service_update!` wiring, `mode: :protected` sites, `publication_result!` coverage.
- Report verification: `lab/079d7b55` (24/186/0/0) and `assign/fe2d7bf4` (23/249/0/0) plus failing runs `fbf0452e` (23/69/23 ERROR) and `c9752c1d` (1 ERROR) — report.md, summary.json and raw_output.txt all mutually consistent.

## Limitations

1. No shell/write tools in this session → could not re-run `bin/ace-test` myself and could not create `.ace-local/ei9-common-core-review/f6d6/report.md`; the verdict is delivered inline above. 2. Could not independently confirm worktree HEAD == f6d6f518 via git; relied on the provided diff matching the tree (it does, including the rename and both test-file hunks). 3. Base-commit failing run (dd3bc3ed) not present in this worktree; base equivalence established structurally (untouched `service_evidence.rb` + fixture change isolated to this commit). 4. Broader protected suites (e.g., `service_settlement_test.rb`, `historical_rotation_test.rb`, `service_pr_admission_test.rb`, which also call the moved API) were not executed here per the "no broad suite" instruction — their pass status is unverified beyond the two focused runs.
