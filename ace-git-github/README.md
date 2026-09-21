# ace-git-github

GitHub provider for the forge-neutral [`ace-git`](../ace-git) core.

This package owns **all** GitHub-specific behavior for ACE:

- `gh` CLI invocation (with timeout handling and structured output)
- `gh` output parsing and normalization
- `gh` authentication verification
- GitHub-specific identifier formats (including `github.com` PR URLs)

It implements the provider contract defined by the core
(`Ace::Git::Providers::Base`) and registers itself under the `:github`
provider type, so consumers resolve it through
`Ace::Git::Providers.for(server)` and read normalized evidence types
(`Ace::Git::ProviderPullRequest`, `Ace::Git::ProviderIssue`,
`Ace::Git::ProviderCheck`, `Ace::Git::ProviderRepository`).

Failures are classified with the shared taxonomy
(`ProviderCliMissingError`, `ProviderAuthenticationError`,
`ProviderUnreachableError`, `ProviderMalformedOutputError`,
`ProviderObjectNotFoundError`). There is no silent fallback.
