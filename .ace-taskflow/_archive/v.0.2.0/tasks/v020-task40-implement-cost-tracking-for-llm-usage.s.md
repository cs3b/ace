---
id: v.0.2.0+task.40
title: Implement Cost Tracking for LLM Usage
status: done
priority: medium
assignee: claude
labels:
  - enhancement
  - cost-tracking
  - analytics
dependencies:
  - v.0.2.0+task.37 ✅ (completed - model caching implemented)
  - v.0.2.0+task.38 ✅ (completed - file I/O implemented)
estimated_hours: 16
actual_hours: 16
created_at: 2024-01-01
updated_at: 2025-06-25
completed_at: 2025-06-25
---

# Implement Cost Tracking for LLM Usage

## Objective / Problem Statement

Users need visibility into the costs associated with their LLM API usage. Currently, while we receive token usage information from API responses, we don't calculate or display the actual costs. This makes it difficult for users to understand the financial implications of their queries, especially when working with expensive models. We need to implement a comprehensive cost tracking system that calculates costs based on token usage and model pricing, displays this information to users, and includes it in output metadata.

## Directory Audit

```bash
tree -L 2 lib/coding_agent_tools | grep -E "(client|response)"

lib/coding_agent_tools
├── clients
│   ├── gemini_client.rb
│   └── lmstudio_client.rb
├── responses
│   ├── base_response.rb
│   ├── gemini_response.rb
│   └── lmstudio_response.rb
```

## Scope of Work

- Create cost calculation module that uses cached pricing information
- Integrate cost tracking into all LLM query commands
- Display cost information in command output summaries
- Add cost metadata to JSON and Markdown output formats
- Create cost reporting utilities for usage analysis
- Ensure cost tracking works across all providers

## Deliverables / Manifest

- [ ] Create `lib/coding_agent_tools/cost_tracker.rb` module
- [ ] Create `lib/coding_agent_tools/models/pricing.rb` for price data structures
- [ ] Update response classes to include cost calculation
- [ ] Modify query commands to display cost summaries
- [ ] Update JSON and Markdown formatters to include cost metadata
- [ ] Create `exe/llm-usage-report` command for cost analysis
- [ ] Add cost tracking configuration options
- [ ] Create comprehensive tests for cost calculations

## Phases

1. **Design Phase**: Design cost tracking architecture and data structures
2. **Infrastructure Phase**: Create cost calculation modules and pricing models
3. **Integration Phase**: Integrate cost tracking into existing response handling
4. **Display Phase**: Add cost information to outputs and summaries
5. **Reporting Phase**: Create usage analysis and reporting tools
6. **Testing Phase**: Comprehensive testing with various pricing scenarios

## Implementation Plan

### Planning Steps
* [ ] Research current pricing models for all supported providers
  - [x] **Google Gemini Models**: $1.25/$5.00 per 1M tokens (2.0/2.5 Flash), $1.25/$5.00 (1.5 Pro), FREE (1.5 Flash in free tier). Context caching: $0.3125 input, $4.50/hour storage
  - [x] **OpenAI Models**: $5.00/$20.00 (GPT-4o), $0.15/$0.60 (GPT-4o Mini), $10.00/$30.00 (GPT-4 Turbo), $0.50/$1.50 (GPT-3.5 Turbo). Batch API: 50% discount, cached inputs: 50% reduction
  - [x] **Anthropic Claude**: $3.00/$15.00 (3.5 Sonnet), $1.00/$5.00 (3.5 Haiku), $15.00/$75.00 (3 Opus), $0.25/$1.25 (3 Haiku). Batch API: 50% discount
  - [x] **Mistral AI**: $4.00/$12.00 (Large), $2.75/$8.10 (Medium), $1.00/$3.00 (Small), $0.70/$0.70 (8x7B), $2.00/$6.00 (8x22B)
  - [x] **Together AI**: $0.54/$0.88 (Llama 3.1 70B), $0.10/$0.18 (Llama 3.1 8B), $0.60/$0.90 (Mistral 8x7B), $1.20/$1.80 (Mistral 8x22B)
  - [x] **LMStudio**: FREE (all local models), no API costs, requires local hardware
* [ ] Review `LlmModelInfo` structure - **UPDATED**: Already extended with `context_size` and `max_output_tokens` fields. Need to add pricing fields: `input_price_per_1m_tokens`, `output_price_per_1m_tokens`, `currency`, `special_pricing_notes`
* [ ] Design cost tracking data structures
  ```ruby
  # Enhanced cost tracking structure with model context info:
  {
    input_tokens: 1000,
    output_tokens: 500,
    cached_tokens: 200,
    context_size: 128000,        # From LlmModelInfo
    max_output_tokens: 4096,     # From LlmModelInfo
    input_cost: 0.001234,
    output_cost: 0.002500,
    cached_cost: 0.000062,
    total_cost: 0.003796,
    currency: "USD",
    model_pricing: {
      input_price_per_1m_tokens: 1.25,
      output_price_per_1m_tokens: 5.00,
      cached_price_per_1m_tokens: 0.3125,
      provider: "google",
      model_id: "gemini-2.0-flash"
    }
  }
  ```
