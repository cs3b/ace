# Provider Usage Analysis for MetadataNormalizer Extension

## API Response Format Analysis

Based on actual API response recordings from VCR cassettes, here are the usage metadata patterns for all 6 supported providers:

### 1. Google (Gemini)

**Response Structure:**
```json
{
  "candidates": [...],
  "usageMetadata": {
    "promptTokenCount": 2,
    "candidatesTokenCount": 10,
    "totalTokenCount": 12,
    "promptTokensDetails": [...],
    "candidatesTokensDetails": [...]
  }
}
```

**Key Fields:**
- `usageMetadata.promptTokenCount` → input_tokens
- `usageMetadata.candidatesTokenCount` → output_tokens  
- `usageMetadata.totalTokenCount` → total_tokens (redundant, calculated)

### 2. Anthropic (Claude)

**Response Structure:**
```json
{
  "id": "test-id",
  "content": [...],
  "stop_reason": "end_turn",
  "usage": {
    "input_tokens": 9,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 0,
    "output_tokens": 11,
    "service_tier": "standard"
  }
}
```

**Key Fields:**
- `usage.input_tokens` → input_tokens
- `usage.output_tokens` → output_tokens
- Total calculated from input + output

### 3. OpenAI (GPT)

**Response Structure:**
```json
{
  "choices": [...],
  "usage": {
    "prompt_tokens": 9,
    "completion_tokens": 9,
    "total_tokens": 18,
    "prompt_tokens_details": {...},
    "completion_tokens_details": {...}
  }
}
```

**Key Fields:**
- `usage.prompt_tokens` → input_tokens
- `usage.completion_tokens` → output_tokens
- `usage.total_tokens` → total_tokens (provided)

### 4. Mistral AI

**Response Structure:**
```json
{
  "choices": [...],
  "usage": {
    "prompt_tokens": 5,
    "total_tokens": 15,
    "completion_tokens": 10
  }
}
```

**Key Fields:**
- `usage.prompt_tokens` → input_tokens
- `usage.completion_tokens` → output_tokens
- `usage.total_tokens` → total_tokens (provided)

### 5. Together AI

**Response Structure:**
```json
{
  "choices": [...],
  "usage": {
    "prompt_tokens": 7,
    "completion_tokens": 10,
    "total_tokens": 17,
    "cached_tokens": 0
  }
}
```

**Key Fields:**
- `usage.prompt_tokens` → input_tokens
- `usage.completion_tokens` → output_tokens  
- `usage.total_tokens` → total_tokens (provided)
- `usage.cached_tokens` → additional metadata

### 6. LM Studio (Local)

**Response Structure:**
```json
{
  "choices": [...],
  "usage": {
    "prompt_tokens": 1227,
    "completion_tokens": 9,
    "total_tokens": 1236
  }
}
```

**Key Fields:**
- `usage.prompt_tokens` → input_tokens
- `usage.completion_tokens` → output_tokens
- `usage.total_tokens` → total_tokens (provided)

## Unified Usage Metadata Structure

Based on the analysis, here's the proposed consistent structure:

```ruby
{
  # Token counts
  input_tokens: Integer,
  output_tokens: Integer,
  total_tokens: Integer,
  
  # Timing
  took: Float, # execution time in seconds
  
  # Provider information
  provider: String,
  model: String,
  timestamp: String, # ISO 8601 UTC
  
  # Completion status
  finish_reason: String, # normalized
  
  # Provider-specific additional data (optional)
  provider_specific: Hash,
  
  # Google-specific (when applicable)
  safety_ratings: Array,
  
  # Cache information (when available)
  cached_tokens: Integer
}
```

## Provider Groups by Format

**OpenAI-Compatible Format (4 providers):**
- OpenAI, Mistral, Together AI, LM Studio
- All use `usage.prompt_tokens`, `usage.completion_tokens`, `usage.total_tokens`

**Google Format (1 provider):**
- Google: `usageMetadata.promptTokenCount`, `usageMetadata.candidatesTokenCount`

**Anthropic Format (1 provider):**
- Anthropic: `usage.input_tokens`, `usage.output_tokens`

## Implementation Strategy

1. **Create specialized parser classes** for each provider group
2. **Extend MetadataNormalizer** to route to appropriate parser
3. **Maintain backward compatibility** with existing Google/LMStudio logic
4. **Add provider detection** based on response structure patterns
5. **Implement extensible architecture** for future providers