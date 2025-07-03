# Create Test Cases Workflow Instruction

## Goal

Generate a structured list of test cases (unit, integration, performance, etc.) for a specific feature, task, or code change based on requirements and comprehensive testing principles.

## Prerequisites

- Clear understanding of the feature/task requirements
- Knowledge of the code changes or implementation approach
- Understanding of different test types and their purposes
- Access to existing test patterns in the codebase

## Project Context Loading

- Load project objectives: `docs/what-do-we-build.md`
- Load architecture overview: `docs/architecture.md`
- Load project structure: `docs/blueprint.md`

## High-Level Execution Plan

### Planning Steps

- [ ] Analyze requirements and identify testable components
- [ ] Identify test scenarios across different categories (happy path, edge cases, errors)
- [ ] Categorize tests by type (unit, integration, end-to-end, performance, security)

### Execution Steps

- [ ] Create comprehensive test case structure using embedded template
- [ ] Generate test cases covering all identified scenarios
- [ ] Include implementation hints and examples
- [ ] Review and refine test cases for completeness
- [ ] Save test cases in appropriate project location

## Process Steps

1. **Analyze Requirements:**
   - Review the feature/task details:
     - Business requirements and user stories
     - Technical specifications
     - Acceptance criteria
     - Implementation approach
     - Dependencies and integrations

   - Identify testable components:
     - Input validation rules
     - Business logic flows
     - Output expectations
     - Error scenarios
     - Performance requirements

2. **Identify Test Scenarios:**

   **Scenario Categories:**

   **Happy Path (Core Functionality):**
   - Standard expected usage
   - Primary user workflows
   - Common configurations
   - Successful outcomes

   **Edge Cases:**
   - Boundary values (min/max)
   - Empty or null inputs
   - Special characters
   - Large data sets
   - Concurrent operations

   **Error Conditions:**
   - Invalid inputs
   - Missing required data
   - Service failures
   - Network timeouts
   - Permission denials

   **Integration Points:**
   - External API calls
   - Database operations
   - File system access
   - Message queues
   - Third-party services

3. **Categorize by Test Type:**

   **Unit Tests** (Isolated component testing):
   - Individual functions/methods
   - Class behavior
   - Pure logic validation
   - Mock external dependencies

   **Integration Tests** (Component interaction):
   - API endpoint testing
   - Database integration
   - Service communication
   - Configuration loading

   **End-to-End Tests** (Full workflow):
   - Complete user journeys
   - Multi-step processes
   - Cross-system flows
   - UI interaction (if applicable)

   **Performance Tests** (Speed and scale):
   - Response time benchmarks
   - Throughput limits
   - Resource usage
   - Concurrent user load

   **Security Tests** (Vulnerability checks):
   - Authentication bypass
   - Authorization violations
   - Input injection
   - Data exposure

4. **Create Test Case Structure:**

   Use the test case template:

5. **Generate Comprehensive Test Cases:**

   **Example: User Authentication Feature**

   ```markdown
   # Test Cases: User Authentication
   
   ## Unit Tests
   
   ### TC-001: Valid Password Validation
   **Category**: Unit
   **Priority**: High
   **Component**: PasswordValidator
   
   **Description**: Verify password meets all security requirements
   
   **Test Steps**:
   1. Call validatePassword("SecureP@ss123")
   2. Check return value
   
   **Expected**: Returns true for valid password
   
   ---
   
   ### TC-002: Weak Password Rejection
   **Category**: Unit
   **Priority**: High
   **Component**: PasswordValidator
   
   **Description**: Verify weak passwords are rejected
   
   **Test Cases**:
   - "123456" → false (too simple)
   - "password" → false (common word)
   - "short" → false (too short)
   - "" → false (empty)
   - null → false (null input)
   
   ---
   
   ## Integration Tests
   
   ### TC-010: Successful Login Flow
   **Category**: Integration
   **Priority**: High
   **Component**: AuthenticationService
   
   **Description**: Verify complete login process with valid credentials
   
   **Prerequisites**:
   - Test user exists in database
   - Authentication service running
   
   **Test Steps**:
   1. POST /api/login with valid credentials
   2. Verify response status 200
   3. Check returned JWT token
   4. Validate token contains correct user claims
   
   **Expected**:
   - Status: 200 OK
   - Valid JWT token
   - User session created
   
   ---
   
   ### TC-011: Failed Login - Invalid Credentials
   **Category**: Integration
   **Priority**: High
   **Component**: AuthenticationService
   
   **Test Matrix**:
   | Username | Password | Expected Status | Error Message |
   |----------|----------|----------------|---------------|
   | valid@email | wrong_pass | 401 | Invalid credentials |
   | wrong@email | valid_pass | 401 | Invalid credentials |
   | "" | valid_pass | 400 | Email required |
   | valid@email | "" | 400 | Password required |
   
   ---
   
   ## Performance Tests
   
   ### TC-020: Login Response Time
   **Category**: Performance
   **Priority**: Medium
   **Component**: AuthenticationService
   
   **Description**: Verify login completes within acceptable time
   
   **Test Steps**:
   1. Measure single login request time
   2. Repeat 100 times
   3. Calculate average, min, max, p95
   
   **Expected**:
   - Average response time < 200ms
   - 95th percentile < 500ms
   - No requests > 1000ms
   ```

