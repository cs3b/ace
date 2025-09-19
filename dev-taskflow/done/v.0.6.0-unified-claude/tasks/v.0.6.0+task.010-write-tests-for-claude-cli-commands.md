---
id: v.0.6.0+task.010
status: done
priority: high
estimate: 6h
dependencies: [v.0.6.0+task.002, v.0.6.0+task.003, v.0.6.0+task.004, v.0.6.0+task.005, v.0.6.0+task.006, v.0.6.0+task.007]
release: v.0.6.0-unified-claude
---

# Write tests for Claude CLI commands

## Review Summary (2025-08-04)

**Questions Answered:** 6 total (3 HIGH, 2 MEDIUM, 1 LOW)
**Research Findings:** Claude command implementations exist in expected locations
**Implementation Readiness:** Ready to implement with clarified requirements

### Key Clarifications Received:
1. **Prerequisites**: Ensure all command implementation tasks are completed before writing tests
2. **Test Strategy**: Implementations will exist; tests may need adjustment based on actual implementations
3. **Command Coverage**: All 5 commands confirmed: generate-commands, update-registry, integrate, validate, list
4. **API Testing**: No LLM calls - focus on unit and command tests only
5. **Test Fixtures**: Create as needed with emphasis on cleanup of generated files
6. **Test Organization**: Use spec/integration/ for integration tests as per existing pattern

### Additional Research Findings:
- **Command Implementations Found**: All 5 Claude commands exist in `lib/coding_agent_tools/cli/commands/handbook/claude/`
- **Existing Test Pattern**: integrate_spec.rb already exists, showing test patterns to follow
- **Integration Tests**: handbook_claude_cli_spec.rb exists with subprocess-based integration tests
- **Test Helpers**: CliHelpers module available for direct command invocation
- **Cleanup Pattern**: safe_directory_cleanup helper available in spec_helper.rb

## Behavioral Specification

### User Experience
- **Input**: Developer runs test suite for Claude CLI commands
- **Process**: System executes comprehensive test scenarios
- **Output**: Test results showing coverage and validation

### Expected Behavior
The test suite should comprehensively validate all Claude CLI commands, including unit tests for individual components and integration tests for command workflows. Tests should cover happy paths, edge cases, error conditions, and ensure commands work correctly both individually and together.

### Interface Contract
```bash
# Run all Claude-related tests
bundle exec rspec spec/coding_agent_tools/cli/commands/handbook/claude/

# Run specific command tests
bundle exec rspec spec/coding_agent_tools/cli/commands/handbook/claude/generate_commands_spec.rb

# Run with coverage
bundle exec rspec spec/coding_agent_tools/cli/commands/handbook/claude/ --format documentation

# Expected output:
CodingAgentTools::CLI::Commands::Handbook::Claude
  displays help when called without subcommand

CodingAgentTools::CLI::Commands::Handbook::Claude::GenerateCommands
  #call
    with dry-run option
      displays what would be generated
      does not create files
    with force option
      regenerates existing commands
    with workflow option
      generates specific workflow only

... (more test output)

Finished in X seconds
XX examples, 0 failures
Coverage: 95%
```

**Error Handling:**
- Test failures: Clear error messages with context
- Missing fixtures: Helpful setup instructions
- Environment issues: Configuration guidance

**Edge Cases:**
- Empty directories during testing
- Concurrent test execution
- File system permissions
- Temporary file cleanup

### Success Criteria
- [ ] **Full Coverage**: All command classes have tests
- [ ] **Edge Cases**: Error conditions and edge cases covered
- [ ] **Integration Tests**: Commands work together correctly
- [ ] **Fixture Management**: Test data properly isolated
- [ ] **CI Ready**: Tests run reliably in CI environment

### Validation Questions
- [ ] **Test Isolation**: How to prevent tests affecting each other?
  - **[Resolved through research]**: spec_helper.rb already handles isolation with temp dirs and cleanup
- [ ] **Fixture Strategy**: Real files vs mocks for file operations?
  - **[Resolved through research]**: Use temp directories (rspec/temp_dir) and mock external calls
- [ ] **Performance**: How to keep test suite fast?
  - **[Resolved through research]**: Use CliHelpers for direct invocation, avoid subprocess overhead
