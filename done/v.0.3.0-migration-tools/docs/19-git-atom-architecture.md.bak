# Git Module ATOM Architecture Design

## Overview

This document outlines the comprehensive git module architecture following the ATOM pattern (Atoms → Molecules → Organisms → CLI).

## Analysis Summary

### Existing Shell Script Patterns

**Multi-Repository Operations:**
- `bin/gc` - Fish script with intention-based commits across all repos (dev-tools, dev-taskflow, dev-handbook, main)
- `bin/gp` - Fish script for pushing all repositories sequentially
- `bin/gpull` - Fish script for pulling all repositories using `git -C <dir>`
- `bin/gl` - Ruby wrapper executing `get-recent-git-log` with multi-repo flags

**Key Patterns Identified:**
1. **Repository List**: `[main, dev-tools, dev-taskflow, dev-handbook]`
2. **Intention-Based Commits**: `-i/--intention` flag for LLM-generated messages
3. **Sequential Execution**: Scripts process repos one by one with output prefixes
4. **Fish Function Integration**: `gcama` (git add all + commit all + message all) patterns

### Fish Function Patterns

**gc-llm.fish Analysis:**
- Uses `--intention` flag for contextual commit messages
- Integrates with `gemini-query` and `lms-query` for LLM commit generation
- Supports `--local` flag for local LLM models
- Pattern: `gaa && gcm` (git add all + commit message)

**git.fish Aliases:**
- `gcama` = "git add all, commit all, message all"
- `gcam` = "git commit all, message" (no edit)
- Uses `gc-llm` as the core commit function

## ATOM Architecture Design

### Atoms (Basic Building Blocks)

**lib/coding_agent_tools/atoms/git/**
- `git_command_executor.rb` - Execute git commands with error handling
- `repository_scanner.rb` - Scan filesystem for git repositories
- `submodule_detector.rb` - Detect submodules and their paths
- `path_resolver.rb` - Resolve file paths to their repository context

### Molecules (Simple Compositions)

**lib/coding_agent_tools/molecules/git/**
- `path_dispatcher.rb` - Group file paths by repository and dispatch commands
- `multi_repo_coordinator.rb` - Coordinate operations across multiple repositories
- `concurrent_executor.rb` - Execute git operations concurrently using threads/fibers
- `commit_message_generator.rb` - Generate commit messages using LLM integration

### Organisms (Complex Business Logic)

**lib/coding_agent_tools/organisms/git/**
- `git_orchestrator.rb` - High-level coordination of all git operations

### CLI Commands (User Interface)

**lib/coding_agent_tools/cli/commands/git.rb** - Namespace module
**lib/coding_agent_tools/cli/commands/git/**
- `commit.rb` - Git commit with intention-based message generation
- `status.rb` - Multi-repo status with clear prefixes
- `push.rb` - Concurrent push operations across all repos
- `pull.rb` - Concurrent pull operations across all repos
- `log.rb` - Unified log display sorted by date
- `diff.rb` - Multi-repo diff operations
- `add.rb` - Intelligent path grouping and addition
- `mv.rb` - Git move operations with path resolution
- `rm.rb` - Git remove operations with path resolution
- `restore.rb` - Git restore operations with path resolution
- `fetch.rb` - Git fetch operations across all repos

## Component Interactions

```
CLI Commands
    ↓
Git Orchestrator (organism)
    ↓
Multi-Repo Coordinator + Concurrent Executor (molecules)
    ↓
Path Dispatcher + Commit Message Generator (molecules)
    ↓
Git Command Executor + Repository Scanner + Submodule Detector (atoms)
```

## Multi-Repository Strategy

### Repository Detection
1. Use `ProjectRootDetector` for base path resolution
2. Scan for submodules using `git submodule status`
3. Hardcoded fallback: `[main, dev-tools, dev-taskflow, dev-handbook]`

### Path Resolution
- `git add dev-handbook/file.md lib/file.rb` → 
  - Group 1: `git -C dev-handbook add file.md`
  - Group 2: `git add lib/file.rb`

### Concurrent Execution
- Use Ruby threads/fibers for submodule operations
- Main repository operations wait for submodule synchronization
- Proper error handling and result aggregation

## LLM Integration Strategy

### Replacing Fish Functions
- Replace `gc-llm.fish` with Ruby implementation
- Use existing gem `llm-query` executable instead of fish functions
- Support both local and remote LLM models
- Maintain `--intention` flag compatibility

### Commit Message Generation
- Extract diff using `git diff --staged`
- Generate system prompt with commit guidelines
- Support intention-based context injection
- Clean response (remove markdown markers)

## CLI Interface Design

### Command Structure
```
coding_agent_tools git <command> [options] [files...]
```

### Options Pattern
- `--debug/-d` - Debug output
- `--intention/-i` - Intention-based commits
- `--local/-l` - Use local LLM models
- `--repository/-C` - Explicit repository context
- `--all/-a` - Explicit all-repositories flag

### Help Integration
- Follow dry-cli patterns with `desc` and `example`
- Consistent option naming and behavior
- Comprehensive usage examples

## Integration Points

### Binstub Mapping
```yaml
# dev-tools/config/binstub-aliases.yml
gc: "git commit"
gp: "git push"
gpull: "git pull"
gl: "git log"
```

### ProjectRootDetector Integration
- Use existing `ProjectRootDetector` for directory-agnostic operation
- Support running from any project subdirectory
- Maintain cache for performance

### Error Handling
- Comprehensive error messages
- Debug mode for verbose output
- Graceful handling of missing repositories
- Proper exit codes for shell integration

## Testing Strategy

### Unit Tests
- Each ATOM component tested in isolation
- Mock external dependencies (LLM, git commands)
- Test error conditions and edge cases

### Integration Tests
- Multi-repository scenarios
- Path resolution and grouping
- Concurrent execution behavior
- LLM integration workflows

### CLI Tests
- Command-line interface behavior
- Option parsing and validation
- Output formatting and prefixes
- Error handling and exit codes

## Migration Path

### Phase 1: Foundation
- Implement ATOM components
- Create basic CLI structure
- Test core functionality

### Phase 2: Multi-Repo Support
- Add concurrent execution
- Implement path resolution
- Test multi-repository scenarios

### Phase 3: LLM Integration
- Replace fish functions with Ruby
- Add intention-based commits
- Test LLM workflows

### Phase 4: Shell Integration
- Configure binstub aliases
- Test shell integration
- Document migration from bin/g* scripts

## Implementation Priorities

1. **High Priority**: commit, status, push, pull (core workflows)
2. **Medium Priority**: log, add, diff (development workflows)
3. **Low Priority**: mv, rm, restore, fetch (auxiliary commands)

This architecture provides a solid foundation for implementing the comprehensive git module while maintaining compatibility with existing workflows and enabling future enhancements.