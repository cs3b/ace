---
id: v.0.2.0+task.16
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# Implement Aruba for CLI Integration Testing

## 0. Directory Audit ✅

_Command run:_

```bash
find spec/ -name "*integration*" -o -name "*cli*" | head -10
```

_Result excerpt:_

```
spec/integration/llm_gemini_query_integration_spec.rb
```

_Additional context:_

```bash
grep -n "Open3\|capture3" spec/integration/llm_gemini_query_integration_spec.rb | head -5
```

```
4:require "open3"
11:  let(:ruby_path) { RbConfig.ruby }
35:    it "shows help when requested" do
36:      output, status = Open3.capture2e("#{ruby_path} #{exe_path} --help")
42:    it "requires a prompt argument" do
```

## Objective

Replace the current manual subprocess execution approach in CLI integration tests with Aruba framework, as specified in the PRD testing strategy. The current implementation uses Open3 directly for CLI testing, which requires complex manual environment setup, process status checking, and error handling. Aruba provides a specialized framework for CLI testing that will simplify test code, improve maintainability, and align with the project's documented testing architecture.

## Scope of Work

- Add Aruba gem dependency to the project Gemfile
- Refactor existing CLI integration test to use Aruba instead of Open3
- Simplify VCR integration with Aruba's command execution
- Update documentation to reflect Aruba usage
- Ensure all existing test scenarios continue to work with Aruba

### Deliverables

#### Add

- Aruba gem dependency in `Gemfile`

#### Modify

- `spec/integration/llm_gemini_query_integration_spec.rb` - refactor to use Aruba
- `docs/DEVELOPMENT.md` - add Aruba back to development dependencies section
- `docs-project/blueprint.md` - add Aruba back to development tools and dependencies
- `docs-project/architecture.md` - add Aruba back to testing framework description

## Phases

1. Add Aruba dependency to Gemfile and update documentation
2. Analyze current integration test structure and plan Aruba migration
3. Refactor integration test to use Aruba framework
4. Verify all test scenarios work with Aruba
5. Clean up and optimize the test implementation

## Implementation Plan

### Planning Steps

* [ ] Analyze current integration test patterns and identify Aruba equivalent approaches

* [ ] Plan VCR integration strategy with Aruba's command execution model
* [ ] Review Aruba documentation for CLI testing best practices and subprocess environment handling

### Execution Steps

- [ ] Add Aruba gem dependency to `Gemfile` in the development group
- [ ] Update `docs/DEVELOPMENT.md` to include Aruba in Core Development Tools section
- [ ] Update `docs-project/blueprint.md` to include Aruba in Development Tools and Dependencies
- [ ] Update `docs-project/architecture.md` to include Aruba in Testing Framework description
- [ ] Install Aruba dependency by running `bundle install`
  > TEST: Dependency Installation
  > Type: Action Validation
  > Assert: Aruba gem is installed and available in test environment
  > Command: bundle exec ruby -e "require 'aruba'; puts 'Aruba loaded successfully'"
- [ ] Refactor `spec/integration/llm_gemini_query_integration_spec.rb` to use Aruba instead of Open3
  > TEST: Integration Test Refactoring
  > Type: Action Validation
  > Assert: All existing test scenarios pass with Aruba implementation
  > Command: bundle exec rspec spec/integration/llm_gemini_query_integration_spec.rb
- [ ] Simplify VCR subprocess environment setup to work with Aruba's command execution
- [ ] Replace manual process status checking with Aruba's built-in assertions
- [ ] Clean up helper methods that are no longer needed with Aruba
- [ ] Verify all test scenarios continue to work correctly
  > TEST: Full Integration Test Suite
  > Type: Action Validation
  > Assert: All integration tests pass and maintain same coverage
  > Command: bin/test spec/integration/llm_gemini_query_integration_spec.rb

## Acceptance Criteria

- [ ] Aruba gem is added as a development dependency in `Gemfile`
- [ ] Documentation is updated to reflect Aruba usage in development dependencies
- [ ] `spec/integration/llm_gemini_query_integration_spec.rb` uses Aruba instead of Open3
- [ ] All existing test scenarios (help output, error handling, API calls, file input, etc.) continue to pass
- [ ] VCR cassette recording and playback works correctly with Aruba
- [ ] Test code is simplified and more maintainable than the previous Open3 implementation
- [ ] No manual subprocess environment setup is required (leverages Aruba's built-in capabilities)
- [ ] Process status checking uses Aruba's assertions instead of manual expect_process_success helper

## Out of Scope

- ❌ Changing the CLI command interface or functionality
- ❌ Modifying VCR cassette contents or recording strategy
- ❌ Adding new test scenarios beyond existing coverage
- ❌ Refactoring other test files that don't use CLI integration testing

## References

- [PRD Testing Strategy](../../../done/v.0.0.0-bootstrap/PRD.md#10-testing-strategy) - Specifies Aruba for CLI testing
- [Aruba Documentation](https://github.com/cucumber/aruba) - Official Aruba gem documentation
- [Embedding Tests Guide](../../../docs-dev/guides/.meta/workflow-instructions-embeding-tests.g.md) - Testing standards for task implementation
- Current integration test: `spec/integration/llm_gemini_query_integration_spec.rb`

## Risks & Mitigations

**Risk**: VCR integration complexity with Aruba subprocess execution
**Mitigation**: Analyze current VCR subprocess setup and adapt the environment variable passing to Aruba's command execution model

**Risk**: Loss of test coverage during refactoring
**Mitigation**: Run tests frequently during refactoring and ensure all existing assertions are preserved

**Risk**: Aruba learning curve and implementation differences
**Mitigation**: Start with simple test cases and progressively migrate complex scenarios, referencing Aruba documentation