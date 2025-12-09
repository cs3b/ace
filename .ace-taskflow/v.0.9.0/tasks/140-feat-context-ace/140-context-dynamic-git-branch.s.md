---
id: v.0.9.0+task.140
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Enhance ace-context with Dynamic Git Branch and PR Information

## Behavioral Specification

### User Experience
- **Input**: User runs `ace-context project` or similar preset commands in a Git repository (no additional flags required)
- **Process**: ace-context automatically detects Git repository, fetches current branch, discovers associated PR (if exists), extracts PR metadata, caches results, and integrates Git context into overall project context
- **Output**: Standard ace-context output enhanced with Git section showing current branch, PR details (if associated), target branch, and task context (if linked)

### Expected Behavior

When `ace-context` is executed within a Git repository, it automatically gathers and exposes dynamic Git information including:

- The name of the currently active Git branch (including detached HEAD handling)
- Comprehensive details about any open Pull Request associated with the current branch (PR ID, title, URL, status, author, target branch)
- The target branch to which the PR is intended to merge (e.g., `main`, `develop`)
- Task linkage when branch/PR is associated with ace-taskflow tasks

This enriched Git context is seamlessly integrated into the overall context loaded by ace-context, making it readily available to other ACE gems (like ace-git-commit, ace-review, ace-docs) and AI agents for more informed decision-making and output generation.

**Key Behaviors:**
- Automatic detection and graceful degradation (works in non-Git repos)
- Smart caching to minimize redundant Git CLI calls and network requests
- Provider-agnostic architecture (starting with GitHub, extensible to GitLab/Bitbucket)
- No performance degradation for basic context loading

### Interface Contract

```bash
# Basic usage - automatically includes Git context
ace-context project
# Output includes:
# Git Context:
#   Branch: feat-context-git-pr-info
#   PR: #142 - Enhance ace-context with Git/PR tracking
#   Target: main
#   Task: v.0.9.0+task.130 (if linked)

# Show only Git context
ace-context --git-info
# Output:
# branch: feat-context-git-pr-info
# pr:
#   number: 142
#   title: "Enhance ace-context with Git/PR tracking"
#   url: "https://github.com/owner/repo/pull/142"
#   status: open
#   target_branch: main

# Programmatic access (for other ACE gems)
# Ruby API:
git_context = Ace::Context.load_git_context
git_context.current_branch  # => "feat-context-git-pr-info"
git_context.pr&.number      # => 142
git_context.pr&.target_branch  # => "main"
git_context.task_id         # => "v.0.9.0+task.130" (if linked)
```

**Error Handling:**
- Not a Git repository: Git context section omitted (graceful degradation)
- No PR for branch: PR details shown as "none" or omitted
- GitHub CLI not available: PR fetching disabled with warning (optional)
- API rate limits: Uses cached data with staleness indicator
- Network unavailable: Falls back to cached data or shows limited local Git info

**Edge Cases:**
- Detached HEAD state: Shows commit SHA instead of branch name
- Multiple PRs for same branch: Shows most recent PR
- Closed/merged PRs: Includes status in output
- Branch without remote tracking: Shows local branch only
- Task number in branch name: Automatically extracts and links to ace-taskflow

### Success Criteria

- [ ] **Automatic Git Detection**: ace-context automatically detects and includes Git context when run in a Git repository
- [ ] **Current Branch Retrieval**: Accurately retrieves and displays current branch name (including detached HEAD handling)
- [ ] **PR Discovery**: Discovers associated PR for current branch via GitHub CLI or API
- [ ] **PR Metadata Extraction**: Extracts and displays PR number, title, URL, status, and target branch
- [ ] **Smart Caching**: Caches Git/PR information to minimize redundant CLI calls and API requests
- [ ] **Programmatic Access**: Other ACE gems can access Git context via clean Ruby API
- [ ] **Graceful Degradation**: Functions properly in non-Git repos, branches without PRs, or without GitHub CLI
- [ ] **Task Integration**: Links PR/branch context to ace-taskflow tasks when applicable
- [ ] **Performance**: Git context gathering adds <100ms overhead to context loading
- [ ] **Configuration**: Users can disable/configure Git context via `.ace/context/config.yml`

### Validation Questions

- [ ] **Configuration Scope**: Should users be able to disable automatic Git context inclusion via `.ace/context/config.yml`?
- [ ] **PR Provider Support**: Start with GitHub only, or plan for GitLab/Bitbucket from the beginning?
- [ ] **Cache Duration**: How long should Git/PR information be cached before refreshing?
- [ ] **Task Linkage**: Should ace-context automatically detect task numbers from branch names or PR descriptions?
- [ ] **Performance Impact**: What's the acceptable overhead for Git/PR information gathering?
- [ ] **Offline Behavior**: How should ace-context behave when GitHub API is unreachable?
- [ ] **Integration Points**: Which ACE gems should consume this context first (ace-git-commit, ace-review, ace-docs)?

## Objective

Enable AI agents and ACE gems to make more informed, context-aware decisions by providing real-time Git workflow context. This reduces hallucinations, improves commit message quality, enhances code review relevance, and enables more intelligent automation across the ACE ecosystem.

**User Value:**
- More accurate commit messages that understand PR context
- Better code reviews that consider target branch and PR scope
- Relevant documentation updates that align with current development task
- Reduced need for manual context switching and information gathering

## Scope of Work

### User Experience Scope
- Automatic Git context detection and inclusion in ace-context output
- PR discovery and metadata extraction from GitHub
- Branch and target branch identification
- Task linkage when branch/PR associated with ace-taskflow tasks

### System Behavior Scope
- Git CLI interaction for branch information
- GitHub CLI/API interaction for PR details
- Smart caching mechanism for performance optimization
- Graceful error handling and degradation
- Integration with existing ace-context caching system

### Interface Scope
- CLI output format enhancement (YAML/JSON)
- Programmatic Ruby API for Git context access
- Configuration options for Git context behavior
- Cache management and invalidation
- CLI flag `--git-info` for Git-only context

### Deliverables

#### Behavioral Specifications
- User experience flow definitions for Git context gathering
- System behavior specifications for caching and error handling
- Interface contract definitions (CLI and Ruby API)

#### Validation Artifacts
- Success criteria validation methods (performance benchmarks, integration tests)
- User acceptance criteria (manual testing scenarios)
- Behavioral test scenarios (unit and integration tests)

## Out of Scope

- ❌ **Multi-repository Support**: Only current repository context (no submodule tracking)
- ❌ **Git History Analysis**: No commit history parsing or analysis
- ❌ **Automated PR Creation**: Only reads PR info, doesn't create PRs
- ❌ **Non-GitHub Providers**: Initial implementation GitHub-only (future enhancement via provider pattern)
- ❌ **Complex Task Extraction**: Simple pattern matching only (no NLP for task detection)
- ❌ **Git Configuration Management**: No modification of Git settings

## References

- Source idea 1: `.ace-taskflow/v.0.9.0/ideas/done/20251202-231239-ace-context-enhance/add-dynamic-git-branch-and-pr-info.s.md`
- Source idea 2: `.ace-taskflow/v.0.9.0/ideas/done/20251119-122409-llm-add/ace-context-to-load-context-of-work-more-precesi.s.md`
- Related: ace-context gem architecture (`ace-context/lib/ace/context/`)
- Related: GitHub CLI integration patterns
- Related: ace-taskflow task detection patterns
