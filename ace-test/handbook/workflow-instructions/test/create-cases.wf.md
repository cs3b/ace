---
doc-type: workflow
title: Create Test Cases Workflow Instruction
purpose: create-test-cases workflow instruction
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Create Test Cases Workflow Instruction

## Goal

Generate a structured list of test cases following the ACE testing approach (atoms, molecules, organisms, e2e) for a specific feature, task, or code change based on requirements and comprehensive testing principles.

## Prerequisites

- Clear understanding of the feature/task requirements
- Knowledge of the code changes or implementation approach
- Understanding of ACE test layers and their IO policies
- Access to existing test patterns in the codebase

## Project Context Loading

- Read and follow: `ace-bundle wfi://bundle`

## High-Level Execution Plan

### Planning Steps

- [ ] Analyze requirements and identify testable components
- [ ] Identify test scenarios across different categories (happy path, edge cases, errors)
- [ ] Assign tests to ACE layers (atoms, molecules, organisms, e2e)

### Execution Steps

- [ ] Create comprehensive test case structure using embedded template
- [ ] Generate test cases covering all identified scenarios
- [ ] Include implementation hints and examples
- [ ] Review and refine test cases for completeness
- [ ] Save test cases in appropriate project location

## ACE Testing Framework

All ACE packages use Minitest with layer-specific conventions:

| Layer | Directory | IO Policy | Performance Target |
|-------|-----------|-----------|-------------------|
| Atoms | `test/atoms/` | **No IO** | <10ms (max 50ms) |
| Molecules | `test/molecules/` | **No IO** | <50ms (max 100ms) |
| Organisms | `test/organisms/` | **Mocked IO** | <100ms (max 200ms) |
| E2E | `test/e2e/TS-*/` | **Real IO** | <2s (max 5s) |

**All tests MUST inherit from the package test base class:**

```ruby
# CORRECT: Has access to package helpers
class FeedbackExtractorTest < AceReviewTest
  # Can use stub_prompt_path, shared temp dir, etc.
end

# INCORRECT: Missing package helpers
class FeedbackExtractorTest < Minitest::Test
  # No access to stub_prompt_path
end
```

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

3. **Assign to ACE Test Layer:**

   ### ACE Test Layer Assignment

   | Layer | Directory | IO Policy | Performance Target |
   |-------|-----------|-----------|-------------------|
   | Atoms | `test/atoms/` | **No IO** | <10ms (max 50ms) |
   | Molecules | `test/molecules/` | **No IO** | <50ms (max 100ms) |
   | Organisms | `test/organisms/` | **Mocked IO** | <100ms (max 200ms) |
   | E2E | `test/e2e/TS-*/` | **Real IO** | <2s (max 5s) |

   **Layer Decision Matrix:**

   | Test This... | At Layer | Because |
   |-------------|----------|---------|
   | Pure logic (input → output) | Atoms | No dependencies |
   | Component composition | Molecules | Stubs external calls |
   | Business workflows | Organisms | Mocked boundaries |
   | CLI parity (ONE per file) | Organisms | Real subprocess |
   | Critical user journeys | E2E | Full system validation |

4. **Apply IO Isolation Requirements:**

   **Atoms & Molecules (Unit Tests):**
   - [ ] No filesystem operations (use temp dirs or mocks)
   - [ ] No network calls (use WebMock)
   - [ ] No subprocess calls (stub `Open3`, `system`, backticks)
   - [ ] No real git operations (use MockGitRepo)
   - [ ] No sleep calls (stub `Kernel.sleep`)

   **Organisms (Integration):**
   - [ ] External services stubbed
   - [ ] ONE real CLI test per file maximum
   - [ ] All other subprocess calls mocked

   **Common Subprocess Patterns to Stub:**
   | Pattern | Typical Cost | Standard Stub |
   |---------|-------------|---------------|
   | `` `ace-nav ...` `` | ~200ms | `stub_prompt_path(object)` |
   | `` `git ...` `` | ~100ms | MockGitRepo or stub |
   | `Open3.capture3` | ~150ms | Stub `:capture3` |

5. **Create Test Case Structure:**

   Use the test case template embedded below.

