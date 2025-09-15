---
id: v.0.3.0+task.87
status: done
priority: high
estimate: 4h
dependencies: []
---

# Consolidate duplicate PathResolver and GitCommandExecutor atoms

## 0. Directory Audit ✅

_Command run:_

```bash
find dev-tools/lib/coding_agent_tools/atoms -name "*path_resolver*" -o -name "*git_command_executor*" | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools/lib/coding_agent_tools/atoms/code/git_command_executor.rb
    dev-tools/lib/coding_agent_tools/atoms/code_quality/path_resolver.rb
    dev-tools/lib/coding_agent_tools/atoms/git/git_command_executor.rb
    dev-tools/lib/coding_agent_tools/atoms/git/path_resolver.rb
    dev-tools/lib/coding_agent_tools/atoms/path_resolver.rb
```

## Objective

Eliminate component duplication by consolidating multiple implementations of PathResolver and GitCommandExecutor atoms into single, canonical versions. This addresses the architectural issue of "component drift" where multiple slightly different implementations of the same concept create confusion and potential bugs.

## Scope of Work

- Analyze all PathResolver implementations (3 versions) to identify the most complete one
- Analyze both GitCommandExecutor implementations to identify the most secure/complete one
- Consolidate functionality into single implementations
- Update all references throughout the codebase
- Remove duplicate implementations

### Deliverables

#### Create

- None (consolidating existing code)

#### Modify

- All files that reference the duplicate atoms to use the consolidated versions
- dev-tools/lib/coding_agent_tools/atoms.rb (autoload configuration)

#### Delete

- dev-tools/lib/coding_agent_tools/atoms/path_resolver.rb (if not the chosen one)
- dev-tools/lib/coding_agent_tools/atoms/code_quality/path_resolver.rb (if not the chosen one)
- dev-tools/lib/coding_agent_tools/atoms/code/git_command_executor.rb (likely candidate for removal based on review)
- Corresponding test files for deleted atoms

## Phases

1. Analyze and compare implementations
2. Choose canonical versions
3. Merge unique features
4. Update references
5. Delete duplicates
6. Test thoroughly

## Implementation Plan

### Planning Steps

- [x] Analyze all three PathResolver implementations
  > TEST: PathResolver Analysis
  > Type: Pre-condition Check
  > Assert: All PathResolver implementations are compared
  > Command: cd dev-tools && for f in lib/coding_agent_tools/atoms/path_resolver.rb lib/coding_agent_tools/atoms/code_quality/path_resolver.rb lib/coding_agent_tools/atoms/git/path_resolver.rb; do echo "=== $f ==="; wc -l $f; grep "def self\." $f; done
- [x] Analyze both GitCommandExecutor implementations
  > TEST: GitCommandExecutor Analysis
  > Type: Pre-condition Check
  > Assert: Both implementations are compared for security and features
  > Command: cd dev-tools && diff -u lib/coding_agent_tools/atoms/code/git_command_executor.rb lib/coding_agent_tools/atoms/git/git_command_executor.rb
- [x] Identify which components are using each version
- [x] Document unique features in each implementation

### Execution Steps

- [x] Step 1: Choose canonical PathResolver implementation
  - Based on code review, atoms/git/path_resolver.rb appears most complete
  - Merge any unique features from other versions
- [x] Step 2: Choose canonical GitCommandExecutor implementation
  - atoms/git/git_command_executor.rb is preferred (uses Shellwords.escape)
  - atoms/code/git_command_executor.rb has command injection risk
- [x] Step 3: Update all references to use canonical PathResolver
  > TEST: Verify PathResolver References
  > Type: Action Validation
  > Assert: All references point to the chosen implementation
  > Command: cd dev-tools && grep -r "PathResolver" --include="*.rb" | grep -v "spec/" | grep -v "atoms/git/path_resolver.rb"
  > NOTE: Analysis shows different PathResolvers serve different purposes - no consolidation needed
- [x] Step 4: Update all references to use canonical GitCommandExecutor
  > TEST: Verify GitCommandExecutor References
  > Type: Action Validation
  > Assert: All references point to the secure implementation
  > Command: cd dev-tools && grep -r "GitCommandExecutor" --include="*.rb" | grep -v "spec/" | grep -v "atoms/git/git_command_executor.rb"
- [x] Step 5: Update autoload configuration in atoms.rb
- [x] Step 6: Skip deleting PathResolver files - they serve different purposes
- [x] Step 7: Delete insecure GitCommandExecutor and its tests
- [x] Step 8: Run all tests to ensure nothing is broken
  > TEST: All Tests Pass
  > Type: Integration Test
  > Assert: All tests pass after consolidation
  > Command: cd dev-tools && bundle exec rspec
- [x] Step 9: Test git-related commands still work
  > TEST: Git Commands Work
  > Type: Functional Test
  > Assert: Git commands function correctly
  > Command: cd dev-tools && bundle exec exe/git-status

## Acceptance Criteria

- [x] AC 1: PathResolver implementations verified to serve different purposes - kept separate
- [x] AC 2: Only one GitCommandExecutor implementation remains in atoms/
- [x] AC 3: The remaining GitCommandExecutor uses proper security (Shellwords.escape)
- [x] AC 4: All references throughout codebase updated to use secure GitCommandExecutor
- [x] AC 5: All tests pass after consolidation
- [x] AC 6: Git-related CLI commands continue to function correctly
- [x] AC 7: No functionality is lost during consolidation

## Out of Scope

- ❌ Refactoring the implementation logic of the chosen atoms
- ❌ Adding new features to PathResolver or GitCommandExecutor
- ❌ Changing the public interface of these atoms

## References

- Code review report: dev-taskflow/current/v.0.3.0-workflows/code_review/code-dev-tools-lib-20250724-184702/cr-report-gpro.md (lines 50-54, 128-132)
- Security concern about command injection in atoms/code/git_command_executor.rb
- Recommendation to use atoms/git/ versions as most feature-complete