# Selected-repository contract
1. Resolve provider through existing ace-git server selection for fixture server `lab-b`, then call `provider.pull_request(number: 7)` while cwd belongs to `lab-a`. Only lab-b is queried; normalized evidence refers to lab-b.
2. Call `provider.update_pull_request(number: 7, expected_head: sha, title: "Reviewed")` with a CLI that cannot target lab-b. Expect ProviderUnsupportedCapabilityError and zero mutation subprocesses. Do not instruct the caller to rely on changing cwd.
3. Fetch merged PR evidence for lab-b. A real merge SHA may feed cleanup; missing SHA preserves the checkout. A SHA copied from lab-a or inferred merely from the PR head is never accepted as merge proof. Equality with the head is valid if the exact PR's authoritative merge field itself reports that SHA, as in a fast-forward.

## Observed support (2026-09-29, see evidence/fj-capabilities.md)
- Scenarios 1–2 are enforced by the executor boundary: `-H <authority>` on
  every subprocess, qualified `owner/repo#N` / `-r owner/repo` targeting,
  target validation before any subprocess, and an observed-version gate
  (v0.6.0) that refuses unobserved CLI surfaces before any mutation.
- Scenario 3: fj v0.6.0 exposes **no** authoritative merge-commit field, so
  the Forgejo provider never supplies `merge_commit_sha`; merged PRs retain
  the checkout at the cleanup resolver (`merge_commit_unavailable`), and the
  resolver additionally requires evidence provenance (server, repository,
  branch, base) to agree with the selection before any merge proof.
- Read-only smoke against a real Forgejo server (codeberg.org) with the
  real v0.6.0 binary exercised view/commits/diff/search/issue/repo-view
  with the exact bound argv forms. The Lab-specific smoke test
  (`bin/ace-git pr show <PR> --server <NAME> --format json`) remains OPEN:
  the Lab API requires sign-in and no Lab credentials exist on the
  workstation (no `fj` binary installed locally).
