---
id: v.0.8.0+task.001
status: pending
priority: high
estimate: 4h
dependencies: {dependencies}
---

# Setup Minitest Testing Framework

## Behavioral Context

**Key Behavioral Requirements**:
- Developers need a reliable, fast testing framework for Ruby code
- Tests must run quickly with clear, informative output
- Testing approach should focus on behavior, not implementation details
- Framework must support unit, integration, and CLI testing scenarios

## Objective

Replace RSpec with Minitest as the primary testing framework, establishing a clean foundation for behavior-focused testing that emphasizes simplicity, speed, and maintainability.

## Scope of Work

- Complete removal of RSpec and all related dependencies
- Setup Minitest with comprehensive configuration
- Create test directory structure with clear separation of concerns
- Implement base test classes for different test types
- Configure VCR and Aruba for HTTP and CLI testing

### Deliverables

#### Create

- test/test_helper.rb - Main test configuration
- test/support/vcr.rb - VCR configuration for HTTP testing
- test/support/aruba.rb - Aruba configuration for CLI testing
- test/support/env_helper.rb - Environment variable management
- test/unit/example_test.rb - Example test to verify setup
- test/ directory structure (unit/, integration/, fixtures/, cassettes/, support/)

#### Modify

- Gemfile - Remove RSpec, add Minitest and related gems
- Rakefile - Replace RSpec tasks with Minitest tasks
- bin/test - Update for Minitest with multiple run modes

#### Delete

- spec/ directory (274 test files)
- .rspec configuration file

## Phases

1. Clean Slate - Remove all RSpec dependencies and files
2. Foundation - Setup Minitest with proper configuration
3. Infrastructure - Create support files and helpers
4. Verification - Ensure framework works correctly

## Technical Approach

### Architecture Pattern
- [x] Test framework: Minitest chosen for simplicity, speed, and Ruby standard library integration
- [x] Directory structure: test/ instead of spec/ for clarity and convention
- [x] Base classes: UnitTest, IntegrationTest, CLITest for different test types

### Technology Stack
- [x] Minitest 5.25 - Core testing framework
- [x] Minitest-reporters 1.7 - Better output formatting
- [x] VCR 6.3 + WebMock 3.0 - HTTP interaction testing
- [x] Aruba 2.0 - CLI testing with in-process support
- [x] SimpleCov 0.22 - Code coverage tracking

### Implementation Strategy
- [x] Clean slate approach - Remove RSpec completely before setup
- [x] Parallel test execution support for speed
- [x] In-process Aruba testing for VCR compatibility
- [x] Coverage tracking from the start

## Tool Selection

| Criteria | RSpec (current) | Minitest | Test::Unit | Selected |
|----------|----------|----------|----------|----------|
| Performance | Good | Excellent | Good | Minitest |
| Integration | Complex | Simple | Simple | Minitest |
| Maintenance | High | Low | Low | Minitest |
| Security | Good | Good | Good | Minitest |
| Learning Curve | Steep | Gentle | Gentle | Minitest |

**Selection Rationale:** Minitest selected for its simplicity, speed, Ruby standard library inclusion, and minimal DSL approach that aligns with our behavior-focused testing philosophy.

### Dependencies
- [x] minitest ~> 5.25 - Core framework
- [x] minitest-reporters ~> 1.7 - Output formatting
- [x] minitest-focus ~> 1.4 - Run specific tests
- [x] minitest-hooks ~> 1.5 - Setup/teardown hooks
- [x] webmock ~> 3.0 - HTTP mocking
- [x] vcr ~> 6.3 - HTTP recording
- [x] aruba ~> 2.0 - CLI testing

## File Modifications

### Create
- test/test_helper.rb
  - Purpose: Central configuration for all tests
  - Key components: Coverage setup, base test classes, helper methods
  - Dependencies: All test files require this

