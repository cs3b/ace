# Candidate view review disposition

Both retained reports came from the configured `role:review-default` Pi provider
(`zai/glm-5.3`, finish `stop`). Raw report/metadata bytes are preserved with
SHA256 inventory. Neither reviewer executed tests. The first review of 5488862bc
noticed a temporary traversal correction in its working-tree context; it is not
an exact clean final-source verdict. The separate clean 1cb4010be review approved
with MED followups and no critical/high findings. Its inspection statements do
not establish Linux execution. Root source-only acceptance is still pending.

## Verified followups

- **MED observable traversal:** 1cb4010be uses `Find.find(ignore_error: false)` and
  typed refusal. The Linux fixture's nonroot observer case is available for
  actual RED/GREEN, not yet claimed executed.
- **MED failure cleanup / existing root:** only a newly created pre-child view
  whose root remains the exact dev/inode/root UID is removed on failure. EEXIST
  refuses and preserves the existing output. Canonical accepted bytes remain
  in Assign; completed source/results are never removed by this path.
- **MED filesystem classification:** Owner source observation errors become
  InvalidConfigurationError/ReceiptRejected; materializer errors become a
  security refusal after safe fresh-view cleanup. Missing generated config has
  an actual filesystem regression.
- **MED production admission coverage:** a new real Assign journal/Unix/native-
  controlled Lab fixture exercises production CommandOwnerAdmission policy,
  runtime/compiler, claim/download, held reader lifetime, canonical origin,
  immutable source/config and historical checks. Its named installed-root and
  native/launcher observations are controlled; no child/test success is invented.
- **MED package release notes:** Assign and Lab Unreleased notes added; package
  versions deliberately remain for the coordinated final cut.
- **LOW source inventory:** preflight counts source files and ancestor directories
  before source writes. Source 20,000 and generated Git administration 1,000
  budgets remain distinct. The shared byte budget belongs to root's separately
  evidenced real ACE size/performance work.
- **LOW argv:** compiler rejects actual argv beyond the canonical 2,048-byte
  proof bound before admission.
- **LOW CLI parsing/errors:** existing retained-input parser deliberately shares
  bounded regular/no-follow/duplicate-key validation and typed refusal; no
  second parser or permissive fallback is added. The current CLI native hint
  uses the actual Herdr `HERDR_PANE` variable (38a88dc50).
- **LOW repeated transfer descriptor / reference cost:** retain the existing
  canonical download framing and full current-origin/byte validation. Redundant
  caller descriptors do not supply authority; removing validation for speed
  without whole-candidate measurements would weaken the contract.

## Historical proof refinement

The campaign consumer may select exact earlier accepted candidate proof using a
source-only historical reader at the current prefix. Default current selection,
wire operations and merge stay latest-only. Test evidence compares retained
admitted native binding to the genuine canonical active producer rather than
re-observing a requester CLI which may already have exited. Positive historical
consumption, stale current-merge refusal, unrelated candidate-proof refusal and
revoked-origin refusal are covered by actual canonical integration tests.

No full ei9 outcome, installed dynamic pipeline, maintained runtime packaging,
publication or taskless secret completion is claimed here. The domain maintained
runtime preparation task remains externally approval-blocked; this work does not
retry or replace it.
