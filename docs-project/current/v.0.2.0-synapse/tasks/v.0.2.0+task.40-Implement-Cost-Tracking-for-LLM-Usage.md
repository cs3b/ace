---
id: v.0.2.0+task.40
title: Implement Cost Tracking for LLM Usage
status: ready
priority: medium
assignee: unassigned
labels:
  - enhancement
  - cost-tracking
  - analytics
dependencies:
  - v.0.2.0+task.37 ✅ (completed - model caching implemented)
  - v.0.2.0+task.38 ✅ (completed - file I/O implemented)
estimated_hours: 16
actual_hours: 0
created_at: 2024-01-01
updated_at: 2025-06-25
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
* [ ] Plan integration with cache system from task.37
* [ ] Design cost summary display format

### Execution Steps
- [ ] Create core cost tracking infrastructure
  - [ ] Implement `lib/coding_agent_tools/cost_tracker.rb`
  - [ ] Create pricing data structures in `lib/coding_agent_tools/models/pricing.rb`
  - [ ] Add methods to load pricing from cache
  > TEST: Cost Calculation Accuracy
  >   Type: Unit Test
  >   Assert: Cost calculations are accurate to 6 decimal places
  >   Command: bin/test --verify-cost-calculations
- [ ] Integrate with cache system
  - [ ] Read model pricing from `.coding-agent-tools-cache/`
  - [ ] Handle missing pricing data gracefully
  - [ ] Support pricing updates via cache refresh
- [ ] Update response classes
  - [ ] Add cost calculation to `base_response.rb`
  - [ ] Implement provider-specific cost logic
  - [ ] Include all token types (input/output/cached)
- [ ] Modify query command output
  - [ ] Add cost summary after each query
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
- [ ] Update output formatters
  - [ ] Add cost metadata to JSON output
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
  - [ ] Add cost to Markdown YAML front matter
  ```yaml
  ---
  model: gemini-pro
  timestamp: 2024-01-01T12:00:00Z
  cost:
    total: 0.002380
    currency: USD
  ---
  ```
- [ ] Create usage reporting command
  - [ ] Implement `exe/llm-usage-report`
  - [ ] Support date range filtering
  - [ ] Group by model/provider
  - [ ] Export to CSV option
  > TEST: Usage Report Generation
  >   Type: Integration Test
  >   Assert: Reports accurately sum costs from multiple queries
  >   Command: bin/test --verify-usage-reports
- [ ] Add configuration options
  - [ ] Cost display on/off
  - [ ] Currency selection
  - [ ] Custom pricing overrides
- [ ] Handle edge cases
  - [ ] Free tier models (LMStudio)
  - [ ] Models without pricing data
  - [ ] Currency conversion (future)

## Acceptance Criteria

- [ ] Cost is calculated for every LLM query based on token usage
- [ ] Cost information uses pricing data from model cache
- [ ] Cost summary is displayed in stdout after each query
- [ ] JSON output includes complete cost breakdown in metadata
- [ ] Markdown output includes cost information in YAML front matter
- [ ] Cost tracking works for all providers (including free/local ones)
- [ ] Usage report command provides accurate cost summaries
- [ ] Cost display can be toggled via configuration
- [ ] Missing pricing data is handled gracefully with warnings
- [ ] Cost calculations are accurate to at least 6 decimal places
- [ ] Tests verify cost calculation accuracy
- [ ] Documentation explains cost tracking features

## Out of Scope

- Currency conversion between different currencies
- Historical pricing (only current prices from cache)
- Cost budgets or spending limits
- Real-time price updates from provider APIs
- Billing integration or payment processing
- Complex pricing tiers or volume discounts

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
