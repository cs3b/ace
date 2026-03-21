---
doc-type: guide
title: Testable Code Patterns
purpose: Testable code design
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Testable Code Patterns

## Avoiding Exit Calls in Testable Code

Commands that call `exit` will terminate the entire test process, preventing test completion and reporting. This manifests as:
- Test runner stops mid-execution
- No test summary is printed
- `ace-test` reports "0 tests, 0 assertions"
- Rake test fails with "Command failed with status (1)"

### Pattern: Return Status Codes in Commands

Commands should return status codes (0 for success, 1 for failure) and let the CLI entry point handle exit:

```ruby
# BAD - Terminates test process
class MyCommand
  def execute(args)
    if args.include?("--help")
      show_help
      exit 0  # Kills tests!
    end

    do_work
  rescue => e
    puts "Error: #{e.message}"
    exit 1  # Kills tests!
  end
end

# GOOD - Returns status codes
class MyCommand
  def execute(args)
    if args.include?("--help")
      show_help
      return 0
    end

    do_work
    0
  rescue => e
    puts "Error: #{e.message}"
    1
  end
end
```

### Pattern: Raise Exceptions in Organisms

Organisms (business logic) should raise exceptions instead of calling exit:

```ruby
# BAD - Terminates test process
class IdeaWriter
  def write(content, options)
    if content.nil? || content.strip.empty?
      puts "Error: No content provided"
      exit 1  # Kills tests!
    end
    # ...
  end
end

# GOOD - Raises exceptions
class IdeaWriter
  class IdeaWriterError < StandardError; end

  def write(content, options)
    if content.nil? || content.strip.empty?
      raise IdeaWriterError, "No content provided"
    end
    # ...
  end
end
```

### CLI Entry Point Pattern

The CLI entry point (exe/ace-*) should handle status codes and exit only at the top level:

```ruby
#!/usr/bin/env ruby
# exe/ace-taskflow

require_relative "../lib/ace/taskflow"

# CLI.start returns status code
exit_code = Ace::Taskflow::CLI.start(ARGV)
exit(exit_code || 0)
```

```ruby
# lib/ace/taskflow/cli.rb
class CLI
  def self.start(args)
    case args.shift
    when "retro"
      require_relative "commands/retro_command"
      Commands::RetroCommand.new.execute(args)  # Returns status code
    when "--help"
      show_help
      0  # Return status code
    else
      puts "Unknown command"
      1  # Return status code
    end
  end
end
```

### Testing Commands with Status Codes

Test commands by asserting on their return values:

```ruby
def test_help_returns_success
  output = capture_io do
    exit_code = @command.execute(["--help"])
    assert_equal 0, exit_code
  end

  assert_match(/Usage:/, output)
end

def test_error_returns_failure
  output = capture_io do
    exit_code = @command.execute(["invalid"])
    assert_equal 1, exit_code
  end

  assert_match(/Error:/, output)
end
```

### Testing Organisms with Exceptions

Test organisms by asserting on raised exceptions:

```ruby
def test_raises_error_on_invalid_input
  error = assert_raises(Ace::Taskflow::Organisms::IdeaWriterError) do
    @writer.write("")
  end

  assert_match(/No content provided/, error.message)
end
```

### Migration Strategy

When refactoring commands with exit calls:

1. **Identify exit calls**: `grep -r "exit [01]" lib/`
2. **Refactor commands**: Replace `exit N` with `return N`
3. **Refactor organisms**: Replace `exit N` with `raise CustomError`
4. **Update CLI**: Return status codes, exit only at entry point
5. **Update tests**: Assert on return values instead of SystemExit
6. **Verify**: Run full test suite to ensure completion

### Benefits

1. **Test Completion**: Tests run to completion and report properly
2. **Better Debugging**: Exceptions provide stack traces
3. **Composability**: Commands can be called from other commands
4. **Isolation**: Test failures don't affect other tests

## Designing for Testability

### Explicit Dependencies

Pass dependencies (services, configurations, clients) into functions or classes rather than relying on global state or singletons. This makes mocking easier for unit tests.

```ruby
# BAD - Hard to test, relies on global
class UserService
  def create_user(params)
    Database.connection.insert(:users, params)
    EmailService.instance.send_welcome(params[:email])
  end
end

# GOOD - Dependencies are injectable
class UserService
  def initialize(database:, email_service:)
    @database = database
    @email_service = email_service
  end

  def create_user(params)
    @database.insert(:users, params)
    @email_service.send_welcome(params[:email])
  end
end
```

### Pure Functions

Prefer functions that always return the same output for the same input and have no side effects. These are the easiest to test.

```ruby
# PURE - Easy to test, deterministic
def calculate_discount(price, percentage)
  price * (percentage / 100.0)
end

# IMPURE - Hard to test, depends on external state
def calculate_discount(product_id)
  product = Product.find(product_id)
  today_rate = DiscountService.current_rate
  product.price * today_rate
end
```

### Separate Logic from I/O

Isolate core business logic from operations that interact with external systems (files, network, databases). Test the logic separately from the I/O.

```ruby
# MIXED - Hard to test
class ReportGenerator
  def generate
    data = File.read("input.csv")
    results = CSV.parse(data).map { |row| transform(row) }
    File.write("output.json", results.to_json)
  end
end

# SEPARATED - Logic is testable independently
class ReportGenerator
  def generate(input_data)
    CSV.parse(input_data).map { |row| transform(row) }
  end
end

# I/O handled separately
class ReportService
  def run(input_path, output_path)
    data = File.read(input_path)
    results = ReportGenerator.new.generate(data)
    File.write(output_path, results.to_json)
  end
end
```

### Clear Interfaces

Define clear, well-documented public interfaces for modules and classes. This clarifies boundaries for testing and for AI interaction.

```ruby
# Clear interface with documented contract
class PaymentProcessor
  # @param amount [Decimal] Amount to charge
  # @param card_token [String] Payment card token
  # @return [PaymentResult] Result with success/failure status
  def charge(amount, card_token)
    # ...
  end
end
```

### Stateless Components

Where possible, favor stateless components or functions, as state management adds complexity to testing.

```ruby
# STATEFUL - Harder to test, order matters
class Counter
  def initialize
    @count = 0
  end

  def increment
    @count += 1
  end

  def current
    @count
  end
end

# STATELESS - Easy to test, no hidden state
def increment(count)
  count + 1
end
```

## Summary

### Core Principles
- Extract external dependencies to protected methods
- Use method stubbing instead of subprocess isolation
- Profile tests regularly with `ace-test --profile 10`
- Only use subprocesses when true process isolation is required

### Testability Patterns
- **Never call exit in commands or organisms** - return status codes and raise exceptions
- **Handle exit only at the CLI entry point** (exe/ace-*)
- **Return status codes from commands**, let CLI handle exit
- **Inject dependencies** instead of using globals
- **Separate logic from I/O** for easier testing

## Related Guides

- [Testing Philosophy](guide://testing-philosophy) - Why testability matters
- [Mocking Patterns](guide://mocking-patterns) - How to stub dependencies
- [Test Performance](guide://test-performance) - Fast test execution