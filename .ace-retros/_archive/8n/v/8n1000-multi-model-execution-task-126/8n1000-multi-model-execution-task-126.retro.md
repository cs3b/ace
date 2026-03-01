---
id: 8n1000
title: Multi-Model Execution Feature (Task 126.01)
type: conversation-analysis
tags: []
created_at: "2025-12-02 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8n1000-multi-model-execution-task-126.md
---
# Reflection: Multi-Model Execution Feature (Task 126.01)

**Date**: 2025-12-02
**Context**: Implementation of multi-model concurrent LLM execution for ace-review
**Author**: Claude Code + mc
**Type**: Conversation Analysis

## What Went Well

- **Incremental review-driven development**: Using multi-model reviews (claude:opus, codex, gpro) to catch bugs worked extremely well - each model found different issues
- **Fast iteration cycle**: Code reviews identified critical bugs (output_file not passed, task path propagation) that were fixed before they caused issues in production
- **DRY preset consolidation**: Moving from duplicated `pr.yml` (50 lines) to `code-pr.yml` extending `code` (15 lines) was a clean refactor
- **Config-over-ENV pattern**: Moving `max_concurrent_models` and `auto_execute` from ENV variables to config file improved UX significantly

## What Could Be Improved

- **Pre-existing test failures**: 5 organism tests were failing - didn't investigate root cause, just verified multi-model tests passed
- **Review synthesis could be automated**: Currently manual process to read 3 review files and synthesize - could be a tool
- **Preset naming inconsistency**: Had `code-pr.yml` in gem but `pr.yml` locally - caused Codex false positive about "removed preset"

## Key Learnings

- **Multi-model reviews are highly valuable**: Different models catch different issues - Codex found filename collision bug that Claude missed
- **Thread-safe patterns in Ruby**: `Mutex.new` + `@mutex.synchronize` for thread-safe hash updates worked well
- **Preset resolution chain**: Local `.ace/` > gem `.ace.example/` - understanding this prevented confusion about "missing" presets
- **Config cascading**: `Ace::Review.get("defaults", "key") || fallback` pattern is clean and flexible

## Action Items

### Stop Doing

- Using ENV variables for config that should be in config files
- Duplicating preset content when composition is available

### Continue Doing

- Multi-model code reviews for catching diverse issues
- Incremental fix-review-fix cycles for quality assurance
- Using DRY preset composition with `presets:` array

### Start Doing

- Add `/ace:synthesize-reviews` command to auto-summarize multi-model review outputs
- Consider adding `--synthesize` flag to ace-review for automatic post-review synthesis
- Document the preset resolution chain in ace-review README

## Technical Details

### Thread Concurrency Pattern
```ruby
@mutex = Mutex.new
threads = models.map { |m| Thread.new { execute_model(m) } }
threads.each(&:join)
```

### Config Access Pattern
```ruby
Ace::Review.get("defaults", "max_concurrent_models") || 3
```

### Preset Composition
```yaml
# code-pr.yml - DRY pattern
presets:
  - code
subject:
  diffs: ["origin...HEAD"]
```

## Additional Context

- PR #59, #61 reviewed during development
- Released as ace-review v0.20.0 (multi-model) and v0.20.1 (config improvements)
- Task: `.ace-taskflow/v.0.9.0/tasks/126-llm-enhance/`
