# Let's Test Workflow Instruction

## Goal
Guide the developer through writing and running automated tests (unit, integration) following Test-Driven Development (TDD) principles.

## Prerequisites
- A specific feature or piece of functionality requires testing (often defined in a task `.md` file).
- Development environment is set up with the testing framework configured (e.g., RSpec, Jest).
- Understanding of the project's testing guidelines and conventions.

## Input
- Feature/task requirements and acceptance criteria.
- Optional: Existing code that needs tests.
# Let's Test Workflow Instruction

For implementing tests using Test-Driven Development. See [Testing Guide](docs-dev/guides/testing.md) for details.

## Process Steps

1. **Review Feature Specification**:
- Identify test requirements from the feature spec in `docs-project/1-next/`
   - Create a test plan covering:
     - Class/method structure tests
     - Happy path scenarios
     - Edge cases and error conditions
     - Integration points

2. **Implement Test First**:
   ```bash
   # Create a new test file if needed
   touch spec/aira/[component]_spec.rb
   ```

   - Write failing tests first
   - Run tests to verify they fail with clear messages:
   ```bash
   bin/rspec spec/aira/[component]_spec.rb
   ```

3. **Implementation & Verification Cycle**:
   - Implement minimal code to make tests pass
   - Run tests again to verify:
   ```bash
   bin/rspec spec/aira/[component]_spec.rb
   ```
   - Refactor code while keeping tests green
   - Document any design decisions or edge cases

4. **Coverage Validation**:
   ```bash
   COVERAGE=true bin/rspec
   ```
   - Review coverage/index.html
   - Add tests for any uncovered code paths
   - Document any intentionally uncovered paths

## Test Structure Guidelines

```ruby
RSpec.describe Component do
  # Context blocks for different scenarios
  context "when initializing" do
    # Examples with clear descriptions
    it "sets default values" do
      # Implementation
    end
  end

  # Isolation from external services
  context "with external dependencies" do
    # Use mocks/stubs appropriately
    let(:dependency) { instance_double("Dependency") }
    before do
      allow(dependency).to receive(:call).and_return(result)
    end
  end

  # Edge case testing
  context "with invalid inputs" do
    it "raises an appropriate error" do
      expect { subject.method(invalid_input) }.to raise_error(ExpectedError)
    end
  end
end
```

## Output / Success Criteria

**Output:**
- New or updated test files (e.g., `spec/..._spec.rb`).
- Passing test suite execution results.
- Optional: Updated code coverage reports.

**Success Criteria:**

- All tests pass
- Tests written before implementation
- Coverage targets met (95% for core components)
- Thread safety verified
- Clear test names that document behavior
- Tests run in under 5 seconds (or are tagged as slow)
## Reference Documentation
- [Writing Workflow Instructions Guide](docs-dev/guides/writing-workflow-instructions.md)
- [Testing Guidelines Guide](docs-dev/guides/testing.md)
- [Testing Frameworks Guide](docs-dev/guides/testing/frameworks.md) (If applicable)
- [Coding Standards Guide](docs-dev/guides/coding-standards.md)
