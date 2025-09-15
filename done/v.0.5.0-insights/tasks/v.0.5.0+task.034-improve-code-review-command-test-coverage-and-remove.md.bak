---
id: v.0.5.0+task.034
status: completed
priority: high
estimate: 8-10h
dependencies: [v.0.5.0+task.028, v.0.5.0+task.033]
---

# Improve code-review command test coverage and remove deprecated prepare command

## Behavioral Specification

### User Experience
- **Input**: Developers run `code-review` command with various presets, configurations, and options
- **Process**: Command executes reliably with comprehensive test coverage, proper error handling, and clear feedback messages
- **Output**: Consistent, high-quality code reviews with proper path handling and no legacy code artifacts

### Expected Behavior
The code-review system should provide a robust, well-tested command-line interface that handles all configuration scenarios gracefully. Users should experience consistent behavior across different presets, proper error messages for invalid configurations, and reliable execution without encountering untested code paths or deprecated commands.

The system should:
- Execute successfully with any valid preset or configuration combination
- Provide clear error messages for invalid inputs or missing dependencies
- Handle edge cases like missing files, invalid YAML, or network failures gracefully
- Maintain high code quality through comprehensive test coverage
- Remove all deprecated and unused code to reduce maintenance burden

### Interface Contract
```bash
# CLI Interface - Primary command remains unchanged
code-review --preset <name> [options]
code-review --context <yaml> --subject <yaml> [options]
code-review --list-presets

# Deprecated command should no longer exist
code-review-prepare  # Expected: Command not found error

# Expected outputs for various scenarios
code-review --preset invalid-preset
# Error: Preset 'invalid-preset' not found. Available presets: pr, code, docs, ...

code-review --context 'invalid: yaml: structure'
# Error: Invalid YAML in context parameter: [specific error details]

code-review --preset pr --auto-execute
# Success: Review completed and saved to [output path]
```

**Error Handling:**
- Invalid preset: Clear error with list of available presets
- Malformed YAML: Specific parsing error with line/column info
- Missing files: Graceful degradation with warning messages
- Network failures: Retry logic with timeout and clear error messages
- Invalid configuration: Validation errors with correction suggestions

**Edge Cases:**
- Empty context or subject: Proceed with warning
- Very large diffs: Handle with chunking or size limits
- Concurrent executions: Proper session isolation
- Interrupted execution: Clean up temporary files

### Success Criteria
- [ ] **Test Coverage**: Code-review command and related molecules have >80% test coverage
- [ ] **Command Removal**: code-review-prepare command completely removed from codebase
- [ ] **Clean Root**: All debug scripts removed from project root directory
- [ ] **Code Quality**: Complex methods refactored into smaller, testable units
- [ ] **Path Consistency**: All LLM query invocations use absolute paths
- [ ] **Error Handling**: Comprehensive error handling with helpful messages
- [ ] **Documentation**: All references to deprecated commands removed

### Validation Questions
- [ ] **Test Framework**: Should we use RSpec, Minitest, or another framework for new tests?
- [ ] **Coverage Target**: Is 80% coverage sufficient or should we aim for 90%+?
- [ ] **Deprecation Notice**: Should we add a deprecation warning before removing code-review-prepare?
- [ ] **Backward Compatibility**: Are there any scripts or workflows depending on code-review-prepare?

## Objective

Improve the reliability and maintainability of the code-review command by adding comprehensive test coverage, removing deprecated code, and refactoring complex methods. This ensures the new preset-based architecture is stable and production-ready.

## Scope of Work

- **User Experience Scope**: All code-review command interactions and error scenarios
- **System Behavior Scope**: Test coverage, error handling, and code quality improvements
- **Interface Scope**: Maintaining current CLI interface while removing deprecated commands

### Deliverables

#### Behavioral Specifications
- Comprehensive test scenarios for all command options
- Error handling specifications for edge cases
- Performance expectations for large reviews

#### Validation Artifacts
- Test coverage reports showing >80% coverage
- Verification that code-review-prepare is fully removed
- Confirmation that all debug scripts are deleted

## Out of Scope

- ❌ **New Features**: Adding new functionality to code-review command
- ❌ **Interface Changes**: Modifying the current CLI interface
- ❌ **Performance Optimization**: Speed improvements beyond fixing obvious issues
- ❌ **External Integrations**: Adding new LLM providers or services

## Technical Approach

### Architecture Pattern
- Maintain ATOM architecture with clear separation between atoms, molecules, and organisms
- Keep test files parallel to implementation files following Ruby conventions
- Use dependency injection for better testability

### Technology Stack
- RSpec for comprehensive unit and integration testing
- SimpleCov for code coverage reporting
- VCR for HTTP interaction recording (needs Ruby 3.4.2 compatibility fix)
- Existing Ruby testing infrastructure

### Implementation Strategy
- Phase 1: Add comprehensive tests before any code removal
- Phase 2: Remove deprecated command and related code
- Phase 3: Refactor complex methods with tests in place
- Phase 4: Clean up debug scripts and documentation

## File Modifications

### Create
- spec/coding_agent_tools/cli/commands/code/review_spec.rb (expanded)
  - Purpose: Comprehensive test coverage for code-review command
  - Key components: Tests for all options, presets, error cases
  - Dependencies: RSpec, VCR, test fixtures

