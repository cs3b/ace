# Cross-user services — draft usage

## Authorized call
Deployment starts `ace-lab service serve --service admin-ace` under its fixed executor account. A worker uses the existing `ace-lab service request --project ace --assignment assign-1 --attempt attempt-1 --operation setup-project --input request.json --authorization decision-1 --request-id request-1`. Expected: one authorized effect and a durable public receipt; no executor credentials returned.

## Duplicate and loss
Repeat exact request after client disconnect. Expected: stored outcome or uncertainty; no blind second effect. Changed input under request-1 refuses.

## Invalid authority
Wrong peer UID, stale decision, caller-selected sink, or writable trusted parent refuses before handler execution. `--dry-run` on request validates eligibility with no claim or credentials.

Exact protected assignment mapping and receipt authority configuration remain readiness-review items; this draft is not implementation-ready.
