# Documentation Standards

## Goal
This guide defines the standards and best practices for documenting code and project artifacts within this toolkit, ensuring clarity, maintainability, and effective knowledge sharing for both human developers and AI agents.

# Documentation Standards

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
   # AI Ruby Agent SDK

   Build AI agents that interact with LLMs and system tools.

   ## Quick Start
   ```ruby
   agent = Aira.create(:assistant)
   result = agent.execute(prompt: "Browse website")
   ```

   ## Installation
   ```bash
   gem install aidarb
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
   ### 3. Documenting for AI Collaboration

   Clear documentation is crucial for effective AI collaboration.

   - **Structured Project Docs:** Maintain core documents like `docs-project/what-do-we-build.md`, `docs-project/architecture.md`, and `docs-project/blueprint.md`. Keep them up-to-date as they provide essential high-level context for the AI.
   - **Task Definitions:** Use the structured `.md` format for tasks (see `guides/project-management.md`) with clear descriptions, implementation notes, and acceptance criteria.
   - **ADRs:** Document significant architectural decisions in `docs-dev/decisions/` to provide rationale and context for the AI.
   - **Workflow Instructions:** Write clear, specific workflow instructions (`workflow-instructions/*.md`) outlining processes for the AI to follow for common tasks. Follow guidelines similar to writing good code: focused, clear inputs/outputs, examples. (See Task 04 for creating a dedicated guide on this).
   - **Code Comments:** Use comments to explain the "why" behind complex logic, not just the "what". This helps the AI understand intent.
   - **Cross-Referencing:** Link related documents (guides, tasks, ADRs, code files) to create a connected knowledge base that the AI can potentially navigate or be guided through. For example, a task file might link to a relevant ADR or guide section.
   ```
   ## Related Documentation
   - [Coding Standards](coding-standards.md)
   - [Project Management Guide](project-management.md) (Task format, ADRs)
   - [ADR Template](prepare-release/v.x.x.x/decisions/_template.md)
   - [Writing Guides Guide](writing-guides-guide.md)
