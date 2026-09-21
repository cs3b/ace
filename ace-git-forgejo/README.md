# ace-git-forgejo

Forgejo provider for the forge-neutral [`ace-git`](../ace-git) core.

This package owns **all** Forgejo-specific behavior for ACE:

- `fj` CLI invocation (with timeout handling and structured output)
- `fj` minimal-style output parsing and normalization
- `fj` authentication verification (`fj auth list` per configured server host)
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
