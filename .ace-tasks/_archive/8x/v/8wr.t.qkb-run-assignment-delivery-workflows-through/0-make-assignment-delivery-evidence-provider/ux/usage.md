# Assignment provider parameters — usage

## Canonical provenance
```yaml
forge_server: forgejo-lab
pr_provenance:
  mode: canonical
  head_repository_url: https://forge.example/team/repo
  head_ref: feature
  base_repository_url: https://forge.example/team/repo
  base_ref: main
```
Expected: resolve named base once; record qjl attempt-bound draft PR and exact pushed head. No credentials appear in these parameters.

## Wrong canonical origin
Input: mode=canonical with different head/base repositories.
Expected: validation error before remote mutation; the driver does not guess fork mode.

## Unknown remote write
Input: provider timeout after PR creation.
Expected: retain unknown outcome, reconcile exact source/base identity before repeat; adopt one existing PR, block on none/ambiguous evidence. No blind retry of merge/publication.
