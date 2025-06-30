# Test Cases: [Feature Name]

## Test Case: [TC-001] [Descriptive Name]

**Category**: [Unit | Integration | E2E | Performance | Security]
**Priority**: [High | Medium | Low]
**Component**: [Component/Module being tested]

### Description

Brief explanation of what this test validates.

### Prerequisites

- Required test data
- System state
- Configuration settings
- External dependencies

### Test Steps

1. [Action 1]
   - Input: [Specific data/parameters]
   - Action: [What to do]
2. [Action 2]
   - Input: [Specific data/parameters]
   - Action: [What to do]
3. [Verification]
   - Check: [What to verify]

### Expected Results

- [Expected outcome 1]
- [Expected outcome 2]
- [System state after test]

### Actual Results

(To be filled during test execution)

- [ ] Pass
- [ ] Fail
- Notes:

### Test Data

```json
{
  "input": "example",
  "config": {
    "setting": "value"
  }
}
```

## Test Implementation Examples

### Jest/JavaScript Example

```javascript
describe('[Feature Name]', () => {
  test('[Test Case Description]', () => {
    // Arrange
    const input = 'test data';
    
    // Act
    const result = featureFunction(input);
    
    // Assert
    expect(result).toBe('expected value');
  });
});
```

### RSpec/Ruby Example

```ruby
describe '[Feature Name]' do
  it '[Test Case Description]' do
    # Arrange
    input = 'test data'
    
    # Act
    result = feature_function(input)
    
    # Assert
    expect(result).to eq('expected value')
  end
end
```

### Pytest/Python Example

```python
def test_feature_name():
    # Arrange
    input_data = 'test data'
    
    # Act
    result = feature_function(input_data)
    
    # Assert
    assert result == 'expected value'
```