- [ ] **Coverage Target**: What percentage coverage is required?
  - **[Resolved through research]**: SimpleCov configured with 0% minimum (will increase over time)
- [ ] **Command Implementation Dependencies**: When to write tests given dependent tasks?
  - **[Resolved through user input]**: Write tests after command implementations are complete

## Objective

Create comprehensive test suite for all Claude CLI commands ensuring reliability, maintainability, and confidence in the integration functionality.

## Scope of Work

- **User Experience Scope**: Test execution and reporting
- **System Behavior Scope**: Unit and integration test coverage
- **Interface Scope**: RSpec test structure and conventions

### Deliverables

#### Behavioral Specifications
- Test structure documentation
- Coverage requirements
- CI integration setup

#### Validation Artifacts
- Test coverage reports
- Performance benchmarks
- CI configuration

### Prerequisites
- [ ] Complete all Claude command implementation tasks (v.0.6.0+task.002 through v.0.6.0+task.007)
- [ ] Verify command implementations exist in lib/coding_agent_tools/cli/commands/handbook/claude/
- [ ] Review existing integrate_spec.rb for test patterns

## Out of Scope
- ❌ **Implementation Details**: Specific mocking libraries
- ❌ **Technology Decisions**: Alternative test frameworks
- ❌ **Performance Optimization**: Test parallelization
- ❌ **Future Enhancements**: Mutation testing, property testing

## Technical Approach

### Architecture Pattern
- RSpec with clear describe/context/it structure
- Shared examples for common behaviors
- Fixtures and factories for test data

### Technology Stack
- RSpec for test framework
- WebMock/VCR for external calls
- SimpleCov for coverage reporting

## Tool Selection

| Tool/Library | Purpose | Rationale |
|--------------|---------|-----------|
| RSpec | Test framework | Project standard |
| FactoryBot | Test data generation | Consistent fixtures |
| WebMock | HTTP mocking | External API isolation |
| SimpleCov | Coverage reporting | Track test completeness |

## File Modifications

### Create
- `.ace/tools/spec/coding_agent_tools/cli/commands/handbook/claude_spec.rb`
- `.ace/tools/spec/coding_agent_tools/cli/commands/handbook/claude/generate_commands_spec.rb`
- `.ace/tools/spec/coding_agent_tools/cli/commands/handbook/claude/update_registry_spec.rb`
- `.ace/tools/spec/coding_agent_tools/cli/commands/handbook/claude/validate_spec.rb`
- `.ace/tools/spec/coding_agent_tools/cli/commands/handbook/claude/integrate_spec.rb`
- `.ace/tools/spec/coding_agent_tools/cli/commands/handbook/claude/list_spec.rb`
- `.ace/tools/spec/support/claude_test_helpers.rb`
- `.ace/tools/spec/fixtures/claude/` - Test fixtures directory
- **[Added on review]** `.ace/tools/spec/fixtures/claude/sample_workflows/` - Sample workflow files
- **[Added on review]** `.ace/tools/spec/fixtures/claude/commands/` - Sample command files
- **[Added on review]** `.ace/tools/spec/integration/claude_workflow_spec.rb` - Integration tests

### Modify
- `.ace/tools/spec/spec_helper.rb` - Add Claude test configuration
- **[Added on review]** `.ace/tools/spec/support/cli_helpers.rb` - Add Claude command execution helpers

### Delete
- None required

## Risk Assessment

### Technical Risks
- **File System Dependencies**: Tests might be fragile
  - Mitigation: Use temporary directories, proper cleanup
  - **[Added on review]**: Use safe_directory_cleanup helper from spec_helper.rb
- **Test Interdependence**: Order-dependent failures
  - Mitigation: Proper isolation, random test order
  - **[Added on review]**: RSpec configured with random order and proper cleanup hooks
- **Missing Implementation Risk**: Commands don't exist yet
  - **[Added on review]**: Tests may need pending examples until implementations complete
  - Mitigation: Use test doubles and stubs for missing components

### Integration Risks
- **CI Environment Differences**: Local vs CI behavior
  - Mitigation: Docker-based testing, environment parity
- **Fixture Management**: Stale or incorrect test data
  - Mitigation: Fixture validation, regular updates

## Implementation Plan

### Planning Steps

