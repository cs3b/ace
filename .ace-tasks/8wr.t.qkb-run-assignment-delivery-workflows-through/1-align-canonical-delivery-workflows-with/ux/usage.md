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
