# Specialized Sub-Agents Architecture

## Intention

Create focused sub-agent executables in dev-tools that handle specific development tasks (test running, code analysis, formatting) with appropriate model tiers and reduced cognitive load on the main AI agent.

## Problem It Solves

**Current Issues:**
- Main AI agent handles too many distinct tasks
- No specialization for specific operations
- Inefficient use of expensive models for simple tasks
- Lack of parallel processing capabilities

**Impact:**
- Increased cognitive load on main agent
- Higher costs from using premium models for all tasks
- Sequential processing limits throughput
- Reduced accuracy from context overload

## Solution Direction

### 1. New Sub-Agent Executables

**Test Runner Agent (`dev-tools/exe/agent-test-runner`):**
```ruby
# Specialized for test execution and result parsing
module CodingAgentTools::CLI::Commands
  class AgentTestRunner < Dry::CLI::Command
    desc "Specialized agent for running and analyzing tests"
    
    option :framework, values: %w[rspec minitest pytest jest], default: "rspec"
    option :filter, desc: "Run only specific tests"
    option :format, values: %w[json summary detailed], default: "summary"
    option :fix, type: :boolean, desc: "Attempt to fix failing tests"
  end
end
```

**Code Analyzer Agent (`dev-tools/exe/agent-code-analyzer`):**
```ruby
# Specialized for code quality and architecture analysis
module CodingAgentTools::CLI::Commands
  class AgentCodeAnalyzer < Dry::CLI::Command
    desc "Specialized agent for code analysis"
    
    option :type, values: %w[quality security performance architecture]
    option :path, desc: "Path to analyze"
    option :depth, values: %w[shallow deep], default: "shallow"
    option :suggest_fixes, type: :boolean, default: true
  end
end
```

**Formatter Agent (`dev-tools/exe/agent-formatter`):**
```ruby
# Specialized for code formatting and style fixes
module CodingAgentTools::CLI::Commands
  class AgentFormatter < Dry::CLI::Command
    desc "Specialized agent for code formatting"
    
    option :standard, values: %w[rubocop standardrb prettier black]
    option :fix, type: :boolean, default: true
    option :verify_only, type: :boolean, default: false
  end
end
```

### 2. ATOM Architecture Components

**New Organisms:**
```ruby
# dev-tools/lib/coding_agent_tools/organisms/
test_runner_agent.rb      # Orchestrates test execution
code_analyzer_agent.rb     # Performs code analysis
formatter_agent.rb         # Handles formatting
agent_coordinator.rb       # Coordinates multiple agents
```

**New Molecules:**
```ruby
# dev-tools/lib/coding_agent_tools/molecules/
test_result_parser.rb      # Parse test outputs
code_metrics_calculator.rb # Calculate code metrics
format_rule_applier.rb     # Apply formatting rules
agent_communicator.rb      # Inter-agent communication
```

### 3. Agent Communication Protocol

```ruby
# dev-tools/lib/coding_agent_tools/models/agent_message.rb
class AgentMessage
  attr_accessor :from_agent, :to_agent, :task_type, :payload, :status
  
  def self.create_task(from:, to:, task:, data:)
    new(from_agent: from, to_agent: to, task_type: task, payload: data)
  end
end
```

### 4. Integration with Existing Tools

**Leverage existing infrastructure:**
- Use `llm-query` for LLM interactions
- Use `SystemCommandExecutor` for running tests
- Use existing `code-review` tools for analysis
- Integrate with `task-manager` for task tracking

### 5. Workflow Integration

**Update workflows to use sub-agents:**
```bash
# dev-handbook/workflow-instructions/fix-tests.wf.md

# Before: Main agent runs everything
Bash bin/test
Read test output
Fix failures

# After: Delegate to specialized agent
agent-test-runner --filter failing --fix
```

## Implementation Plan

### Phase 1: Test Runner Agent (Week 1)
1. Create `agent-test-runner` executable
2. Implement test execution organism
3. Add result parsing and formatting
4. Integrate with existing test frameworks

### Phase 2: Code Analyzer Agent (Week 1)
1. Create `agent-code-analyzer` executable
2. Implement analysis organisms
3. Add metrics calculation
4. Generate improvement suggestions

### Phase 3: Agent Coordination (Week 2)
1. Implement `AgentCoordinator` organism
2. Create communication protocol
3. Add parallel execution support
4. Build agent registry

## Expected Benefits

- **40% reduction** in main agent cognitive load
- **Parallel processing** of independent tasks
- **Specialized optimization** per task type
- **Better accuracy** through focused context

## Success Metrics

- Task completion time: 30% faster
- Error rates: 25% reduction
- Parallel execution: 3-5 concurrent agents
- Cost optimization: 35% reduction

## Dependencies

- Existing ATOM architecture
- `llm-query` infrastructure
- Test frameworks (RSpec, etc.)
- Code analysis tools

## Testing Strategy

**Unit Tests:**
- Test each agent independently
- Mock inter-agent communication
- Verify result formatting

**Integration Tests:**
- Test agent coordination
- Verify parallel execution
- Test error handling

**End-to-End Tests:**
- Complete workflow execution
- Performance benchmarks
- Cost analysis