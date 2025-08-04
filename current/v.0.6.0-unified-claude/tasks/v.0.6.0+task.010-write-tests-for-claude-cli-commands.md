---
id: v.0.6.0+task.010
status: pending
priority: high
estimate: 6h
dependencies: [v.0.6.0+task.002, v.0.6.0+task.003, v.0.6.0+task.004, v.0.6.0+task.005, v.0.6.0+task.006, v.0.6.0+task.007]
release: v.0.6.0-unified-claude
needs_review: true
---

# Write tests for Claude CLI commands

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions
- [ ] Where are the Claude command implementations located?
  - **Research conducted**: Searched for Claude command files in lib/coding_agent_tools/cli/commands/handbook/claude/
  - **Similar implementations**: Found sync_templates.rb in handbook namespace
  - **Finding**: No Claude command implementations exist yet in expected location
  - **Why needs human input**: Dependencies indicate commands should exist but are not found

- [ ] Should tests be written before or alongside command implementations?
  - **Research conducted**: Checked task dependencies - all command implementation tasks are listed
  - **Industry practice**: TDD suggests writing tests first, but requires interfaces
  - **Suggested default**: Write test stubs with pending examples until implementations exist
  - **Why needs human input**: Testing strategy depends on development workflow preference

- [ ] What specific Claude commands need test coverage?
  - **Research conducted**: Found references to 5 commands in release notes
  - **Commands identified**: generate-commands, update-registry, integrate, validate, list
  - **Similar pattern**: handbook sync-templates command exists with tests
  - **Why needs human input**: Need confirmation of exact command names and behaviors

### [MEDIUM] Enhancement Questions
- [ ] Should we use VCR for testing external API calls to Claude?
  - **Research conducted**: Found VCR setup in spec/support/vcr.rb
  - **Current practice**: Other LLM tests use VCR (anthropic_client_spec.rb exists)
  - **Suggested default**: Use VCR for any Claude API interactions
  - **Why needs human input**: Depends on whether commands make API calls

- [ ] What test data/fixtures are needed for Claude command tests?
  - **Research conducted**: Found spec/fixtures directory with coverage samples
  - **Similar fixtures**: No Claude-specific fixtures exist yet
  - **Suggested default**: Create spec/fixtures/claude/ with sample workflows and commands
  - **Why needs human input**: Fixture requirements depend on command implementations

### [LOW] Optimization Questions  
- [ ] Should integration tests be in spec/integration/ or with unit tests?
  - **Research conducted**: Found both patterns - spec/integration/ exists with various tests
  - **Current pattern**: Integration tests are separate from unit tests
  - **Suggested default**: Follow existing pattern with spec/integration/claude_workflow_spec.rb
  - **Why needs human input**: Team preference for test organization

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
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude_spec.rb`
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/generate_commands_spec.rb`
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/update_registry_spec.rb`
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/validate_spec.rb`
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/integrate_spec.rb`
- `dev-tools/spec/coding_agent_tools/cli/commands/handbook/claude/list_spec.rb`
- `dev-tools/spec/support/claude_test_helpers.rb`
- `dev-tools/spec/fixtures/claude/` - Test fixtures directory
- **[Added on review]** `dev-tools/spec/fixtures/claude/sample_workflows/` - Sample workflow files
- **[Added on review]** `dev-tools/spec/fixtures/claude/commands/` - Sample command files
- **[Added on review]** `dev-tools/spec/integration/claude_workflow_spec.rb` - Integration tests

### Modify
- `dev-tools/spec/spec_helper.rb` - Add Claude test configuration
- **[Added on review]** `dev-tools/spec/support/cli_helpers.rb` - Add Claude command execution helpers

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

* [ ] Design test structure and organization
* [ ] Define shared examples for common patterns
* [ ] Plan fixture and mock strategy
* [ ] Set coverage targets per component

### Execution Steps

- [ ] Create test helper module
  ```ruby
  # spec/support/claude_test_helpers.rb
  module ClaudeTestHelpers
    def setup_claude_test_environment
      @temp_dir = Dir.mktmpdir
      @handbook_dir = File.join(@temp_dir, "dev-handbook")
      @claude_dir = File.join(@handbook_dir, ".integrations/claude")
      FileUtils.mkdir_p(@claude_dir)
    end
    
    def teardown_claude_test_environment
      # Use safe_directory_cleanup from spec_helper
      safe_directory_cleanup(@temp_dir) if @temp_dir
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

- [ ] Write main Claude command tests
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

- [ ] Write generate-commands tests
  ```ruby
  describe "#call" do
    context "with dry-run option" do
      it "does not create files" do
        subject.call(dry_run: true)
        expect(Dir.glob(File.join(@generated_dir, "*.md"))).to be_empty
      end
    end
    
    context "with missing workflows" do
      before do
        create_workflow("test-workflow.wf.md")
      end
      
      it "generates missing commands" do
        subject.call
        expect(File.exist?(File.join(@generated_dir, "test-workflow.md"))).to be true
      end
    end
  end
  ```

- [ ] Write integration tests
  ```ruby
  # spec/integration/claude_workflow_spec.rb
  RSpec.describe "Claude Integration Workflow" do
    it "completes full workflow successfully" do
      # Generate commands
      run_command("handbook claude generate-commands")
      
      # Update registry
      run_command("handbook claude update-registry")
      
      # Validate
      output = run_command("handbook claude validate")
      expect(output).to include("✓ Valid commands")
      
      # Integrate
      run_command("handbook claude integrate")
      expect(File.exist?(".claude/commands/commands.json")).to be true
    end
  end
  ```

- [ ] Add shared examples
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

- [ ] Configure test coverage
  ```ruby
  # spec/spec_helper.rb additions
  SimpleCov.start do
    add_group "Claude Commands", "lib/coding_agent_tools/cli/commands/handbook/claude"
    add_group "Claude Organisms", "lib/coding_agent_tools/organisms/claude"
  end
  ```

- [ ] Write performance tests
  > TEST: Performance Validation
  > Type: Benchmark Test
  > Assert: Commands complete within time limits
  > Command: bundle exec rspec --tag performance

## Acceptance Criteria

- [ ] All Claude command classes have test coverage
- [ ] Unit tests for each public method
- [ ] Integration tests for workflows
- [ ] Edge cases and error conditions covered
- [ ] Test coverage > 90%
- [ ] All tests pass in CI environment
- [ ] Test execution time < 30 seconds
- **[Added on review]** Tests follow RSpec best practices (describe/context/it structure)
- **[Added on review]** Tests use shared examples for common behaviors
- **[Added on review]** Tests are documented with --format documentation output

## References

- RSpec best practices
- Existing test patterns in dev-tools
- Testing file system operations
- **[Added on review]** spec/coding_agent_tools/cli/commands/handbook/sync_templates_spec.rb - Similar command test pattern
- **[Added on review]** spec/support/cli_helpers.rb - CLI command testing infrastructure
- **[Added on review]** Web research: RSpec 2025 best practices for CLI testing with dry-cli