- spec/coding_agent_tools/molecules/code/*_spec.rb
  - Purpose: Unit tests for all new molecules
  - Key components: ReviewPresetManager, ContextIntegrator, PromptEnhancer tests
  - Dependencies: RSpec, factory fixtures

### Modify
- lib/coding_agent_tools/cli/commands/code/review.rb
  - Changes: Refactor call method into smaller methods
  - Impact: Better testability and maintainability
  - Integration points: Extract preset loading, context generation, execution

- lib/coding_agent_tools/molecules/code/llm_executor.rb
  - Changes: Ensure absolute paths for llm-query
  - Impact: More reliable execution across different contexts
  - Integration points: Path resolution before command execution

### Delete
- lib/coding_agent_tools/cli/commands/code/review_prepare.rb (entire file)
- lib/coding_agent_tools/cli/commands/code/review_prepare/ (entire directory)
- spec/coding_agent_tools/cli/commands/code/review_prepare/ (entire directory)
- debug_*.rb (from project root)
- test_multi_preset.rb (from project root)

### Update References
- lib/coding_agent_tools/cli.rb
  - Remove: register_code_review_prepare_commands method call
- docs/tools.md
  - Remove: All references to code-review-prepare
- dev-handbook/workflow-instructions/review-code.wf.md
  - Remove: References to code-review-prepare if any remain

## Risk Assessment

### Technical Risks
- **Risk:** Breaking existing functionality while refactoring
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Write tests first, refactor incrementally
  - **Rollback:** Git revert to previous working state

- **Risk:** VCR compatibility issues with Ruby 3.4.2
  - **Probability:** High (already occurring)
  - **Impact:** Medium
  - **Mitigation:** Fix VCR compatibility or use alternative mocking
  - **Monitoring:** Check test suite execution

### Integration Risks
- **Risk:** Scripts or workflows depending on code-review-prepare
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Search codebase for references before removal
  - **Monitoring:** Check CI/CD pipelines after removal

## Implementation Plan

### Planning Steps
* [ ] Analyze current test coverage to identify gaps
  > TEST: Coverage Analysis
  > Type: Pre-condition Check
  > Assert: Current coverage baseline documented
  > Command: cd dev-tools && bundle exec rspec --format documentation 2>/dev/null | grep -E "examples?, .* failures?"

* [ ] Research VCR compatibility issues with Ruby 3.4.2
* [ ] Identify all references to code-review-prepare command
* [ ] Map all debug scripts in project root

### Execution Steps

#### Phase 1: Test Coverage Enhancement (4h)
- [ ] Fix VCR compatibility issue or implement alternative mocking
- [ ] Write comprehensive tests for code-review command
  > TEST: Command Tests Pass
  > Type: Action Validation
  > Assert: All new tests pass with >80% coverage
  > Command: cd dev-tools && bundle exec rspec spec/coding_agent_tools/cli/commands/code/review_spec.rb

- [ ] Write unit tests for ReviewPresetManager molecule
- [ ] Write unit tests for ContextIntegrator molecule
- [ ] Write unit tests for PromptEnhancer molecule
- [ ] Write unit tests for LLMExecutor molecule
- [ ] Verify coverage exceeds 80% for new code

#### Phase 2: Code Removal (2h)
- [ ] Remove code-review-prepare command registration from CLI
- [ ] Delete code-review-prepare command files
  > TEST: Command Removed
  > Type: Action Validation
  > Assert: code-review-prepare command no longer exists
  > Command: code-review-prepare --help 2>&1 | grep -q "ERROR.*was called with" && echo "Command removed successfully"

- [ ] Delete associated test files for code-review-prepare
- [ ] Remove any molecules/organisms only used by prepare command
- [ ] Update documentation to remove prepare command references

#### Phase 3: Refactoring (2h)
- [ ] Extract preset loading logic from call method
- [ ] Extract context generation logic into separate method
- [ ] Extract execution logic into separate method
- [ ] Fix LLM executor to use absolute paths
  > TEST: Absolute Paths Used
  > Type: Action Validation
  > Assert: LLM queries use absolute paths
  > Command: grep -r "llm-query" dev-tools/lib --include="*.rb" | grep -v "File.expand_path\|absolute"

#### Phase 4: Cleanup (1h)
- [ ] Delete all debug_*.rb files from project root
- [ ] Delete test_multi_preset.rb from project root
  > TEST: Root Directory Clean
  > Type: Action Validation
  > Assert: No debug scripts in root
  > Command: ls -la | grep -E "(debug_.*\.rb|test_.*\.rb)" | wc -l | grep -q "^0$"

- [ ] Run full test suite to ensure nothing broken
- [ ] Generate final coverage report

## Acceptance Criteria

- [ ] Test coverage for code-review functionality exceeds 80%
- [ ] All tests pass without VCR compatibility errors
- [ ] code-review-prepare command completely removed
- [ ] Debug scripts deleted from project root
- [ ] Complex call method refactored into smaller methods
- [ ] LLM queries consistently use absolute paths
- [ ] Documentation updated to remove deprecated references

## References

- Code review report: dev-taskflow/current/v.0.5.0-insights/code-review/review-20250822-015517/cr-google-gemini-2.0-flash-exp.md
- Code review report: dev-taskflow/current/v.0.5.0-insights/code-review/review-20250822-015517/cr-gpro.md
- Original implementation: v.0.5.0+task.028-redesign-code-review-command-with-preset-based-configuration.md
- Multi-preset fix: v.0.5.0+task.033-fix-multi-preset-context-loading-in-code-review.md