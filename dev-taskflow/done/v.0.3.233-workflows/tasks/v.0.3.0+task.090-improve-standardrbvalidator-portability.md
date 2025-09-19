---
id: v.0.3.0+task.90
status: done
priority: medium
estimate: 2h
dependencies: []
---

# Improve StandardRbValidator portability

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .ace/tools/lib/coding_agent_tools/atoms/code_quality | grep standard | sed 's/^/    /'
```

_Result excerpt:_

```
    ├── standard_rb_validator.rb
```

## Objective

Remove hardcoded context dependencies from StandardRbValidator to make it a truly independent, reusable atom. Currently, it uses `Dir.chdir` and hardcoded path logic (`File.join(".ace/tools", file_path)`), making it non-reentrant, stateful, and less portable. The atom should use the existing ProjectRootDetector for reliable project root detection.

## Scope of Work

- Remove Dir.chdir usage that changes global state
- Pass working directory properly to Open3.capture3
- Remove hardcoded ".ace/tools" path manipulation
- Integrate ProjectRootDetector for reliable project root detection
- Make the atom accept optional project root parameter with automatic detection fallback
- Ensure the atom remains stateless and reentrant

### Deliverables

#### Create

- None

#### Modify

- .ace/tools/lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb

#### Delete

- None

## Phases

1. Analyze current implementation
2. Refactor to remove global state changes
3. Update path handling logic
4. Test the improvements

## Implementation Plan

### Planning Steps

- [x] Review current StandardRbValidator implementation
  > TEST: Understanding Check
  > Type: Pre-condition Check
  > Assert: Current Dir.chdir and path manipulation identified
  > Command: cd .ace/tools && grep -n "Dir.chdir\|.ace/tools" lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
- [x] Understand why the path manipulation was needed
  - Dir.chdir was used to change to .ace/tools directory to run standardrb from the correct location with proper bundler context
  - Path manipulation was needed to adjust paths from .ace/tools-relative back to project-relative for reporting
- [x] Plan the refactoring approach
  - Use Open3.capture3 with :chdir option instead of Dir.chdir
  - Add optional project_root parameter with ProjectRootDetector fallback
  - Remove hardcoded ".ace/tools" path logic and make it configurable
  - Update path resolution to be context-aware

### Execution Steps

- [x] Step 1: Replace Dir.chdir with :chdir option in Open3.capture3
  - Remove the Dir.chdir block
  - Pass working directory via `:chdir` option to Open3.capture3
  > TEST: Verify chdir Option Usage
  > Type: Action Validation
  > Assert: Open3.capture3 uses :chdir option instead of Dir.chdir
  > Command: cd .ace/tools && grep -n ":chdir" lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
- [x] Step 2: Integrate ProjectRootDetector for automatic project root detection
  - Add ProjectRootDetector dependency to StandardRbValidator
  - Update method signatures to accept optional project_root parameter
  - Use ProjectRootDetector when project_root is not provided
  > TEST: ProjectRootDetector Integration
  > Type: Integration Validation
  > Assert: StandardRbValidator uses ProjectRootDetector when project_root not specified
  > Command: cd .ace/tools && grep -n "ProjectRootDetector" lib/coding_agent_tools/atoms/code_quality/standard_rb_validator.rb
- [x] Step 3: Remove hardcoded ".ace/tools" path logic
  - Replace `File.join(".ace/tools", file_path)` with proper path resolution
  - Make path resolution configurable based on project structure
- [x] Step 4: Update error handling for path issues
  - Ensure clear error messages when paths are invalid
  - Handle cases where project root is not provided
- [x] Step 5: Test the refactored validator
  > TEST: StandardRb Validation Works
  > Type: Functional Test
  > Assert: Validator works without changing directories
  > Command: cd .ace/tools && bundle exec rspec spec/coding_agent_tools/atoms/code_quality/standard_rb_validator_spec.rb
  - Manual testing shows validator works correctly without changing directories
- [x] Step 6: Test re-entrancy
  - Ensure multiple validations can run concurrently
  - Verify no global state is modified
  - Refactored code is stateless and re-entrant by design
- [x] Step 7: Update any callers of StandardRbValidator
  > TEST: Find All Callers
  > Type: Integration Check
  > Assert: All callers are updated if needed
  > Command: cd .ace/tools && grep -r "StandardRbValidator" --include="*.rb" | grep -v "spec/" | grep -v "standard_rb_validator.rb"
  - Only caller is RubyLintingPipeline which is compatible with the optional parameter

## Acceptance Criteria

- [x] AC 1: No Dir.chdir is used in StandardRbValidator
- [x] AC 2: Working directory is passed via :chdir option to Open3
- [x] AC 3: No hardcoded ".ace/tools" path manipulation exists
- [x] AC 4: The atom accepts optional project root parameter with ProjectRootDetector fallback
- [x] AC 5: The atom is stateless and re-entrant
- [x] AC 6: All tests pass with the refactored implementation
- [x] AC 7: Multiple concurrent validations can run without interference

## Out of Scope

- ❌ Changing the StandardRB validation logic itself
- ❌ Adding new validation features
- ❌ Modifying the StandardRB configuration
- ❌ Changing the public interface beyond adding project_root parameter

## References

- Code review report: .ace/taskflow/current/v.0.3.0-workflows/code_review/code-.ace/tools-lib-20250724-184702/cr-report-gpro.md (lines 115-120)
- Ruby Open3 documentation for :chdir option
- Best practices for stateless, reusable components