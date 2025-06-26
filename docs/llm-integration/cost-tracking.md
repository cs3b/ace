# Cost Tracking Guide

This guide explains how to use the comprehensive cost tracking system built into the Coding Agent Tools gem to monitor and analyze your LLM usage costs.

## Overview

The cost tracking system provides:

- **Accurate Cost Calculations**: Based on authoritative LiteLLM pricing data
- **Multi-Provider Support**: Covers Google Gemini, OpenAI, Anthropic, Mistral, and more
- **Detailed Usage Reports**: Comprehensive breakdowns by provider, model, and time period
- **Automatic Cost Tracking**: All LLM queries are automatically tracked for cost analysis
- **Flexible Export Options**: JSON, CSV, and formatted table outputs

## How Cost Tracking Works

### Pricing Data Source

The cost tracking system uses [LiteLLM's pricing database](https://github.com/BerriAI/litellm/blob/main/model_prices_and_context_window.json) as its authoritative source for pricing information. This is the same data source used by the `ccusage` tool and other cost tracking utilities.

**Benefits of using LiteLLM pricing data:**
- **Up-to-date**: Regularly updated with the latest provider pricing
- **Comprehensive**: Covers all major LLM providers and models
- **Accurate**: Maintained by the LiteLLM community with real pricing data
- **Standardized**: Consistent format across all providers

### Automatic Token Counting

When you run LLM queries using `exe/llm-query`, the system automatically:

1. **Captures Usage Metadata**: Extracts token counts from provider responses
2. **Normalizes Data**: Converts different provider formats to a standard structure
3. **Calculates Costs**: Applies current pricing to token usage
4. **Stores Results**: Caches data for reporting and analysis

### Pricing Cache

Pricing data is cached locally to ensure fast calculations and offline functionality:

- **Cache Location**: `~/.cache/coding-agent-tools/pricing/` (XDG-compliant)
- **Cache Duration**: 24 hours before refresh
- **Automatic Updates**: Fresh data fetched when cache expires
- **Fallback**: Uses cached data if network is unavailable

## Usage Reports Command

The `exe/llm-usage-report` command provides comprehensive cost and usage analysis.

### Basic Usage

```bash
# Generate a basic usage report
exe/llm-usage-report

# Output in JSON format
exe/llm-usage-report --format json

# Export to CSV file
exe/llm-usage-report --format csv --output usage-report.csv
```

### Filtering Options

**Filter by Provider:**
```bash
exe/llm-usage-report --provider google
exe/llm-usage-report --provider anthropic
exe/llm-usage-report --provider openai
```

**Filter by Model:**
```bash
exe/llm-usage-report --model claude-3-5-sonnet
exe/llm-usage-report --model gpt-4o
exe/llm-usage-report --model gemini-2.0-flash
```

**Filter by Date Range:**
```bash
# Predefined ranges
exe/llm-usage-report --date-range today
exe/llm-usage-report --date-range week
exe/llm-usage-report --date-range month

# Custom date range
exe/llm-usage-report --date-range 2024-01-01:2024-01-31
```

### Output Formats

#### Table Format (Default)

```bash
exe/llm-usage-report
```

**Sample Output:**
```
LLM Usage Report
================================================================================

Summary:
  Total Queries: 3
  Total Cost: $0.008601
  Total Tokens: 6701
  Average Cost per Query: $0.002867

By Provider:
  Google: 1 queries, $0.001891
  Anthropic: 1 queries, $0.006125
  Openai: 1 queries, $0.000585

Detailed Usage:
Timestamp           Provider     Model                   Input   Output   Cached       Cost     Time
--------------------------------------------------------------------------------
2024-01-01T10:00:00 google       gemini-2.0-flash         1234      567        0 $0.001891    2.5s
2024-01-01T11:00:00 anthropic    claude-3-5-sonnet        2000      800      100 $0.006125    3.2s
2024-01-01T12:00:00 openai       gpt-4o-mini              1500      600        0 $0.000585    1.8s
```

#### JSON Format

```bash
exe/llm-usage-report --format json
```

**Sample Output:**
```json
{
  "summary": {
    "total_queries": 3,
    "total_cost": 0.008601,
    "total_tokens": 6701,
    "average_cost_per_query": 0.002867,
    "providers": {
      "google": {
        "queries": 1,
        "cost": 0.001891
      },
      "anthropic": {
        "queries": 1,
        "cost": 0.006125
      },
      "openai": {
        "queries": 1,
        "cost": 0.000585
      }
    },
    "models": {
      "gemini-2.0-flash": {
        "queries": 1,
        "cost": 0.001891
      },
      "claude-3-5-sonnet": {
        "queries": 1,
        "cost": 0.006125
      },
      "gpt-4o-mini": {
        "queries": 1,
        "cost": 0.000585
      }
    }
  },
  "usage_data": [
    {
      "timestamp": "2024-01-01T10:00:00Z",
      "provider": "google",
      "model": "gemini-2.0-flash",
      "input_tokens": 1234,
      "output_tokens": 567,
      "cached_tokens": 0,
      "total_cost": 0.001891,
      "input_cost": 0.001543,
      "output_cost": 0.000348,
      "cache_cost": 0.0,
      "execution_time": 2.5
    }
  ]
}
```

#### CSV Format

```bash
exe/llm-usage-report --format csv --output report.csv
```

**Sample CSV Structure:**
```csv
timestamp,provider,model,input_tokens,output_tokens,cached_tokens,total_cost,input_cost,output_cost,cache_cost,execution_time
2024-01-01T10:00:00Z,google,gemini-2.0-flash,1234,567,0,0.001891,0.001543,0.000348,0.0,2.5
2024-01-01T11:00:00Z,anthropic,claude-3-5-sonnet,2000,800,100,0.006125,0.006000,0.004000,0.000125,3.2
```

## Cost Calculation Details

### Token Types and Pricing

The system tracks and prices different types of tokens:

1. **Input Tokens**: Tokens in your prompt/request
2. **Output Tokens**: Tokens in the model's response
3. **Cache Creation Tokens**: Tokens used to create cache entries (provider-specific)
4. **Cache Read Tokens**: Tokens read from cache (typically cheaper than input)

### Pricing Accuracy

**Accurate Pricing For:**
- All major commercial LLM providers (Google, OpenAI, Anthropic, Mistral, etc.)
- Current pricing as of the last LiteLLM database update
- Token-based billing models

**Free Models:**
The system automatically detects and handles free models:
- **LM Studio Models**: Always $0.00 (local inference)
- **Free Tier Models**: Some Google models in free tiers
- **Local Models**: Any model containing "local" or "lmstudio" in the name

### Cost Calculation Components

For each query, costs are broken down into:

```ruby
total_cost = input_cost + output_cost + cache_creation_cost + cache_read_cost

where:
  input_cost = input_tokens × input_rate_per_token
  output_cost = output_tokens × output_rate_per_token
  cache_creation_cost = cache_creation_tokens × cache_creation_rate
  cache_read_cost = cache_read_tokens × cache_read_rate
```

## Integration with LLM Query Command

Cost tracking is automatically integrated with the `exe/llm-query` command:

```bash
# Cost tracking happens automatically
exe/llm-query google:gemini-2.0-flash "Explain quantum computing"

# Costs are calculated and stored for later reporting
exe/llm-usage-report --provider google
```

### Cost Display During Queries

When making queries, you can see cost information in real-time:

```bash
exe/llm-query google:gemini-2.0-flash "Hello world" --debug
# Shows token usage and cost calculation details
```

## Cache Management

### Pricing Data Cache

**View Cache Information:**
```bash
# Check cache status (when implemented)
exe/llm-models --cache-info
```

**Refresh Pricing Data:**
```bash
# Force refresh of pricing data
exe/llm-usage-report --refresh-pricing
```

### Usage Data Storage

Usage data is stored in the XDG-compliant cache directory:
- **Location**: `~/.cache/coding-agent-tools/usage/`
- **Format**: JSON files with query metadata and cost calculations
- **Retention**: Configurable (default: 90 days)

## Advanced Usage Examples

### Monthly Cost Analysis

```bash
# Get monthly breakdown in JSON for analysis
exe/llm-usage-report --date-range month --format json --output monthly-costs.json

# Analyze costs by provider for the month
exe/llm-usage-report --date-range month --provider anthropic
exe/llm-usage-report --date-range month --provider google
exe/llm-usage-report --date-range month --provider openai
```

### Model Comparison

```bash
# Compare costs between similar models
exe/llm-usage-report --model claude-3-5-sonnet
exe/llm-usage-report --model gpt-4o
exe/llm-usage-report --model gemini-1.5-pro
```

### Budget Monitoring

```bash
# Weekly usage summary for budget tracking
exe/llm-usage-report --date-range week --format json | jq '.summary.total_cost'

# Export for spreadsheet analysis
exe/llm-usage-report --format csv --output weekly-usage.csv
```

### Historical Analysis

```bash
# Compare usage across different months
exe/llm-usage-report --date-range 2024-01-01:2024-01-31 --format json
exe/llm-usage-report --date-range 2024-02-01:2024-02-29 --format json
exe/llm-usage-report --date-range 2024-03-01:2024-03-31 --format json
```

## Understanding Cost Data

### Cost Accuracy Considerations

1. **Token Counting**: Based on provider-reported token usage
2. **Pricing Updates**: LiteLLM database updated regularly but may lag pricing changes
3. **Currency**: All costs reported in USD
4. **Billing Periods**: Costs calculated per query, not billing cycle
5. **Free Tiers**: System cannot track free tier quotas automatically

### Cost Optimization Tips

**Choose Cost-Effective Models:**
```bash
# Compare model costs for similar tasks
exe/llm-usage-report --model gpt-4o-mini      # Usually cheaper
exe/llm-usage-report --model gpt-4o           # More expensive
exe/llm-usage-report --model claude-3-5-haiku # Fast and cheap
```

**Monitor Token Usage:**
- Use shorter prompts when possible
- Leverage context caching for repeated content
- Choose appropriate models for task complexity

**Regular Analysis:**
```bash
# Weekly cost reviews
exe/llm-usage-report --date-range week

# Provider comparison for cost optimization
exe/llm-usage-report --format json | jq '.summary.providers'
```

## Troubleshooting

### Common Issues

**No Usage Data:**
```bash
# Check if any queries have been made
exe/llm-usage-report --debug
```

**Pricing Data Issues:**
```bash
# Refresh pricing cache
exe/llm-usage-report --refresh-pricing

# Check pricing cache status
ls -la ~/.cache/coding-agent-tools/pricing/
```

**Missing Model Pricing:**
- Some newer or specialized models may not be in LiteLLM database yet
- Local/custom models default to $0.00 cost
- Check LiteLLM database directly for model availability

### Debug Information

```bash
# Enable debug output for detailed information
exe/llm-usage-report --debug

# Check system configuration
exe/llm-query --help
```

## API Integration

For programmatic access to cost tracking data, the cost tracking components can be used directly:

```ruby
require 'coding_agent_tools'

# Initialize cost tracker
tracker = CodingAgentTools::CostTracker.new

# Calculate cost for specific usage
cost = tracker.calculate_cost(
  model_id: "claude-3-5-sonnet",
  input_tokens: 1000,
  output_tokens: 500
)

puts "Total cost: $#{cost.total_cost}"
puts "Input cost: $#{cost.input_cost}"
puts "Output cost: $#{cost.output_cost}"

# Check available models
models = tracker.available_models
puts "Supported models: #{models.length}"
```

## Related Documentation

- **[LLM Query Guide](./query.md)**: Learn how to use the `llm-query` command
- **[Model Management](./model-management.md)**: Discover and manage LLM models
- **[LiteLLM Pricing Database](https://github.com/BerriAI/litellm/blob/main/model_prices_and_context_window.json)**: Authoritative pricing source

---

The cost tracking system helps you make informed decisions about LLM usage while providing detailed insights into your spending patterns across different providers and models.