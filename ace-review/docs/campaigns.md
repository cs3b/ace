# Durable review campaigns

A campaign preserves verified review history across commits, squash, rebase and process restarts. Its search counters describe completed rounds; current acceptance also requires current-head evidence, passing required checks and an independent reviewer approval. Campaign commands execute no models, commits, merges, publications or deployments.

## Start and inspect

Use a frozen requirements document containing behavioral requirements only. Do not supply mutable task status, implementation plans or completion reports as requirements. Place input artifacts under `.ace-local/` so they do not change the candidate worktree.

```sh
mkdir -p .ace-local/campaign-input
# Run inside the candidate repository. This writes a local discovery identity.
python3 - <<'PY'
import json, pathlib
root = pathlib.Path.cwd().resolve()
out = root / '.ace-local/campaign-input'
(out / 'subject.json').write_text(json.dumps({
    'repository': 'local:' + str(root), 'local_candidate_id': 'candidate-a'
}))
(out / 'requirements.md').write_text('Reject invalid input and preserve accepted history.\n')
PY
ace-review campaign start --subject .ace-local/campaign-input/subject.json \
  --contract .ace-local/campaign-input/requirements.md --profile delivery --dry-run
ace-review campaign start --subject .ace-local/campaign-input/subject.json \
  --contract .ace-local/campaign-input/requirements.md --profile delivery
ace-review campaign status CAMPAIGN_ID --format json
```

Expected: dry-run emits `dry_run: true` without creating campaign state. Start emits a `campaign_id`, the requirements content digest and a policy snapshot. Initial status has zero completed rounds and `accepted: false`. In this repository use `bin/ace-review` for every invocation.

For an existing GitHub subject use `{"repository":"https://github.com/owner/repo","pr":"owner/repo#42"}`. The identity format is provider-neutral; collection currently supports the existing local and GitHub sources. An unavailable forge adapter is an explicit error. Local repository identity is `local:` followed by its real checkout path; different local candidates use different `local_candidate_id` values.

## Pin and collect a round

Before collection, record a pin with empty sessions and dispositions. `attempt_id` identifies one immutable recording submission; `round_id` identifies the logical round. Use a new attempt ID for partial progress and completion. Required scopes must equal the frozen policy scopes. Each scope identity pins the review preset and explicit subject selectors before collection. Collection must use those exact selectors.

```json
{
  "attempt_id": "pin-r1",
  "round_id": "r1",
  "head": "EXACT_REVIEWED_HEAD_SHA",
  "base": "EXACT_REVIEWED_BASE_SHA",
  "required_scopes": ["full"],
  "scope_identity": {"full": {"preset":"code-valid","subjects":["diff:EXACT_BASE_SHA..EXACT_HEAD_SHA"]}},
  "sessions": [],
  "dispositions": []
}
```

Replace the SHA placeholders with exact Git revisions. For local campaigns, the first round fixes the base; a new head does not change that base. For PR scopes pin `subjects: ["pr:owner/repo#42"]`; PR collection uses the fetched PR head/base. Candidate code must be committed before campaign collection or acceptance.

```sh
ace-review campaign record-round CAMPAIGN_ID --input .ace-local/campaign-input/pin.json
ace-review --preset code-valid --subject diff:BASE..HEAD --auto-execute \
  --campaign CAMPAIGN_ID --campaign-round r1 --campaign-scope full
```

Expected: the pin reports `recorded_complete: false`, then the existing review runner writes its ordinary session artifacts with the pinned campaign/contract/scope/head/base binding. Other review invocations, repeated model/subject/evidence flags and feedback commands retain their normal behavior. A zero-model no-op or failed/incomplete report cannot complete a campaign round.

Verify findings with `ace-review-feedback verify --valid|--invalid --research ... --session SESSION`, and resolve repairs with `ace-review-feedback resolve --resolution ... --session SESSION`. Every feedback item must have substantive verification research; resolved items also need a resolution.

## Record coverage and dispositions

Submit a new attempt ID with all reports needed for the round. Metadata, reports and prompts must retain their execution checksums. An artifact reference always has repository-relative `path` and SHA-256 of the exact file bytes.

```json
{
  "attempt_id": "complete-r1",
  "round_id": "r1",
  "head": "EXACT_REVIEWED_HEAD_SHA",
  "base": "EXACT_REVIEWED_BASE_SHA",
  "required_scopes": ["full"],
  "scope_identity": {"full": {"preset":"code-valid","subjects":["diff:EXACT_BASE_SHA..EXACT_HEAD_SHA"]}},
  "sessions": [{"scope":"full","metadata":{
    "path":".ace-local/review/sessions/review-SESSION/metadata.yml",
    "sha256":"METADATA_SHA256"
  }}],
  "dispositions": [{
    "source_id":".ace-local/review/sessions/review-SESSION#FEEDBACK_ID",
    "reason":"Verified claim against the requirements and regression test."
  }]
}
```

Use `dispositions: []` for a session with no findings. Every source finding needs exactly one disposition. Source status derives the disposition: pending/skip stays open, done is resolved, invalid is invalid. A confirmed High/Critical makes the round non-clean even if already resolved. The same rule applies to a High/Critical observed during partial coverage. Earlier findings remain open when absent from later reports.

