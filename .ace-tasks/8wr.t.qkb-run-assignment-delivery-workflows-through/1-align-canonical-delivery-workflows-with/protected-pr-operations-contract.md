# Protected PR operations — current source contract

This extends the existing merge request/receiver/authority contract according to
the Captain's 2026-10-08 decision. It does not close qkb.1 or claim installed Lab
acceptance. The final integrated independent review is still required.

- [x] Public protected request forwards `create`, `update`, `ready`, `merge` to the
  original receiver; each retains its own operation-scoped authorization and
  stable request mutation identity. No caller-local provider fallback.
- [x] Fixed receiver handlers `ace-git service create/update/ready/merge` use the
  same original claimed envelope, executor identity and private staging root.
  They accept no operation override or local flags.
- [x] Create targets the selected base repository, other operations the exact PR
  URL. Create/update input is exactly `{target,delivery,title,body}`, ready
  `{target,delivery}`, merge `{target,delivery,method}`. Delivery must be normalized
  with complete source/base provenance. All inputs retain their canonical digest.
- [x] Draft create/update may run before review. Update requires an open draft;
  stale candidate, wrong receiver or revoked authorization still refuse.
- [x] Forge-specific draft title encoding is owned by the provider's pure
  `pull_request_title(title:, draft:)` contract. Original title/body remain in the
  accepted input; create/update read-back must match the encoded title and exact
  body. Forgejo's WIP encoding is preserved during update.
- [x] One verified operation publishes fixed immutable `pr-result.txt` and the
  existing response shape. Canonical completion/import also publishes its exact
  delivery event; the worker verifies the original imported evidence read-only.
  Lost reply, changed head or unverifiable outcome produces no success/retry.
- [ ] Bind the ready/merge gate to completed R2 required-check evidence as well
  as its current independent approval. An existing standalone review proves
  review only; it is not a substitute for executed test checks.
- [ ] Final coherent source/workflow integration and one independent review.
- [ ] Real installed task execution: owned solely by lab-config:gad.2.

## Executed local evidence

Remote transport and process/deployment observations are controlled boundaries;
these are source tests, not installed proofs.

| Check | Actual result | Retained report |
|---|---|---|
| Fixed merge plus actual GitHub/Forgejo draft/create/update/ready | 15 tests, 327 assertions, PASS | `e647cd00-337b-4696-81c4-2295324e0d1f` |
| Canonical result input binding plus authority draft/review gates | 9 tests, 72 assertions, PASS | `1b211666-22a0-466d-ab3d-72a9cab054bb` |
| Public original request adapter | 9 tests, 79 assertions, PASS | `3fe5cd21-efe5-4e7c-94b0-e5c7e80d0f4e` |
| Existing scoped policy/authorization | 7 tests, 40 assertions, PASS | `4e7c3f80-bd26-4d8a-b1db-473ef352ccae` |
| Existing Forgejo lifecycle contract | 24 tests, 226 assertions, PASS | `bf5661fa-d4d4-4463-bc77-8ccaa9c34e9a` |

Subsequent checks after tightening provider-owned draft update preservation:
fixed PR producer/merge **15 tests / 391 assertions PASS**
(`4b7d8ad6-0f82-446e-8456-f8db964573d5`); Forgejo provider/lifecycle
**50 tests / 316 assertions PASS**
(`4e8be418-a18f-4266-8954-1bba3a04e66f`). Ordinary title updates preserve
the original draft state, so removing a WIP prefix cannot substitute for the
reviewed ready operation. A contradictory draft-state read-back is uncertain.
The first added fixture used a nonexistent receipt member and was corrected to
the public `pull_request` member; the old lifecycle fixture expected an edit to
remove the WIP prefix and was corrected to the preserved draft contract. Those
earlier failed reports remain retained, not counted as passes.

An additional `ace-git all` run was interrupted after more than six minutes
around its unchanged core stage. It is **not** a full-suite PASS. Its completed
earlier groups do not replace final verification of the integrated revision.
The original process sample is `/tmp/ace-pr-suite-36785.sample.txt`.

Current uncommitted source hashes are retained under
`.ace-local/task/8wr.t.qkb.1/protected-pr-operations/manifest.json`; changes after
that manifest require a fresh final review/verification selection.
