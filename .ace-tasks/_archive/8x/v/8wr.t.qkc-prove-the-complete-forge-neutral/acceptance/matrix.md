# Installed acceptance matrix — source handoff

Status: **all installed rows unexecuted**. This is a source checkpoint, not a Lab pass. lab-config:8wl.t.gad.2 `forge-matrix` owns the one installed run and receipt; l2d.8 reads that receipt without rerunning. Source assets are maintained under `ace-assign/test/e2e/TS-DELIVERY-*`. They use the existing `ace-test-e2e` runner/verifier and do not add a CLI, simulator, account installer or model driver.

## Inputs and operation boundary

The operator completes `scope.template.json` outside source assets, supplies its absolute path as `ACE_QKC_SCOPE_FILE`, and selects **local-only**, **github**, **forgejo-default** or **forgejo-named**. Null values are deliberately non-runnable and must refuse, never silently pick a configured endpoint. Supply one coherent manifest with every package version/source SHA/digest, qk1/qkb/qjl/R2/R3/xz9 source receipts and gad.8/gad.b installation/handler receipts bound to its digest. The operator supplies configuration, credentials by protected external reference, scoped disposable repositories/forks/PRs/issues, one actual assignment and its attempt-owned native sessions. Secrets are absent from scope/report files.

The selection receipt enumerates allowed endpoint/server/provider/repository/ref/object identities and permitted operations. Local-only scope has no provider config, CLI, credentials or network. Remote scopes name each server explicitly; default Forgejo also proves explicit default resolution. Named Forgejo is a distinct server and includes read-only query from a second checkout. No production target, repo-root endpoint, new deployment or cleanup outside that receipt is permitted. gad.8 supplies actual distinct principals, runtime target identities and topology; gad.b supplies real scoped handlers and operation-specific observations. Runner setup only copies this non-secret input; operation setup remains the installed owner’s responsibility.

`fault_controls` enumerates each approved disposable fault, producer operation, bounded deadline, effect observation, stop condition and restoration owner. No available fault mechanism means unexecuted required variant. A generic fixture cannot replace a real installed operation. Scenarios share the supplied original assignment and its immutable candidate, with separate owned attempts where the canonical recipe requires them. They do not create three fake Labs.

## Execution through existing tooling

Run only in gad.2's installed environment from the supplied fresh external checkout, using installed `ace-test-e2e ace-assign TS-DELIVERY-001`, `TS-DELIVERY-002` and `TS-DELIVERY-003` with independent verifier enabled by the documented runner option. Select a provider column in the completed scope for each required provider run. TS-DELIVERY-003 observes the same real assignment's distinct-account/native paths; it does not redeploy them per provider. Within an ACE source checkout, command references use `bin/ace-*`; installed external cwd uses installed binaries and must prove their manifest resolution. `--dry-run` validates discovery/contracts only and cannot mark an installed row passed.

For every expanded matrix row, gad.2 records: scenario/TC/variant, manifest ID/digest, selected server/provider/repository, task/assignment/attempt/candidate/generation, expected and observed state, exact argv/cwd, exit status, actual product artifact paths/digests, imported operation/result receipt and claim references, actor UIDs/OS birth and review reference. Preserve product-reported paths and raw harness observations; no hand-written success report substitutes for them. Evidence rows below are templates with no fabricated command or result. Fill exact commands only after actual execution. Changed head/manifest invalidates affected evidence; retain earlier failure and explicit retest links. Missing/skipped required rows prevent acceptance. Optional provider unsupported features and local remote-only cells are explicit N/A, never PASS.

## Required row expansion

Each remote column expands its positive cells through canonical and fork provenance, named/default/remote resolution, and all refusal variants below. Separate evidence records are required for every variant; a family-level PASS cannot hide missing variants.

