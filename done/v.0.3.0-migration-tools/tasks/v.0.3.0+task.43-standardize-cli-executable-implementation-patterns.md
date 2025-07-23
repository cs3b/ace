---
id: v.0.3.0+task.43
status: done
priority: high
estimate: 6h
dependencies: []
---

# Standardize CLI Executable Implementation Patterns

## 0. Directory Audit ✅

_Command run:_

```bash
ls -la dev-tools/exe/ | head -10 | sed 's/^/    /'
```

_Result excerpt:_

```
    total 192
    drwxr-xr-x  28 user  staff   896 Jan 14 12:00 .
    drwxr-xr-x  12 user  staff   384 Jan 14 12:00 ..
    -rwxr-xr-x   1 user  staff   314 Jan 14 12:00 code-review
    -rwxr-xr-x   1 user  staff   314 Jan 14 12:00 git-add
    -rwxr-xr-x   1 user  staff  2156 Jan 14 12:00 git-commit
    -rwxr-xr-x   1 user  staff  1843 Jan 14 12:00 git-status
    -rwxr-xr-x   1 user  staff   314 Jan 14 12:00 llm-query
```

## Objective

Address code review feedback by standardizing all CLI executable implementations to use the consistent `ExecutableWrapper` molecule pattern. Currently, executables use two different implementation approaches: clean `ExecutableWrapper` pattern (e.g., `llm-query`, `git-add`) and manual argument parsing logic (e.g., `git-commit`, `git-status`, `code-lint`). This creates inconsistency, increases maintenance burden, and duplicates CLI entry point logic.

## Scope of Work

- Audit all executables in `dev-tools/exe/` to identify inconsistent implementation patterns
- Refactor executables using manual argument parsing to use `ExecutableWrapper` molecule
- Ensure all executables follow the same clean, consistent pattern
- Verify functionality is preserved after refactoring
- Update any necessary CLI command registrations or wrapper configurations

### Deliverables

#### Create

- None (refactoring existing files)

#### Modify

- dev-tools/exe/git-commit (refactor to use ExecutableWrapper)
- dev-tools/exe/git-status (refactor to use ExecutableWrapper)
- dev-tools/exe/code-lint (refactor to use ExecutableWrapper)
- Any other executables identified during audit that use manual parsing

#### Delete

- None

## Phases

1. **Audit Phase**: Identify all executables and categorize by implementation pattern
2. **Analysis Phase**: Understand ExecutableWrapper requirements and current manual parsing logic
3. **Refactoring Phase**: Convert manual parsing executables to ExecutableWrapper pattern
4. **Testing Phase**: Verify all executables work correctly after refactoring

## Implementation Plan

### Planning Steps

- [x] Audit all executables in dev-tools/exe/ and categorize by implementation pattern
  > TEST: Pattern Analysis
  > Type: Pre-condition Check
  > Assert: All executables categorized as either ExecutableWrapper or manual parsing
  > Command: find dev-tools/exe/ -type f -exec head -15 {} \; | grep -E "(ExecutableWrapper|ARGV|case.*when)"
- [x] Analyze ExecutableWrapper molecule to understand its interface and requirements
  > TEST: ExecutableWrapper Understanding
  > Type: Pre-condition Check
  > Assert: ExecutableWrapper interface, command_path, and registration_method understood
  > Command: cd dev-tools && rspec spec/unit/coding_agent_tools/molecules/executable_wrapper_spec.rb -v
- [x] Review existing manual parsing logic to understand argument handling requirements
- [x] Plan migration strategy ensuring no functionality loss

### Execution Steps

- [x] Refactor git-commit executable to use ExecutableWrapper pattern
  > TEST: Git Commit Executable
  > Type: Action Validation
  > Assert: git-commit executable uses ExecutableWrapper and preserves all functionality
  > Command: cd dev-tools && exe/git-commit --help && echo "Test intention flag:" && exe/git-commit --intention "test" --dry-run
- [x] Refactor git-status executable to use ExecutableWrapper pattern
  > TEST: Git Status Executable
  > Type: Action Validation
  > Assert: git-status executable uses ExecutableWrapper and preserves all functionality
  > Command: cd dev-tools && exe/git-status --help && exe/git-status --verbose
- [x] Refactor code-lint executable to use ExecutableWrapper pattern (if it uses manual parsing)
  > TEST: Code Lint Executable
  > Type: Action Validation
  > Assert: code-lint executable uses ExecutableWrapper and preserves all functionality
  > Command: cd dev-tools && exe/code-lint --help
- [x] Refactor any other executables identified during audit
- [x] Update CLI command registrations if needed for ExecutableWrapper integration
- [x] Verify all executables use consistent implementation pattern
  > TEST: Pattern Consistency
  > Type: Final Validation
  > Assert: All executables in dev-tools/exe/ use ExecutableWrapper pattern
  > Command: find dev-tools/exe/ -type f -exec grep -l "ExecutableWrapper" {} \; | wc -l && find dev-tools/exe/ -type f | wc -l

## Acceptance Criteria

- [x] All executables in dev-tools/exe/ use the ExecutableWrapper molecule pattern
- [x] No executables contain manual argument parsing logic (ARGV handling, case statements)
- [x] All existing functionality is preserved (help text, argument handling, command behavior)
- [x] Code is more maintainable with reduced boilerplate across executables
- [x] CLI entry point logic is centralized in ExecutableWrapper molecule

## Out of Scope

- ❌ Changing the functionality or behavior of any executable commands
- ❌ Modifying the ExecutableWrapper molecule interface or implementation
- ❌ Adding new CLI commands or executables
- ❌ Changing the underlying CLI command classes that executables wrap
- ❌ Updating documentation beyond what's needed for the refactoring

## References

**Code Review Feedback:**
> **Inconsistent CLI Executable Implementation**: The new `exe/` scripts use two different implementation patterns. Most use the clean `ExecutableWrapper` molecule (e.g., `llm-query`, `git-add`), but some contain manual argument parsing logic (e.g., `git-commit`, `git-status`, `code-lint`).
> **Suggestion**: Refactor all executables to use the `ExecutableWrapper` pattern. This will improve consistency, reduce boilerplate, and centralize the CLI entry point logic.

**Implementation References:**
- Good example: dev-tools/exe/llm-query (uses ExecutableWrapper)
- Good example: dev-tools/exe/git-add (uses ExecutableWrapper)
- Needs refactoring: dev-tools/exe/git-commit (manual parsing)
- Needs refactoring: dev-tools/exe/git-status (manual parsing)
- ExecutableWrapper molecule: lib/coding_agent_tools/molecules/executable_wrapper.rb