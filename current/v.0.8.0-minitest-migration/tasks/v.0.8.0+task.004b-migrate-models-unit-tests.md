---
id: v.0.8.0+task.004b
status: pending
priority: high
estimate: 2h
dependencies: []
parent_task: v.0.8.0+task.004
---

# Migrate Models Unit Tests

## Objective

Migrate all unit tests for Model components to Minitest. Models are pure data structures with validation, making them straightforward to test without external dependencies.

## Scope of Work

- Write comprehensive unit tests for 28 Model components
- Test data validation and structure integrity
- Verify serialization/deserialization when applicable
- Follow Minitest patterns established in test_helper.rb

## Component Checklist (28 total)

### Core Models (3 components)
- [ ] `error.rb` - Error data structure
- [ ] `result.rb` - Result wrapper with success/failure
- [ ] `validation_result.rb` - Validation result data

### Autofix Models (1 component)
- [ ] `autofix_operation.rb` - Autofix operation data

### Claude Models (2 components)
- [ ] `claude_command.rb` - Claude command metadata
- [ ] `claude_validation_result.rb` - Claude validation results

### Code Review Models (4 components)
- [ ] `code/review_context.rb` - Code review context data
- [ ] `code/review_prompt.rb` - Review prompt structure
- [ ] `code/review_session.rb` - Review session state
- [ ] `code/review_target.rb` - Review target specification

### Command Models (1 component)
- [ ] `command_metadata.rb` - Command metadata structure

### Coverage Models (3 components)
- [ ] `coverage_analysis_result.rb` - Coverage analysis results
- [ ] `coverage_result.rb` - Coverage calculation results
- [ ] `method_coverage.rb` - Method-level coverage data

### File Operation Models (1 component)
- [ ] `file_operation.rb` - File operation specification

### Installation Models (3 components)
- [ ] `installation_options.rb` - Installation configuration
- [ ] `installation_result.rb` - Installation outcome data
- [ ] `installation_stats.rb` - Installation statistics

### Linting Models (2 components)
- [ ] `linting_config.rb` - Linting configuration
- [ ] `error_distribution.rb` - Error distribution data

### LLM Models (3 components)
- [ ] `llm_model_info.rb` - LLM model information
- [ ] `pricing.rb` - LLM pricing data
- [ ] `default_model_config.rb` - Default model configuration

### Search Models (3 components)
- [ ] `search/search_options.rb` - Search configuration options
- [ ] `search/search_preset.rb` - Search preset definition
- [ ] `search/search_result.rb` - Search result data

### Usage Models (2 components)
- [ ] `usage_metadata.rb` - Basic usage metadata
- [ ] `usage_metadata_with_cost.rb` - Usage with cost calculation

## Progress Tracking

- **Components completed:** 0/28
- **Estimated time per component:** ~4 minutes
- **Current focus:** [Not started]

## Implementation Plan

### Execution Steps

1. **Setup Test Infrastructure**
   - [ ] Create test/unit/models/ directory structure
   - [ ] Set up shared test helpers for models

2. **Test Core Models First** (Priority: High)
   - [ ] Test Result and Error models (fundamental types)
   - [ ] Test validation models (used across codebase)
   - [ ] Test command metadata models

3. **Test Domain Models** (Priority: Medium)
   - [ ] Test code review models
   - [ ] Test coverage models
   - [ ] Test search models
   - [ ] Test LLM models

4. **Test Configuration Models** (Priority: Low)
   - [ ] Test installation models
   - [ ] Test linting configuration
   - [ ] Test default configurations

## Acceptance Criteria

- [ ] All 28 model components have corresponding test files
- [ ] Each test validates:
  - Initialization with valid/invalid data
  - Attribute accessors and mutators
  - Data validation rules
  - Serialization methods (to_h, to_json if present)
- [ ] Tests pass with `ace-test models`
- [ ] Tests run in parallel (using parallelize_me!)
- [ ] No external dependencies in tests

## Testing Guidelines

### Model Test Principles
- Data integrity: validate structure and types
- Immutability: test frozen states where applicable
- Validation: test all validation rules
- Edge cases: nil, empty, and boundary values
- Serialization: round-trip conversion testing

### Example Test Structure
```ruby
class SomeModelTest < ModelTest
  def test_initialization_with_valid_data
    model = SomeModel.new(field: "value")
    assert_equal "value", model.field
  end

  def test_validation_rejects_invalid_data
    assert_raises(ValidationError) do
      SomeModel.new(field: nil)
    end
  end

  def test_serialization_round_trip
    original = SomeModel.new(field: "value")
    restored = SomeModel.from_h(original.to_h)
    assert_equal original, restored
  end
end
```

## Out of Scope

- Behavior testing (models should be data-only)
- Integration with external services
- Database persistence testing
- Complex business logic (belongs in molecules/organisms)

## References

- **Testing Guide**: `docs/development/testing.g.md` - Essential testing patterns and setup
- Test helper: `test/test_helper.rb`
- Model base class: `ModelTest`
- Example model test: `test/unit/models/example_model_test.rb`