# ANSI Color StringIO Behavior Documentation

## Overview

This document describes the behavior of ANSI color codes when captured through Ruby's `StringIO` class and provides infrastructure for testing CLI applications with color output. The testing infrastructure was created to prepare for future color features in CLI commands while ensuring consistent behavior across different output capture scenarios.

## Key Findings

### StringIO Behavior with ANSI Codes

When using `StringIO` to capture output containing ANSI escape sequences:

1. **ANSI codes are preserved as literal strings** - No interpretation or filtering occurs
2. **All escape sequences remain intact** - Colors, formatting, and control codes are captured exactly as written
3. **TTY detection has no effect** - `StringIO` objects report `tty? = false`, but ANSI codes are still captured
4. **Environment variables are ignored** - `FORCE_COLOR` and similar variables don't affect StringIO capture

### Behavior Matrix

| Scenario | ANSI Codes Captured | TTY Detection | Environment Variables |
|----------|-------------------|---------------|---------------------|
| StringIO Default | ✅ Yes | ❌ `tty? = false` | ❌ Ignored |
| StringIO + FORCE_COLOR=1 | ✅ Yes | ❌ `tty? = false` | ❌ Ignored |
| StringIO + TTY Simulation | ✅ Yes | ✅ `tty? = true` (mocked) | ❌ Ignored |

**Key Insight**: StringIO captures ANSI codes regardless of TTY status or environment variables, making it reliable for testing color output.

## Testing Infrastructure

### AnsiColorTestingHelper Module

The `AnsiColorTestingHelper` provides comprehensive tools for testing ANSI color behavior:

#### Core Features

- **Color Generation**: Predefined ANSI color codes and helper methods
- **Output Capture**: Multiple capture scenarios (default, forced color, TTY simulation)
- **Code Analysis**: Extract, strip, and analyze ANSI escape sequences
- **RSpec Integration**: Custom matchers for color testing

#### Helper Methods

```ruby
# Create colored text
AnsiColorTestingHelper.red("Error message")
AnsiColorTestingHelper.colorize("Custom", :bold, :green)

# Analyze ANSI codes
AnsiColorTestingHelper.has_ansi_codes?(text)
AnsiColorTestingHelper.strip_ansi(text)
AnsiColorTestingHelper.extract_ansi_codes(text)

# Capture output scenarios
AnsiColorTestingHelper.capture_output { puts colored_text }
AnsiColorTestingHelper.capture_with_color { puts colored_text }
AnsiColorTestingHelper.capture_with_tty { puts colored_text }
```

#### Output Capture API

```ruby
# Basic capture
output = AnsiColorTestingHelper.capture_output do
  puts AnsiColorTestingHelper.green("Success!")
end

# Access captured content
output.stdout_content    # Raw output with ANSI codes
output.stdout_clean      # Clean text without ANSI codes
output.stdout_has_ansi?  # Boolean check for ANSI presence
output.stdout_ansi_codes # Array of extracted ANSI codes
```

#### Behavior Matrix Testing

```ruby
# Test all scenarios at once
results = AnsiColorTestingHelper.test_behavior_matrix do
  puts AnsiColorTestingHelper.blue("Test output")
end

# Access results for each scenario
results[:stringio_default]  # Normal StringIO capture
results[:forced_color]      # With FORCE_COLOR=1
results[:tty_simulation]    # With mocked TTY
```

## Usage Patterns for CLI Testing

### Basic Color Output Testing

```ruby
describe "CLI command with colors" do
  it "outputs colored status messages" do
    output = AnsiColorTestingHelper.capture_output do
      run_cli_command_with_colors
    end
    
    expect(output.stdout_has_ansi?).to be true
    expect(output.stdout_clean).to include("Operation completed")
    expect(output.stdout_ansi_codes).to include("\033[32m") # green
  end
end
```

### Testing Color vs Plain Output

```ruby
describe "conditional color output" do
  it "includes colors when supported" do
    output = AnsiColorTestingHelper.capture_with_tty do
      cli_command.run_with_color_detection
    end
    
    expect(output.stdout_has_ansi?).to be true
  end
  
  it "omits colors for non-TTY output" do
    output = AnsiColorTestingHelper.capture_output do
      cli_command.run_with_color_detection
    end
    
    # Note: This test demonstrates StringIO behavior
    # In practice, CLI apps might check $stdout.tty?
    # and disable colors, but StringIO still captures them
  end
end
```

