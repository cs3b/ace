---
id: v.0.9.0+task.162
status: draft
priority: medium
estimate: 30m
dependencies: []
---

# Remove individual Gemfiles from ace-* gems

## Description

Remove individual `Gemfile` files from ace-* gems. The mono-repo pattern uses a single root `Gemfile` for all development - individual gems should only have `*.gemspec` files for runtime dependencies.

Per ADR and updated `docs/ace-gems.g.md`:
- Root `Gemfile`: Development dependencies for entire mono-repo
- `*.gemspec`: Runtime dependencies for gem distribution
- Individual gem `Gemfile`: NOT needed (anti-pattern)

## Gems with Gemfiles to Remove

1. ace-config/Gemfile
2. ace-docs/Gemfile
3. ace-git-worktree/Gemfile
4. ace-handbook/Gemfile
5. ace-integration-claude/Gemfile
6. ace-lint/Gemfile
7. ace-llm-providers-cli/Gemfile
8. ace-nav/Gemfile
9. ace-review/Gemfile
10. ace-search/Gemfile
11. ace-support-mac-clipboard/Gemfile
12. ace-support-markdown/Gemfile

## Acceptance Criteria

- [ ] All 12 Gemfiles removed from individual gems
- [ ] Root Gemfile still works (`bundle install` succeeds)
- [ ] All tests pass via `ace-test-suite`
- [ ] No orphaned Gemfile.lock files remain

## Implementation Notes

Simple cleanup task:
```bash
rm ace-*/Gemfile
rm ace-*/Gemfile.lock  # if any exist
```

Verify with:
```bash
bundle install
ace-test-suite
```