6. **Generate Comprehensive Test Cases:**

   **Example: Feedback Extraction Feature**

   ```markdown
   # Test Cases: Feedback Extraction

   ## Atoms

   ### TC-001: Extract File Path from Line
   **Layer**: Atoms
   **Priority**: High
   **Component**: PatternAnalyzer
   **Target**: <10ms

   **Description**: Extract file path from review feedback line

   **Test Steps**:
   1. Parse "src/foo.rb:42: warning: unused variable"
   2. Extract file path component

   **Expected**: Returns "src/foo.rb"

   ---

   ### TC-002: Parse Feedback Severity
   **Layer**: Atoms
   **Priority**: High
   **Component**: FeedbackParser
   **Target**: <10ms

   **Test Cases**:
   | Input | Expected Severity | Expected Code |
   |-------|-------------------|---------------|
   | "error: missing method" | error | E001 |
   | "warning: unused var" | warning | W001 |
   | "info: style issue" | info | I001 |

   ---

   ## Molecules

   ### TC-010: Extract Feedback from Review Output
   **Layer**: Molecules
   **Priority**: High
   **Component**: FeedbackExtractor
   **Target**: <50ms
   **Stubs Required**: `stub_prompt_path(@extractor)`

   **Description**: Parse review output and extract structured feedback

   **Setup**:
   ```ruby
   stub_prompt_path(@extractor)  # Stubs ace-nav subprocess
   ```

   **Test Steps**:
   1. Create extractor with mocked prompt path
   2. Call extract with review text
   3. Verify parsed feedback items

   **Expected**:
   - Returns array of FeedbackItem objects
   - File paths correctly extracted
   - Severity levels parsed

   ---

   ## Organisms

   ### TC-020: Coordinate Multi-Model Review
   **Layer**: Organisms
   **Priority**: High
   **Component**: ReviewOrchestrator
   **Target**: <100ms
   **Stubs Required**: Mock LLM, MockGitRepo

   **Description**: Orchestrate review across multiple models

   **Setup**:
   ```ruby
   mock_llm = Minitest::Mock.new
   mock_llm.expect(:complete, response, [prompt])
   ```

   **Test Steps**:
   1. Create orchestrator with mocked LLM
   2. Submit diff for review
   3. Verify LLM called correctly
   4. Assert result.success?

   **Expected**:
   - LLM receives correct prompt
   - Response properly parsed
   - Result marked successful

   ---

   ## E2E

   ### TC-030: Full Review Workflow
   **Layer**: E2E
   **Priority**: Medium
   **Component**: CLI
   **Target**: <2s
   **Real IO**: Yes

   **Description**: Complete review workflow from CLI invocation

   **Prerequisites**:
   - Git repository with staged changes
   - ACE tools installed

   **Test Steps**:
   1. Run `ace-review` on test repo
   2. Verify exit code is 0
   3. Check feedback file created
   4. Verify feedback content

   **Expected**:
   - Exit code: 0
   - Feedback file: `.ace/review/feedback.json`
   - Contains structured feedback
   ```

7. **Include Test Implementation Hints:**

   **Atom test - pure logic, no IO:**
   ```ruby
   class PatternAnalyzerTest < AceLintTest
     def test_extracts_file_path_from_line
       line = "src/foo.rb:42: warning: unused variable"
       result = PatternAnalyzer.extract_path(line)
       assert_equal "src/foo.rb", result
     end
   end
   ```

   **Molecule test - stubs subprocess calls:**
   ```ruby
   class FeedbackExtractorTest < AceReviewTest
     def setup
       @extractor = FeedbackExtractor.new
       stub_prompt_path(@extractor)  # Stubs ace-nav subprocess
     end

     def test_extracts_feedback_from_review
       result = @extractor.extract(review_text)
       assert_equal 3, result.items.length
     end
   end
   ```

   **Organism test - mocked boundaries:**
   ```ruby
   class ReviewOrchestratorTest < AceReviewTest
     def test_coordinates_multi_model_review
       mock_llm = Minitest::Mock.new
       mock_llm.expect(:complete, response, [prompt])

       orchestrator = ReviewOrchestrator.new(llm: mock_llm)
       result = orchestrator.review(diff)

       assert result.success?
       mock_llm.verify
     end
   end
   ```

8. **Verification:**

   After creating test cases, validate with:

   ```bash
   # Verify tests meet performance targets
   ace-test <package> --profile 10

   # Full suite health check
   ace-bundle wfi://test/verify-suite
   ```

   Expected:
   - All atoms <50ms
   - All molecules <100ms
   - All organisms <200ms
   - No unstubbed subprocess calls in unit tests

