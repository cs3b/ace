---
update:
  update_frequency: weekly
  max_lines: 150
  required_sections: []
  frequency: weekly
  last-updated: '2026-01-22'
---

# ACE Commands Reference

Quick reference for all ACE commands. `/ace:` commands run in Claude Code chat; `ace-` commands run in terminal. Detailed usage in each gem's `docs/usage.md`.

## Quick Reference

| Purpose | Claude Command | CLI Tool |
|---------|----------------|----------|
| Work on task | `/ace:work-on-task 148` | `ace-taskflow task 148` |
| Smart commit | `/ace:commit` | `ace-git-commit --staged` |
| Review PR | `/ace:review-pr 90` | `ace-review --preset pr` |
| Run tests | `/ace:fix-tests` | `ace-test atoms` |
| Load context | `/ace:bundle project` | `ace-bundle wfi://workflow` |
| Create PR | `/ace:create-pr` | `gh pr create` |
| Security scan | `/ace:security-audit` | `ace-git-secrets scan` |

---

## Task Management

| Command | Purpose |
|---------|---------|
| `/ace:work-on-task [id]` | Work on task with full agent context |
| `/ace:draft-task` | Draft new task specification |
| `/ace:plan-task [id]` | Create implementation plan |
| `/ace:review-task [id]` | Review completed task |
| `ace-taskflow task 047` | View task (any ref format) |
| `ace-taskflow tasks all` | List all tasks in release |
| `ace-taskflow task done 047` | Mark task complete |

## Git Operations

| Command | Purpose |
|---------|---------|
| `/ace:commit` | Generate commit with LLM assistance |
| `/ace:create-pr` | Create pull request |
| `/ace:rebase` | Rebase with CHANGELOG preservation |
| `ace-git-commit` | Generate commit message |
| `ace-git-commit --staged` | Commit only staged files |
| `ace-git status` | Full context (branch, PR, activity) |
| `ace-git diff HEAD~5..HEAD` | Generate diff between refs |
| `ace-git-worktree create --task 081` | Create worktree for task |

## Code Review

| Command | Purpose |
|---------|---------|
| `/ace:review` | Review code changes |
| `/ace:review-pr [pr]` | Review pull request with AI |
| `ace-review --preset pr` | Review PR changes |
| `ace-review --preset security` | Security-focused review |
| `ace-review --task 121` | Review task implementation |

## Testing and Quality

| Command | Purpose |
|---------|---------|
| `/ace:fix-tests` | Fix failing tests systematically |
| `/ace:create-test-cases` | Generate structured test cases |
| `/ace:analyze-bug` | Analyze bug root cause |
| `/ace:fix-bug` | Execute bug fix plan |
| `ace-test` | Run all tests |
| `ace-test atoms` | Run atom tests only |
| `ace-test ace-bundle` | Run tests in specific package |
| `ace-lint file.md` | Lint file |
| `ace-lint file.md --fix` | Auto-fix issues |

## Documentation

| Command | Purpose |
|---------|---------|
| `/ace:update-docs` | Update docs with ace-docs workflow |
| `/ace:create-adr` | Create Architecture Decision Record |
| `ace-docs status --needs-update` | Check docs needing updates |
| `ace-docs update file.md` | Update document metadata |

## Context and Navigation

| Command | Purpose |
|---------|---------|
| `/ace:bundle [preset]` | Load bundle with AI assistance |
| `/ace:prompt-prep` | Run prompt-prep workflow |
| `ace-bundle project` | Load project context |
| `ace-bundle wfi://workflow` | Load workflow via protocol |
| `ace-nav wfi://resource` | Navigate to resource |
| `ace-search "pattern"` | Search content |
| `ace-search "*.rb" --file` | Find files by pattern |

## Release Management

| Command | Purpose |
|---------|---------|
| `/ace:draft-release` | Draft release with changelog |
| `/ace:publish-release` | Publish release |
| `/ace:update-roadmap` | Update project roadmap |

## Ideas and Retrospectives

| Command | Purpose |
|---------|---------|
| `/ace:capture-idea` | Capture new idea |
| `/ace:prioritize-ideas` | Prioritize and align ideas |
| `/ace:create-retro` | Create retrospective |

## Security

| Command | Purpose |
|---------|---------|
| `ace-git-secrets scan` | Scan history for tokens |
| `ace-git-secrets revoke` | Revoke detected tokens |

## LLM Utilities

| Command | Purpose |
|---------|---------|
| `ace-llm "prompt" -m gpt-4` | Query LLM provider |
| `ace-llm "prompt" -m gemini:gemini-2.5-flash` | Query Gemini |

---

## Task Lookup

Use `ace-taskflow task` for any reference format:

```sh
ace-taskflow task 047            # By number
ace-taskflow task task.047       # With prefix
ace-taskflow task v.0.9.0+047    # Full ID
```

---

*Detailed documentation: each ace-*/docs/usage.md*
