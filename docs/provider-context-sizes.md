# LLM Provider Context Size Research

## Overview

This document researches the availability and methods for obtaining context size information from different LLM providers to enhance the `LlmModelInfo` model and llm-models command functionality.

## Provider Analysis

### Google Gemini
- **API Support**: Yes, via `inputTokenLimit` field in model info
- **Current Implementation**: Available in existing GoogleClient.list_models
- **Context Size Field**: `inputTokenLimit` and `outputTokenLimit`
- **Example Values**: 
  - Gemini 1.5 Pro: 2,097,152 tokens
  - Gemini 1.5 Flash: 1,048,576 tokens
- **Implementation**: Enhance model mapping to include context size

### OpenAI
- **API Support**: Limited (not in list models endpoint)
- **Context Size Source**: Hardcoded mapping based on model names
- **Known Context Sizes**:
  - GPT-4: 8,192 tokens
  - GPT-4-32k: 32,768 tokens
  - GPT-4 Turbo: 128,000 tokens
  - GPT-4o: 128,000 tokens
  - GPT-3.5 Turbo: 16,385 tokens
- **Implementation**: Static mapping in client

### Anthropic Claude
- **API Support**: No direct API field
- **Context Size Source**: Hardcoded mapping based on model names
- **Known Context Sizes**:
  - Claude 3.5 Sonnet: 200,000 tokens
  - Claude 3 Opus: 200,000 tokens
  - Claude 3 Sonnet: 200,000 tokens
  - Claude 3 Haiku: 200,000 tokens
- **Implementation**: Static mapping in client

### LM Studio (Local Models)
- **API Support**: No standard context size field
- **Context Size Source**: Model-dependent, not consistently available
- **Challenges**: Local models vary widely in context window
- **Implementation**: Return null/unknown for context size

### Mistral AI
- **API Support**: Limited in public API
- **Context Size Source**: Hardcoded mapping based on model names
- **Known Context Sizes**:
  - Mistral Large: 32,768 tokens
  - Mistral Medium: 32,768 tokens
  - Mistral Small: 32,768 tokens
  - Mistral 8x7B: 32,768 tokens
- **Implementation**: Static mapping in client

### Together AI
- **API Support**: Sometimes available in model metadata
- **Context Size Source**: Hybrid approach (API + fallback mapping)
- **Implementation**: Check API response, fall back to model name mapping

## Implementation Strategy

### Model Enhancement
```ruby
# Enhanced LlmModelInfo structure
class LlmModelInfo
  attr_reader :id, :name, :description, :default, :context_size, :max_output_tokens

  def initialize(id:, name:, description:, default: false, context_size: nil, max_output_tokens: nil)
    @id = id
    @name = name
    @description = description
    @default = default
    @context_size = context_size
    @max_output_tokens = max_output_tokens
  end
end
```

### Context Size Resolution Strategy
1. **API First**: Try to get context size from API response
2. **Static Mapping**: Fall back to hardcoded mappings
3. **Null Handling**: Gracefully handle unknown context sizes
4. **Cache Integration**: Include context size in cached model data

### Display Strategy
- Show context size in human-readable format (e.g., "128K tokens", "200K tokens")
- Handle null/unknown context sizes gracefully
- Include context size in JSON output
- Sort models by context size when requested

## Data Sources

### Hardcoded Mappings
Create configuration files with known context sizes:
```yaml
# config/model_context_sizes.yml
openai:
  "gpt-4": 8192
  "gpt-4-32k": 32768
  "gpt-4-turbo": 128000
  "gpt-4o": 128000
  "gpt-3.5-turbo": 16385

anthropic:
  "claude-3-5-sonnet": 200000
  "claude-3-opus": 200000
  "claude-3-sonnet": 200000
  "claude-3-haiku": 200000

mistral:
  "mistral-large": 32768
  "mistral-medium": 32768
  "mistral-small": 32768
```

### Dynamic Resolution
- Google: Extract from API response
- Others: Use static mappings with version detection
- Unknown models: Return nil for context size

## Testing Considerations

### Unit Tests
- Test context size extraction from API responses
- Test static mapping fallbacks
- Test graceful handling of unknown models
- Test display formatting of context sizes

### Integration Tests
- Test context size caching and retrieval
- Test JSON output includes context size
- Test text output displays context size appropriately
- Test filtering and sorting by context size

## Future Enhancements

### Dynamic Updates
- Periodic updates to static mappings
- Community-driven context size database
- Automated detection from model documentation

### Enhanced Features
- Context size-based model recommendations
- Token counting and model selection helpers
- Cost estimation based on context usage