* [x] **[Updated based on review]** Verify all command implementations are complete
* [x] Design test structure and organization
* [x] Define shared examples for common patterns
* [x] Plan fixture and mock strategy
* [x] Set coverage targets per component
* [x] **[Added on review]** Review existing test patterns in integrate_spec.rb and sync_templates_spec.rb

### Execution Steps

- [x] Create test helper module
  ```ruby
  # spec/support/claude_test_helpers.rb
  module ClaudeTestHelpers
    def setup_claude_test_environment
      @temp_dir = Dir.mktmpdir
      @handbook_dir = File.join(@temp_dir, ".ace/handbook")
      @claude_dir = File.join(@handbook_dir, ".integrations/claude")
      FileUtils.mkdir_p(@claude_dir)
    end

    def teardown_claude_test_environment
      # Use safe_directory_cleanup from spec_helper
      safe_directory_cleanup(@temp_dir) if @temp_dir
    end

    # Helper to execute Claude commands directly (performance optimization)
    def execute_claude_command(command_name, options = {})
      command_class = case command_name
      when "generate-commands"
        CodingAgentTools::Cli::Commands::Handbook::Claude::GenerateCommands
      when "update-registry"
        CodingAgentTools::Cli::Commands::Handbook::Claude::UpdateRegistry
      when "validate"
        CodingAgentTools::Cli::Commands::Handbook::Claude::Validate
      when "integrate"
        CodingAgentTools::Cli::Commands::Handbook::Claude::Integrate
      when "list"
        CodingAgentTools::Cli::Commands::Handbook::Claude::List
      end
      
      command_class.new.call(**options)
    end

    # Helper to create sample workflow files for testing
    def create_sample_workflow(name, content = nil)
      workflow_dir = File.join(@handbook_dir, "workflow-instructions")
      FileUtils.mkdir_p(workflow_dir)

      content ||= "# #{name} Workflow\n\n## Goal\nTest workflow"
      File.write(File.join(workflow_dir, "#{name}.wf.md"), content)
    end

    # Helper to verify command generation
    def expect_command_generated(workflow_name)
      command_file = File.join(@claude_dir, "commands", "#{workflow_name}.md")
      expect(File.exist?(command_file)).to be true
    end
  end
  ```

- [x] Write main Claude command tests
  ```ruby
  # spec/coding_agent_tools/cli/commands/handbook/claude_spec.rb
  RSpec.describe CodingAgentTools::CLI::Commands::Handbook::Claude do
    include ClaudeTestHelpers

    before { setup_claude_test_environment }
    after { teardown_claude_test_environment }

    describe "#call" do
      it "displays help when called without subcommand" do
        output = capture_output { subject.call }
        expect(output).to include("Usage: handbook claude [SUBCOMMAND]")
        expect(output).to include("generate-commands")
        expect(output).to include("update-registry")
      end
    end
  end
  ```
  > TEST: Test Execution
  > Type: RSpec Run
  > Assert: Tests pass
  > Command: bundle exec rspec spec/coding_agent_tools/cli/commands/handbook/claude_spec.rb

- [x] Write generate-commands tests
  ```ruby
  # spec/coding_agent_tools/cli/commands/handbook/claude/generate_commands_spec.rb
  RSpec.describe CodingAgentTools::Cli::Commands::Handbook::Claude::GenerateCommands do
    include ClaudeTestHelpers
    
    subject { described_class.new }
    
    before { setup_claude_test_environment }
    after { teardown_claude_test_environment }
    
    describe "#call" do
      context "with dry-run option" do
        it "does not create files" do
          create_sample_workflow("test-workflow")
          
          output = capture_output { subject.call(dry_run: true) }
          
          expect(output).to include("Would generate")
          expect(Dir.glob(File.join(@claude_dir, "commands", "*.md"))).to be_empty
        end
      end

      context "with force option" do
        before do
          create_sample_workflow("existing-workflow")
          FileUtils.mkdir_p(File.join(@claude_dir, "commands"))
          File.write(File.join(@claude_dir, "commands", "existing-workflow.md"), "old content")
        end

        it "overwrites existing commands" do
          subject.call(force: true)
          
          content = File.read(File.join(@claude_dir, "commands", "existing-workflow.md"))
          expect(content).not_to eq("old content")
        end
      end
      
      context "with workflow option" do
        before do
          create_sample_workflow("workflow-one")
          create_sample_workflow("workflow-two")
        end
        
        it "generates only specified workflow" do
          subject.call(workflow: "workflow-one")
          
          expect(File.exist?(File.join(@claude_dir, "commands", "workflow-one.md"))).to be true
          expect(File.exist?(File.join(@claude_dir, "commands", "workflow-two.md"))).to be false
        end
      end
    end
  end
  ```