- test/support/*.rb
  - Purpose: Modular test support files
  - Key components: VCR config, Aruba config, environment helpers
  - Dependencies: Loaded by test_helper.rb

### Modify
- Gemfile
  - Changes: Remove RSpec gems, add Minitest gems
  - Impact: Changes test framework dependencies
  - Integration points: Bundle install required

- Rakefile
  - Changes: Replace RSpec tasks with Minitest tasks
  - Impact: Changes available rake tasks
  - Integration points: rake test now uses Minitest

### Delete
- spec/ directory
  - Reason: RSpec tests no longer needed
  - Dependencies: 274 test files removed
  - Migration strategy: Will be reimplemented in subsequent tasks

## Implementation Plan

<!-- This section details the specific steps required to implement the behavioral requirements -->
<!-- Clear distinction between planning/analysis activities and concrete implementation work -->

### Planning Steps

* [x] **System Analysis**: Analyzed current RSpec setup - 274 test files across spec/ directory
* [x] **Framework Research**: Evaluated Minitest vs RSpec - chose Minitest for simplicity and speed
* [x] **Architecture Design**: Designed test structure with unit/integration/CLI separation
* [x] **Dependency Analysis**: Identified required gems and versions for Minitest ecosystem
* [x] **Migration Strategy**: Decided on clean slate approach - remove RSpec completely first

### Execution Steps

- [x] **Clean RSpec Dependencies**: Remove RSpec and test-related gems from Gemfile
  > TEST: Gemfile Validation
  > Type: Dependency Check
  > Assert: No RSpec-related gems remain in Gemfile
  > Command: grep -c "rspec" Gemfile || echo "Clean"

- [x] **Remove RSpec Files**: Delete spec/ directory and .rspec configuration
  > TEST: Directory Cleanup
  > Type: File System Check
  > Assert: spec/ directory and .rspec file no longer exist
  > Command: test ! -d .ace/tools/spec && test ! -f .ace/tools/.rspec && echo "Cleaned"

- [x] **Add Minitest Gems**: Add Minitest and supporting gems to Gemfile
  > TEST: Dependency Installation
  > Type: Bundle Check
  > Assert: Minitest gems are installable
  > Command: cd .ace/tools && bundle install

- [x] **Create Test Structure**: Setup test/ directory with proper organization
  > TEST: Directory Structure
  > Type: File System Validation
  > Assert: Test directories exist with correct structure
  > Command: test -d .ace/tools/test/{unit,integration,support,fixtures,cassettes} && echo "Structure OK"

- [x] **Configure Test Helper**: Create test_helper.rb with base configuration
  > TEST: Helper Loading
  > Type: Ruby Syntax Check
  > Assert: test_helper.rb loads without errors
  > Command: cd .ace/tools && ruby -Itest -rtest_helper -e "puts 'Helper loads OK'"

- [x] **Setup Support Files**: Create VCR, Aruba, and environment helpers
  > TEST: Support File Loading
  > Type: Ruby Require Check
  > Assert: All support files load correctly
  > Command: cd .ace/tools && ruby -Itest -rtest_helper -e "puts 'All support loaded'"

- [x] **Update Build System**: Modify Rakefile to use Minitest tasks
  > TEST: Rake Task Check
  > Type: Task Availability
  > Assert: Minitest rake tasks are available
  > Command: cd .ace/tools && rake -T | grep test

- [x] **Update Test Runner**: Modify bin/test script for Minitest
  > TEST: Script Execution
  > Type: Executable Check
  > Assert: Test script runs without errors
  > Command: cd .ace/tools && ./bin/test unit

- [x] **Verify Setup**: Create and run example test
  > TEST: Framework Verification
  > Type: End-to-End Test
  > Assert: Minitest framework runs tests successfully
  > Command: cd .ace/tools && bundle exec ruby test/unit/example_test.rb

## Risk Assessment

### Technical Risks
- **Risk:** Gem dependency conflicts during migration
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Clean slate approach, removing all RSpec first
  - **Rollback:** Git reset to previous state

### Integration Risks
- **Risk:** VCR/WebMock compatibility issues with Minitest
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Using proven gem versions, in-process Aruba testing
  - **Monitoring:** Run example tests to verify HTTP mocking

### Performance Risks
- **Risk:** Slower test execution compared to RSpec
  - **Mitigation:** Parallel test execution, separate unit/integration tests
  - **Monitoring:** Time test runs, compare with RSpec baseline
  - **Thresholds:** Unit tests < 30s, full suite < 2min

## Acceptance Criteria

### Framework Setup
- [x] **Minitest Installation**: All Minitest gems installed successfully
- [x] **Test Structure**: test/ directory created with proper subdirectories
- [x] **Configuration Files**: test_helper.rb and support files created and working

### RSpec Removal
- [x] **Clean Removal**: All RSpec dependencies and files completely removed
- [x] **No Conflicts**: No gem conflicts after migration
- [x] **Build System**: Rake tasks updated for Minitest

### Functionality Validation
- [x] **Example Test Runs**: Example test executes successfully
- [x] **Test Runner Works**: bin/test script functions with all modes
- [x] **Coverage Tracking**: SimpleCov generates coverage reports
- [ ] **CI Compatibility**: Tests run in CI environment (to be verified)

## Out of Scope

- ❌ Migrating existing RSpec tests (handled in subsequent tasks)
- ❌ Writing comprehensive test suite (separate tasks)
- ❌ Performance optimization beyond basic setup
- ❌ CI/CD pipeline configuration (separate task)

## References

```