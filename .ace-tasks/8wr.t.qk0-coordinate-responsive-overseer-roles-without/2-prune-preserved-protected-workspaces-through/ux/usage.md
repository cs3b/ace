# Protected physical workspace cleanup — draft usage

## Preview accepted obsolete work

`ace-overseer prune --project ace --agent old-builder --assignment ASSIGNMENT --attempt ATTEMPT --request prune-preview-intent.json --dry-run`

The dry-run FILE is the closed preview intent `{schema,maintenance,target,publication,destinations}` defined in [the reviewed physical inspection amendment](../0-authenticate-fixed-cleanup-owner-invocation/physical-inspection-owner-amendment-candidate.md). It omits preservation, artifact_digest and caller-selected candidate head/generation. The bounded public response includes exact authenticated maintenance_context, selected target/publication and computed preservation selectors. The CLI validates and retains that complete response to construct the separate apply FILE; preview creates no dispatch grant.

Expected: exact workspace/accepted head and original terminal/release/preservation selectors or explicit blockers. Slice retirement and disposable pane/cache cleanup are separate outcomes; durable journal/history/receipts remain retained.

## Apply through the authorized owner

`ace-overseer prune --project ace --agent old-builder --assignment ASSIGNMENT --attempt ATTEMPT --request prune-request.json --yes --mutation prune-001 --expected-generation 7`

The apply FILE is the complete bounded preview-result response defined by the amendment, including maintenance_context. The CLI validates its closed schema and exact target/publication/maintenance correlation, extracts the existing canonical service input `{schema,maintenance,target,publication,preservation}` and uses the persisted maintenance_context head/generation in the request. It never refreshes these selectors. Existing accepted review and service authorization are still required.

Expected draft contract: the request names a separate authorized maintenance/service attempt with generation 7, while the CLI names the sealed target. The trusted installer must already have completed successor publication excluding this workspace. The fixed operation then reacquires complete affected-scope locks, verifies original proofs and preservation, and removes the exact obsolete object. Current/candidate descriptor roots, uncertain writers, changed head or missing authorization remain protected. The receipt survives outside the target and is imported only after lock release. No delivered cleanup service is claimed before independent review and implementation.

## Lost confirmation

`ace-overseer prune --status --request prune-request.json --mutation prune-001`

Expected: existing receipt/status reconciliation, never blind repeated deletion or a new maintenance identity. Changed input under the same ID refuses. Unrelated scopes and original evidence remain intact.
