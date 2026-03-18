# Comparison: dev-tools git-commit vs ace-git-commit

## Overview

This document compares the existing `git-commit` command in dev-tools with the new `ace-git-commit` gem implementation.

## Command Line API Comparison

### dev-tools git-commit

```bash
git-commit [options] [files...]
```

**Options:**
- `-d, --debug` - Enable debug output
- `-C, --repository REPO` - Specify explicit repository
- `-i, --intention INTENTION` - Intention context for commit message
- `-l, --local` - Use local LM Studio model
- `-n, --no-edit` - Skip editor, commit directly
- `-m, --message MESSAGE` - Use provided message (no LLM)
- `-a, --all` - Stage all changes before committing
- `--model MODEL` - Specify LLM model
- `--concurrent` - Execute commits concurrently
- `--main-only` - Process main repository only
- `--submodules-only` - Process submodules only
- `--repo-only` - Process only current repository

### ace-git-commit

```bash
ace-git-commit [options] [files...]
```

**Options:**
- `-i, --intention INTENTION` - Provide context for LLM generation ✅ (same)
- `-m, --message MESSAGE` - Use provided message (no LLM) ✅ (same)
- `--model MODEL` - Override default LLM model ✅ (same)
- `-s, --only-staged` - Commit only staged changes ⚡ (different from --all)
- `-n, --dry-run` - Show what would be committed ⚡ (different from --no-edit)
- `-d, --debug` - Enable debug output ✅ (same)
- `-f, --force` - Force operation (future use) ⚡ (new)
- `-h, --help` - Show help ✅ (standard)
- `-v, --version` - Show version ✅ (standard)

## Key Differences

### 1. Repository Scope

| Feature | dev-tools git-commit | ace-git-commit |
|---------|---------------------|----------------|
| Multi-repo support | ✅ Yes (submodules) | ❌ No |
| Concurrent execution | ✅ Yes | ❌ No |
| Repository selection | ✅ --repository, --main-only, etc. | ❌ Single repo only |
| Default scope | Current + submodules | Current repo only |

### 2. Staging Behavior

| Feature | dev-tools git-commit | ace-git-commit |
|---------|---------------------|----------------|
| Default behavior | Uses currently staged | **Stages ALL changes** |
| Stage all option | `--all` flag | Default (no flag needed) |
| Use only staged | Default behavior | `--only-staged` flag |
| Stage specific files | Pass as arguments | Pass as arguments |

### 3. LLM Integration

| Feature | dev-tools git-commit | ace-git-commit |
|---------|---------------------|----------------|
| LLM integration | Via subprocess (ace-llm-query) | **Direct Ruby (QueryInterface)** |
| Default model | google:gemini-2.0-flash-lite | glite (alias) |
| Local model support | `--local` flag | Via `--model lmstudio:*` |
| Model selection | `--model` flag | `--model` flag |
| System prompt location | Embedded in code | dev-handbook/templates/prompts/ |

### 4. Architecture

| Aspect | dev-tools git-commit | ace-git-commit |
|--------|---------------------|----------------|
| Pattern | Command pattern with orchestrator | **ATOM architecture** |
| Structure | CLI → Orchestrator → Multiple repos | CLI → Orchestrator → Single repo |
| Dependencies | Dry::CLI, complex orchestration | ace-core, ace-llm |
| Testing | Spec files with VCR | Minitest with mocks |

### 5. Additional Features

| Feature | dev-tools git-commit | ace-git-commit |
|---------|---------------------|----------------|
| Dry run | ❌ No | ✅ `--dry-run` |
| Editor support | ✅ `--no-edit` to skip | ❌ Always direct commit |
| Concurrent commits | ✅ `--concurrent` | ❌ Single repo only |
| Force flag | ❌ No | ✅ Future use |

## Migration Guide

### For Users

If you're migrating from dev-tools git-commit to ace-git-commit:

| Old Command | New Command |
|-------------|-------------|
| `git-commit` | `ace-git-commit` (stages all by default) |
| `git-commit --all` | `ace-git-commit` (default behavior) |
| `git-commit --intention "msg"` | `ace-git-commit -i "msg"` ✅ (same) |
| `git-commit --message "msg"` | `ace-git-commit -m "msg"` ✅ (same) |
| `git-commit --local` | `ace-git-commit --model lmstudio:model` |
| `git-commit --repo-only` | `ace-git-commit` (default, single repo) |
| `git-commit --concurrent` | ❌ Not supported (single repo only) |
| `git-commit file1 file2` | `ace-git-commit file1 file2` ✅ (same) |

### Key Behavioral Changes

1. **Default Staging**: ace-git-commit stages ALL changes by default
   - Old: `git-commit --all` to stage everything
   - New: `ace-git-commit` stages everything automatically
   - New: `ace-git-commit --only-staged` to use current staging

2. **Repository Scope**: ace-git-commit is single-repo only
   - Old: Processes submodules by default
   - New: Only processes current repository
   - Rationale: Simplified for true monorepo use

3. **LLM Integration**: Direct Ruby integration
   - Old: Subprocess call to ace-llm-query
   - New: Direct Ruby call via QueryInterface
   - Benefit: Better performance, error handling

## Implementation Status

### ace-git-commit Completed Features ✅

- [x] Core ATOM architecture
- [x] GitExecutor atom for git commands
- [x] DiffAnalyzer molecule for diff analysis
- [x] MessageGenerator with LLM integration
- [x] FileStager for staging logic
- [x] CommitOrchestrator for workflow
- [x] CommitOptions model
- [x] CLI with option parsing
- [x] Configuration support (YAML)
- [x] System prompt in dev-handbook
- [x] Comprehensive tests (22 passing)
- [x] README documentation

### Not Implemented (Out of Scope) ❌

- [ ] Multi-repository support
- [ ] Submodule handling
- [ ] Concurrent execution
- [ ] Editor integration (--no-edit)
- [ ] Complex repository filtering

## Recommendations

### Use ace-git-commit when:
- Working in a true monorepo (ace)
- Want automatic staging of all changes
- Need better LLM integration performance
- Prefer simpler, focused tooling

### Use dev-tools git-commit when:
- Need multi-repository support
- Working with submodules
- Need concurrent execution
- Require complex repository filtering

## Summary

`ace-git-commit` is a simplified, monorepo-focused reimplementation that:
- **Simplifies** the default workflow (auto-stages all changes)
- **Improves** LLM integration (direct Ruby calls)
- **Focuses** on single-repository use cases
- **Follows** ATOM architecture patterns
- **Reduces** complexity by removing multi-repo features

The trade-off is losing multi-repository and submodule support in favor of a cleaner, simpler implementation optimized for monorepo workflows.