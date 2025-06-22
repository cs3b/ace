# OpenAI Provider Integration

This guide covers the OpenAI provider integration in the Coding Agent Tools gem.

## Prerequisites

- An OpenAI API key from [platform.openai.com](https://platform.openai.com/)
- Ruby 3.2+ installed
- The `coding-agent-tools` gem installed

## Configuration

### API Key Setup

Set your OpenAI API key as an environment variable:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

Alternatively, you can add it to your `.env` file:

```
OPENAI_API_KEY=your-api-key-here
```

## Available Models

The OpenAI provider supports the following models:

- **gpt-4o** (default) - Most capable OpenAI model with vision and advanced reasoning
- **gpt-4o-mini** - Smaller, faster, and cheaper GPT-4 variant
- **gpt-4-turbo** - Previous generation GPT-4 with 128k context
- **gpt-3.5-turbo** - Fast and cost-effective for simpler tasks

To list all available models:

```bash
llm-models openai
```

## Usage Examples

### Basic Query

```bash
llm-openai-query "What is Ruby programming language?"
```

### Using a Specific Model

```bash
llm-openai-query "Explain quantum computing" --model gpt-4o-mini
```

### With System Instruction

```bash
llm-openai-query "Write a haiku" --system "You are a helpful poetry assistant"
```

### Reading from Files

```bash
# Prompt from file
llm-openai-query prompt.txt

# System instruction from file
llm-openai-query "Analyze this code" --system instructions.md
```

### Output Formatting

```bash
# JSON output
llm-openai-query "List 3 programming languages" --format json

# Save to file
llm-openai-query "Write a README" --output readme.md

# Markdown format
llm-openai-query "Create a tutorial" --format markdown --output tutorial.md
```

### Advanced Options

```bash
# Adjust temperature (0.0-2.0)
llm-openai-query "Be creative" --temperature 1.5

# Limit output tokens
llm-openai-query "Summarize briefly" --max-tokens 100

# Debug mode for troubleshooting
llm-openai-query "Test prompt" --debug
```

## API Client Usage (Ruby)

```ruby
require 'coding_agent_tools'

# Initialize client
client = CodingAgentTools::Organisms::OpenAIClient.new(
  model: "gpt-4o-mini",
  api_key: ENV['OPENAI_API_KEY'] # Optional, uses env by default
)

# Generate text
response = client.generate_text(
  "What is Ruby?",
  system_instruction: "You are a programming expert",
  generation_config: {
    temperature: 0.7,
    max_tokens: 1000
  }
)

puts response[:text]
puts response[:usage_metadata]
```

## Error Handling

Common errors and solutions:

### Invalid API Key
```
Error: OpenAI API Error (401): Invalid API key provided
```
**Solution**: Check that your `OPENAI_API_KEY` environment variable is set correctly.

### Rate Limiting
```
Error: OpenAI API Error (429): Rate limit exceeded
```
**Solution**: Wait a moment before retrying, or upgrade your OpenAI plan for higher limits.

### Model Not Found
```
Error: OpenAI API Error (404): Model not found
```
**Solution**: Use `llm-models openai` to see available models.

## Cost Considerations

OpenAI models are priced per token. Approximate costs (as of 2024):

- **gpt-4o**: ~$5/1M input tokens, ~$15/1M output tokens
- **gpt-4o-mini**: ~$0.15/1M input tokens, ~$0.60/1M output tokens
- **gpt-3.5-turbo**: ~$0.50/1M input tokens, ~$1.50/1M output tokens

Use `--max-tokens` to control costs by limiting output length.

## Best Practices

1. **Model Selection**: Use `gpt-4o-mini` for most tasks, upgrade to `gpt-4o` for complex reasoning
2. **Temperature**: Use lower values (0.0-0.5) for factual tasks, higher (0.7-1.5) for creative tasks
3. **System Instructions**: Provide clear, specific system instructions for consistent results
4. **Error Handling**: Always use `--debug` when troubleshooting issues

## See Also

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [OpenAI Pricing](https://openai.com/pricing)
- [Model Comparison Guide](https://platform.openai.com/docs/models)