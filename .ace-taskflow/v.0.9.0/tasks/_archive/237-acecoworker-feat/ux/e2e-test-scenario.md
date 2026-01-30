# E2E Test Scenario: MT-COWORKER-001

## Work Queue Session Lifecycle

### Objective

Validate ace-coworker manages sessions with a work queue model where:
- Steps have states: done, in_progress, in_queue, failed
- Failed steps remain in queue as history
- Work can be added dynamically
- Status shows complete queue state

### Prerequisites

- ace-coworker gem installed
- Temp test directory available
- Ruby available for running actual tests

### Setup

Create test-job.yaml with a real FooBar gem creation workflow:

```yaml
# test-job.yaml - A real workflow that creates a Ruby project
session:
  name: foobar-gem-session
  description: Create a minimal Ruby gem with FooBar class

steps:
  - name: init-project
    instructions: |
      Create a minimal Ruby project structure:

      ```bash
      mkdir -p lib test
      ```

      Create lib/foo_bar.rb with a placeholder:
      ```ruby
      class FooBar
        # TODO: implement
      end
      ```

      Create test/test_helper.rb:
      ```ruby
      require 'minitest/autorun'
      require_relative '../lib/foo_bar'
      ```

      Report when done with: ace-coworker report init-report.md

  - name: write-tests
    instructions: |
      Create test/foo_bar_test.rb with these tests:

      ```ruby
      require_relative 'test_helper'

      class FooBarTest < Minitest::Test
        def test_greet_returns_hello
          fb = FooBar.new("World")
          assert_equal "Hello, World!", fb.greet
        end

        def test_greet_with_custom_name
          fb = FooBar.new("Ruby")
          assert_equal "Hello, Ruby!", fb.greet
        end

        def test_shout_returns_uppercase
          fb = FooBar.new("test")
          assert_equal "HELLO, TEST!", fb.shout
        end
      end
      ```

      Report when done with: ace-coworker report tests-report.md

  - name: implement-foobar
    instructions: |
      Implement the FooBar class in lib/foo_bar.rb:

      ```ruby
      class FooBar
        def initialize(name)
          @name = name
        end

        def greet
          "Hello, #{@name}!"
        end

        def shout
          greet.upcase
        end
      end
      ```

      Report when done with: ace-coworker report impl-report.md

  - name: run-tests
    instructions: |
      Run the tests:

      ```bash
      ruby -Ilib:test test/foo_bar_test.rb
      ```

      Report with test output: ace-coworker report test-results.md
    verifications:
      - ruby -Ilib:test test/foo_bar_test.rb

  - name: report-status
    instructions: |
      Summarize what was created:
      - Project structure
      - Test coverage
      - Implementation status

      Final report: ace-coworker report final-report.md
```

---

## Test Cases

### TC-001: Start session and init project

```bash
# Create temp directory for test
mkdir -p /tmp/foobar-test && cd /tmp/foobar-test
cp test-job.yaml .

# Start the workflow
ace-coworker start --config test-job.yaml

# Expected output:
# Session: foobar-gem-session (abc123)
# Step 1/5: init-project [in_progress]
#
# Instructions:
# Create a minimal Ruby project structure...

# Verify initial queue state
ace-coworker status
# Expected: init-project (in_progress), write-tests..report-status (in_queue)
```

**Assertions:**
- [ ] Session created with unique ID
- [ ] First step marked as in_progress
- [ ] Remaining steps marked as in_queue
- [ ] Instructions displayed for first step

---

### TC-002: Complete init and advance to tests

```bash
# Agent creates the project structure
mkdir -p lib test
cat > lib/foo_bar.rb << 'EOF'
class FooBar
  # TODO: implement
end
EOF

cat > test/test_helper.rb << 'EOF'
require 'minitest/autorun'
require_relative '../lib/foo_bar'
EOF

# Report completion
echo "Created lib/foo_bar.rb and test/test_helper.rb" > init-report.md
ace-coworker report init-report.md

# Expected: init-project -> done, write-tests -> in_progress
ace-coworker status
```

**Assertions:**
- [ ] init-project status changed to done
- [ ] write-tests status changed to in_progress
- [ ] Report file stored in session directory
- [ ] Next step instructions displayed

---

### TC-003: Progress through implementation

