---
id: v.0.9.0+task.140
status: in-progress
priority: medium
estimate: 8-12h (total across subtasks)
dependencies: []
---

# Enhance ace-context with Dynamic Git Branch and PR Information

**Type:** Orchestrator

## Objective

Enable AI agents and ACE gems to make more informed, context-aware decisions by providing real-time Git workflow context via composable commands.

## Architecture Decision

Split into two packages with clear separation of concerns:

1. **ace-context-repo** (new gem) - Pure Git/PR context, no task awareness
2. **ace-taskflow context** (new subcommand) - Task-aware context consuming repo context

This keeps ace-context neutral (just packs things) while each domain owns its context generation.

## Subtasks

### 140.01: Create ace-context-repo gem
- New gem providing Git repository context
- CLI: `ace-context-repo` → markdown output
- Output: branch, remote tracking, PR info, task pattern (extracted from branch)
- No ace-taskflow dependency

### 140.02: Add context subcommand to ace-taskflow
- New `ace-taskflow context` subcommand
- Consumes ace-context-repo output
- Output: repo context + resolved task + release info + recent/next tasks

## Success Criteria

- [ ] `ace-context-repo` outputs branch, PR, and task pattern
- [ ] `ace-taskflow context` outputs full task-aware context
- [ ] Both commands work in ace-context preset `commands:` section
- [ ] Graceful degradation (no git, no PR, no gh CLI)
- [ ] Performance: <100ms for local git info, <500ms with PR fetch

## Out of Scope

- ❌ Multi-repository Support
- ❌ Non-GitHub Providers (GitLab/Bitbucket - future)
- ❌ Modifying ace-context internals

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251202-231239-ace-context-enhance/`
- Key patterns: `ace-review/.../task_auto_detector.rb`, `ace-context/.../gh_pr_executor.rb`
