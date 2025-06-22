# Mistral Provider Integration

This guide covers the Mistral AI provider integration (including Mistral models) in the Coding Agent Tools gem.

## Prerequisites

- A Mistral AI API key from [console.mistral.ai](https://console.mistral.ai/)
- Ruby 3.2+ installed
- The `coding-agent-tools` gem installed

## Configuration

### API Key Setup

Set your Mistral API key as an environment variable:

```bash
export MISTRAL_API_KEY="your-api-key-here"
```

Alternatively, you can add it to your `.env` file:

```
MISTRAL_API_KEY=your-api-key-here
```

## Available Models

The Mistral provider supports the following Mistral AI models:

- **mistral-large-latest** (default) - Most capable Mistral model with advanced reasoning
- **mistral-medium-latest** - Balanced performance and efficiency
- **mistral-small-latest** - Fast and efficient for simpler tasks
- **mistral-8x7b-instruct** - Open-source mixture of experts model
- **mistral-8x22b-instruct** - Large open-source mixture of experts model

To list all available models:

```bash
llm-models mistral
```

## Usage Examples

### Basic Query

```bash
llm-mistral-query "What is Ruby programming language?"
```

### Using a Specific Model

```bash
llm-mistral-query "Explain quantum computing" --model mistral-8x7b-instruct
```

### With System Instruction

```bash
llm-mistral-query "Write a haiku" --system "You are a helpful poetry assistant"
```

### Reading from Files

```bash
# Prompt from file
llm-mistral-query prompt.txt

# System instruction from file
llm-mistral-query "Analyze this code" --system instructions.md
```

### Output Formatting

```bash
# JSON output
llm-mistral-query "List 3 programming languages" --format json

# Save to file
llm-mistral-query "Write a README" --output readme.md

# Markdown format
llm-mistral-query "Create a tutorial" --format markdown --output tutorial.md
```

### Advanced Options

```bash
# Adjust temperature (0.0-1.0)
llm-mistral-query "Be creative" --temperature 0.9

# Limit output tokens
llm-mistral-query "Summarize briefly" --max-tokens 100

# Debug mode for troubleshooting
llm-mistral-query "Test prompt" --debug
```

## API Client Usage (Ruby)

```ruby
require 'coding_agent_tools'

# Initialize client
client = CodingAgentTools::Organisms::MistralClient.new(
  model: "mistral-8x7b-instruct",
  api_key: ENV['MISTRAL_API_KEY'] # Optional, uses env by default
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
Error: Mistral API Error (401): Invalid API key
```
**Solution**: Check that your `MISTRAL_API_KEY` environment variable is set correctly.

### Rate Limiting
```
Error: Mistral API Error (429): Rate limit exceeded
```
**Solution**: Wait a moment before retrying, or upgrade your Mistral AI plan for higher limits.

### Model Not Found
```
Error: Mistral API Error (404): Model not found
```
**Solution**: Use `llm-models mistral` to see available models.

## Cost Considerations

Mistral AI models are priced per token. Approximate costs (as of 2024):

- **Mistral Large**: ~$4/1M input tokens, ~$12/1M output tokens
- **Mistral Medium**: ~$2.7/1M input tokens, ~$8.1/1M output tokens
- **Mistral Small**: ~$0.2/1M input tokens, ~$0.6/1M output tokens
- **Mistral 8x7B**: ~$0.7/1M input tokens, ~$0.7/1M output tokens
- **Mistral 8x22B**: ~$2/1M input tokens, ~$6/1M output tokens

Use `--max-tokens` to control costs by limiting output length.

## Best Practices

1. **Model Selection**: 
   - Use Mistral Small for simple, fast tasks
   - Use Mistral Medium for balanced performance
   - Use Mistral Large for complex reasoning
   - Use Mistral models for open-source requirements

2. **Temperature**: Use lower values (0.0-0.5) for factual tasks, higher (0.7-1.0) for creative tasks

3. **System Instructions**: Provide clear, concise system instructions for best results

4. **Language Support**: Mistral models excel at multilingual tasks, supporting English, French, Italian, German, and Spanish

## Mistral-Specific Features

### Mixture of Experts Architecture
Mistral models use a sparse mixture of experts architecture, providing:
- Efficient inference despite large parameter counts
- Strong performance across diverse tasks
- Better cost-performance ratio compared to dense models

### Open Source Availability
Mistral models are available as open-source, allowing:
- Self-hosting for sensitive data
- Fine-tuning for specific use cases
- Full transparency in model behavior

### Code Generation
Mistral models are particularly strong at:
- Code generation and completion
- Code explanation and documentation
- Debugging and optimization suggestions

## See Also

- [Mistral AI API Documentation](https://docs.mistral.ai/api/)
- [Mistral AI Pricing](https://mistral.ai/pricing/)
- [Mistral Paper](https://arxiv.org/abs/2401.04088)
- [Mistral AI Models Overview](https://docs.mistral.ai/models/)