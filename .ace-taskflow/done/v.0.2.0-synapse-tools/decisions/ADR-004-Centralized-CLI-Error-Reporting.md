# ADR-004: Centralized CLI Error Reporting Strategy

## Status

Accepted
Date: 2025-06-08

## Context

Command-Line Interface (CLI) executables often produce various error messages, ranging from user input validation failures to unexpected system errors. Without a unified approach, each executable might handle and display errors differently, leading to an inconsistent and confusing user experience. Furthermore, debugging CLI applications becomes challenging if error output is not standardized or if critical debug information is not readily available when needed. There was a clear need to centralize error handling to ensure consistency, improve user guidance, and provide robust debugging capabilities via a debug flag.

## Decision

We decided to implement a `ErrorReporter` module or class responsible for centralizing CLI error reporting. This module will provide a consistent interface for handling exceptions and displaying error messages to the user.

Key aspects of this decision include:
- A dedicated `ErrorReporter` module/class to encapsulate error formatting and output logic.
- Support for a debug flag (e.g., `--debug` or `DEBUG=true` environment variable) that, when enabled, provides more verbose error information, such as backtraces, for diagnostic purposes.
- Standardized error message formats for different types of errors (e.g., validation errors, configuration errors, internal errors).
- Integration into CLI executables to ensure all errors are routed through this central mechanism.

```ruby
# Example (conceptual) ErrorReporter module
module MyProject
  module CLI
    module ErrorReporter
      DEBUG_MODE = ENV['DEBUG'] == 'true' || ARGV.include?('--debug')

      def self.report(exception, message: nil, exit_code: 1)
        STDERR.puts "Error: #{message || exception.message}"
        if DEBUG_MODE
          STDERR.puts "Type: #{exception.class}"
          STDERR.puts "Backtrace:\n\t#{exception.backtrace.join("\n\t")}" if exception.backtrace
        end
        exit(exit_code) unless exception.is_a?(SystemExit) # Prevent SystemExit from being wrapped
      end

      # Example usage within a CLI executable
      # begin
      #   # CLI logic here
      # rescue StandardError => e
      #   ErrorReporter.report(e, message: "An unexpected error occurred.")
      # end
    end
  end
end
```

## Consequences

### Positive

- **Consistent User Experience**: All CLI executables will present error messages in a predictable and uniform way, reducing user confusion.
- **Simplified Error Handling**: Developers can use a single, well-defined mechanism to handle and report errors across the entire suite of CLI tools, reducing boilerplate and potential for inconsistencies.
- **Enhanced Debugging**: The debug flag provides immediate access to detailed error information (like backtraces) directly in the terminal, significantly aiding in troubleshooting.
- **Improved Maintainability**: Changes to error reporting logic (e.g., message formatting, logging integration) can be made in one central place, affecting all executables.
- **Clear Separation of Concerns**: Isolates error reporting logic from core application logic.

### Negative

- **Initial Setup Overhead**: Requires implementing and integrating the `ErrorReporter` module into all relevant CLI executables.
- **Potential for Over-reporting**: Without careful design, the debug mode might produce excessively verbose output that is difficult to parse.
- **Dependency**: Introduces a new internal dependency (the `ErrorReporter` module) that all CLI tools must adhere to.

### Neutral

- **Explicit Debug Flag**: Relies on users or developers to explicitly enable debug mode, which is standard practice for verbose output.

## Alternatives Considered

### Individual Executable Error Handling

- **Why rejected**: Leads to inconsistent error messages, duplicated code, and makes it difficult to apply global changes to error reporting. Debugging would be fragmented and manual.
- **Trade-offs**: Simpler for a single, very small executable, but becomes unmanageable and error-prone as the number of executables or complexity grows.

### Using a Generic Logging Library

- **Why rejected**: While logging libraries can capture errors, they typically don't provide the structured, user-friendly CLI output format desired, nor do they inherently handle the debug flag for interactive CLI use as directly as a dedicated error reporter.
- **Trade-offs**: Good for backend logging, but less tailored for immediate, actionable CLI user feedback and interactive debugging. Would still require custom formatting logic.

### Raising and Rescuing `SystemExit` for all errors

- **Why rejected**: While `SystemExit` is good for controlling application exit, using it for all error types can obscure the original exception context and make it harder to differentiate between different error conditions programmatically. It's typically used for intentional exits.
- **Trade-offs**: Very simple way to terminate execution but loses valuable error metadata and can be misleading about the true nature of the error.

## Related Decisions

- Observability strategy (ADR-003) for broader system events and metrics.
- CLI argument parsing strategy, as it relates to the `--debug` flag.

## References

- Ruby's `StandardError` and `SystemExit` classes
- Command-line interface design best practices