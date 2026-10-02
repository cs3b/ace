## 📋 Summary

Tasks can now be linked to one exact issue on any named forge — GitHub or Forgejo — and synchronized offline-safely. Before this change, issue tracking was GitHub-only (`github-sync`), silently tied to whatever the default remote pointed at, and an uncertain network result could duplicate tracking comments or touch the wrong repository. Links now carry a validated `remote_issue` identity (`server_name`, `provider`, `repository_url`, `number`, `url`), replay resolves that stored identity instead of the current default, and cleanup that fails or stays uncertain keeps the link recoverable instead of losing it.

## ✏️ Changes

- **Provider-neutral issue contract** — `Ace::Git::Providers::Base` gains issue lookup, comment create/update/delete, label add/remove, and state transitions; shared `IssueTracking` organism in ace-git reconciles the ACE sticky marker and ownership so unknown send outcomes never duplicate tracking entries (b5563160f).
- **Provider implementations** — ace-git-github and ace-git-forgejo each own their forge's issue mutations behind the shared contract; the GitHub-only `Ace::Git::Github::IssueSync` is deleted (6aa11e19f, 571100819).
- **Exact-issue task links** — `ace-task create TITLE --issue N_OR_URL [--server NAME|--default-server]`, `ace-task issue-link REF --issue …|--clear`, and `ace-task issue-sync REF|--all|--pending` replace `github-sync`; partial `remote_issue` mappings fail frontmatter validation and generic update can no longer retarget links silently (6ca55346a).
- **Offline-safe lifecycle** — linked tasks keep updating locally without forge tooling; deferred syncs persist `issue_sync_pending` with the exact identity and replay never consults a changed default server (f20de9577).
- **Docs and guidance** — task usage, draft workflow, and provider docs describe the forge-neutral flow; the demo tape was renamed to `ace-task-issue-sync` (9b395e22e, bfc6bc3a1).

## 📁 File Changes