6. **Include Test Implementation Hints:**

   Use the test implementation examples:

7. **Review and Refine:**

   **Test Case Review Checklist:**
   - [ ] All requirements have corresponding tests
   - [ ] Happy path scenarios covered
   - [ ] Edge cases identified and tested
   - [ ] Error conditions properly tested
   - [ ] Test data is realistic
   - [ ] Tests are independent
   - [ ] Clear pass/fail criteria
   - [ ] Appropriate test types chosen

8. **Save Test Cases:**

   **File Organization:**

   ```
   dev-taskflow/current/v.X.Y.Z/test-cases/
   ├── feature-authentication-tests.md
   ├── api-endpoint-tests.md
   └── performance-benchmarks.md
   ```

   **Naming Convention:**
   - `feature-[name]-tests.md` - Feature-specific tests
   - `api-[endpoint]-tests.md` - API testing
   - `security-[component]-tests.md` - Security tests
   - `performance-[area]-tests.md` - Performance tests

## Test Case Prioritization

**High Priority:**

- Core business logic
- Security-critical features
- User-facing functionality
- Data integrity operations

**Medium Priority:**

- Secondary features
- Admin functions
- Reporting features
- Performance optimizations

**Low Priority:**

- Nice-to-have features
- Cosmetic issues
- Rare edge cases
- Internal tools

## Success Criteria

- Comprehensive test case list covering all requirements
- Tests organized by type and priority
- Each test has clear steps and expected results
- Test data and prerequisites documented
- Edge cases and error scenarios included
- Tests are atomic and independent
- Clear traceability to requirements

## Common Testing Patterns

### Boundary Testing

```markdown
### TC-030: Age Validation Boundaries
**Test Cases**:
- Age = -1 → Error (negative)
- Age = 0 → Valid (minimum)
- Age = 17 → Invalid (below minimum)
- Age = 18 → Valid (minimum adult)
- Age = 120 → Valid (maximum reasonable)
- Age = 121 → Warning (unusually high)
- Age = null → Error (required field)
```

### State Transition Testing

```markdown
### TC-040: Order State Transitions
**Valid Transitions**:
- Draft → Submitted → Approved → Fulfilled
- Draft → Cancelled
- Submitted → Rejected

**Invalid Transitions**:
- Fulfilled → Draft (cannot reverse)
- Cancelled → Approved (terminated state)
```

### Data Validation Matrix

```markdown
### TC-050: Input Validation
| Field | Valid Values | Invalid Values | Expected Error |
|-------|--------------|----------------|----------------|
| Email | user@domain.com | plaintext | Invalid format |
| Phone | +1-555-1234 | 12345 | Invalid format |
| Date | 2024-01-01 | 01-01-2024 | Invalid format |
```

## Common Patterns

### Feature Test Case Development

Create comprehensive test suites when implementing new features with complex business logic.

### API Endpoint Test Coverage

Develop test cases for REST API endpoints covering various HTTP methods and response scenarios.

### Security Feature Testing

Generate security-focused test cases for authentication, authorization, and data protection features.

### Performance Benchmark Testing

Create performance test cases to establish and maintain system performance standards.

## Usage Example
>
> "I've implemented a new user registration feature with email verification. Create comprehensive test cases covering all aspects of the registration flow."

---

This workflow ensures thorough test coverage through systematic identification and documentation of test scenarios across all testing levels.

<documents>
    <template path="dev-handbook/templates/release-testing/test-case.template.md"># Test Cases: [Feature Name]

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

</template>
</documents>
