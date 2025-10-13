# Context Loading Optimization Tool

## Intention

Create a new `context` executable in .ace/tools that combines file reading and command execution into a single, efficient operation, reducing token usage and improving workflow performance.

## Problem It Solves

**Current Issues:**
- AI agents make 4-5 separate tool calls to load context (multiple Read + Bash calls)
- Each file is read separately, increasing overhead and context switching
- Commands are executed separately from file reading
- No caching mechanism for frequently accessed context
- Expensive models read simple files that could be delegated to cheaper models

**Impact:**
- 75% more tool calls than necessary for context loading
- Increased token usage and costs
- Slower workflow execution
- Repeated reading of unchanged files

## Solution Direction

### 1. New Executable: `.ace/tools/exe/context`

Create a new tool following the ATOM architecture:

**Executable Structure:**
```ruby
# .ace/tools/exe/context
#!/usr/bin/env ruby
require_relative "../lib/coding_agent_tools"
CodingAgentTools::CLI.start(ARGV)
```

**CLI Command Class:**
```ruby
# .ace/tools/lib/coding_agent_tools/cli/context.rb
module CodingAgentTools::CLI::Commands
  class Context < Dry::CLI::Command
    desc "Load files and execute commands in a single operation"
    
    option :files, desc: "Comma-separated file paths"
    option :cmds, desc: "Comma-separated commands to execute"
    option :format, values: %w[text json yaml], default: "text"
    option :cache, type: :boolean, default: false
    option :model, desc: "LLM model for file reading (cheap model)"
    option :max_size, type: :integer, default: 15000
  end
end
```

### 2. ATOM Components

**New Atoms:**
- `context_cache_key_generator.rb` - Generate cache keys for context
- `file_batch_reader.rb` - Read multiple files efficiently

**New Molecules:**
- `context_aggregator.rb` - Combine files and command outputs
- `cheap_model_delegator.rb` - Delegate file reading to cheaper models
- `context_cache_manager.rb` - Cache context with TTL

**New Organism:**
- `context_loader.rb` - Orchestrate the entire context loading process

### 3. Integration with Existing Infrastructure

**Leverage Existing Components:**
- Use `llm-query` infrastructure for cheap model delegation
- Use existing `CacheManager` molecule for caching
- Use `SystemCommandExecutor` atom for command execution
- Use `FileIOHandler` molecule for file operations

**Workflow Integration:**
Update `.ace/handbook/workflow-instructions/load-project-context.wf.md`:
```bash
# Before: Multiple tool calls
Read docs/what-do-we-build.md
Read docs/architecture.md
Read docs/blueprint.md
Bash task-manager next

# After: Single tool call
context --files docs/what-do-we-build.md,docs/architecture.md,docs/blueprint.md --cmds "task-manager next"
```

## Implementation Plan

### Phase 1: Basic Implementation (Day 1)
1. Create `.ace/tools/exe/context` executable
2. Implement CLI command class with basic options
3. Create `ContextLoader` organism
4. Add file reading and command execution

### Phase 2: Optimization (Day 2)
1. Add caching with `ContextCacheManager` molecule
2. Implement cheap model delegation via `llm-query`
3. Add truncation strategies for large outputs

### Phase 3: Integration (Day 3)
1. Update workflow instructions to use new tool
2. Add comprehensive tests in `spec/`
3. Document in `docs/tools.md`

## Expected Benefits

- **75% reduction** in tool calls for context loading
- **60-80% cost reduction** when using cheap models for file reading
- **90% cache hit rate** for unchanged files
- **Immediate adoption** - works with all existing workflows

## Success Metrics

- Tool call count: 4-5 calls → 1 call
- Token usage: Reduce by 60-80% for context operations
- Performance: < 200ms for cached context
- Adoption: Used in 100% of context-loading workflows

## Dependencies

- Existing `llm-query` infrastructure
- Existing ATOM architecture components
- Ruby >= 3.2
- dry-cli framework

## Testing Strategy

**Unit Tests (RSpec):**
- Test each ATOM component independently
- Mock LLM interactions with VCR

**Integration Tests (Aruba):**
- Test CLI interface
- Test caching behavior
- Test model delegation

## Documentation Updates

- Add to `docs/tools.md` with usage examples
- Update workflow instructions
- Create ADR for context optimization decision