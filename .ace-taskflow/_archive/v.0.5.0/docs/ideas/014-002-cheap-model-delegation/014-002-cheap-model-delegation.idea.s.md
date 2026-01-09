# Cheap Model Delegation for Context Operations

## Intention

Enhance existing `llm-query` and new `context` tools to automatically delegate simple operations (file reading, concatenation, summarization) to cheaper LLM models, reducing costs by 60-80%.

## Problem It Solves

**Current Issues:**
- Premium models (Claude Sonnet, GPT-4) read simple files that don't require intelligence
- No automatic model selection based on task complexity
- Manual model specification for every operation
- High costs for routine context loading

**Impact:**
- Unnecessary costs for simple operations
- Token waste on premium models
- No intelligent routing based on task type

## Solution Direction

### 1. Enhance Existing `llm-query` Tool

**Add Model Routing Logic:**
```ruby
# .ace/tools/lib/coding_agent_tools/molecules/model_router.rb
module CodingAgentTools::Molecules
  class ModelRouter
    TASK_MODELS = {
      file_reading: "google:gemini-2.5-flash-lite",
      summarization: "anthropic:claude-3-haiku",
      code_analysis: "anthropic:claude-3-5-sonnet",
      complex_reasoning: "openai:gpt-4o"
    }
    
    def select_model(task_type, override: nil)
      override || TASK_MODELS[task_type] || default_model
    end
  end
end
```

### 2. Update Context Tool Integration

**Automatic Model Selection:**
```ruby
# .ace/tools/lib/coding_agent_tools/organisms/context_loader.rb
def load_files(paths, use_llm: true)
  if use_llm && simple_text_files?(paths)
    model = model_router.select_model(:file_reading)
    delegate_to_llm(paths, model)
  else
    read_directly(paths)
  end
end
```

### 3. Workflow Instruction Updates

**Update `load-project-context.wf.md`:**
```bash
# Automatically uses cheap model for file reading
context --files docs/*.md --cmds "task-manager next" --auto-model

# Or explicit cheap model
context --files docs/*.md --model gflash
```

### 4. Model Aliases Configuration

**Extend existing aliases:**
```ruby
# .ace/tools/lib/coding_agent_tools/constants/model_aliases.rb
CHEAP_MODELS = {
  "gflash" => "google:gemini-2.5-flash-lite",
  "haiku" => "anthropic:claude-3-haiku",
  "gpt3" => "openai:gpt-3.5-turbo"
}

TASK_APPROPRIATE_MODELS = {
  reading: CHEAP_MODELS,
  analysis: PREMIUM_MODELS,
  generation: PREMIUM_MODELS
}
```

## Implementation Plan

### Phase 1: Model Router (2 hours)
1. Create `ModelRouter` molecule
2. Define task-to-model mappings
3. Add cost tracking per model

### Phase 2: Integration (2 hours)
1. Update `llm-query` to use router
2. Integrate with `context` tool
3. Add `--auto-model` flag

### Phase 3: Monitoring (2 hours)
1. Track model usage statistics
2. Add cost reporting
3. Create usage dashboard

## Expected Benefits

- **60-80% cost reduction** for context operations
- **Automatic optimization** without user intervention
- **Maintains quality** for complex tasks
- **Transparent routing** with override options

## Success Metrics

- Cost per context load: $0.10 → $0.02
- Model selection accuracy: > 95%
- User satisfaction: No quality degradation
- Adoption rate: 80% of workflows use auto-model

## Dependencies

- Existing `llm-query` tool
- Multiple LLM provider integrations
- Cost tracking infrastructure

## Testing Strategy

- Unit tests for `ModelRouter`
- Integration tests with different task types
- Cost comparison benchmarks
- Quality validation tests