- [x] Write integration tests
  ```ruby
  # spec/integration/claude_workflow_spec.rb
  RSpec.describe "Claude Integration Workflow" do
    include ClaudeTestHelpers
    include CliHelpers
    
    before { setup_claude_test_environment }
    after { teardown_claude_test_environment }
    
    it "completes full workflow successfully" do
      # Setup test workflows
      create_sample_workflow("draft-task")
      create_sample_workflow("review-task")
      
      # Generate commands
      result = execute_cli_command("handbook", ["claude-generate-commands"])
      expect(result).to be_success
      expect(File.exist?(File.join(@claude_dir, "commands", "draft-task.md"))).to be true
      expect(File.exist?(File.join(@claude_dir, "commands", "review-task.md"))).to be true

      # Update registry
      result = execute_cli_command("handbook", ["claude-update-registry"])
      expect(result).to be_success
      expect(File.exist?(File.join(@claude_dir, "commands.json"))).to be true

      # Validate
      result = execute_cli_command("handbook", ["claude-validate"])
      expect(result).to be_success
      expect(result.stdout).to include("✓")

      # List commands
      result = execute_cli_command("handbook", ["claude-list"])
      expect(result).to be_success
      expect(result.stdout).to include("draft-task")
      expect(result.stdout).to include("review-task")
      
      # Integrate
      result = execute_cli_command("handbook", ["claude-integrate", "--dry-run"])
      expect(result).to be_success
    end
    
    it "handles missing workflows gracefully" do
      result = execute_cli_command("handbook", ["claude-generate-commands"])
      expect(result).to be_success
      expect(result.stdout).to include("No workflows found")
    end
  end
  ```

- [x] Add shared examples
  ```ruby
  RSpec.shared_examples "claude command" do
    it "responds to call method" do
      expect(subject).to respond_to(:call)
    end

    it "includes proper description" do
      expect(described_class.description).not_to be_empty
    end
  end
  ```

- [x] Configure test coverage
  ```ruby
  # spec/spec_helper.rb additions
  SimpleCov.start do
    add_group "Claude Commands", "lib/coding_agent_tools/cli/commands/handbook/claude"
    add_group "Claude Organisms", "lib/coding_agent_tools/organisms/claude"
  end
  ```

- [x] Write performance tests
  > TEST: Performance Validation
  > Type: Benchmark Test
  > Assert: Commands complete within time limits
  > Command: bundle exec rspec --tag performance

## Acceptance Criteria

- [x] All Claude command classes have test coverage
- [x] Unit tests for each public method
- [x] Integration tests for workflows
- [x] Edge cases and error conditions covered
- [x] Test coverage > 90% (for Claude commands specifically)
- [x] All tests pass in CI environment
- [x] Test execution time < 30 seconds
- [x] **[Added on review]** Tests follow RSpec best practices (describe/context/it structure)
- [x] **[Added on review]** Tests use shared examples for common behaviors
- [x] **[Added on review]** Tests are documented with --format documentation output
- [x] **[Added on review]** File cleanup is properly handled in all tests
- [x] **[Added on review]** Tests work with both direct invocation and subprocess execution

## References

- RSpec best practices
- Existing test patterns in .ace/tools
- Testing file system operations
- **[Added on review]** spec/coding_agent_tools/cli/commands/handbook/sync_templates_spec.rb - Similar command test pattern
- **[Added on review]** spec/support/cli_helpers.rb - CLI command testing infrastructure
- **[Added on review]** spec/coding_agent_tools/cli/commands/handbook/claude/integrate_spec.rb - Existing Claude test pattern
- **[Added on review]** spec/integration/handbook_claude_cli_spec.rb - Integration test examples
- **[Added on review]** spec/spec_helper.rb - safe_directory_cleanup helper for test cleanup
