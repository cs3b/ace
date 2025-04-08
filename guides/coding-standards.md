## Ruby SDK Development Standards

### 1. Module Organization

1. **Top Level Structure**:
   - Single top-level module for the SDK
   - Clear separation of concerns
   - Consistent file naming and organization

```ruby
# lib/ruby_ai_agent.rb
require_relative "ruby_ai_agent/version"
require_relative "ruby_ai_agent/errors"
require_relative "ruby_ai_agent/core"

module RubyAIAgent
  class Error < StandardError; end

  class << self
    # Configuration and setup methods
    def configure
      yield config if block_given?
    end

    def config
      @config ||= Configuration.new
    end
  end
end
```

2. **Component Organization**:
   - Group related functionality in submodules
   - Use consistent naming conventions
   - Separate concerns appropriately

```ruby
# lib/ruby_ai_agent/agents/base.rb
module RubyAIAgent
  module Agents
    class Base
      # Base agent implementation
    end
  end
end
```

### 2. Design Patterns

1. **Factory Pattern**:
   ```ruby
   module RubyAIAgent
     module Agents
       def self.create(type, options = {})
         case type
         when :chat
           ChatAgent.new(options)
         when :task
           TaskAgent.new(options)
         else
           raise ArgumentError, "Unknown agent type: #{type}"
         end
       end
     end
   end
   ```

2. **Registry Pattern**:
   ```ruby
   module RubyAIAgent
     class ToolRegistry
       def initialize
         @tools = {}
       end

       def register(tool)
         @tools[tool.name] = tool
       end

       def get(name)
         @tools[name] or raise ToolNotFoundError, "Tool '#{name}' not found"
       end
     end
   end
   ```

3. **Command Pattern**:
   ```ruby
   module RubyAIAgent
     module CLI
       class Command
         def self.run(args)
           new(args).execute
         end

         def execute
           raise NotImplementedError
         end
       end
     end
   end
   ```

### 3. Error Handling

1. **Error Hierarchy**:
   ```ruby
   module RubyAIAgent
     class Error < StandardError; end

     class ConfigurationError < Error; end
     class ToolError < Error; end
     class AgentError < Error; end

     class ToolNotFoundError < ToolError; end
   end
   ```

2. **Context Preservation**:
   ```ruby
   begin
     tool.execute(params)
   rescue ToolError => e
     raise AgentError.new("Failed to execute tool: #{e.message}", cause: e)
   end
   ```

### 4. Thread Safety

1. **Thread-Safe Resources**:
   ```ruby
   module RubyAIAgent
     class SharedResource
       def initialize
         @mutex = Mutex.new
         @data = {}
       end

       def update(key, value)
         @mutex.synchronize { @data[key] = value }
       end
     end
   end
   ```

2. **Test Mode**:
   ```ruby
   module RubyAIAgent
     def self.test_mode!
       @test_mode = true
     end

     def self.test_mode?
       @test_mode ||= false
     end
   end
   ```

### 5. Coding Style

1. **Ruby Conventions**:
   - Use 2 spaces for indentation
   - Use snake_case for methods and variables
   - Use CamelCase for classes and modules
   - Prefer explicit over implicit returns

2. **Documentation**:
   - Document all public APIs
   - Include usage examples
   - Note thread safety considerations
   - Explain error conditions

3. **Testing**:
   - Write tests first (TDD)
   - Test edge cases
   - Ensure thread safety
   - Mock external dependencies
