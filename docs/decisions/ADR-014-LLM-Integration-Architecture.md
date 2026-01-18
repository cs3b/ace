# ADR-014: LLM Integration Architecture

## Status

Accepted
Date: 2024-07-06

## Context

The Coding Agent Tools gem requires comprehensive integration with multiple LLM providers (Google Gemini, OpenAI, Anthropic, Mistral, Together AI, LM Studio) to provide unified query capabilities. This integration involves several architectural challenges:

1. **Provider Diversity**: Each LLM provider has different API response formats, authentication methods, and capabilities
2. **Context Size Management**: Models have varying context window sizes that need to be tracked and exposed to users
3. **Usage Tracking**: Different providers report token usage in different formats, requiring normalization for cost tracking
4. **Caching Strategy**: Model information and usage data need XDG-compliant caching for performance and compliance
5. **Cost Calculation**: Accurate cost tracking requires integration with authoritative pricing data

Without a unified architectural approach, these integrations would result in inconsistent behavior, duplicated code, and difficulty maintaining compatibility across providers.

## Decision

We decided to implement a comprehensive LLM Integration Architecture that standardizes provider interactions while accommodating provider-specific requirements. The architecture consists of four key components:

### 1. Provider Context Size Management

**Strategy**: Hybrid approach combining API-provided data with static mappings for comprehensive context size information.

