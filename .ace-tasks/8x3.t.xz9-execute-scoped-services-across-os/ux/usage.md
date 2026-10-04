# Cross-user services — draft usage

## Deployment and authoritative attempt origin

Deployment starts `ace-assign authority serve --authority project-ace` under the fixed assignment owner, then `ace-lab service serve --service admin-ace` under the fixed executor. The launcher reserves/binds a managed worker through the protected authority API, imports its candidate to an immutable protected snapshot and obtains an independent exact-snapshot review. The protected-authority-contract.md defines mapping/API fields. These are proposed interfaces, not commands delivered by current main.

## One effect

Worker invokes existing `ace-lab service request --project ace --assignment assign-1 --attempt attempt-1 --operation setup-project --input request.json --authorization decision-1 --request-id request-1`. Expected: one configured effect and qjl durable public receipt. The receiver authenticates the worker; only its configured executor peer can complete the authority claim. Worker never rewrites canonical evidence or receives secrets.

## Replay and refusal

Same request after lost response returns its canonical result/uncertainty without redispatch. Changed input conflicts. Worker-local refs, forged review/receipt paths, wrong peer or writable trust ancestor refuses before effects. `--dry-run` checks current eligibility without claim or import. Native domain operation proof remains gad.b.
