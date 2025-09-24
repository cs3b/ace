---
id: v.0.8.0+task.004e
status: pending
priority: low
estimate: 1h
dependencies: [v.0.8.0+task.004a, v.0.8.0+task.004b, v.0.8.0+task.004c, v.0.8.0+task.004d]
parent_task: v.0.8.0+task.004
---

# Migrate Ecosystems Unit Tests

## Objective

Migrate all unit tests for Ecosystem components to Minitest. Ecosystems represent complete end-to-end workflows that coordinate multiple organisms to deliver full features.

## Scope of Work

- Write comprehensive unit tests for 2 Ecosystem components
- Test complete workflows with extensive mocking
- Verify end-to-end coordination and error recovery
- Follow Minitest patterns established in test_helper.rb

## Component Checklist (2 total)

### Ecosystem Components
- [ ] `claude_commands_installer.rb` - Complete Claude commands installation workflow
  - Discovers available commands and workflows
  - Validates command structure and metadata
  - Installs commands with proper error handling
  - Generates installation reports
  - Manages rollback on failures

- [ ] `coverage_analysis_workflow.rb` - Complete coverage analysis workflow
  - Loads coverage data from multiple sources
  - Analyzes coverage across ATOM architecture layers
  - Identifies under-covered components
  - Generates comprehensive coverage reports
  - Provides actionable improvement recommendations

## Progress Tracking

- **Components completed:** 0/2
- **Estimated time per component:** ~30 minutes
- **Current focus:** [Not started]

## Implementation Plan

### Execution Steps

1. **Setup Test Infrastructure**
   - [ ] Create test/unit/ecosystems/ directory
   - [ ] Set up comprehensive mocking framework for ecosystems
   - [ ] Create test fixtures for complete workflows

2. **Test Claude Commands Installer**
   - [ ] Test discovery phase with mocked file system
   - [ ] Test validation of command structures
   - [ ] Test installation with success scenarios
   - [ ] Test rollback on installation failures
   - [ ] Test report generation

3. **Test Coverage Analysis Workflow**
   - [ ] Test coverage data loading from multiple sources
   - [ ] Test analysis across ATOM layers
   - [ ] Test identification of coverage gaps
   - [ ] Test report generation with various formats
   - [ ] Test recommendation engine

## Detailed Test Requirements

### Claude Commands Installer Tests

```ruby
# Key scenarios to test:
- Discovery of commands in multiple locations
- Validation of command YAML frontmatter
- Handling of invalid command structures
- Installation to correct destinations
- Symlink creation and management
- Rollback on partial failures
- Dry-run mode operation
- Force installation over existing files
- Installation statistics and reporting
```

### Coverage Analysis Workflow Tests

```ruby
# Key scenarios to test:
- Loading coverage data from SimpleCov
- Parsing coverage for different ATOM layers
- Calculating coverage percentages
- Identifying uncovered methods and classes
- Generating HTML reports
- Generating JSON reports
- Threshold validation
- Coverage trend analysis
- Recommendation generation based on gaps
```

## Acceptance Criteria

- [ ] Both ecosystem components have comprehensive test files
- [ ] Each test covers:
  - Complete workflow from start to finish
  - All decision branches and paths
  - Error scenarios and recovery
  - Rollback mechanisms
  - Report generation
  - State management throughout workflow
- [ ] Tests pass with `ace-test ecosystems`
- [ ] Tests run serially (no parallelize_me!)
- [ ] Extensive use of mocks for all external dependencies
- [ ] Clear documentation of workflow steps in tests

## Testing Guidelines

### Ecosystem Test Principles
- End-to-end: test complete workflows
- Comprehensive mocking: mock all organisms and external systems
- State verification: check state at each workflow step
- Error simulation: test all failure modes
- Recovery testing: verify rollback and cleanup
- Report validation: verify output formats

### Example Test Structure
```ruby
class ClaudeCommandsInstallerTest < EcosystemTest
  def setup
    @mock_discoverer = Minitest::Mock.new
    @mock_validator = Minitest::Mock.new
    @mock_installer = Minitest::Mock.new
    @mock_reporter = Minitest::Mock.new

    @ecosystem = ClaudeCommandsInstaller.new(
      discoverer: @mock_discoverer,
      validator: @mock_validator,
      installer: @mock_installer,
      reporter: @mock_reporter
    )
  end

  def test_complete_installation_workflow
    # Setup discovery
    commands = [mock_command1, mock_command2]
    @mock_discoverer.expect(:discover_commands, commands)

    # Setup validation
    @mock_validator.expect(:validate, true, [mock_command1])
    @mock_validator.expect(:validate, true, [mock_command2])

    # Setup installation
    @mock_installer.expect(:install, success_result, [mock_command1])
    @mock_installer.expect(:install, success_result, [mock_command2])

    # Setup reporting
    @mock_reporter.expect(:generate_report, report, [installation_stats])

    # Execute workflow
    result = @ecosystem.execute(dry_run: false)

    # Verify complete workflow
    assert result.success?
    assert_equal 2, result.installed_count
    assert_equal report, result.report

    # Verify all mocks were called
    [@mock_discoverer, @mock_validator, @mock_installer, @mock_reporter].each(&:verify)
  end

  def test_rollback_on_installation_failure
    # Setup partial success then failure
    @mock_discoverer.expect(:discover_commands, [mock_command1, mock_command2])
    @mock_validator.expect(:validate, true, [mock_command1])
    @mock_validator.expect(:validate, true, [mock_command2])
    @mock_installer.expect(:install, success_result, [mock_command1])
    @mock_installer.expect(:install, -> { raise InstallationError }, [mock_command2])

    # Expect rollback
    @mock_installer.expect(:rollback, nil, [mock_command1])

    # Execute and verify rollback
    result = @ecosystem.execute(dry_run: false)

    assert result.failed?
    assert_equal "Installation failed and was rolled back", result.error_message
    @mock_installer.verify
  end

  def test_dry_run_mode
    # Setup discovery and validation only
    @mock_discoverer.expect(:discover_commands, [mock_command1])
    @mock_validator.expect(:validate, true, [mock_command1])

    # No installation should occur in dry-run
    # Reporter should still generate preview report
    @mock_reporter.expect(:generate_preview, preview_report, [mock_command1])

    result = @ecosystem.execute(dry_run: true)

    assert result.success?
    assert_equal 0, result.installed_count
    assert_equal preview_report, result.report
  end
end
```

## Out of Scope

- Integration with real file system
- Network calls to external services
- Performance testing
- UI/CLI interaction testing
- Actual file modifications

## Notes

### Why Only 2 Components?
Ecosystems are rare in the ATOM architecture because they represent complete, complex workflows. Most functionality is implemented at the Organism level or below. These two ecosystems handle critical infrastructure tasks:

1. **Claude Commands Installer**: Manages the entire Claude integration setup
2. **Coverage Analysis Workflow**: Provides comprehensive test coverage insights

### Testing Strategy
Despite having only 2 components, these tests are critical because ecosystems:
- Coordinate the most complex workflows
- Have the highest potential for cascading failures
- Directly impact developer experience
- Are entry points for major features

## References

- **Testing Guide**: `docs/development/testing.g.md` - Essential testing patterns and setup
- Test helper: `test/test_helper.rb`
- Ecosystem base class: `EcosystemTest`
- Example ecosystem test: `test/unit/ecosystems/example_ecosystem_test.rb`
- Note: Ecosystems always run serially, never in parallel