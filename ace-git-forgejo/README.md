# ace-git-forgejo

Forgejo provider for the forge-neutral [`ace-git`](../ace-git) core.

This package owns **all** Forgejo-specific behavior for ACE:

- `fj` CLI invocation (with timeout handling and structured output)
- **Selected-repository binding**: every repository-scoped `fj` call is
  bound to the resolved server's exact host/owner/repository — `-H` plus
  qualified `owner/repo#N` object ids or `-r owner/repo` — never cwd,
  remotes, a default login, or user `fj` configuration. Malformed server
  URLs fail as `ConfigError` before any subprocess; operations whose argv
  form was never observed on a real `fj` refuse with
  `ProviderUnsupportedCapabilityError` before launch, and the installed
  `fj` version must be one of the observed versions (`v0.6.0`) to inherit
  the capability table.
- `fj` minimal-style output parsing and normalization, with returned
  identity validated against the selection (misrouted evidence raises
  `ProviderIdentityMismatchError` instead of being relabelled)
- `fj` authentication verification (`fj auth list`, compared exactly
  against the selected host authority)
- Forgejo-specific identifier formats (including `/pulls/N` web URLs)

It implements the provider contract defined by the core
(`Ace::Git::Providers::Base`) and registers itself under the `:forgejo`
provider type, so consumers resolve it through
`Ace::Git::Providers.for(server)` and read normalized evidence types
(`Ace::Git::ProviderPullRequest`, `Ace::Git::ProviderIssue`,
`Ace::Git::ProviderCheck`, `Ace::Git::ProviderRepository`).

Failures are classified with the shared taxonomy
(`ProviderCliMissingError`, `ProviderAuthenticationError`,
`ProviderUnreachableError`, `ProviderMalformedOutputError`,
`ProviderObjectNotFoundError`). Ad-hoc curl fallbacks are strictly
forbidden; there is no silent fallback of any kind.

## Supported operations (observed on forgejo-cli v0.6.0)

Through `fj` (observed on forgejo-cli v0.6.0): PR view/diff/head-commits,
PR search (all/open, client-side newest-first window — `fj` has no
`--limit`), issue view, actions tasks, repository view, version and
`auth list` probes. Through the repository-bound API v1: authoritative PR
reads, PR create (canonical and same-server fork heads, exact draft
state), edit, ready transitions, and expected-head-guarded merges — see
the delivery lifecycle section below. The per-surface capability evidence
and its provenance live in the `8wr.t.uj0` (`evidence/fj-capabilities.md`)
and `8x2.t.z78` (`capability-evidence-2026-10-04.md`) task folders.

Endpoint fidelity: `-H` carries the selected `scheme://authority` (fj
otherwise assumes HTTPS), and because fj v0.6.0 silently applies its
keys-file `aliases` map to `-H`, the provider read-only checks the
observed keys-file locations and refuses a repository command when an
alias redirects the selected host — never modifying user fj
configuration; an absent or unreadable keys file is allowed.

## PR delivery lifecycle (Forgejo API v1)

The delivery lifecycle — create (canonical and same-server fork sources,
exact draft state), mark-ready, and merge with a server-enforced
expected-head precondition — rides the repository-bound Forgejo REST API
v1 through the same selected host and `fj` token as the review transport.
The `fj` v0.6 CLI cannot encode a fork head, an explicit draft state, a
ready transition, or an atomic merge precondition, so those operations do
not approximate it with check-then-act sequencing.

Minimum supported server: **Forgejo 8.0** (the first line that both
enforces the documented `MergePullRequestOption.head_commit_id` merge
precondition server-side and reports the API `draft` field; the provider
probes `/api/v1/version` and refuses lifecycle mutations below the
floor). Official capability evidence lives in the
`8x2.t.z78` task folder (`capability-evidence-2026-10-04.md`).

Forgejo-specific conventions the provider translates:

- **Drafts**: the create/edit API forms have no writable draft field —
  a draft is a WIP-prefixed title (server defaults `WIP:`, `[WIP]`;
  compared case-insensitively). The server reports the computed boolean
  in the API `draft` response field, which this provider treats as the
  only draft truth on reads. Create with
  `draft: true` prefixes the title `WIP: `; `draft: false` refuses a
  WIP-prefixed title instead of silently publishing it as a draft. Ready
  strips one leading prefix and proves the resulting `draft: false` by
  read-back. A draft whose title carries no known prefix refuses before
  the mutation (the server likely uses configured prefixes).
- **Merge** sends the full expected SHA in `head_commit_id`; Forgejo
  re-resolves the head ref inside the merge and refuses with 409 when it
  moved. The provider classifies that as
  `ProviderExpectedHeadConflictError` and never pre-reads as a substitute
  guard. A 409 that reads back as already merged at the expected source
  SHA, with a merge commit, is reusable authoritative evidence.
- **Reconciliation**: a transport failure on any mutation raises
  `ProviderUnknownOutcomeError` carrying the exact identity; nothing is
  retried automatically. A duplicate-create 409 reconciles to the exact
  open match; mutation outcomes are proven by authoritative read-backs
  (head unchanged, requested state, merged evidence).

Identical lifecycle assertions run against every provider through the
shared `Ace::TestSupport::PullRequestLifecycleContract` parity suite.

Create preflight verifies the repository that Forgejo's `owner:branch` selector resolves, including direct forks and a fork's parent. Sharing an owner, branch or SHA does not establish source identity. An accepted create returns a receipt only when the response and authoritative read agree with the requested repository IDs, refs, SHA and draft state. A failed or contradictory verification stays `unknown_outcome`; reconcile by reading the exact identity before authorizing another mutation.
