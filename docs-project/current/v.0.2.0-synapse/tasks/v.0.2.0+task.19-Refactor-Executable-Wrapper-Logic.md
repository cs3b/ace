---
id: v.0.2.0+task.19
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Refactor Executable Wrapper Logic

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 exe/ && tree -L 3 lib/coding_agent_tools/cli/
```

_Result excerpt:_

```
exe/
├── llm-gemini-models
├── llm-lmstudio-models
├── llm-lmstudio-query
└── llm-gemini-query

lib/coding_agent_tools/cli/
├── commands/
│   ├── llm/
│   │   └── models.rb
│   └── lms/
│       └── models.rb
└── base.rb
```

## Objective

Extract shared wrapper logic from `exe/*` scripts to eliminate code duplication and improve maintainability. The current implementation violates DRY principles with repeated patterns across executable scripts.

## Scope of Work

- Analyze common patterns across all `exe/*` scripts
- Create shared wrapper module/class for common functionality
- Refactor existing executables to use shared logic
- Ensure all executables maintain identical functionality
- Add comprehensive tests for the new shared module

### Deliverables

#### Create

- lib/coding_agent_tools/cli/executable_wrapper.rb
- spec/coding_agent_tools/cli/executable_wrapper_spec.rb

#### Modify

- exe/llm-gemini-models
- exe/llm-lmstudio-models
- exe/llm-lmstudio-query
- exe/llm-gemini-query (if exists)

## Phases

1. Audit - Identify common patterns across executable scripts
2. Extract - Create shared wrapper module with common functionality
3. Refactor - Update existing executables to use shared logic
4. Verify - Ensure all executables maintain same behavior

## Implementation Plan

### Planning Steps

* [ ] Analyze all `exe/*` scripts to identify common patterns and shared logic
  > TEST: Pattern Analysis Complete
  > Type: Pre-condition Check
  > Assert: Common patterns are documented and shared functionality identified
  > Command: diff -u exe/llm-gemini-models exe/llm-lmstudio-models | head -50
* [ ] Design shared wrapper module interface to accommodate all use cases
* [ ] Plan refactoring strategy to maintain backward compatibility

### Execution Steps

- [ ] Create base ExecutableWrapper module with common functionality
  > TEST: Wrapper Module Created
  > Type: Action Validation
  > Assert: ExecutableWrapper module is properly defined and loadable
  > Command: ruby -r "./lib/coding_agent_tools/cli/executable_wrapper" -e "puts CodingAgentTools::Cli::ExecutableWrapper"
- [ ] Extract common error handling, argument parsing, and setup logic
- [ ] Implement shared command execution pattern
- [ ] Add comprehensive tests for ExecutableWrapper module
  > TEST: Wrapper Tests Pass
  > Type: Action Validation
  > Assert: All ExecutableWrapper tests pass with good coverage
  > Command: bin/test spec/coding_agent_tools/cli/executable_wrapper_spec.rb
- [ ] Refactor exe/llm-gemini-models to use shared wrapper
- [ ] Refactor exe/llm-lmstudio-models to use shared wrapper
- [ ] Refactor exe/llm-lmstudio-query to use shared wrapper
- [ ] Refactor remaining exe/* scripts to use shared wrapper
- [ ] Verify all executables maintain identical command-line behavior
  > TEST: Executable Behavior Preserved
  > Type: Action Validation
  > Assert: All executables produce same output as before refactoring
  > Command: bin/test --check-executable-compatibility
- [ ] Update documentation for new shared wrapper approach

## Acceptance Criteria

- [ ] All `exe/*` scripts use shared ExecutableWrapper module
- [ ] No code duplication remains between executable scripts
- [ ] All executables maintain identical command-line interface behavior
- [ ] ExecutableWrapper module has comprehensive test coverage (>90%)
- [ ] Error handling is consistent across all executables
- [ ] Performance impact is negligible (< 5% execution time increase)
- [ ] Code follows established patterns and conventions

## Out of Scope

- ❌ Changing command-line interface or adding new features
- ❌ Refactoring CLI command classes (only executable scripts)
- ❌ Adding new executable scripts beyond existing ones
- ❌ Modifying underlying CLI framework or architecture

## References

- [Ruby executable script best practices](https://github.com/rubygems/rubygems/wiki/Make-your-own-gem#adding-an-executable)
- [DRY principle documentation](https://en.wikipedia.org/wiki/Don%27t_repeat_yourself)
- [CLI wrapper pattern examples](https://github.com/dry-rb/dry-cli/blob/master/examples/)
- [Project coding standards](docs-dev/guides/coding-standards.md)