**Implementation**:
- **API First**: Extract context size from provider APIs when available (e.g., Google's `inputTokenLimit`)
- **Static Mapping**: Maintain hardcoded mappings for providers without API support
- **Graceful Degradation**: Handle unknown context sizes with null values
- **Enhanced Model Info**: Extend `LlmModelInfo` to include `context_size` and `max_output_tokens` fields

**Provider-Specific Approaches**:
- **Google Gemini**: Extract from `inputTokenLimit` and `outputTokenLimit` API fields
- **OpenAI/Anthropic/Mistral**: Use static mappings based on model names
- **LM Studio**: Return null/unknown for local models
- **Together AI**: Hybrid approach with API fallback to mapping

### 2. Unified Usage Metadata Structure

**Strategy**: Normalize different provider response formats into a consistent structure for cost tracking and analysis.

**Unified Structure**:
```ruby
{
  # Token counts
  input_tokens: Integer,
  output_tokens: Integer,
  total_tokens: Integer,
  
  # Timing and metadata
  took: Float, # execution time in seconds
  provider: String,
  model: String,
  timestamp: String, # ISO 8601 UTC
  finish_reason: String, # normalized
  
  # Cache information (when available)
  cached_tokens: Integer,
  
  # Provider-specific additional data
  provider_specific: Hash
}
```

**Provider Format Groups**:
- **OpenAI-Compatible**: OpenAI, Mistral, Together AI, LM Studio (`usage.prompt_tokens`, `usage.completion_tokens`)
- **Google Format**: Gemini (`usageMetadata.promptTokenCount`, `usageMetadata.candidatesTokenCount`)
- **Anthropic Format**: Claude (`usage.input_tokens`, `usage.output_tokens`)

**Implementation**: `MetadataNormalizer` with specialized parser classes for each provider group.

### 3. XDG-Compliant Caching System

**Strategy**: Implement standards-compliant cache directory structure with automatic migration from legacy locations.

**XDG Implementation**:
- **Primary Location**: `$XDG_CACHE_HOME/coding-agent-tools/` if set
- **Fallback Location**: `$HOME/.cache/coding-agent-tools/` if `XDG_CACHE_HOME` unset
- **Directory Structure**: Organized subdirectories for different cache types
  - `models/` - LLM model information cache
  - `pricing/` - Cost tracking and pricing data
  - `usage/` - Usage tracking data
  - `temp/` - Temporary cache files

**Migration Strategy**:
- **Phase 1**: Detect existing cache at `~/.coding-agent-tools-cache`
- **Phase 2**: Auto-migrate to XDG location with user notification
- **Phase 3**: Create migration marker to prevent re-migration
- **Phase 4**: Preserve original files for safety during transition

**Components**:
- **XDGDirectoryResolver (Atom)**: Handle XDG path resolution and directory creation
- **CacheManager (Molecule)**: Manage cache operations with XDG compliance and migration

### 4. Comprehensive Cost Tracking System

**Strategy**: Integrate with authoritative LiteLLM pricing database for accurate cost calculations across all providers.

**Pricing Data Source**:
- **Primary Source**: [LiteLLM pricing database](https://github.com/BerriAI/litellm/blob/main/model_prices_and_context_window.json)
- **Update Frequency**: 24-hour cache refresh cycle
- **Offline Support**: Cached pricing data for network-unavailable scenarios
- **Free Model Detection**: Automatic detection and $0.00 costing for local/free models

**Cost Calculation**:
```ruby
total_cost = input_cost + output_cost + cache_creation_cost + cache_read_cost

where:
  input_cost = input_tokens × input_rate_per_token
  output_cost = output_tokens × output_rate_per_token
  cache_creation_cost = cache_creation_tokens × cache_creation_rate
  cache_read_cost = cache_read_tokens × cache_read_rate
```

**Usage Tracking Features**:
- **Automatic Tracking**: All LLM queries automatically tracked
- **Multiple Export Formats**: JSON, CSV, formatted table outputs
- **Flexible Filtering**: By provider, model, date range
- **Cost Analysis**: Detailed breakdowns and trend analysis

### Architecture Integration

The four components integrate seamlessly within the existing ATOM architecture:

**Atoms**:
- `XDGDirectoryResolver`: XDG-compliant directory resolution
- `SecurityLogger`: Sanitized logging for cost and usage data

**Molecules**:
- `CacheManager`: XDG cache operations with migration
- `MetadataNormalizer`: Provider response normalization
- `PricingDataFetcher`: LiteLLM pricing data retrieval
- `UsageTracker`: Cost calculation and storage

**Organisms**:
- Enhanced provider clients with context size support
- `CostCalculator`: Comprehensive cost analysis
- `UsageReporter`: Multi-format usage reporting

## Implementation Examples

### Enhanced Model Info with Context Size

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

### XDG Cache Directory Resolution

```ruby
# XDGDirectoryResolver implementation
class XDGDirectoryResolver
  def cache_directory
    xdg_cache_home = ENV['XDG_CACHE_HOME']
    
    if xdg_cache_home && !xdg_cache_home.empty?
      File.join(xdg_cache_home, 'coding-agent-tools')
    else
      File.join(ENV['HOME'], '.cache', 'coding-agent-tools')
    end
  end
end
```

### Usage Metadata Normalization

```ruby
# MetadataNormalizer with provider-specific parsers
class MetadataNormalizer
  def normalize_usage(response, provider, model)
    parser = parser_for_provider(provider)
    normalized = parser.parse_usage(response)
    
    normalized.merge(
      provider: provider,
      model: model,
      timestamp: Time.now.utc.iso8601
    )
  end
  
  private
  
  def parser_for_provider(provider)
    case provider
    when 'google' then GoogleUsageParser.new
    when 'anthropic' then AnthropicUsageParser.new
    else OpenAICompatibleParser.new
    end
  end
end
```

## Consequences

### Positive

- **Unified Provider Interface**: Consistent behavior across all LLM providers while accommodating provider-specific features
- **Standards Compliance**: XDG-compliant caching provides better system integration and user expectations
- **Accurate Cost Tracking**: LiteLLM integration ensures up-to-date and accurate pricing across all providers
- **Enhanced User Experience**: Context size information helps users make informed model selection decisions
- **Future-Proof Architecture**: Easy addition of new providers with consistent integration patterns
- **Comprehensive Usage Analysis**: Detailed cost and usage tracking enables informed decision-making
- **Backward Compatibility**: Automatic migration preserves existing user data and workflows
- **Extensible Design**: ATOM architecture allows easy extension and modification of components

### Negative

- **Implementation Complexity**: Four interconnected systems require careful coordination and testing
- **Migration Overhead**: Automatic migration adds complexity to initial implementation
- **External Dependency**: Reliance on LiteLLM pricing database for cost accuracy
- **Storage Requirements**: XDG cache structure and usage tracking increase disk space usage
- **Performance Impact**: Cost calculation and metadata normalization add processing overhead
- **Testing Complexity**: Multiple provider formats and edge cases require comprehensive test coverage

### Neutral

- **Configuration Options**: Extensive configuration capabilities require clear documentation and sensible defaults
- **Provider Variability**: Some providers may change APIs or pricing, requiring ongoing maintenance
- **Cache Management**: Users need to understand cache locations and cleanup procedures

## Alternatives Considered

### Simple Per-Provider Implementation

- **Why Rejected**: Would result in code duplication and inconsistent behavior across providers
- **Trade-offs**: Simpler individual implementations vs. unified architecture benefits

### Third-Party Cost Tracking Services

- **Why Rejected**: External services add dependencies and may not support all providers
- **Trade-offs**: Reduced implementation complexity vs. control and accuracy

### Non-XDG Cache Locations

- **Why Rejected**: Violates user expectations and system standards on Unix-like systems
- **Trade-offs**: Simpler implementation vs. standards compliance and user experience

### Static Pricing Data

- **Why Rejected**: Pricing changes frequently and static data becomes outdated quickly
- **Trade-offs**: No external dependencies vs. accuracy and maintenance burden

## Related Decisions

- **ADR-010**: HTTP Client Strategy with Faraday - Provides foundation for provider API interactions
- **ADR-011**: ATOM Architecture House Rules - Defines component organization and boundaries
- **ADR-012**: Dynamic Provider System Architecture - Establishes provider abstraction patterns

## Implementation Timeline

### Phase 1: Core Infrastructure (Completed)
- XDGDirectoryResolver and CacheManager implementation
- MetadataNormalizer with basic provider support
- Enhanced LlmModelInfo structure

### Phase 2: Cost Tracking Integration (Completed)
- LiteLLM pricing data integration
- Usage tracking and cost calculation
- Multi-format reporting capabilities

### Phase 3: Provider Enhancement (Completed)
- Context size support across all providers
- Provider-specific usage parsers
- Comprehensive error handling

### Phase 4: Migration and Polish (Completed)
- Automatic cache migration implementation
- Documentation and user guides
- Performance optimization and testing

## References

- [LiteLLM Pricing Database](https://github.com/BerriAI/litellm/blob/main/model_prices_and_context_window.json)
- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
- Provider API Documentation: Google Gemini, OpenAI, Anthropic, Mistral, Together AI
- `LlmModelInfo`, `MetadataNormalizer`, `CacheManager`, `XDGDirectoryResolver` component implementations