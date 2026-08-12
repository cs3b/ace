---
id: 8vb.t.vyq.1
status: draft
priority: medium
created_at: "2026-08-12 21:18:45"
estimate: TBD
dependencies: [8vb.t.vyq.0]
tags: [worktree, cleanup, github, squash-merge]
parent: 8vb.t.vyq
bundle:
  presets: [project]
  files: [ace-git/lib/ace/git/molecules/pr_metadata_fetcher.rb, ace-git/lib/ace/git/molecules/gh_cli_executor.rb, ace-git-worktree/lib/ace/git/worktree/molecules/worktree_lister.rb, ace-git-worktree/lib/ace/git/worktree/models/worktree_info.rb, ace-git/test/fast/molecules/pr_metadata_fetcher_test.rb, ace-git/test/fast/molecules/gh_cli_executor_test.rb, ace-git-worktree/test/fast/molecules/worktree_lister_test.rb, ace-git-worktree/test/feat/worktree_manager_contract_test.rb]
  commands: [ace-git pr --format json, ace-test ace-git all, ace-test ace-git-worktree all]
---

# Classify merged refs through bounded GitHub evidence

## Behavioral Specification

### User Experience

- **Input:** A cleanup report contains refs that are not ancestors of the target but may belong to squash-merged pull requests.
- **Process:** ACE requests only PR evidence associated with the exact ref/branch relationship and tests exact merged-head or stable patch equivalence against the configured target.
- **Output:** Each ref gains a named proof or a conservative retention reason; provider loss never broadens cleanup eligibility.

### Expected Behavior

- Exact merged-PR-head proof requires the candidate tip to equal the PR's recorded head, the PR to be merged into the configured target/base, and the resulting merge commit to be reachable from the target.
- Stable patch-equivalence proof is bounded to the candidate's exact associated PR, compares the complete candidate series with the PR's first-parent merged change, and requires matching path, object type, and mode inventory.
- Stable comparison may normalize patch identifiers to tolerate ordinary squash/whitespace rewriting, but never ignores path/type/mode differences or missing commits.
- ACE never scans unrelated PRs for a coincidentally matching patch.
- Unavailable, unauthenticated, rate-limited, incomplete, or ambiguous GitHub evidence falls back to ancestry-only reporting.

### Interface Contract

Each candidate classification records:

```text
proof: ancestry | exact_merged_pr_head | stable_patch_equivalence | none
pr: <number or null>
candidate_head: <sha>
merged_head: <sha or null>
merge_commit: <sha or null>
target_reachable: <boolean|unknown>
path_type_mode_match: <boolean|unknown>
provider_status: available|offline|unavailable|ambiguous
retention_reason: <code or null>
```

Error Handling:

- Open, closed-unmerged, wrong-base, unreachable, head-advanced, missing-commit, or ambiguous PRs remain unproven.
- Patch calculation or object-metadata failure retains the candidate and records which evidence was unavailable.
- Provider output is treated as evidence, never as authority to delete independently of target reachability and inventory checks.

Edge Cases:

- A branch advanced after its PR merged does not satisfy exact-head proof and its aggregate patch must not hide the extra commits.
- Rename, symlink, executable-bit, submodule, or file-type changes must match exactly in the stable inventory.
- Multiple PR associations are ambiguous unless the exact branch/head/base relationship uniquely identifies one.

## Success Criteria

- Exact-head proof accepts only the recorded merged head for the configured reachable target.
- Stable proof is limited to the uniquely associated PR and matches the complete path/type/mode inventory.
- Unrelated PRs are never queried as patch candidates.
- Advanced branches, wrong-base or unreachable merges, incomplete objects, and ambiguous associations are retained.
- Provider unavailability yields the same ancestry-only classifications as explicit offline mode.
- Proof details are sufficient to explain and reproduce each decision.

## Validation Questions

- None open. The two bounded GitHub proofs and ancestry-only fallback are fixed by issue #312.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Squash-merged branches can be recognized without weakening cleanup safety
- **Advisory size:** Large
- **Context dependencies:** Normalized cleanup report, GitHub PR metadata, Git object and patch evidence

## Verification Plan

### Unit/Component Validation

- Verify exact-head/base/reachability logic, stable series comparison, path/type/mode inventory, and provider fallback.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Exercise merge commits, squash merges, advanced heads, wrong bases, multiple associations, symlinks/modes, and offline/provider-failure paths.

### Failure/Invalid Path Validation

- Missing objects, malformed provider data, rate limits, ambiguity, and patch collisions must retain candidates and avoid unrelated PR searches.

### Verification Commands

- `ace-test ace-git all`
- `ace-test ace-git-worktree all`
- `ace-test-suite --target fast`

## Objective

Add narrowly scoped squash-merge proof to cleanup classification without treating broad patch similarity as deletion evidence.

## Scope of Work

- Exact merged-PR-head proof
- Bounded stable patch-equivalence proof
- Path/type/mode and target-reachability guards
- Ancestry-only fallback and explainable evidence

## Deliverables

### Behavioral Specifications

- GitHub proof requirements and retention classifications

### Validation Artifacts

- Exact, squash, advanced, ambiguous, object-mode, and provider-failure scenarios

## Out of Scope

- Cross-repository or unrelated-PR patch discovery
- Plan application (`8vb.t.vyq.2`)

## References

- https://github.com/cs3b/ace/issues/312
- Parent `8vb.t.vyq`
- Dependency `8vb.t.vyq.0`
- `../ux-usage.md`
