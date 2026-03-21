---
doc-type: guide
title: Test Organization
purpose: Test file organization
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Test Organization

## Flat Directory Structure

All ACE gems use a **flat test directory structure** that mirrors the ATOM architecture:

```
test/
├── test_helper.rb
├── search_test.rb              # Main module test
├── atoms/
│   ├── pattern_analyzer_test.rb
│   ├── result_parser_test.rb
│   └── tool_checker_test.rb
├── molecules/
│   ├── preset_manager_test.rb
│   └── git_scope_filter_test.rb
├── organisms/
│   ├── unified_searcher_test.rb
│   └── result_formatter_test.rb
├── models/
│   └── search_result_test.rb
└── integration/
    └── cli_integration_test.rb
```

## Key Conventions

- **Flat structure**: `test/atoms/`, not `test/ace/search/atoms/`
- **Suffix naming**: `pattern_analyzer_test.rb`, not `test_pattern_analyzer.rb`
- **Layer directories match ATOM architecture**: atoms, molecules, organisms
- **Integration tests in separate `integration/` directory**

## Benefits

- Easier to navigate and find tests
- Matches layer boundaries clearly
- Consistent across all ACE gems
- Less nesting = simpler paths

See `ace-taskflow/test/` for reference implementation.

## Naming Conventions

### Test Files

- Use `*_test.rb` suffix (Minitest convention)
- Name matches the class being tested: `PatternAnalyzer` → `pattern_analyzer_test.rb`
- One test file per class/module

### Test Methods

- Use `test_` prefix: `def test_finds_patterns_in_code`
- Be descriptive: `test_returns_empty_when_no_matches` not `test_empty`
- Include the scenario: `test_raises_error_on_invalid_input`

### Test Classes

- Mirror the class hierarchy: `class PatternAnalyzerTest < Minitest::Test`
- Group related tests with modules if needed

## Test Data

### Fixtures

Store test data in `test/fixtures/`:

```
test/fixtures/
├── sample_config.yml
├── git_diff_output.txt
└── api_responses/
    └── github_pr_123.json
```

### Creating Fixtures

Use `yaml_fixture` helper for YAML fixtures:

```ruby
def test_loads_config
  config = yaml_fixture("sample_config.yml")
  assert_equal "expected_value", config["key"]
end
```

### Inline Data

Prefer inline data for small test cases:

```ruby
def test_parses_simple_input
  input = "key: value"
  result = Parser.parse(input)
  assert_equal "value", result["key"]
end
```

## Test Helpers

### Location

Place shared helpers in `test/test_helper.rb` or a dedicated `test/support/` directory:

```
test/
├── test_helper.rb
└── support/
    ├── mock_git_repo.rb
    └── api_stubs.rb
```

### Including Helpers

```ruby
# test_helper.rb
require_relative "support/mock_git_repo"

module TestHelpers
  include MockGitRepo
end

class Minitest::Test
  include TestHelpers
end
```

## Related Guides

- [Testing Philosophy](guide://testing-philosophy) - Why this structure
- [Mocking Patterns](guide://mocking-patterns) - Test isolation patterns