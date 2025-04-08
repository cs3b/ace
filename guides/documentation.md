## Documentation Guidelines

### 1. Code Documentation

1. **YARD Documentation**:
   ```ruby
   # The main Agent class that executes AI tasks with given tools
   #
   # @example Basic usage
   #   agent = Agent.new("assistant")
   #   result = agent.execute(prompt: "Summarize text", tools: [:browser])
   #
   # @example With error handling
   #   begin
   #     agent.execute(prompt: "Process file", tools: [:file_reader])
   #   rescue ConfigError => e
   #     logger.error("Configuration error: #{e.message}")
   #   end
   class Agent
     # Executes an AI agent task with given tools
     #
     # @param task [Hash] The task configuration
     # @option task [String] :prompt The task prompt
     # @option task [Array<Symbol>] :tools Available tools
     # @return [Result] Task execution result
     # @raise [ConfigError] If configuration is invalid
     # @raise [ToolError] If a tool fails during execution
     # @note This method is thread-safe
     def execute(task)
       # Implementation
     end
   end
   ```

2. **Class and Module Documentation**:
   ```ruby
   # Manages the registration and lookup of agent tools
   #
   # @example Registering a custom tool
   #   registry = ToolRegistry.new
   #   registry.register(:browser, BrowserTool.new)
   #
   # @thread-safety This class is thread-safe
   class ToolRegistry
     # @return [Hash<Symbol, Tool>] The registered tools
     attr_reader :tools

     # @private
     def initialize
       @tools = {}
       @mutex = Mutex.new
     end
   end
   ```

3. **Performance Documentation**:
   ```ruby
   # Processes files in parallel with controlled concurrency
   #
   # @complexity O(n) where n is the number of files
   # @performance Processes up to 10 files concurrently
   # @memory Uses ~10MB per file being processed
   def process_files(files)
     # Implementation
   end
   ```

### 2. Project Documentation

1. **README.md Structure**:
   ```markdown
   # Ruby AI Agent SDK
   
   Build AI agents that interact with LLMs and system tools.
   
   ## Quick Start
   ```ruby
   agent = RubyAIAgent.create(:assistant)
   result = agent.execute(prompt: "Browse website")
   ```
   
   ## Installation
   ```bash
   gem install ruby_ai_agent
   ```
   
   ## Documentation
   - [API Reference](docs/api.md)
   - [Tutorials](docs/tutorials/)
   - [Examples](examples/)
   ```

2. **Architecture Documentation**:
   ```markdown
   # Architecture Overview
   
   ## Components
   - Agent: Core execution engine
   - Tools: System capabilities
   - Registry: Tool management
   
   ## Data Flow
   1. Agent receives task
   2. Tools are loaded
   3. LLM processes task
   4. Results returned
   
   ## Extension Points
   - Custom tools
   - Prompt templates
   - Result processors
   ```

3. **Tutorial Structure**:
   ```markdown
   # Building Your First Agent
   
   1. Create agent
   2. Configure tools
   3. Execute tasks
   4. Handle results
   
   ## Example Implementation
   ```ruby
   # Complete working example
   ```
   
   ## Common Patterns
   - Error handling
   - Tool composition
   - State management
   ```