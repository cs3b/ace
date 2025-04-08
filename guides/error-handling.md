## Error Handling Guidelines

### 1. Exception Hierarchy

```ruby
module RubyAIAgent
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

1. **Enable Debug Logging**:
```ruby
RubyAIAgent.configure do |config|
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