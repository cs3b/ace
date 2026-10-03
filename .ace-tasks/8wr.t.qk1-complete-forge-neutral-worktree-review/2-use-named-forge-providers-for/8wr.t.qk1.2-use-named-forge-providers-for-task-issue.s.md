---
id: 8wr.t.qk1.2
status: done
priority: high
created_at: "2026-09-28 17:44:28"
estimate: TBD
dependencies: [8wr.t.qk1.0, 8wr.t.uj0]
tags: [lab-readiness]
parent: 8wr.t.qk1
bundle:
  presets: [project]
  files: [.ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/8wr.t.qk1-complete-forge-neutral-worktree-review-and-task.s.md, ace-task/lib/ace/task/cli/commands/issue_sync.rb, ace-task/lib/ace/task/cli/commands/issue_link.rb, ace-task/lib/ace/task/molecules/issue_link.rb, ace-task/lib/ace/task/organisms/task_manager.rb, ace-git/lib/ace/git/organisms/issue_tracking.rb, .ace-tasks/8wr.t.qk1-complete-forge-neutral-worktree-review/2-use-named-forge-providers-for/ux/usage.md]
  commands: []
needs_review: false
worktree:
  branch: qk1.2-use-named-forge-providers-for-task-issue-synchronization
  path: .ace-wt/ace-t.qk1.2
  created_at: "2026-10-02 00:19:46"
  updated_at: "2026-10-02 00:19:46"
  target_branch: main
---

# Use named forge providers for task issue synchronization

## Observable behavior

Local task lifecycle works offline. A task can be associated with one exact issue on a named forge and synchronize its tracked status without selecting another server or mutating an unrelated issue. This is the successor to current github_issue/github_sync_pending behavior, not a compatibility wrapper.

## Public contract

- `ace-task create TITLE --issue NUMBER_OR_URL [--server NAME|--default-server]` links one issue. `ace-task issue-sync REF|--all|--pending` replaces github-sync. `ace-task update REF --set remote_issue.number=N` is not a partial retargeting mechanism: link changes use `ace-task issue-link REF --issue NUMBER_OR_URL [selection]`; `ace-task issue-link REF --clear` removes the association after reconciling its owned remote tracking artifacts.
- Store a single `remote_issue` mapping containing `server_name`, `provider`, `repository_url`, `number`, `url`. It is resolved and validated as one identity; partial mappings fail validation. `issue_sync_pending` marks deferred synchronization and retains that same exact identity. Remove github_issue/github_sync_pending and GitHub-named CLI/API entrypoints rather than aliases or automatic conversion.
- Shared qk1 server selection applies when creating the link. Later sync resolves the stored identity and rejects changed repository/provider under that server name; it never uses a newly changed default. No selection flags are needed to replay persisted links. Same exact link is idempotent; link to a different issue while already linked is a conflict until explicit clear succeeds.
- Explicit new link validation requires reachable authoritative issue evidence and checks existing ownership before changing local metadata. A conflicting owner fails with no local or remote change. Never create an unvalidated offline link. Existing linked local task updates remain successful offline, retain pending sync plus classified warning, and never pretend remote success.
- Issue sync preserves the existing one-task ownership contract and ACE sticky marker/label behavior through a provider-neutral service. Statuses done/cancelled/skipped close the owned issue; draft/pending/in-progress/blocked reopen it. Only ACE-owned tracking blocks/labels are updated; unrelated issue body/comments/labels remain intact.
- Clear removes only the task's owned tracking artifacts; it does not change issue state as a side effect. If cleanup fails or its outcome is uncertain, keep link/pending state and return nonzero; do not lose the recovery identity. Explicit re-link then has a clean starting point.
- Explicit issue-sync returns nonzero if any requested issue failed or remains unresolved, with per-task exact identity and outcome. `--all` and `--pending` are mutually exclusive and cannot combine with REF. Empty pending set succeeds with zero counts. Bulk sync continues independent tasks and reports partial failures; no fallback server or silent skipped success.
- Provider APIs own issue comments, labels and state updates needed for tracking; core task semantics remain forge-neutral. Reconciliation uses the existing sticky marker and exact task identity to avoid duplicate tracking comments after unknown send outcome. No uncontrolled retry of non-idempotent mutations.

## Success criteria and verification

1. Local create/show/update/hierarchy without links require no forge tooling/config/network. Test complete absence of provider dependencies from local path.
2. Link, repeated same link, sync, terminal close, reopen and clear work on GitHub/default Forgejo/named Forgejo while preserving unrelated content. Provider contract tests and controlled-IO feature tests cover each.
3. Unknown server, invalid number/URL, changed server identity, partial mapping, ownership conflict and attempted replacement fail before unintended mutation. Tests cover URL+server mismatch and changed default.
4. Offline existing local edits persist with pending evidence; explicit sync failure is nonzero, recoverable and never wrong-server. Test partial bulk failure and empty pending set.
5. Timeout after remote update reconciles sticky/state evidence without duplicate ownership entries. Clear failure retains link for recovery. Scan CLI/metadata validators/docs/handbook for obsolete GitHub-only interfaces and update authored active records that use them.

Run `ace-test ace-task all`, all changed ace-git/provider suites, then `ace-test-suite`; include independent verdict and exact SHA for qkc and l2d.5. No compatibility migration or unrelated historical archive rewrite is part of this task.

## Shared defaults and authority

The qk1 parent defines selection, exact identity, failures and compatibility policy; its task-local `ux/usage.md` is part of this contract. Local-only operations never resolve a forge. No direct gh/fj parsing remains in consumers. Provider-specific execution belongs exclusively to ace-git-github/ace-git-forgejo. Missing required evidence cannot be replaced by a done flag, prose report or exit code 0. Executed tests and independent review of exact SHA are the delivery gate; CI status is advisory.

## Readiness and boundaries

This is a real implementation slice, advisory size: large. The current task creates specifications only. No deployment, production data mutation or release is authorized by this spec work. Implementation updates the affected API/config/CLI docs and package dependencies together, removing old surfaces rather than shipping aliases. No extra force mode may bypass identity/evidence checks. Review must verify all listed outcomes before promotion; no unresolved user decision remains.