```bash
# Complete write-tests step (create test file)
cat > test/foo_bar_test.rb << 'EOF'
require_relative 'test_helper'

class FooBarTest < Minitest::Test
  def test_greet_returns_hello
    fb = FooBar.new("World")
    assert_equal "Hello, World!", fb.greet
  end

  def test_greet_with_custom_name
    fb = FooBar.new("Ruby")
    assert_equal "Hello, Ruby!", fb.greet
  end

  def test_shout_returns_uppercase
    fb = FooBar.new("test")
    assert_equal "HELLO, TEST!", fb.shout
  end
end
EOF

echo "Created test/foo_bar_test.rb with 3 tests" > tests-report.md
ace-coworker report tests-report.md

# Complete implement-foobar step
cat > lib/foo_bar.rb << 'EOF'
class FooBar
  def initialize(name)
    @name = name
  end

  def greet
    "Hello, #{@name}!"
  end

  def shout
    greet.upcase
  end
end
EOF

echo "Implemented FooBar class with greet and shout methods" > impl-report.md
ace-coworker report impl-report.md

# Now at run-tests step
ace-coworker status
# Shows: init-project(done), write-tests(done), implement-foobar(done),
#        run-tests(in_progress), report-status(in_queue)
```

**Assertions:**
- [ ] Three steps marked as done
- [ ] run-tests now in_progress
- [ ] report-status still in_queue

---

### TC-004: Simulate test failure

```bash
# Simulate failed tests (e.g., implementation bug)
ace-coworker fail --message "2 tests failed: test_greet, test_shout"

# Key behavior: run-tests stays in queue as FAILED (history preserved)
ace-coworker status
# Shows: ...run-tests(failed), report-status(in_queue)
```

**Assertions:**
- [ ] run-tests status is "failed" (NOT removed)
- [ ] Error message preserved in queue item
- [ ] report-status still in_queue (workflow not advanced)

---

### TC-005: Add fix step dynamically

```bash
# Add a fix step before retrying
ace-coworker add "fix-implementation" --instructions "Fix the FooBar bug"

# Queue now shows:
ace-coworker status
# ...run-tests(failed), fix-implementation(in_progress), report-status(in_queue)
```

**Assertions:**
- [ ] New step "fix-implementation" added to queue
- [ ] New step has status in_progress
- [ ] New step has added_by: "dynamic" metadata
- [ ] Queue order preserved

---

### TC-006: Retry failed step (as new item)

```bash
# Complete the fix step first
echo "Fixed the FooBar implementation" > fix-report.md
ace-coworker report fix-report.md

# Retry the tests - creates NEW queue item, preserves failed one
ace-coworker retry 4

ace-coworker status
# Expected output:
# QUEUE - Session: foobar-gem-session
# #  STATUS       NAME
# 1  done         init-project
# 2  done         write-tests
# 3  done         implement-foobar
# 4  failed       run-tests        (2 tests failed)
# 5  done         fix-implementation
# 6  in_progress  run-tests        (retry of #4)
# 7  in_queue     report-status
```

**Assertions:**
- [ ] Original failed step #4 PRESERVED with failed status
- [ ] NEW step #6 created with same name "run-tests"
- [ ] Step #6 has added_by: "retry_of:4" metadata
- [ ] Step #6 is in_progress
- [ ] Queue shows complete history (7 items)

---

### TC-007: Complete workflow successfully

```bash
# Complete the retry - actually run tests
ruby -Ilib:test test/foo_bar_test.rb > test-output.txt 2>&1
cat test-output.txt > test-results.md
ace-coworker report test-results.md

# Final step
echo "Created FooBar gem with 3 passing tests" > final-report.md
ace-coworker report final-report.md

ace-coworker status
# All steps done, including the failed one in history
# #  STATUS  NAME
# 1  done    init-project
# 2  done    write-tests
# 3  done    implement-foobar
# 4  failed  run-tests        (2 tests failed) <- preserved!
# 5  done    fix-implementation
# 6  done    run-tests        (retry)
# 7  done    report-status
#
# Session completed!
```

**Assertions:**
- [ ] All 7 queue items have final status
- [ ] Step #4 still shows "failed" (history preserved)
- [ ] Step #6 shows "done" (retry succeeded)
- [ ] Session marked as completed
- [ ] Actual test execution passes (`ruby -Ilib:test test/foo_bar_test.rb`)

---

## Success Criteria

- [ ] Session created from YAML config with 5 steps
- [ ] Queue items have states: done, in_progress, in_queue, failed
- [ ] Steps actually execute (creates lib/foo_bar.rb, test files)
- [ ] `ruby -Ilib:test test/foo_bar_test.rb` passes after implementation
- [ ] Failed items preserved in queue (not overwritten)
- [ ] `add` command inserts new work (fix-implementation step)
- [ ] `retry` adds new step, preserves original failed
- [ ] `status` shows complete queue with full history
- [ ] Final queue shows 7 items including 1 failed (preserved history)

---

## What This Test Validates

1. **Real work** - Actually creates Ruby files, runs tests
2. **Queue persistence** - State survives between commands
3. **History preservation** - Failed step #4 visible alongside retry step #6
4. **Dynamic work** - Can add steps mid-workflow
5. **Verification integration** - `verifications:` field documented (execution in future task)
