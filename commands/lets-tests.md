# Let's Test Command

For implementing tests using Test-Driven Development. See [Testing Guide](../guides/testing.md) for details.

## Process Steps

1. **Review Feature Specification**:
   - Identify test requirements from the feature spec in `docs-dev/project/1-next/`
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

## Success Criteria

- All tests pass
- Tests written before implementation
- Coverage targets met (95% for core components)
- Thread safety verified
- Clear test names that document behavior
- Tests run in under 5 seconds (or are tagged as slow)
