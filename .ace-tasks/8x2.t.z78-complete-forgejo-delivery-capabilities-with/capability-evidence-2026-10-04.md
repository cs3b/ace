# Forgejo capability evidence — 8x2.t.z78, 2026-10-04

Official-source evidence for the delivery lifecycle contract (create/ready/merge).
All sources are the Forgejo project's own release branches and swagger spec on
codeberg.org, inspected 2026-10-04. No server claim is made beyond what the
sources below prove; the disposable-server scenario (step_06) proves behavior.

## 1. Atomic expected-head merge — `head_commit_id`

- `MergePullRequestOption` (swagger `templates/swagger/v1_json.tmpl`) defines
  `head_commit_id` (string) alongside `Do`, `MergeTitleField`,
  `MergeMessageField`, `delete_branch_after_merge`, `force_merge`,
  `merge_when_checks_succeed`. Present in release branches v7.0/forgejo
  through v12.0/forgejo and the forgejo dev branch.
- `POST /repos/{owner}/{repo}/pulls/{index}/merge` passes `form.HeadCommitID`
  into `pull_service.Merge(..., expectedHeadCommitID, ...)`
  (routers/api/v1/repo/pull.go).
- Server-side enforcement (services/pull/merge_prepare.go,
  `createTemporaryRepoForMerge`): the head ref is fetched into a temporary
  clone and re-resolved (`show-ref --hash refs/heads/tracking`) at merge
  processing time; a mismatch returns `models.ErrSHADoesNotMatch{GivenSHA,
  CurrentSHA}`. Identical code on v7.0 and dev branches.
- API error mapping: `models.IsErrSHADoesNotMatch(err)` → HTTP 409 "Merge"
  "head out of date" (routers/api/v1/repo/pull.go). The check reads the git
  ref inside the merge transaction — a pre-read guard is not used.
- Other 409 causes on the merge endpoint: `ErrPullRequestHasMerged` (already
  merged), `ErrMergeConflicts`/`ErrRebaseConflicts`/`ErrUnrelatedHistories`
  (serialized conflict objects), `git.IsErrPushOutOfDate`. Disabled merge
  style → 405 "Invalid merge style".

## 2. Draft state — WIP title prefix (no stored draft flag)

- The API `PullRequest.draft` field is computed: `Draft:
  pr.IsWorkInProgress(ctx)` (services/convert/pull.go) — i.e. the issue title
  has a work-in-progress prefix.
- `HasWorkInProgressPrefix` matches `setting.Repository.PullRequest.
  WorkInProgressPrefixes`; default `["WIP:", "[WIP]"]`
  (modules/setting/repository.go, case-insensitive).
- `CreatePullRequestOption` and `EditPullRequestOption` expose **no** draft
  field on any inspected branch. Draft-on-create is therefore expressed by a
  WIP-prefixed title; ready-for-review is expressed by PATCHing the title
  without the prefix (what the web UI's "ready for review" button does).
- Draft truth on reads must come from the API's `draft` field (server's own
  configured prefixes), not from client-side prefix guessing.

## 3. Fork heads on create — `head: "<owner>:<branch>"`

- `parseCompareInfo` (routers/api/v1/repo/pull.go): `form.Head` accepts
  `<branch>` (same repository) or `<head-owner>:<branch>` (same-server fork;
  headUser must own a fork of the base repo, or the base repo is itself a
  fork of a repository owned by headUser). Cross-host heads are impossible by
  construction.
- Duplicate create: an open PR with the same head/base returns HTTP 409
  `ErrPullRequestAlreadyExists` (GetUnmergedPullRequest branch).

## 4. Merge evidence on reads

- `PullRequest` response carries `merged` (HasMerged), `merged_at`, and
  `merge_commit_sha` (MergedCommitID) — authoritative merged-state proof.
- `head`/`base` are `PRBranchInfo` objects (`label` = "owner:branch" for
  forks, `ref`, `sha`, `repo.full_name`) — exact provenance per read.

## 5. Provider transport conclusion

- The `fj` v0.6.0 CLI cannot encode fork heads, draft state, ready
  transitions, or the atomic merge precondition (RepositoryBinding.FORMS).
  The lifecycle therefore uses the repository-bound JSON API v1 — the same
  provider-owned transport precedent as `HttpClient`/`IssueApi`.
- Minimum supported server/transport combination implemented and
  documented: Forgejo v8.0+ REST API v1. `head_commit_id` is documented
  and enforced from v7.0, but the API `draft` field is only computed from
  the WIP title from v8.0 (`Draft: pr.IsWorkInProgress(ctx)` in
  services/convert/pull.go with a non-omitempty bool; v7.0's
  ToAPIPullRequest never assigns Draft — verified on release branches
  v7.0 through v12.0 and the live 7.0.16 preflight instance, where both
  list and single-PR payloads omit `draft`). The lifecycle proves draft
  state, so v8.0 is the first line that can honor the full contract.
  `/api/v1/version` is probed and validated before enabling lifecycle
  mutations (fail closed on mismatch).

## 6. Runtime proof (recorded in the step_06 report)

The disposable-server scenario (TS-FORGEJO-001) proves draft behavior, fork
encoding, and atomic merge against a live instance; sanitized outcome
evidence is recorded in the task report. Swagger/source evidence above does
not substitute for that runtime proof.
