# Canonical restart discovery — draft usage

## Restart without local state

`ace-overseer status --project ace --format json`

Expected: literal visible installed mappings, complete/partial project visibility and owner-authenticated accepted assignment/task/attempt rows with their selected revisions. Canonical state and original terminal/release selectors remain visible after launcher restart. Detailed current liveness may remain unknown; overlapping launcher/supervisor UID never substitutes for the original process.

## Advance between pages

Continue the authority `assignment_inventory` request with its original `journal_commit` and returned tuple cursor.

Expected: old pages retain the same canonical revision and definition. A later detailed observation carries its own revision. Revocation or missing retained prefix refuses; discard incomplete results instead of reporting an empty inventory or combining revisions.

## Unavailable authority or malformed proof

Run the same status command when one selected authority is unreachable or original release evidence is corrupt.

Expected: that mapping is explicitly unavailable, while successful mappings remain attributable. No completed/released claim is fabricated, no native input occurs, and no private directory or labd fallback is attempted. Full usage is completed with implemented source and executed checks.
