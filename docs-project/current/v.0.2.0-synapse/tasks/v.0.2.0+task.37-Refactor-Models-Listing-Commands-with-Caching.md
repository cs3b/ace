---
id: v.0.2.0+task.37
title: Refactor Models Listing Commands with Caching
status: pending
priority: high
assignee: unassigned
labels:
  - enhancement
  - refactoring
  - cli
dependencies: []
estimated_hours: 8
actual_hours: 0
created_at: 2024-01-01
updated_at: 2024-01-01
---

# Refactor Models Listing Commands with Caching

## Objective / Problem Statement

Currently, we have separate binaries for listing models from different providers (`llm-gemini-models` and `llm-lmstudio-models`). This creates maintenance overhead and inconsistent user experience. Additionally, model information is fetched from APIs on every call, which is inefficient since model availability doesn't change frequently. We also lack cost information for models, which is crucial for users to make informed decisions.

## Directory Audit

```bash
tree -L 1 exe | head -20

exe
├── coding_agent_tools
├── llm-gemini-models
├── llm-gemini-query
├── llm-lmstudio-models
└── llm-lmstudio-query

1 directory, 5 files
```

## Scope of Work

- Consolidate `llm-gemini-models` and `llm-lmstudio-models` into a single `llm-models` command
- Implement caching mechanism for model information

- Create cache management functionality (read from cache by default, refresh on demand)

## Deliverables / Manifest

- [ ] Create new `exe/llm-models` binary
- [ ] Remove `exe/llm-gemini-models` binary
- [ ] Remove `exe/llm-lmstudio-models` binary
- [ ] Create cache directory structure at `.coding-agent-tools-cache/`
- [ ] Implement cache storage format (YAML) for model data
- [ ] Update relevant documentation

## Phases

1. **Design Phase**: Design cache structure and unified command interface
2. **Implementation Phase**: Create unified binary with provider selection
3. **Caching Phase**: Implement cache storage and retrieval logic

5. **Migration Phase**: Remove old binaries and update references
6. **Documentation Phase**: Update user guides and examples

## Implementation Plan

### Planning Steps
* [ ] Research optimal cache structure and format (YAML vs JSON)
* [ ] Design unified CLI interface for multiple providers
* [ ] Plan cost information retrieval strategy (API vs LLM-assisted search)
* [ ] Determine cache invalidation strategy and refresh mechanism

### Execution Steps
- [ ] Consolidate `llm-gemini-models` and `llm-lmstudio-models` by refactoring `lib/coding_agent_tools/cli/commands/llm/models.rb` to become the unified command.
  ```bash
  llm-models <provider>  # default: google
  llm-models google
  llm-models lmstudio
  ```
- [ ] Delete `lib/coding_agent_tools/cli/commands/lms/models.rb`
- [ ] Merge relevant, unique test cases from `spec/coding_agent_tools/cli/commands/lms/models_spec.rb` into `spec/coding_agent_tools/cli/commands/llm/models_spec.rb`
- [ ] Delete `spec/coding_agent_tools/cli/commands/lms/models_spec.rb`
- [ ] Implement base caching infrastructure
  - [ ] Create `.coding-agent-tools-cache/` directory structure
  - [ ] Implement cache file format (YAML) per provider
  - [ ] Add cache read/write logic
- [ ] Migrate existing Gemini models listing functionality
  > TEST: Gemini Models Listing
  >   Type: Action Validation
  >   Assert: llm-models google returns same output as llm-gemini-models
  >   Command: bin/test --compare-outputs "llm-models google" "llm-gemini-models"
- [ ] Migrate existing LMStudio models listing functionality
  > TEST: LMStudio Models Listing
  >   Type: Action Validation
  >   Assert: llm-models lmstudio returns same output as llm-lmstudio-models
  >   Command: bin/test --compare-outputs "llm-models lmstudio" "llm-lmstudio-models"
- [ ] Implement cache-first retrieval logic
  - [ ] Read from cache by default
  - [ ] Add `--refresh` or `--fetch-from-api` flag for updates
  - [ ] Only update changed models on refresh

- [ ] Remove deprecated binaries
  - [ ] Delete `exe/llm-gemini-models`
  - [ ] Delete `exe/llm-lmstudio-models`
- [ ] Update all references in codebase
- [ ] Update documentation and examples

## Acceptance Criteria

- [ ] Single `llm-models` command handles all providers
- [ ] Default provider is Google/Gemini when no argument provided
- [ ] Cache is used by default for faster response times
- [ ] `--refresh` flag fetches latest data from APIs

- [ ] Cache files are stored in `.coding-agent-tools-cache/` with provider-specific YAML files
- [ ] Old `llm-gemini-models` and `llm-lmstudio-models` commands are removed
- [ ] All tests pass after migration
- [ ] Documentation is updated with new command usage

## Out of Scope

- Adding new providers (OpenAI, Anthropic, Mixtral) - this is covered in a separate task
- The implementation of *detailed* cost calculation, storage, and reporting is explicitly out of scope for this task and will be addressed in `v.0.2.0+task.40`. This task should *not* introduce new data structures or logic for recording cost per token, beyond what is necessary for model listing.
- Implementing actual cost tracking during usage - this is covered in a separate task
- Complex cache invalidation strategies (time-based, etc.)

## References & Risks

- Current implementation: `exe/llm-gemini-models`, `exe/llm-lmstudio-models`
- Cache format should be extensible for future providers
- Risk: Breaking changes for users relying on old commands - mitigate with clear migration guide
## Anticipated Changes

This task will likely require modifications to: `exe/llm-models`, `lib/coding_agent_tools/cli.rb`, `lib/coding_agent_tools/cli/commands/llm/models.rb`, `README.md`, `CHANGELOG.md`, `docs/blueprint.md`, `docs/llm-integration/model-management.md`. It will also involve the deletion of `exe/llm-gemini-models`, `exe/llm-lmstudio-models`, `lib/coding_agent_tools/cli/commands/lms/models.rb`, and `spec/coding_agent_tools/cli/commands/lms/models_spec.rb`. Test updates will be required in `spec/coding_agent_tools/cli/commands/llm/models_spec.rb`.

- Consider using existing Ruby cache libraries vs custom implementation