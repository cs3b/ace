# Active delivery coupling inventory

Inspected source `49a57f4f5994ae04833de3ced95501e8271e52b7`. Scope: four consumers' libraries, defaults, dependencies and maintained handbook; canonical Git/overseer workflows; projected PR/review/overseer skills. Historical changelogs, archives and test URL fixtures are outside the active-route inventory. This is source inspection, not remote or installed acceptance.

Found defect: SubjectExtractor typed PR validation used the GitHub parser. Source `9b9d72d65` now uses the common PrReference; task `qkc.0` retains 91/182 passing tests and awaits combined review. Archived qk1 evidence was not expanded retroactively.

All 57 remaining direct matches are classified below. The separately named GitHub release workflow is explicitly provider-specific and is not used by the common assignment or scoped RubyGems route. The final independent reviewer must check the final source and these classifications. Executable acceptance assets and installed results remain separate requirements.

| Source | Classification | Reason |
|---|---|---|
| `ace-git-worktree/lib/ace/git/worktree/commands/create_command.rb:130` | Non-operational metadata/registration | Named Forgejo server in help example. |
| `ace-git-worktree/lib/ace/git/worktree/molecules/task_fetcher.rb:86` | Non-operational metadata/registration | ACE project help URL; not the selected forge endpoint. |
| `ace-git-worktree/lib/ace/git/worktree/molecules/task_fetcher.rb:226` | Non-operational metadata/registration | ACE project help URL; not the selected forge endpoint. |
| `ace-git-worktree/ace-git-worktree.gemspec:17` | Non-operational metadata/registration | Package homepage/source URI or installed provider dependency; no remote operation. |
| `ace-review/lib/ace/review/atoms/pr_comment_formatter.rb:36` | Non-operational metadata/registration | Bot author filtering of comment metadata. |
| `ace-review/lib/ace/review/atoms/pr_comment_formatter.rb:41` | Non-operational metadata/registration | Bot author filtering of comment metadata. |
| `ace-review/lib/ace/review/atoms/pr_comment_formatter.rb:49` | Non-operational metadata/registration | Bot author filtering of comment metadata. |
| `ace-review/lib/ace/review/molecules/pr_provider.rb:4` | Non-operational metadata/registration | Provider registration; operations delegate to the common lifecycle. |
| `ace-review/lib/ace/review/organisms/review_manager.rb:812` | Non-operational metadata/registration | Link formatting uses resolved provider identity, not an inferred server. |
| `ace-review/lib/ace/review/organisms/review_manager.rb:814` | Non-operational metadata/registration | Link formatting uses resolved provider identity, not an inferred server. |
| `ace-review/.ace-defaults/review/config.yml:28` | Non-operational metadata/registration | Local CONTRIBUTING.md discovery path; no provider operation. |
| `ace-review/handbook/skills/as-review-package/SKILL.md:11` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-review/handbook/workflow-instructions/review/verify-feedback.wf.md:96` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-review/handbook/workflow-instructions/review/verify-feedback.wf.md:99` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-review/handbook/workflow-instructions/review/verify-feedback.wf.md:243` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-review/ace-review.gemspec:15` | Non-operational metadata/registration | Package homepage/source URI or installed provider dependency; no remote operation. |
| `ace-review/ace-review.gemspec:26` | Non-operational metadata/registration | Package homepage/source URI or installed provider dependency; no remote operation. |
| `ace-review/ace-review.gemspec:54` | Non-operational metadata/registration | Package homepage/source URI or installed provider dependency; no remote operation. |
| `ace-task/lib/ace/task/cli/commands/create.rb:24` | Non-operational metadata/registration | Named Forgejo server in help example. |
| `ace-task/lib/ace/task/cli.rb:55` | Non-operational metadata/registration | Named Forgejo server in help example. |
| `ace-task/lib/ace/task/molecules/issue_sync_adapter.rb:86` | Non-operational metadata/registration | Link formatting uses exact linked repository/provider. |
| `ace-task/lib/ace/task/molecules/issue_sync_adapter.rb:90` | Non-operational metadata/registration | Link formatting uses exact linked repository/provider. |
| `ace-task/lib/ace/task/molecules/task_frontmatter_validator.rb:138` | Non-operational metadata/registration | Refuses obsolete GitHub metadata. |
| `ace-task/lib/ace/task/organisms/task_manager.rb:983` | Non-operational metadata/registration | Refuses direct edits of obsolete or issue-owner metadata. |
| `ace-task/lib/ace/task.rb:9` | Non-operational metadata/registration | Provider registration; require does not invoke a CLI or contact a server. |
| `ace-task/handbook/workflow-instructions/task/draft.wf.md:86` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-task/handbook/workflow-instructions/task/draft.wf.md:380` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-task/handbook/workflow-instructions/task/draft.wf.md:381` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-task/ace-task.gemspec:15` | Non-operational metadata/registration | Package homepage/source URI or installed provider dependency; no remote operation. |
| `ace-task/ace-task.gemspec:50` | Non-operational metadata/registration | Package homepage/source URI or installed provider dependency; no remote operation. |
| `ace-assign/lib/ace/assign/authority/deployment.rb:314` | Non-operational metadata/registration | Comment about domain policy ownership. |
| `ace-assign/lib/ace/assign/authority/prepared_task_context.rb:9` | Non-operational metadata/registration | Comment about domain owner, not a legacy forwarding path. |
| `ace-assign/ace-assign.gemspec:13` | Non-operational metadata/registration | Package homepage/source URI or installed provider dependency; no remote operation. |
| `ace-git/handbook/workflow-instructions/git/pr/create.wf.md:22` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:3` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:4` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:10` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:14` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:28` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:31` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:91` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:214` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:229` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:231` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:238` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-git/handbook/workflow-instructions/github/release-publish.wf.md:253` | Explicit provider-specific release | Separately named GitHub release workflow, outside common assignment delivery and scoped RubyGems publication. |
| `ace-overseer/handbook/workflow-instructions/overseer.wf.md:55` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/lab-coordinator.wf.md:2` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/lab-coordinator.wf.md:5` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/lab-coordinator.wf.md:6` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/lab-coordinator.wf.md:11` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/lab-coordinator.wf.md:22` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/lab-coordinator.wf.md:45` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/lab-coordinator.wf.md:69` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/project-overseer.wf.md:22` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/project-overseer.wf.md:75` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
| `ace-overseer/handbook/workflow-instructions/roles/second-commander.wf.md:22` | Non-operational metadata/registration | Issue example, local CI-file inspection, role wording, tool permission or explicit legacy prohibition; no active common delivery command forwards to gh/fj/lab/labd. |
