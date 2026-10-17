# Cross-user services — draft usage

## Deployment and authoritative attempt origin

Deployment starts `ace-lab authority serve --authority project-ace` under the fixed assignment owner, then `ace-lab service serve --service admin-ace` under the fixed executor. The launcher reserves/binds a managed worker through the protected authority API, imports its candidate to an immutable protected snapshot and obtains an independent exact-snapshot review. The protected-authority-contract.md defines mapping/API fields. These are proposed interfaces, not commands delivered by current main.

## One effect

Worker invokes existing `ace-lab service request --project ace --assignment assign-1 --attempt attempt-1 --operation setup-project --input request.json --authorization decision-1 --request-id request-1`. Expected: one configured effect and qjl durable public receipt. The receiver authenticates the worker; only its configured executor peer can complete the authority claim. Worker never rewrites canonical evidence or receives secrets.

## Replay and refusal

Same request after lost response returns its canonical result/uncertainty without redispatch. Changed input conflicts. Worker-local refs, forged review/receipt paths, wrong peer or writable trust ancestor refuses before effects. `--dry-run` checks current eligibility without claim or import. Native domain operation proof remains gad.b.

## Private review/executor access and completion

Worker submit_candidate uploads bounded self-contained Git bundle bytes; assigned reviewer/executor export_candidate fetches exact head/tree/digest into their own private scratch. Nobody traverses the authority 0700 root. Receiver begins one durable dispatch ticket, invokes v1 handler preserving worker caller_uid, imports staged artifact bytes atomically to qjl, and reports the canonical result. Lost start reply stays uncertain; expired lease prohibits new invocation but not authenticated completion of prior observed outcome. Fresh no-effect completion requires the current owner-issued failure challenge, not old files or caller timestamps.

Current lab_setup_project is local-only; gad.b must migrate its producer/envelope/sink/usage/tests before this flow counts as real setup-project acceptance. The generic fixture is not a substitute.


## Authority command scopes

Full-service deployment uses `ace-lab authority serve --authority ID`; it composes one Assign authority server, 09j launch origin and Endcap with the same Lab-owned policy validator used by service execution. `ace-assign authority serve --authority ID` supplies standalone launch-only scope. Installed composition must match the command; the project never has parallel authority endpoints or journals. A full-service configuration refuses a launch-only command instead of accepting an incomplete server. Commands and actual installed proof remain implementation deliverables; this readiness amendment performs no deployment.