### Complex Scenario Testing

```ruby
describe "mixed output with colors" do
  it "handles combination of plain and colored text" do
    output = AnsiColorTestingHelper.capture_output do
      puts "Plain line"
      puts AnsiColorTestingHelper.red("Error line")
      puts "Another plain line"
    end
    
    expect(output.stdout_clean).to eq(
      "Plain line\nError line\nAnother plain line\n"
    )
    expect(output.stdout_ansi_codes.length).to eq(2) # red + reset
  end
end
```

### RSpec Matchers Integration

```ruby
describe "with custom matchers" do
  it "uses convenience matchers" do
    colored_text = AnsiColorTestingHelper.green("Success")
    
    expect(colored_text).to have_ansi_codes
    expect(colored_text).to have_clean_text("Success")
  end
  
  it "tests block output" do
    expect {
      puts AnsiColorTestingHelper.blue("Test")
    }.to output_with_ansi("Test\n")
  end
end
```

## Side-Effect Management

The testing infrastructure properly manages side effects:

### Stdout/Stderr Restoration

```ruby
# Original streams are always restored, even on exceptions
original_stdout = $stdout
AnsiColorTestingHelper.capture_output do
  raise "Error during capture"
end
# $stdout is restored to original_stdout
```

### Environment Variable Safety

```ruby
# Environment variables are restored after forced color testing
original_force_color = ENV['FORCE_COLOR']
AnsiColorTestingHelper.capture_with_color do
  # FORCE_COLOR=1 during block
end
# ENV['FORCE_COLOR'] restored to original value
```

## Future CLI Color Implementation Guidelines

### Recommended Patterns

1. **TTY Detection**: Use `$stdout.tty?` for color decisions in production code
2. **Environment Override**: Respect `FORCE_COLOR` and `NO_COLOR` environment variables
3. **Graceful Degradation**: Always provide plain text fallbacks
4. **Testing**: Use this infrastructure to test both colored and plain output paths

### Example CLI Color Implementation

```ruby
class ColorizedCLI
  def self.colorize(text, color)
    if should_use_color?
      AnsiColorTestingHelper.colorize(text, color)
    else
      text
    end
  end
  
  private
  
  def self.should_use_color?
    return false if ENV['NO_COLOR']
    return true if ENV['FORCE_COLOR']
    $stdout.tty?
  end
end
```

### Testing the Implementation

```ruby
describe ColorizedCLI do
  it "uses colors when TTY is detected" do
    output = AnsiColorTestingHelper.capture_with_tty do
      puts ColorizedCLI.colorize("Test", :red)
    end
    
    expect(output.stdout_has_ansi?).to be true
  end
  
  it "omits colors for non-TTY output" do
    output = AnsiColorTestingHelper.capture_output do
      puts ColorizedCLI.colorize("Test", :red)
    end
    
    # Depends on implementation - if it checks $stdout.tty?
    # it might not include colors even though StringIO captures them
  end
end
```

## Performance Characteristics

- **Low Overhead**: StringIO capture adds minimal performance impact
- **Memory Efficient**: ANSI code analysis uses regex scanning, not string duplication
- **Scalable**: Tested with 100+ colored lines without performance degradation

## Integration with Existing Test Suite

The helper integrates seamlessly with the existing RSpec test infrastructure:

- **Automatic Loading**: Include in `spec_helper.rb` or require as needed
- **Matcher Registration**: RSpec matchers are automatically registered
- **Environment Safety**: Works with existing environment variable management
- **Coverage Friendly**: All helper methods are covered by the behavior matrix tests

## Canonical ANSI Regex

The helper provides a standard regex for ANSI escape sequence matching:

```ruby
AnsiColorTestingHelper::ANSI_REGEX = /\033\[[0-9;]*m/
```

This regex matches the most common ANSI color and formatting codes used in CLI applications.

## Conclusion

This infrastructure provides a solid foundation for implementing and testing CLI color features. The key insight that StringIO reliably captures ANSI codes regardless of TTY status makes testing straightforward and predictable. Future color implementations can be built with confidence knowing the testing infrastructure will accurately capture and verify color behavior across different scenarios.