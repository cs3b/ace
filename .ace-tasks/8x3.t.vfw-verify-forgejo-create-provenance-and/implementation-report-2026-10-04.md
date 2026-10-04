# Forgejo create provenance implementation — 2026-10-04

Status: in-progress; source implementation ready for independent review. No merge, push, release or production writes.

## Reproductions

Before the fix, `bin/ace-test ace-git-forgejo test/contract/provider_pull_request_lifecycle_contract_test.rb` executed 18 tests / 65 assertions with precisely two new failures. A same-owner unrelated repository was accepted, and a read IOError after HTTP201 escaped as ProviderUnreachableError. Raw reports: `.ace-local/test/reports/git-forgejo/8x3vv4/`.

## Implementation

Preflight reads the selected repository and complete fork inventory, reproducing Forgejo's documented selector: same owner selects canonical repository; another owner selects a direct fork. A parent relationship alone is refused before POST on the supported Forgejo 8 resolver. Requested normalized URL must match that selection. Stable repository IDs bind both the accepted payload and authoritative single-PR readback. Both sides must prove source/destination refs, SHA, draft, open state and positive PR number. Every classified verification failure after acceptance becomes unknown outcome with sanitized operation identity, expected SHA/draft/known PR. No POST is retried.

Independent review corrected an initial current-branch source assumption against exact Forgejo v8.0.3 `routers/api/v1/repo/pull.go`: parseCompareInfo uses own-owner canonical or GetForkedRepo and returns404 for a missing direct fork. Parent-only selectors are now covered by a zero-POST refusal regression. Source runtime tested at Forgejo8.0.3+gitea-1.22.0; no minimum version change.

## Executed verification

- `bin/ace-test ace-git-forgejo all`: 168 tests /751 assertions, zero failures/errors. Latest report `.ace-local/test/reports/git-forgejo/8x3wlt/`.
- `bin/ace-test ace-git all`: 571 tests /1413 assertions, zero failures/errors. `.ace-local/test/reports/git/8x3w11/`.
- Public lifecycle unknown-outcome propagation addition: focused file 13 tests /39 assertions, zero failures/errors. `.ace-local/test/reports/git/8x3w3l/`.
- Shared receipt contract strengthened; `bin/ace-test ace-git-github all`: 92 tests /268 assertions, zero failures/errors. `.ace-local/test/reports/git-github/8x3w3m/`.
- `bin/ace-test-suite`: 49 packages passed; ace-assign hit the suite's120-second timeout. 9697 passed tests /28976 assertions /24 skips. Separate `bin/ace-test ace-assign all --timeout 300` completed782 tests /2938 assertions: zero assertion failures, one pre-existing CampaignReceiptTest Open3.capture3 timeout in ace-review evidence reading; report `.ace-local/test/reports/assign/8x3wcj/`.
- `bin/ace-lint ace-git-forgejo/test/e2e/TS-FORGEJO-001-pr-delivery/scenario.yml ace-git-forgejo/README.md`: passes; existing README style warnings retained. `git diff --check`: passes.

## Real disposable server probe

Container `ace-wave3-vfw`, loopback24427, Forgejo8.0.3. Disposable users `vfw-base` and `vfw-fork`; repository `vfw-base/base`, real fork `vfw-fork/base`, unrelated clone `vfw-fork/unrelated`. Real fork and unrelated source both had branch `feature` at `a1f13ee9e99c43d399f5773e1aa625b7a6600887`.

Source public `bin/ace-git pr create --server wave3-forgejo --head feature --base main --expected-head SHA --title "Wave3 selector probe" --head-repo URL --format json` executed from an isolated synthetic checkout:

1. Unrelated URL: exit1, JSON identity_mismatch, "Forgejo head selector does not select .../vfw-fork/unrelated; refusing create". Raw API open-PR inventory length0.
2. Real fork URL: exit0, created PR1; source `vfw-fork/base`, destination `vfw-base/base`, feature/main, exact SHA, draft true.
3. Same request replay: exit0, existing PR1; raw inventory length1.

Probe printed PASS; synthetic keys removed and container torn down with `docker rm -fv ace-wave3-vfw`. No production endpoint touched. Scenario TC001 now includes durable wrong-source setup/goals for reruns. Setup friction: migration from loopback is correctly blocked by default; explicitly enabled local-network migration only in the disposable container. An immediate admin invocation before server readiness failed; rerun after actual server readiness succeeded.

## Remaining gate

Independent review must approve the exact committed head. Task remains in-progress. Installed consumer acceptance is outside this provider scope. Response-loss cases use scripted IO as specified; no live proxy acceptance claim.
