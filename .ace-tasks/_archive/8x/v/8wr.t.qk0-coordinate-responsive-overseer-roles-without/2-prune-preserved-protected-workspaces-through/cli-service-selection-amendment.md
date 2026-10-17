# Protected prune CLI service selection

This amendment makes the existing preview-result FILE consumer concrete. It does not create authorization or expand the canonical service input.

Protected mode requires `--project`, `--agent`, `--assignment`, and `--attempt` naming the exact sealed target, and `--request FILE`. The separate maintenance tuple remains in FILE. The CLI selects the existing trusted ServicePolicy operation `prune-preserved-workspace` for the maintenance project, uses its literal service_id, and requires that receiver in the maintenance mapping's installed project. Missing, foreign, or ambiguous selection refuses; there is no local-prune fallback.

Dry-run consumes only the closed preview intent, calls the actual ProtectedServiceClient preview method, and writes its complete bounded result as JSON. It requires neither authorization nor mutation and rejects effect-only options.

Apply consumes that same complete preview-result JSON, requires `--yes`, explicit `--authorization REF`, `--mutation ID`, and positive integer `--expected-generation`. The authorization reference is passed unchanged to the existing ServicePolicy owner, which verifies its exact request binding; the CLI never infers or issues a grant. The stable mutation ID is also the service request_id. Receiver request_service uses that original mutation ID; its maintained begin_dispatch and complete_service IDs remain SHA-256 of `begin:ID` and `complete:ID`. No new replay ledger is introduced.

The CLI reconstructs the preview intent from the complete result and authenticates its existing intent_digest and closed correlations, then derives unchanged ServiceInput. Candidate head/generation come only from persisted maintenance_context. Changed bytes under the same mutation refuse through existing immutable mutation/input binding; unavailable or unconfirmed claim is reported as such, never retried automatically. Status uses the same file/request identity and existing read-only service_status, never submit.

`--expected-generation` is the current authority mutation generation, distinct from persisted maintenance_context.candidate_generation; it cannot override the candidate selection in FILE.

Current visibility selection names the maintenance mapping; the retired target need not remain in successor topology. Status uses FILE selectors exclusively and rejects project/agent/assignment/attempt flags rather than silently ignoring mismatched targets.

Independent root contract review APPROVE on 2026-10-07 for this explicit CLI adoption, including the generation distinction. Physical Installer preview/removal/inspection delivery remains separate.
