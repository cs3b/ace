# Ordinary LifecycleExclusion owner repair

Source scope: repository selection, strict retained removed-marker reads, nofollow/nonblocking regular single-link lock admission, partial multi-open unwind and durable marker publication. CACHE_BASE no longer selects repository lifecycle storage; explicit and implicit repository resolution share the actual Git common directory, including linked worktrees. Explicit root injection remains supported. This is ordinary owner correctness, not delivered protected provisioning or creator lifetime adoption.

Executed controlled source tests:

- Final lifecycle_exclusion_test.rb: 18 tests / 71 assertions PASS, 792.9ms; report ac17d216-3c33-45ce-9025-f478a6bf167c. Includes explicit/implicit repository identity under unrelated CACHE_BASE, corrupt/duplicate/misbound/symlink markers, restart fences, hardlink lock rejection, partial-open closure and file/directory fsync failures. A single-close correction prevents rejected lock validation from masking typed refusal with an already-closed IO error.
- Ordinary prune_preservation_test.rb: 10 tests / 67 assertions PASS, 6.14s; report 6eada5fe-7a69-41d6-a6f6-23557c334641. This run follows repository-selection changes and precedes only the rejected-lock single-close correction, which the final fast target covers.
- Earlier final fast receipt f684d2d9-66cb-4919-b07c-a2e2b6f99c0a was 18/68 PASS; earlier prune e5b131fd-e6eb-4de8-897e-2b96ba8feec4 was 10/67 PASS. They do not substitute for the final changed-root coverage.
- Retained initial failure 44855223: test expected the macOS temporary alias rather than Git's canonical /private path. The expectation now uses actual canonical path; no source fallback was introduced.

No installed/root/native/systemd/process-identity probes. No timeout or cleanup-policy relaxation. Ordinary storage is not a protected authority proof: readonly provisioned roots, exact original resource observation, authority control-key creation and PreparedWorker lifetime joins remain required by lifecycle-exclusion-source-amendment.md. No child or family closure is asserted.
