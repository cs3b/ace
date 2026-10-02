---
id: 8wr.t.qk1.1
status: in-progress
priority: high
created_at: "2026-09-28 17:44:28"
estimate: TBD
dependencies: [8wr.t.qk1.0, 8wr.t.uj0]
tags: [lab-readiness]
parent: 8wr.t.qk1
bundle:
  presets: [project]
  files: [.ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/8wr.t.qk1-complete-forge-neutral-worktree-review-and-task.s.md, ace-review/lib/ace/review/cli/commands/review.rb, ace-review/lib/ace/review/molecules/gh_pr_comment_fetcher.rb, ace-review/lib/ace/review/molecules/gh_comment_poster.rb, ace-review/lib/ace/review/molecules/gh_comment_resolver.rb, ace-review/lib/ace/review/organisms/review_manager.rb, .ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/1-use-named-forge-providers-for/ux/usage.md]
  commands: []
needs_review: false
---

# Use named forge providers for review lifecycle

## Observable behavior

A reviewer supplies a PR and obtains exact-head diff/comment/check evidence and a trustworthy review verdict on either provider. Provider failure, failed collection and failed synthesis remain non-approval, distinct from a valid empty diff or no comments.

## Interface contract

- Existing `ace-review --pr ID --preset NAME` accepts shared qk1 selection; local subjects remain provider-free. Replace `--gh-timeout` with `--provider-timeout SECONDS`; do not retain an alias. Existing post-comment/pr-comments/dry-run behavior applies to both providers.
- Input, saved session and posted result retain resolved server/repository/PR/head. Fetch head before gathering and after collection; any change invalidates the collection and verdict. Post/comment mutation rechecks expected head; mismatch posts nothing. Dry-run may prepare/read but executes no LLM review and posts nothing.
- Provider core/adapters gain normalized PR comment/review retrieval, comment create/update and thread resolution capabilities as required by existing review features. Each comment retains server/object, provider comment ID, author, body, URL, optional file/line/head and resolution state. Provider absence of a feature yields explicit unsupported capability; it is never marked resolved or treated as empty evidence. Do not emulate a resolved thread with an unrelated comment.
- Review tools call provider-neutral capabilities instead of gh comment fetcher/poster/resolver directly. Common available capabilities must work on both providers; true provider-specific features advertise unsupported behavior and cannot be required by common delivery workflows.
- Posting is opt-in as today; retrieving comments is read-only. Post-send timeout returns an unknown outcome with correlation context. A repeat reconciles the existing exact session/PR comment before creating another; no automatic duplicate post.
- Existing real presets remain discoverable from the shipped catalog; no invented `code-pr` preset. Missing preset, server ambiguity, malformed provider payload, empty synthesis or subprocess failure is nonzero/non-approval. CI check states are preserved as advisory evidence; failed CI alone cannot override executed tests plus independent exact-head review policy.

## Success criteria and verification

1. GitHub/default Forgejo/named Forgejo produce equivalent common diff/comment/review evidence with exact identity. Contract fixtures cover no comments and valid empty diff distinctly from failure.
2. Moved heads at collection or posting cannot produce an applicable verdict/post. Controlled concurrent update tests assert invalidation and zero mutation on mismatch.
3. Provider missing/auth/offline/malformed and synthesis failure stay classified and non-approval. Tests assert no empty-success or fallback provider.
4. Post-comment repeats reconcile the same session; unsupported thread resolution reports unsupported rather than success. Test timeout-after-send and duplicate outcomes.
5. Local reviews and dry-run require no remote provider unless a PR source was explicitly requested. Scan source/help/docs/gemspec for removed GitHub-only correctness paths and old timeout flag.

Run `ace-test ace-review all` and all changed ace-git/provider package suites, then `ace-test-suite`. Independent review binds the exact tested SHA. qkc owns real endpoint matrix; local l2d.4 consumes the receipt.

## Shared defaults and authority

The qk1 parent defines selection, exact identity, failures and compatibility policy; its task-local `ux/usage.md` is part of this contract. Local-only operations never resolve a forge. No direct gh/fj parsing remains in consumers. Provider-specific execution belongs exclusively to ace-git-github/ace-git-forgejo. Missing required evidence cannot be replaced by a done flag, prose report or exit code 0. Executed tests and independent review of exact SHA are the delivery gate; CI status is advisory.

## Readiness and boundaries

This is a real implementation slice, advisory size: large. The current task creates specifications only. No deployment, production data mutation or release is authorized by this spec work. Implementation updates the affected API/config/CLI docs and package dependencies together, removing old surfaces rather than shipping aliases. No extra force mode may bypass identity/evidence checks. Review must verify all listed outcomes before promotion; no unresolved user decision remains.
