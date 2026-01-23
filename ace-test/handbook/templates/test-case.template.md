---
name: test-case
description: Template for creating test case files
doc-type: template
purpose: Template for writing test cases
update:
  frequency: as-needed
  last-updated: '2026-01-22'
---

# Test Case: {{FEATURE_NAME}}

## Description

Brief description of what this test case covers.

## Test Scenario

### Given
- Precondition 1
- Precondition 2

### When
- Action or event occurs

### Then
- Expected outcome 1
- Expected outcome 2

## Test Implementation

```ruby
# frozen_string_literal: true

require_relative "test_helper"

module {{MODULE_NAME}}
  class {{FEATURE_NAME}}Test < TestCase
    def test_{{scenario_name}}
      # Arrange
      # Setup test conditions

      # Act
      # Execute the behavior being tested

      # Assert
      # Verify expected outcomes
    end
  end
end
```

## Edge Cases to Consider

1. Edge case 1
2. Edge case 2
3. Edge case 3
