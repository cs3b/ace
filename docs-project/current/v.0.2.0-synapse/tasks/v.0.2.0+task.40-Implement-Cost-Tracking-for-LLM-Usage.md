---
id: v.0.2.0+task.40
title: Implement Cost Tracking for LLM Usage
status: pending
priority: medium
assignee: unassigned
labels:
  - enhancement
  - cost-tracking
  - analytics
dependencies:
  - v.0.2.0+task.37
  - v.0.2.0+task.38
estimated_hours: 16
actual_hours: 0
created_at: 2024-01-01
updated_at: 2024-01-01
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
  - [ ] Gemini pricing (input/output/cached tokens)
  - [ ] OpenAI pricing tiers
  - [ ] Anthropic token costs
  - [ ] Mixtral/Together pricing
* [ ] Review `LlmModelInfo` and determine how to extend it to encapsulate pricing data per model without breaking its pure data structure nature. Consider adding new attributes (e.g., `pricing_details`) and helper methods (e.g., `cost_per_token_input`) to `LlmModelInfo`.
* [ ] Design cost tracking data structures
  ```ruby
  # Example structure:
  {
    input_tokens: 1000,
    output_tokens: 500,
    cached_tokens: 200,
    input_cost: 0.001,
    output_cost: 0.002,
    cached_cost: 0.0001,
    total_cost: 0.0031,
    currency: "USD"
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

- Pricing data source: Model cache from task.37
- Token usage data: API response metadata
- Risk: Pricing changes - mitigated by cache refresh mechanism
- Risk: Calculation precision - use BigDecimal for accuracy
- Risk: Missing pricing data - provide clear warnings
- Consider future support for multiple currencies
- Follow existing metadata patterns in response classes