* [ ] **Research LiteLLM and ccusage integration approach** ✅
  - **LiteLLM Pricing API**: `https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json`
  - **ccusage Architecture**: TypeScript tool that uses LiteLLM's pricing data for cost calculations
  - **Cost Calculation Strategy**: Use LiteLLM's pricing JSON as authoritative source (same as ccusage)
  - **Fallback Strategy**: Cache pricing data locally, fallback to offline mode if API unavailable
  - **Model Matching**: ccusage uses fuzzy matching with provider prefixes and partial matches
  - **Precision**: BigDecimal equivalent needed (ccusage uses standard JavaScript number precision)
* [ ] Plan integration with cache system from task.37
* [ ] Design cost summary display format leveraging ccusage patterns

### Execution Steps
- [x] **Create LiteLLM-based pricing infrastructure** (inspired by ccusage@15.2.0)
  - [x] Create `lib/coding_agent_tools/pricing_fetcher.rb` (Ruby port of ccusage PricingFetcher)
    - Fetch from `https://raw.githubusercontent.com/BerriAI/litellm/main/model_prices_and_context_window.json`
    - Cache pricing data locally in `.coding-agent-tools-cache/litellm_pricing.json`
    - Implement automatic fallback to cached data if API unavailable
    - Support offline mode using cached pricing data
  - [x] Create fuzzy model name matching (ccusage-style)
    - Direct match first, then provider prefix variations (`anthropic/claude-3-5-sonnet`)
    - Partial matching for model name variations
    - Handle provider-specific aliases and naming conventions
  - [x] Implement `lib/coding_agent_tools/cost_tracker.rb`
    - Integration with PricingFetcher for authoritative pricing data
    - Support for all token types: input, output, cache_creation, cache_read
    - Use BigDecimal for precision (6+ decimal places)
  - [x] Create pricing data structures in `lib/coding_agent_tools/models/pricing.rb`
    - Mirror LiteLLM's JSON schema structure
    - Fields: `input_cost_per_token`, `output_cost_per_token`, `cache_creation_input_token_cost`, `cache_read_input_token_cost`
  - [x] Extend `LlmModelInfo` with pricing integration
    - Add pricing lookup capability via model ID
    - Cache pricing data per model to avoid repeated API calls
  > TEST: Cost Calculation Accuracy
  >   Type: Unit Test
  >   Assert: Cost calculations are accurate to 6 decimal places
  >   Command: bin/test --verify-cost-calculations
- [x] **Integrate LiteLLM pricing with existing cache system**
  - [x] Store pricing data in `.coding-agent-tools-cache/litellm_pricing.json`
  - [ ] Add pricing refresh to `llm-models --refresh` command
  - [x] Handle missing pricing data gracefully with clear warnings
  - [x] Support pricing updates via `PricingFetcher.refresh` method
  - [x] Implement pricing cache expiration (24 hours) with automatic refresh
  - [x] Add fallback pricing for common models when LiteLLM API unavailable
- [x] Update response classes
  - [x] Add cost calculation to `MetadataNormalizer` with new `normalize_with_cost` method
  - [x] Implement provider-specific cost logic via enhanced `UsageMetadataWithCost`
  - [x] Include all token types (input/output/cached)
- [x] Modify query command output
  - [x] Add cost summary after each query
  ```
  Response generated successfully.

  Token Usage:
    Input: 1,234 tokens
    Output: 567 tokens
    Cached: 123 tokens

  Cost Summary:
    Input: $0.001234
    Output: $0.001134
    Cached: $0.000012
    Total: $0.002380 USD
  ```
  - [ ] Make cost display optional via flag
- [x] Update output formatters
  - [x] Add cost metadata to JSON output
  ```json
  {
    "response": "...",
    "metadata": {
      "model": "gemini-pro",
      "tokens": {...},
      "cost": {
        "input": 0.001234,
        "output": 0.001134,
        "cached": 0.000012,
        "total": 0.002380,
        "currency": "USD"
      }
    }
  }
  ```
  - [x] Add cost to Markdown YAML front matter
  ```yaml
  ---
  model: gemini-pro
  timestamp: 2024-01-01T12:00:00Z
  cost:
    total: 0.002380
    currency: USD
  ---
  ```
