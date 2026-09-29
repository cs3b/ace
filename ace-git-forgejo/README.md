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

PR view/diff/head-commits, PR search (all/open, client-side newest-first
window — `fj` has no `--limit`), PR create (same-repository head only),
PR edit title/body, issue view, actions tasks, repository view, version
and `auth list` probes. `fj` v0.6.0 exposes no draft-to-ready command, no
atomic expected-head merge, and no authoritative merge-commit field, so
`ready_pull_request`/`merge_pull_request` refuse as unsupported
capabilities and `merge_commit_sha` stays empty — worktree cleanup
conservatively retains Forgejo checkouts until `fj` exposes that field.
The capability evidence and its provenance live in the
`8wr.t.uj0` task folder (`evidence/fj-capabilities.md`).

Endpoint fidelity: `-H` carries the selected `scheme://authority` (fj
otherwise assumes HTTPS), and because fj v0.6.0 silently applies its
keys-file `aliases` map to `-H`, the provider read-only checks the
observed keys-file locations and refuses a repository command when an
alias redirects the selected host — never modifying user fj
configuration; an absent or unreadable keys file is allowed.

