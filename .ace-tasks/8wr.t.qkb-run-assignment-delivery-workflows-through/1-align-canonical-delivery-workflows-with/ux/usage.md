# Canonical delivery workflow — usage

## Fresh workflow lookup
`ace-nav resolve wfi://git/pr/create`
`ace-bundle wfi://git/pr/update`
Expected from a clean external directory after install: owning package artifacts resolve using final neutral source names. Source existence in checkout alone is insufficient.

## Remove old vocabulary
`ace-nav resolve wfi://github/pr/create`
Expected after final migration: unknown removed source; no alias or fallback.

## Delivery with advisory CI
Input: current exact SHA, executed tests, independent review and exact integration authority, with red CI.
Expected: report CI issue as advisory; CI alone does not block authorized merge. Missing test/review/current SHA still does.

## Separate privileged proposal
Input: a precise publication proposal with confirmed Telegram delivery and no reply for 16 hours.
Expected: qjz authorizes that operation if unchanged; service still enforces scope and technical/OTP requirements. Merge completion by itself grants none of it.

## Already authorized operation
Input: exact publication request with a valid Captain approval or matching scoped standing authorization.
Expected: consume that authorization without creating another proposal; enforce scope, test/review/current SHA and OTP gates. An approval scoped only to merge does not authorize publication.

## Missing or mismatched authorization
Input: a publication request with no valid authority, or only merge authority.
Expected: create the exact qjz proposal; confirmed delivery starts its 16-hour window. Do not execute before resolution, and do not weaken technical gates after it resolves.

## Protected role handoff

Load the final installed delivery workflow outside the checkout with a deployment-mapped protected assignment. A launcher reserves/binds the worker; an independent reviewer materializes and checks the exact candidate; the worker requests the fixed service through the public client. Expected: receiver/executor operate under their mapped UIDs and the returned status references canonical qjl evidence. A forged worker-local receipt or unavailable authority blocks, with no local fallback or repeated uncertain effect.

## Fixed authorized merge executor

The installed operation entry runs `ace-git service merge` with the receiver-owned envelope on stdin. Its input is `{target:{resource:PR_URL,artifact_digest:null},delivery:{forge_server:NAME,forge_default:false,pr_provenance:{mode:fork,head_repository_url:HEAD_REPO,head_ref:HEAD_REF,base_repository_url:BASE_REPO,base_ref:BASE_REF}},method:squash}`. The receiver's canonical candidate SHA and executor join remain authoritative. Expected: one exact neutral merge and an existing-format executor response referencing its fixed staged evidence artifact. A wrong head/PR/provenance/method refuses before mutation; lost/uncertain remote outcome creates no terminal success and never triggers a retry. This entry is not available as an unprivileged worker fallback.

## Draft protected request and asynchronous observation

Use `ace-lab service request --project PROJECT --assignment ASSIGNMENT --attempt ATTEMPT --mapping MAPPING --scope SCOPE --service RECEIVER --operation merge --candidate-head SHA --candidate-generation GENERATION --expected-generation AUTHORITY_GENERATION --input merge-input.json --authorization AUTHORIZATION --request-id REQUEST`. Retain AUTHORITY_GENERATION from the original canonical candidate/review/status response. Expected: the original authenticated claim reply plus complete non-secret selection, not a merge-success assertion; no caller-local coordinator, provider command or wait for execution. The existing five-second claim exchange is distinct from input preparation and original capability fetch. This command is a draft contract, not a delivered entry yet.

If the claim reply is lost, retain the same request and input/head/generation/target selectors. Use `ace-lab service status --request REQUEST --project PROJECT --assignment ASSIGNMENT --attempt ATTEMPT --mapping MAPPING --scope SCOPE --candidate-head SHA --candidate-generation GENERATION --input-digest SHA256 --target PR_URL`, with --artifact-digest only when the original target has one. Expected: exact read-only canonical status; uncertain remains uncertain, and only verified original completion/import/result reports succeeded. Do not refresh generation and resubmit to resolve uncertainty.

For a protected worker, missing mapping/service, unsafe input or --dry-run refuses without local dispatch. An unreadable/removed installed selection never enables ordinary mode. Genuine standalone request/status retain their existing semantics. These draft cases leave create/update/ready ordering and publication authority unchanged.