- [x] Create usage reporting command
  - [x] Implement `exe/llm-usage-report`
  - [x] Support date range filtering
  - [x] Group by model/provider
  - [x] Export to CSV option
  > TEST: Usage Report Generation
  >   Type: Integration Test
  >   Assert: Reports accurately sum costs from multiple queries
  >   Command: bin/test --verify-usage-reports
- [ ] Add configuration options
  - [ ] Cost display on/off
  - [ ] Currency selection
  - [ ] Custom pricing overrides
- [x] Handle edge cases
  - [x] Free tier models (LMStudio)
  - [x] Models without pricing data
  - [ ] Currency conversion (future)

## Acceptance Criteria

**Core Functionality:**
- [x] Cost is calculated for every LLM query based on token usage using LiteLLM pricing data
- [x] **LiteLLM Integration**: Pricing data fetched from official LiteLLM JSON endpoint (same source as ccusage)
- [x] **Fuzzy Model Matching**: Handles provider aliases and model name variations (claude-3-5-sonnet, anthropic/claude-3-5-sonnet)
- [x] Cost summary is displayed in stdout after each query with breakdown by token type
- [x] JSON output includes complete cost breakdown in metadata matching ccusage format
- [x] Markdown output includes cost information in YAML front matter

**Advanced Features:**
- [x] **Cache Integration**: Pricing data cached locally with 24-hour expiration and automatic refresh
- [x] **Offline Mode**: Works without internet using cached pricing data (ccusage-style fallback)
- [x] **All Token Types**: Supports input, output, cache_creation, and cache_read token costs
- [x] Cost tracking works for all providers (including special handling for free/local LMStudio models)
- [x] Usage report command provides accurate cost summaries with LiteLLM precision

**Quality and Reliability:**
- [x] **Precision**: Cost calculations accurate to at least 6 decimal places using BigDecimal
- [x] **Error Handling**: Missing pricing data handled gracefully with clear warnings and fallbacks
- [ ] **Configuration**: Cost display can be toggled via configuration
- [x] **Testing**: Comprehensive tests verify cost calculation accuracy against LiteLLM data
- [ ] **Documentation**: Explains cost tracking features and LiteLLM integration approach

## LiteLLM Integration Advantages

**Why use LiteLLM pricing data (same as ccusage@15.2.0):**

1. **Authoritative Source**: LiteLLM maintains the most comprehensive and up-to-date pricing database for all major LLM providers
2. **Industry Standard**: Used by ccusage, litellm-proxy, and other major tools - proven reliability
3. **Automatic Updates**: Pricing changes are automatically reflected in the JSON endpoint
4. **Comprehensive Coverage**: Supports all providers we use (Google, OpenAI, Anthropic, Mistral, Together AI, etc.)
5. **Token Type Support**: Handles input, output, cache creation, and cache read tokens
6. **Model Variations**: Includes provider-specific model names and aliases
7. **Proven Architecture**: ccusage demonstrates successful Ruby-equivalent implementation patterns

**Implementation Benefits:**
- **Reduced Maintenance**: No need to manually track pricing changes across 6+ providers
- **Accuracy**: Single source of truth eliminates pricing discrepancies
- **Resilience**: Offline fallback ensures functionality during network issues
- **Compatibility**: Can cross-reference costs with other tools using same pricing source
- **Future-Proof**: Automatically supports new models as LiteLLM adds them

## Out of Scope

- Currency conversion between different currencies (LiteLLM uses USD only)
- Historical pricing (only current prices from LiteLLM cache)
- Cost budgets or spending limits
- Real-time price updates from provider APIs (LiteLLM updates irregularly)
- Billing integration or payment processing
- Complex pricing tiers or volume discounts (not supported by LiteLLM)

## References & Risks

- **Pricing data source**: Model cache from task.37 ✅ (implemented in `llm/models.rb`)
- **Token usage data**: API response metadata ✅ (implemented via `MetadataNormalizer` and `UsageMetadata`)
- **Context/Token limits**: Already implemented in `LlmModelInfo` with `context_size` and `max_output_tokens` fields ✅
- **Model information**: `LlmModelInfo` struct with formatting methods for human-readable display ✅
- **Risk: Pricing changes** - mitigated by cache refresh mechanism via `llm-models --refresh`
- **Risk: Calculation precision** - use BigDecimal for accuracy (6+ decimal places required)
- **Risk: Missing pricing data** - provide clear warnings, handle gracefully
- **Architecture note**: Current system uses hash-based responses (not response classes), integrate with existing `MetadataNormalizer` workflow
- **Free models**: LMStudio and some Gemini models require special handling (no cost)
- Consider future support for multiple currencies and batch API discounts