```
+1652, -1327   57 files   total

 +291,    -1    5 files      ace-git-forgejo/
 +207,    -1    3 files   🧱 lib/
 +142,    -0                 ace/git/forgejo/issue_api.rb
  +64,    -0                 .../provider.rb
   +1,    -1                 .../version.rb
  +79,    -0    1 files   🧪 test/
  +79,    -0                 fast/molecules/issue_api_test.rb
   +5,    -0    1 files      
   +5,    -0                 CHANGELOG.md

 +139,  -552    7 files      ace-git-github/
  +72,  -254    4 files   🧱 lib/
   +0,    -1                 ace/git/github.rb
   +0,  -252                 ace/git/github/issue_sync.rb
  +71,    -0                 .../provider.rb
   +1,    -1                 .../version.rb
  +62,  -298    2 files   🧪 test/
   +0,  -298                 fast/molecules/issue_sync_test.rb
  +62,    -0                 .../issue_tracking_provider_test.rb
   +5,    -0    1 files      
   +5,    -0                 CHANGELOG.md

 +291,    -2    7 files      ace-git/
 +183,    -1    4 files   🧱 lib/
   +1,    -0                 ace/git.rb
 +150,    -0                 ace/git/organisms/issue_tracking.rb
  +31,    -0                 ace/git/providers/base.rb
   +1,    -1                 ace/git/version.rb
  +98,    -0    1 files   🧪 test/
  +98,    -0                 fast/organisms/issue_tracking_test.rb
  +10,    -1    2 files      
   +5,    -0                 CHANGELOG.md
   +5,    -1                 docs/usage.md

 +852,  -770   33 files      ace-task/
 +389,  -268   17 files   🧱 lib/
   +0,    -1                 ace/task.rb
   +2,    -2                 ace/task/atoms/task_frontmatter_defaults.rb
   +9,    -5                 ace/task/cli.rb
  +20,   -13                 ace/task/cli/commands/create.rb
   +0,   -73                 .../github_sync.rb
  +38,    -0                 .../issue_link.rb
  +42,    -0                 .../issue_sync.rb
   +2,    -0                 .../update.rb
   +0,   -88                 ace/task/molecules/github_issue_sync_adapter.rb
  +75,    -0                 .../issue_link.rb
  +50,    -0                 .../issue_sync_adapter.rb
   +2,    -2                 .../subtask_creator.rb
   +2,    -2                 .../task_creator.rb
  +27,   -18                 .../task_frontmatter_validator.rb
   +3,    -3                 .../task_plan_prompt_builder.rb
 +116,   -60                 ace/task/organisms/task_manager.rb
   +1,    -1                 ace/task/version.rb
 +372,  -453   11 files   🧪 test/
   +6,    -3                 fast/atoms/task_frontmatter_defaults_test.rb
  +21,   -16                 fast/commands/create_test.rb
   +0,   -95                 .../github_sync_test.rb
  +30,    -0                 .../issue_link_test.rb
  +50,    -0                 .../issue_sync_test.rb
  +12,   -13                 .../update_test.rb
   +0,  -103                 fast/molecules/github_issue_sync_adapter_test.rb
  +86,    -0                 .../issue_link_test.rb
  +30,    -0                 .../issue_sync_adapter_test.rb
  +18,   -13                 .../task_frontmatter_validator_test.rb
 +119,  -210                 fast/organisms/task_manager_test.rb
  +18,   -18    1 files   📚 handbook/
  +18,   -18                 workflow-instructions/task/draft.wf.md
  +73,   -31    4 files      
   +8,    -0                 CHANGELOG.md
   +2,    -1                 ace-task.gemspec
   +8,    -6                 docs/demo/ace-task-github-sync.tape.yml -> ace-task-issue-sync.tape.yml
  +55,   -24                 docs/usage.md

  +45,    -2    3 files      .ace-tasks/
   +2,    -2                 8wr.t.qk1-complete-forge-neutral-worktree-review/2-use-named-forge-providers-for/8wr.t.qk1.2-use-named-forge-providers-for-task-issue.s.md
  +14,    -0                 8wr.t.qk1-complete-forge-neutral-worktree-review/2-use-named-forge-providers-for/ux/usage.md
  +29,    -0                 8wr.t.qk1-complete-forge-neutral-worktree-review/2-use-named-forge-providers-for/verification-2026-10-02.md

  +30,    -0    1 files      .ace-retros/
  +30,    -0                 8x111w-named-forge-task-issue-tracking/8x111w-named-forge-task-issue-tracking.retro.md

   +4,    -0    1 files      ./
   +4,    -0                 CHANGELOG.md
```

## 🧪 Test Evidence

- **IssueTrackingTest** (ace-git, 98 new lines of tests) — sticky marker reconciliation, ownership isolation, unrelated content preserved.
- **IssueTrackingProviderTest** (ace-git-github contract) + **IssueApiTest** (ace-git-forgejo) — provider issue fetch, comment/label/state mutations with exact repository argv and wrong-identity refusal.
- **IssueLinkTest / IssueSyncTest** (ace-task commands + molecules) — link, same-link idempotence, ownership conflict, invalid URL/number/server, changed identity refusal, pending retention, bulk partial failure.
- Package suites at head 8c89866f8: ace-git 546, ace-git-github 69, ace-git-forgejo 93, ace-task 427 (2 skipped) — 0 failures. Full suite 44/50 packages green; all 6 non-passing packages classified pre-existing/environment with base-commit evidence (verification-2026-10-02.md).

## 📦 Releases

- **ace-git v0.26.0** — provider issue-tracking contract + shared IssueTracking organism.
- **ace-git-github v0.3.0** — provider-owned issue operations; GitHub-only IssueSync removed.
- **ace-git-forgejo v0.4.0** — Forgejo issue API + provider issue operations.
- **ace-task v0.39.0** — named-forge issue links, issue-link/issue-sync commands, atomic remote_issue validation.

## 🎮 Demo

```bash
# Link a task to an exact issue on a named forge
ace-task issue-link q7w --issue 42 --server forgejo-lab

# Same link is idempotent; different issue is a conflict until explicit clear
ace-task issue-link q7w --clear

# Synchronize tracked status for all linked tasks (offline-safe replay)
ace-task issue-sync --pending
```
