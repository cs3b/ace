---
id: v.0.2.0+task.43
status: done
priority: high
estimate: 6h
dependencies: []
---

# Align Provider Naming Throughout Codebase (Use `google` instead of `gemini`)

## 0. Directory Audit ✅

_Command run:_

```bash
find . -name "*.rb" -o -name "*.md" -o -name "*.yml" | grep -E "(gemini|google)" | head -20
```

_Result excerpt:_

```
./exe/llm-gemini-query
./lib/coding_agent_tools/organisms/gemini_client.rb
./lib/coding_agent_tools/cli/commands/llm/gemini_query.rb
./spec/coding_agent_tools/organisms/gemini_client_spec.rb
./spec/fixtures/gemini_models.json
./docs/guides/llm-gemini-query.md
```

## Objective

Standardize provider naming throughout the codebase by using `google` instead of `gemini` for consistency with industry standards and future extensibility. This addresses Priority 1 from the code review findings and establishes a unified naming convention that will support the upcoming unified CLI entry-point.

## Scope of Work

- Rename executables and directories from `gemini` to `google`
- Update class names, constants, and variable names
- Modify YAML model metadata and configuration files
- Update test fixtures and specifications
- Relocate command class with backward-compatibility alias
- Update documentation references

### Deliverables

#### Create

- `exe/llm-google-query` (new primary executable)
- `lib/coding_agent_tools/organisms/google_client.rb`
- `lib/coding_agent_tools/cli/commands/llm/google_query.rb`
- `spec/coding_agent_tools/organisms/google_client_spec.rb`
- `spec/fixtures/google_models.json`

#### Modify

- `lib/coding_agent_tools/cli/commands.rb` (register new command)
- `lib/coding_agent_tools.rb` (update requires)
- `coding_agent_tools.gemspec` (update executables)
- `docs/guides/llm-google-query.md` (rename and update content)
- CI configuration files
- README.md and other documentation

#### Delete

- Legacy files after migration (kept initially for backward compatibility)

## Phases

1. Audit current usage of `gemini` naming
2. Create new `google`-named components
3. Update internal references and dependencies
4. Migrate tests and fixtures
5. Update documentation and CI
6. Add backward-compatibility aliases

## Implementation Plan

### Planning Steps

* [x] Audit all files containing `gemini` references to understand scope
  > TEST: Naming Audit Complete
  > Type: Pre-condition Check
  > Assert: All gemini references are catalogued and migration plan is documented
  > Command: grep -r "gemini" . --include="*.rb" --include="*.md" --include="*.yml" | wc -l
* [x] Design backward-compatibility strategy for existing users
* [x] Plan migration sequence to avoid breaking changes

### Execution Steps

- [x] Create new `GoogleClient` class by copying and renaming `GeminiClient`
  > TEST: Google Client Creation
  > Type: Action Validation
  > Assert: New GoogleClient class exists and compiles without errors
  > Command: ruby -c lib/coding_agent_tools/organisms/google_client.rb
- [x] Create new `llm-google-query` executable
- [x] Update class references in new GoogleClient to use consistent naming
- [x] Create new command class `Google::Query` in appropriate namespace
- [x] Update model fixtures to use `google` provider naming
- [x] Update test specifications for new Google classes
  > TEST: Test Suite Passes
  > Type: Action Validation
  > Assert: All new tests pass and existing functionality is preserved
  > Command: bundle exec rspec spec/coding_agent_tools/organisms/google_client_spec.rb
- [x] Update CLI registration to include new Google command
- [x] Add backward-compatibility alias for `gemini` commands
- [x] Update gemspec to include new executable
- [x] Update documentation to reference new naming convention
- [x] Update CI configuration to test new executable

## Acceptance Criteria

- [x] AC 1: New `llm-google-query` executable works identically to `llm-gemini-query`
- [x] AC 2: All tests pass with new Google-named classes
- [x] AC 3: Backward compatibility maintained - existing `llm-gemini-query` still works
- [x] AC 4: Documentation updated to reflect new naming convention
- [x] AC 5: CI passes with new executable included
- [x] AC 6: Model metadata uses `google` as provider identifier

## Out of Scope

- ❌ Removing old `gemini` naming completely (kept for backward compatibility)
- ❌ Implementing the unified `llm-query` entry-point (separate task)
- ❌ Changing API response structures or data formats

## References

- [Code Review Task 39 - Priority 1 Requirements](../code-review/task.39/cr-user.md)
- [ATOM Architecture Guide](../../../../docs/architecture.md)
- [Testing Standards](../../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md)