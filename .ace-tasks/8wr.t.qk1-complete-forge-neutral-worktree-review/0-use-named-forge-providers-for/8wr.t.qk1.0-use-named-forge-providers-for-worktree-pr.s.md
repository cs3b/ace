---
id: 8wr.t.qk1.0
status: in-progress
priority: high
created_at: "2026-09-28 17:44:28"
estimate: TBD
dependencies: [8wk.t.l1e]
tags: [lab-readiness]
parent: 8wr.t.qk1
bundle:
  presets: [project]
  files: [.ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/8wr.t.qk1-complete-forge-neutral-worktree-review-and-task.s.md, .ace-tasks/_archive/8w/y/8wk.t.l1e-forge-neutral-git-core-with/8wk.t.l1e-forge-neutral-git-core-with-github-and.s.md, ace-git-worktree/lib/ace/git/worktree/commands/create_command.rb, ace-git-worktree/lib/ace/git/worktree/commands/cleanup_command.rb, ace-git/lib/ace/git/providers/base.rb, .ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/0-use-named-forge-providers-for/ux/usage.md]
  commands: []
needs_review: false
---

# Use named forge providers for worktree PR lifecycle

## Observable behavior

Input: an exact PR identifier or reviewed task and a selected forge. Process: worktree operations consume normalized provider evidence and preserve source/base provenance. Output: the correct local worktree and draft PR when requested, or an explicit failure without wrong-repository mutation. Cleanup previews distinguish confirmed remote state from unavailable proof.

## Public interfaces and consumers

- Existing `ace-git-worktree create --pr ID` and task creation retain their current switches and gain qk1 server selection. List/cleanup PR-aware paths share that selection; `cleanup --remote` identifies the Git remote, not a branch. `--no-pr` keeps task creation local/provider-free except separately requested push behavior.
- Add neutral `ace-git pr show ID`, `create --head REF --head-repo URL --base REF --expected-head SHA --title TEXT --body-file PATH [--draft]`, `update ID --expected-head SHA [--title TEXT] [--body-file PATH]`, `ready ID --expected-head SHA`, and `merge ID --expected-head SHA --method squash|merge|rebase`. All use qk1 selection and `--format json`; create defaults to draft, explicit ready is separate. No implicit merge method.
- Consumers are ace-git-worktree, qkb assignments/workflows, ace-review and task-local usage. Provider APIs expose these same PR lifecycle operations, with server from ResolvedServer; raw provider commands stay in adapters.
- PR evidence includes source repository URL, source branch/ref, base repository/ref and exact head so fork and canonical-repository PRs are both fetchable. The selected configured repository is the base; no automatic fork inference from author or username.
- Create proves the pushed head ref resolves to the supplied expected SHA and returns exact PR identity. Same base/head-repo/head-ref with one existing open PR returns that identity without duplicate creation; multiple matches are a conflict. If transport fails after mutation may have occurred, return unknown outcome and reconcile by exact identity before any repeat.
- PR merge requires provider-side expected-head enforcement. CLI performs no authority inference from credentials; workflow/service authorization is external. Changed head or unsupported merge method/precondition fails without merge.
- Existing `--dry-run` worktree creation may read provider evidence but creates no branch/worktree/PR. Cleanup stays report-only without existing apply+digest consent, retains dirty/in-use protections, and binds provider/server/PR/head to the approved report. Recompute before apply; changed proof invalidates consent. `--force` never overrides identity or missing proof.
- Local ancestry proof remains valid without remote evidence where current cleanup rules already permit it; failed PR proof can never be relabeled merged. No PR/open/closed-unmerged/merged/offline/auth/malformed are separate states. Unrelated historical refs and remote names are not cleanup candidates.

## Success criteria and verification

1. Create by PR and by task on GitHub/default Forgejo/named Forgejo yields exact head/provenance and optional draft PR. Test provider contracts plus temporary repositories, including fork and canonical head repositories.
2. Neutral create/show/update/ready/merge operations keep identity, classify failures and avoid duplicate creates. Test expected-head mismatch, unknown post-send outcome, conflicting matches and provider unsupported merge enforcement; none claims success.
3. Dry-run/no-pr/local-only paths perform no unintended provider mutation. Test no provider tooling and assert mutation runner call count zero.
4. Cleanup preview/apply preserves evidence and unrelated/dirty work. Test changed head/digest, no PR and provider failure; no approval from missing proof.
5. No direct Github PrFetcher, GitHub-only dependency or gh/fj parsing remains in worktree correctness paths; scan library, gemspec, command help and tests.

Run `ace-test ace-git all`, `ace-test ace-git-github all`, `ace-test ace-git-forgejo all`, `ace-test ace-git-worktree all`, then `ace-test-suite`. Record scenario evidence and exact review head for qkc and lab-overseer l2d.3.

## Shared defaults and authority

The qk1 parent defines selection, exact identity, failures and compatibility policy; its task-local `ux/usage.md` is part of this contract. Local-only operations never resolve a forge. No direct gh/fj parsing remains in consumers. Provider-specific execution belongs exclusively to ace-git-github/ace-git-forgejo. Missing required evidence cannot be replaced by a done flag, prose report or exit code 0. Executed tests and independent review of exact SHA are the delivery gate; CI status is advisory.

## Readiness and boundaries

This is a real implementation slice, advisory size: large. The current task creates specifications only. No deployment, production data mutation or release is authorized by this spec work. Implementation updates the affected API/config/CLI docs and package dependencies together, removing old surfaces rather than shipping aliases. No extra force mode may bypass identity/evidence checks. Review must verify all listed outcomes before promotion; no unresolved user decision remains.