| Family / executable asset | Local-only | GitHub | Default Forgejo | Named Forgejo | Expected / evidence requirement | Installed result |
|---|---|---|---|---|---|---|
| Git/task/review isolation; 001/TC-001 | required | required | required | required | Exact identity, offline local isolation and second-checkout named-server proof | UNEXECUTED; no exact command/exit/artifact/review yet |
| Worktree/PR provenance; 001/TC-002 | local branch/task in TC-001; remote PR N/A | required | required | required | Preview/apply; canonical and fork checkout/draft exact head/base | UNEXECUTED; no exact command/exit/artifact/review yet |
| Review lifecycle; 001/TC-002 | local subject/dry-run in TC-001; post N/A | required | required | required | Diff/comments/checks, executed exact-head independent verdict, opt-in post, optional unsupported classification | UNEXECUTED; no exact command/exit/artifact/review yet |
| Task issues; 001/TC-003 | CRUD/hierarchy required; remote issue N/A | required | required | required | Link/repeat/sync/close/reopen/clear, pending recovery and ownership refusal | UNEXECUTED; no exact command/exit/artifact/review yet |
| Assignment delivery; 001/TC-004 | local recipe required; remote delivery N/A | required | required | required | Draft/review/ready/authorized merge, qjl evidence and restart reconciliation | UNEXECUTED; no exact command/exit/artifact/review yet |
| Workflow installation; 002/TC-001 | required | required | required | required | Fresh external cwd installed final sources; canonical recipe, role handoffs, merge/release authority separation | UNEXECUTED; no exact command/exit/artifact/review yet |
| R2/R3; 002/TC-002 | required for actual campaign | required for actual campaign | required for actual campaign | required for actual campaign | Effective policy/binding, discovery/delivery/infra caps, escalation and restart without duplicate repair | UNEXECUTED; no exact command/exit/artifact/review yet |
| Protected route; 003/TC-001 | same actual assignment; provider-independent | same actual assignment; provider-independent | same actual assignment; provider-independent | same actual assignment; provider-independent | xz9 and gad.8/gad.b manifest match, distinct UIDs, canonical import/effect count and no-effect/uncertain negatives | UNEXECUTED; no exact command/exit/artifact/review yet |

## Mandatory negative variants

| Variant IDs | Applies to | Required observation |
|---|---|---|
| unknown-server, unknown-provider, invalid-default, ambiguous-remote, mismatched-url-remote, missing-binary, auth-denial, offline, malformed-output, absent-object | Every remote column, 001/TC-001 | Classified refusal, exact target retained, no alternate provider/effect |
| head-change | Every remote column, 001/TC-002 and TC-004 | Old verdict/tests/PR receipt cannot authorize changed candidate |
| lost-create, lost-update, lost-ready, lost-merge, restart | Every remote column, 001/TC-004 | Reconcile original exact intent; one observed effect, no automatic resend |
| lost-link, lost-sync, lost-clear, issue-ownership-conflict | Every remote column, 001/TC-003 | Exact pending original issue identity and recoverable state; conflict refuses |
| merge-no-expected-head | Every remote column, 001/TC-004 | Required merge fails if provider lacks server-side expected-head enforcement |
| ci-failure, tests-failure, reviewer-rejection | Every remote column, 001/TC-004 | CI advisory; actual tests/reviewer failures block |
| policy-conflict, discovery-cap, delivery-cap, infra-exhaustion, completed-stage-restart, lost-review-reply | Actual installed review campaign, 002/TC-002 | R2/R3 limits and retained escalation history; no extra automatic review/repair |
| duplicate-service, lost-service-reply, service-restart, definite-no-effect, uncertain-effect | Actual protected route, 003/TC-001 | One effect; original executor inspection for no-effect; unresolved scope retained otherwise |
| worker-local-success, mutable-ref, same-uid, journal-injection, forged-receipt | Actual protected route, 003/TC-001 | Reject before authority import; no shared journal mutation |

## Source verification and open producers

Existing controlled tests cover provider IO and real temporary Git, qjl delivery reconciliation, canonical result import and R2/R3 convergence. They supplement installed success and are not installed evidence. The message-read proof goals TC-002/003 were removed, not passed or skipped. The retained scoped-effect goal is TC-001; its decision record identifies maintained source checks.

The first observational task run belongs to gad.2: existing ace-llm worker in Herdr/tmux, selected live panel/process, output/result and stop behavior. No dedicated app-server, signed read receipt, additional observation service or cache of terminal truth is required. Read/capture directly when needed.

Open installed prerequisites are tracked in `producer-gaps.md`. No matrix row can pass from an unimplemented producer or a textual recipe. qkc remains pending source review/checkpoint until executed deterministic checks, full coupling classification and the final combined independent review are retained. No task-done, merge or publication occurs here.
