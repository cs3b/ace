# Task report -- 8x2.t.z78, 2026-10-04

## Delivered

Complete Forgejo PR delivery lifecycle behind the existing `ace-git pr`
public surface, on the repository-bound Forgejo API v1:

- **Create** with canonical and same-server fork heads (documented

  `owner:branch` API form), exact draft state, one-PR replay
  idempotency, duplicate-create race reconciliation, and cross-host
  refusal before any request.

- **Ready** via the forge's own convention (WIP title prefix strip),

  already-ready idempotency, stale-head conflict, and read-back proof
  of `draft: false` at the unchanged head.

- **Merge** with the server-enforced `head_commit_id` atomic

  precondition -- no pre-read substitute guard -- proven by merged state
  plus merge commit at the expected source SHA; already-merged results
  are reusable only with that authoritative evidence; disabled methods
  and transient mergeable-check refusals are classified distinctly.

- **Unknown outcomes**: transport failure on any mutation raises

  `ProviderUnknownOutcomeError` with the exact reconciliation identity;
  nothing retries automatically. PR identity reads moved to a single
  authoritative API GET (head provenance, draft, merge evidence).

- Transport: Faraday (ADR-010), retries limited to safe GETs, no

  redirect following, token never in messages; lifecycle mutations gated
  on a `/api/v1/version` capability probe that fails closed.

## Minimum supported server: Forgejo 8.0 (corrected from 7.0)

`head_commit_id` is documented from v7.0, but the API `draft` field is
only computed from the WIP title from v8.0 (`Draft:
pr.IsWorkInProgress(ctx)`; v7.0's `ToAPIPullRequest` never assigns it).
Proven three ways: release-branch source (v7.0 through v12.0), the
official swagger, and the live preflight -- Forgejo 7.0.16 omitted
`draft` from both list and single-PR payloads while 8.0.3 always reports
the boolean. See `capability-evidence-2026-10-04.md` for the full
official-source citations.

## Runtime acceptance (SC1–SC5)

Disposable-server e2e `TS-FORGEJO-001-pr-delivery` against Forgejo
**8.0.3+gitea-1.22.0** (containerized, torn down after the run):
**16/16 goals PASS** (report: `.ace-local/test-e2e/8x33ilb-git-forgejo-ts001-reports/report.md`).
Sanitized outcomes:

- Canonical draft create `idempotency: created` → replay `existing`

  (one PR); same-server fork create with fork `head_repository`
  provenance; cross-host head refused with `unsupported_capability` and
  zero wrong-repository writes; draft:false vs WIP-title conflict.

- Ready on the exact head, replay idempotent, stale head →

  `expected_head_conflict` with the PR unharmed.

- Merge: draft-merge refusal (`unsupported_capability`, work in

  progress); raw-API merge with a wrong `head_commit_id` → HTTP 409
  `head out of date` (server-side atomicity) and the provider maps the
  same refusal to `expected_head_conflict`; squash, merge, and rebase
  methods each merged with merge-commit proof at the recorded branch
  SHA; identical replay returned the same authoritative merge receipt.
  A transient mergeable-computing 405 ("try again later") was recorded
  before a successful attempt -- classified `unreachable` (no mutation,
  caller may repeat), never a false receipt.

- Response loss: missing token → `authentication` (no token material in

  messages); stopped server → parseable `unreachable`; after recovery,
  reconciliation proved one outcome (exactly one open fork PR, no
  duplicates); read-only paths mutated nothing.

Residual gap, recorded honestly: a mid-flight drop of an
already-accepted mutation response (network cut between send and
read-back of a successful write) is covered by the scripted contract
suite (no auto-repeat, reconcile-by-readback) but not reproduced live --
it requires an intercepting proxy between provider and server. The
server-side refusal and reconciliation halves of that path are proven
live above.

Unit/contract verification: ace-git-forgejo 159 tests (including the
shared `PullRequestLifecycleContract` parity suite with
`ready_supported?`/`merge_supported?` true), ace-git 560 tests, full
`ace-test-suite` green (32,576 assertions), `ace-lint` clean on the
touched docs.

## Versions

- ace-git-forgejo 0.5.0 → **0.6.0** (delivery lifecycle; new faraday +

  faraday-retry dependencies)

- ace-git 0.27.0 → **0.28.0** (merge-proof receipts, JSON error

  categories)

## Live-preflight catches fixed before delivery

The disposable-server preflight caught and fixed four defects the
scripted suite could not see: `faraday-retry` must be declared and
required (Faraday 2.x split), the retry option is `methods:` (not
`retry_methods:`), Forgejo 8.0 returns 201 for the title PATCH
(accept any 2xx), and repeat merges of already-merged PRs must return
the authoritative receipt instead of refusing.
