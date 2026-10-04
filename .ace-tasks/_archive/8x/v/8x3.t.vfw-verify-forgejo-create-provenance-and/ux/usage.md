# Exact Forgejo create outcome -- acceptance scenarios

Public API spelling below is the existing provider interface consumed by ace-git's lifecycle; configured server/repository selection is established before these calls.

1. Call `provider.create_pull_request(head_repository_url: fork_url, head_ref: "feature", base_ref: "main", expected_head: sha, title: "Change", draft: true)` for the selected repository's verified same-server fork. Receive one creation receipt whose PR source/destination/ref/SHA/draft all agree. Repeating the same request reuses that exact PR.
2. Supply `head_repository_url: "https://forge.example/owner/unrelated"` while that owner has a different actual fork with the same branch and SHA. The provider refuses before POST; it must not silently create from the actual fork or accept its receipt.
3. The create POST is accepted but verification GET fails, or returns a different head repository/ref. Receive ProviderUnknownOutcomeError with exact non-secret identity. The caller keeps the attempt uncertain and reconciles by read; it sends no second mutation without established safe authorization/outcome. A unique full-identity result can be adopted; absent, ambiguous or mismatching evidence cannot complete delivery.
