# Error Handling Guidelines

## Goal
This guide outlines best practices and standard patterns for handling errors consistently and effectively throughout the project, ensuring robustness, debuggability, and a good user experience.

# Error Handling Guidelines

### 1. Exception Hierarchy

```ruby
module Aira
  # Base error class for all SDK errors
  class Error < StandardError; end

  # Configuration related errors
  class ConfigurationError < Error; end

  # Agent execution errors
  class AgentError < Error
    attr_reader :context
    def initialize(msg, context: {})
      @context = context
      super(msg)
    end
  end

  # Tool-specific errors
  class ToolError < Error; end

  # LLM-related errors
  class LLMError < Error
    attr_reader :request_id
    def initialize(msg, request_id: nil)
      @request_id = request_id
      super(msg)
    end
  end
end
```

### 2. Best Practices

1. **Rich Context**:
```ruby
begin
  agent.execute(task)
rescue AgentError => e
  logger.error("Agent execution failed",
    error: e.message,
    context: e.context,
    backtrace: e.backtrace.first(5)
  )
end
```

2. **Recovery Strategies**:
```ruby
def execute_with_retry
  retries = 0
  begin
    agent.execute(task)
  rescue LLMError => e
    if retries < 3
      retries += 1
      sleep(2 ** retries) # Exponential backoff
      retry
    end
    raise
  end
end
```

3. **Clean Resource Management**:
```ruby
def with_resources
  acquire_resources
  yield
ensure
  release_resources
end
```

### 3. Debugging Guide
### 4. Advanced Error Handling Patterns

Consider these patterns for more robust applications:

- **Structured Error Objects:** Define custom error classes that include relevant context (e.g., status codes, internal error codes, request IDs). This helps in programmatic error handling and monitoring.
  ```ruby
  # Example
  class ApiError < StandardError
    attr_reader :status_code, :error_code, :details
    def initialize(message, status_code: 500, error_code: 'UNKNOWN', details: {})
      super(message)
      @status_code = status_code
      @error_code = error_code
      @details = details
    end
  end
  # Raise specific errors:
  # raise ApiError.new("User not found", status_code: 404, error_code: 'USER_NOT_FOUND', details: { user_id: id })
  ```
- **Error Categorization:** Distinguish between:
    - **Operational Errors:** Expected issues (e.g., invalid input, resource not found) that can often be handled gracefully.
    - **Programming Errors:** Bugs in the code that need fixing (e.g., type errors, null references).
    - **System Errors:** External issues (e.g., database unavailable, network failure).
- **Recovery Strategies:** Implement strategies for transient failures:
    - **Retry with Backoff:** Automatically retry failed operations (especially network requests) with increasing delays.
    - **Circuit Breaker:** Prevent repeated calls to a failing service by temporarily blocking requests after a certain number of failures.
    - **Fallbacks:** Provide a degraded but functional experience if a primary operation fails (e.g., return cached data if a live fetch fails).
- **Contextual Logging:** Ensure logs capture sufficient context (user ID, request ID, operation parameters) to diagnose errors effectively, while avoiding sensitive data.

1. **Enable Debug Logging**:
```ruby
Aira.configure do |config|
  config.log_level = :debug
  config.log_formatter = proc do |severity, time, progname, msg|
    "[#{time}] #{severity}: #{msg}\n"
  end
end
```

2. **Inspect State**:
```ruby
agent.debug_info # Returns internal state
agent.execution_trace # Returns execution history
```

3. **Common Issues**:
- LLM timeouts: Check network and retry settings
- Memory issues: Review resource cleanup
- Thread deadlocks: Check lock ordering

## Related Documentation
- [Coding Standards](docs-dev/guides/coding-standards.md)
- [Quality Assurance](docs-dev/guides/quality-assurance.md) (Logging, Monitoring)
- [Writing Guides Guide](docs-dev/guides/writing-guides-guide.md)