`finding_id` optionally links an assessment to an existing canonical finding. Reopening requires `disposition: "reopened"` and a new verified source occurrence; terminal feedback files are never forced back to pending. Corrections are appended to campaign history. A linked successor contract retains predecessor findings for explicit disposition.

```sh
ace-review campaign record-round CAMPAIGN_ID --input .ace-local/campaign-input/complete.json
ace-review campaign status CAMPAIGN_ID --format json
```

Expected: complete coverage increments `completed_rounds` once. Identical replay returns `replayed: true`; conflicting content for the same attempt or completed round fails nonzero. Partial scope coverage persists as an attempt without incrementing completed or clean counters. Reusing a report from an already counted round is rejected. Provider calls, report files, recording attempts and completed rounds are separate counters.

## Current approval and finish

Delivery defaults are three completed rounds and two consecutive rounds without confirmed High/Critical. The default scope is `full` and required check name is `tests`. Configure `campaign.profiles.delivery` in `.ace/review/config.yml`, or supply `start --policy FILE` with exactly `revision`, `minimum_rounds`, `clean_rounds`, `required_scopes`, `required_checks`. The campaign freezes that revision and policy. R1 does not implement discovery profiles, round caps, automatic retries or escalation.

The final round may reference an explicit approval artifact with `approval: {"path": ..., "sha256": ...}`. An approval is a verified local assessment of executed reports, not assignment approval. It must contain:

```json
{
  "producer":"IMPLEMENTER_ACTOR",
  "reviewer":"ACTUAL_EXECUTED_REVIEWER_MODEL",
  "verdict":"approved",
  "head":"EXACT_REVIEWED_HEAD_SHA",
  "base":"EXACT_REVIEWED_BASE_SHA",
  "contract_identity":"FROZEN_CONTRACT_SHA256",
  "required_scopes":["full"],
  "reports":[{"path":"SESSION/review-report-MODEL.md","sha256":"REPORT_SHA256"}],
  "checks":[{"name":"tests","verdict":"passed","receipt":{
    "attempt_id":"ACCEPTED_CHECK_ATTEMPT_ID","digest":"ACCEPTED_RECEIPT_SHA256"
  }}]
}
```

Producer and reviewer must differ. Reviewer identity must match the actual completed execution model in the referenced session; approvals must cover every required scope. Required checks refer to a succeeded execution receipt already accepted by the ace-assign coordinator. Run the check under an existing assignment attempt and submit its attributable result, current head, check outcomes and checksummed artifacts through `ace-assign attempt finish`. Use the accepted attempt ID and receipt digest here. A self-authored check JSON file is insufficient. Campaign recording and acceptance consult the read-only `ace-assign attempt evidence --attempt ID --receipt-digest DIGEST --format json` boundary, which revalidates current head and source artifacts against accepted history. Retain `ace-assign` alongside `ace-review` for this qjl evidence capability; unavailable authority blocks acceptance explicitly. Campaign commands never run the check for you or create a second execution journal. Authenticated producer/reviewer attribution and execution acceptance remain owned by ace-assign.

```sh
ace-review campaign finish CAMPAIGN_ID --format json
```

Expected: exit zero and `accepted: true` only with convergence, no unresolved High/Critical, intact current-head/base evidence, independent approval and all passing required checks. Otherwise finish emits parseable JSON with `accepted: false` and reasons and exits nonzero. Save the JSON result using your calling process's file API; the CLI does not publish it.

## Consume through an assignment

Submit a normal succeeded review receipt through `ace-assign attempt finish`. Add this optional reference and include the identical result artifact in the receipt's verified `artifacts` array:

```json
{"campaign":{"id":"CAMPAIGN_ID","result":{
  "path":".ace-local/campaign-input/result.json","sha256":"RESULT_SHA256"
}}}
```

The receipt retains ordinary attempt/assignment/project/scope binding, producer, current head, reviewer approval and executed checks. Its producer/reviewer actors must match the campaign assessment. The trusted coordinator rechecks live campaign state and rejects stale, blocked, mismatched or dry-run results. Accepting evidence records a separate journal commit without moving the candidate branch.

## Restart, contract changes and failures

Campaign authority lives in `.ace-local/review/campaigns/`; retain this directory and source evidence across process/context restarts. Records are serialized with a lock and replaced atomically with checksums. Losing/corrupting evidence from any retained counted round or assessment makes it unavailable; historical counters remain diagnostic and do not manufacture acceptance. These records are durable local artifacts, not a second assignment execution journal.

Start with changed requirements and `--reason "Requirement X changed"` to create a linked successor; `--predecessor ID` selects it explicitly. Same subject/requirements/policy starts reuse one campaign, including concurrently. Conflicting policy for an existing contract fails rather than rewriting history.

`status` is read-only and exits successfully for known blocked/stale state. Unknown/corrupt campaigns fail. `start`, `record-round` and `finish` support `--dry-run` without state writes. JSON remains parseable with `--quiet`/`--verbose`; `--format text` supplies compact presentation. No force option bypasses evidence.

Missing report: restore exact retained artifacts or collect a new pinned round. Incomplete scope: use a new attempt ID for the same pinned round with complete coverage. Changed head/base: preserve history and collect current evidence. Invalid/mixed identity: correct the explicit input; no source is silently redirected. Conflicting replay: keep the accepted submission and use a new logical round for new evidence.
