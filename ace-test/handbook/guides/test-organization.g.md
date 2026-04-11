---
doc-type: guide
title: Test Organization
purpose: Test file organization
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Test Organization

## Top-Level Test Structure

All ACE gems should converge on three top-level test directories:

```
test/
├── test_helper.rb
├── fast/
│   ├── atoms/
│   ├── molecules/
│   ├── organisms/
│   ├── models/
│   └── commands/
├── feat/
│   └── cli_contract_test.rb
├── e2e/
│   └── TS-PACKAGE-001-scenario/
│       └── scenario.yml
├── fixtures/
└── support/
```

## Key Conventions

- **Top-level categories**: `test/fast/`, `test/feat/`, `test/e2e/`
- **Fast sublayers mirror ATOM**: atoms, molecules, organisms, models, commands
- **Suffix naming**: `pattern_analyzer_test.rb`, not `test_pattern_analyzer.rb`
- **Deterministic feature tests live in `test/feat/`**
- **Scenario workflows live in `test/e2e/TS-*/`**

## Benefits

- Easier to navigate and find tests
- Matches layer boundaries clearly
- Consistent across all ACE gems
- Less nesting = simpler paths

Use `ace-b36ts/test/` as the reference implementation for the new layout.

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
