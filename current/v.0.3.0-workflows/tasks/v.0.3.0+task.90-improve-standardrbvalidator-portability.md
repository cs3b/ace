---
id: v.0.3.0+task.90
status: pending
priority: medium
estimate: 2h
dependencies: []
---

# Improve StandardRbValidator portability

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/atoms/code_quality | grep standard | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── standard_rb_validator.rb
```

## Objective

Remove hardcoded context dependencies from StandardRbValidator to make it a truly independent, reusable atom. Currently, it uses `Dir.chdir` and hardcoded path logic (`File.join("dev-tools", file_path)`), making it non-reentrant, stateful, and less portable. The atom should use the existing ProjectRootDetector for reliable project root detection.

## Scope of Work

- Remove Dir.chdir usage that changes global state
- Pass working directory properly to Open3.capture3
- Remove hardcoded "dev-tools" path manipulation
- Integrate ProjectRootDetector for reliable project root detection
- Make the atom accept optional project root parameter with automatic detection fallback
- Ensure the atom remains stateless and reentrant

### Deliverables

#### Create

- None

#### Modify

- dev-tools/lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb

#### Delete

- None

## Phases

1. Analyze current implementation
2. Refactor to remove global state changes
3. Update path handling logic
4. Test the improvements

## Implementation Plan

### Planning Steps

- [ ] Review current StandardRbValidator implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current Dir.chdir and path manipulation identified
  > Command: cd dev-tools && grep -n "Dir.chdir\|dev-tools" lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
- [ ] Understand why the path manipulation was needed
- [ ] Plan the refactoring approach

### Execution Steps

- [ ] Step 1: Replace Dir.chdir with :chdir option in Open3.capture3
  - Remove the Dir.chdir block
  - Pass working directory via `:chdir` option to Open3.capture3
  > TEST: Verify chdir Option Usage
  > Type: Action Validation
  > Assert: Open3.capture3 uses :chdir option instead of Dir.chdir
  > Command: cd dev-tools && grep -n ":chdir" lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
- [ ] Step 2: Integrate ProjectRootDetector for automatic project root detection
  - Add ProjectRootDetector dependency to StandardRbValidator
  - Update method signatures to accept optional project_root parameter
  - Use ProjectRootDetector when project_root is not provided
  > TEST: ProjectRootDetector Integration
  > Type: Integration Validation
  > Assert: StandardRbValidator uses ProjectRootDetector when project_root not specified
  > Command: cd dev-tools && grep -n "ProjectRootDetector" lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
- [ ] Step 3: Remove hardcoded "dev-tools" path logic
  - Replace `File.join("dev-tools", file_path)` with proper path resolution
  - Make path resolution configurable based on project structure
- [ ] Step 4: Update error handling for path issues
  - Ensure clear error messages when paths are invalid
  - Handle cases where project root is not provided
- [ ] Step 5: Test the refactored validator
  > TEST: StandardRb Validation Works
  > Type: Functional Test
  > Assert: Validator works without changing directories
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/standard_rb_validator_spec.rb
- [ ] Step 6: Test re-entrancy
  - Ensure multiple validations can run concurrently
  - Verify no global state is modified
- [ ] Step 7: Update any callers of StandardRbValidator
  > TEST: Find All Callers
  > Type: Integration Check
  > Assert: All callers are updated if needed
  > Command: cd dev-tools && grep -r "StandardRbValidator" --include="*.rb" | grep -v "spec/" | grep -v "standard_rb_validator.rb"

## Acceptance Criteria

- [ ] AC 1: No Dir.chdir is used in StandardRbValidator
- [ ] AC 2: Working directory is passed via :chdir option to Open3
- [ ] AC 3: No hardcoded "dev-tools" path manipulation exists
- [ ] AC 4: The atom accepts optional project root parameter with ProjectRootDetector fallback
- [ ] AC 5: The atom is stateless and re-entrant
- [ ] AC 6: All tests pass with the refactored implementation
- [ ] AC 7: Multiple concurrent validations can run without interference

## Out of Scope

- ❌ Changing the StandardRB validation logic itself
- ❌ Adding new validation features
- ❌ Modifying the StandardRB configuration
- ❌ Changing the public interface beyond adding project_root parameter

## References

- Code review report: dev-taskflow/current/v.0.3.0-workflows/code_review/code-dev-tools-lib-20250724-184702/cr-report-gpro.md (lines 115-120)
- Ruby Open3 documentation for :chdir option
- Best practices for stateless, reusable components