9. **Review and Refine:**

   **Test Case Review Checklist:**
   - [ ] All requirements have corresponding tests
   - [ ] Happy path scenarios covered
   - [ ] Edge cases identified and tested
   - [ ] Error conditions properly tested
   - [ ] Test data is realistic
   - [ ] Tests are independent
   - [ ] Clear pass/fail criteria
   - [ ] Appropriate layer chosen (atoms/molecules/organisms/e2e)
   - [ ] IO isolation requirements met
   - [ ] Performance targets achievable

10. **Save Test Cases:**

   **File Organization:**

   Use the current release directory for test cases:

   ```bash
   # Get current release path
   ace-release --path
   ```

   ```
   .ace-taskflow/v.X.Y.Z/test-cases/
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

**Layer**: [Atoms | Molecules | Organisms | E2E]
**Priority**: [High | Medium | Low]
**Component**: [Component/Module being tested]
**Target**: [<10ms | <50ms | <100ms | <2s]
**Stubs Required**: [List stubs needed for atoms/molecules/organisms]

### Description

Brief explanation of what this test validates.

### IO Isolation Checklist

- [ ] No filesystem operations (atoms/molecules)
- [ ] No network calls (atoms/molecules/organisms)
- [ ] No subprocess calls without stubs (atoms/molecules)
- [ ] No sleep calls (atoms/molecules)
- [ ] At most ONE real CLI call (organisms)

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

## ACE Minitest Implementation Examples

### Atom Test Example

```ruby
# test/atoms/pattern_analyzer_test.rb
class PatternAnalyzerTest < AceLintTest
  def test_extracts_file_path_from_line
    line = "src/foo.rb:42: warning: unused variable"
    result = PatternAnalyzer.extract_path(line)
    assert_equal "src/foo.rb", result
  end

  def test_returns_nil_for_invalid_line
    result = PatternAnalyzer.extract_path("invalid line")
    assert_nil result
  end
end
```

### Molecule Test Example

```ruby
# test/molecules/feedback_extractor_test.rb
class FeedbackExtractorTest < AceReviewTest
  def setup
    @extractor = FeedbackExtractor.new
    stub_prompt_path(@extractor)  # Stubs ace-nav subprocess
  end

  def test_extracts_feedback_from_review
    review_text = "src/foo.rb:42: warning: unused variable"
    result = @extractor.extract(review_text)

    assert_equal 1, result.items.length
    assert_equal "src/foo.rb", result.items.first.file
  end

  def test_handles_empty_review
    result = @extractor.extract("")
    assert_empty result.items
  end
end
```

### Organism Test Example

```ruby
# test/organisms/review_orchestrator_test.rb
class ReviewOrchestratorTest < AceReviewTest
  def test_coordinates_multi_model_review
    mock_llm = Minitest::Mock.new
    mock_llm.expect(:complete, mock_response, [Hash])

    orchestrator = ReviewOrchestrator.new(llm: mock_llm)
    result = orchestrator.review(diff)

    assert result.success?
    mock_llm.verify
  end

  def test_handles_llm_failure_gracefully
    mock_llm = Minitest::Mock.new
    mock_llm.expect(:complete, nil) { raise StandardError }

    orchestrator = ReviewOrchestrator.new(llm: mock_llm)
    result = orchestrator.review(diff)

    refute result.success?
    assert result.error
  end
end
```

### E2E Test Example

```
<!-- test/e2e/TS-REVIEW-001-basic-workflow/ -->
scenario.yml          # Metadata + setup (git-init, copy-fixtures, env)
TC-001-basic-review.tc.md
TC-002-missing-git-repo.tc.md
fixtures/
  app.rb              # def foo; end
```

**TC-001-basic-review.tc.md:**
```markdown
---
tc-id: TC-001
title: Basic Review Workflow
---

## Objective

Verify that ace-review runs successfully and creates feedback output.

## Steps

1. Run review
   ```bash
   OUTPUT=$(ace-review 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify feedback file created
   ```bash
   [ -f .ace/review/feedback.json ] && echo "PASS: Feedback file exists" || echo "FAIL: No feedback file"
   ```

## Expected

- Exit code: 0
- Feedback file created at .ace/review/feedback.json
```

</template>
</documents>