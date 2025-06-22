# Together AI Provider Integration

This guide covers the Together AI provider integration in the Coding Agent Tools gem.

## Prerequisites

- A Together AI API key from [api.together.xyz](https://api.together.xyz/)
- Ruby 3.2+ installed
- The `coding-agent-tools` gem installed

## Configuration

### API Key Setup

Set your Together AI API key as an environment variable:

```bash
export TOGETHER_API_KEY="your-api-key-here"
```

Alternatively, you can add it to your `.env` file:

```
TOGETHER_API_KEY=your-api-key-here
```

## Available Models

The Together AI provider supports a wide range of open-source models:

- **meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo** (default) - Fast Llama 3.1 70B with optimized inference
- **meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo** - Smaller, faster Llama 3.1 model
- **mistralai/Mistral-8x7B-Instruct-v0.1** - Mixture of experts model with strong performance
- **mistralai/Mistral-8x22B-Instruct-v0.1** - Large mixture of experts model
- **deepseek-ai/deepseek-coder-33b-instruct** - Specialized model for code generation

To list all available models:

```bash
llm-models together_ai
```

## Usage Examples

### Basic Query

```bash
llm-together-ai-query "What is Ruby programming language?"
```

### Using a Specific Model

```bash
llm-together-ai-query "Explain quantum computing" --model mistralai/Mistral-8x7B-Instruct-v0.1
```

### With System Instruction

```bash
llm-together-ai-query "Write a haiku" --system "You are a helpful poetry assistant"
```

### Reading from Files

```bash
# Prompt from file
llm-together-ai-query prompt.txt

# System instruction from file
llm-together-ai-query "Analyze this code" --system instructions.md
```

### Output Formatting

```bash
# JSON output
llm-together-ai-query "List 3 programming languages" --format json

# Save to file
llm-together-ai-query "Write a README" --output readme.md

# Markdown format
llm-together-ai-query "Create a tutorial" --format markdown --output tutorial.md
```

### Advanced Options

```bash
# Adjust temperature (0.0-2.0)
llm-together-ai-query "Be creative" --temperature 1.2

# Limit output tokens
llm-together-ai-query "Summarize briefly" --max-tokens 100

# Debug mode for troubleshooting
llm-together-ai-query "Test prompt" --debug
```

## API Client Usage (Ruby)

```ruby
require 'coding_agent_tools'

# Initialize client
client = CodingAgentTools::Organisms::TogetherAIClient.new(
  model: "meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo",
  api_key: ENV['TOGETHER_API_KEY'] # Optional, uses env by default
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
Error: Together AI API Error (401): Invalid API key
```
**Solution**: Check that your `TOGETHER_API_KEY` environment variable is set correctly.

### Rate Limiting
```
Error: Together AI API Error (429): Rate limit exceeded
```
**Solution**: Wait a moment before retrying, or upgrade your Together AI plan for higher limits.

### Model Not Found
```
Error: Together AI API Error (404): Model not found
```
**Solution**: Use `llm-models together_ai` to see available models. Note that model availability can change.

### Model Overloaded
```
Error: Together AI API Error (503): Model is currently overloaded
```
**Solution**: Try a different model or wait a few moments before retrying.

## Cost Considerations

Together AI offers competitive pricing for open-source models. Approximate costs (as of 2024):

- **Llama 3.1 70B**: ~$0.88/1M tokens
- **Llama 3.1 8B**: ~$0.18/1M tokens
- **Mistral 8x7B**: ~$0.60/1M tokens
- **Mistral 8x22B**: ~$1.20/1M tokens
- **DeepSeek Coder 33B**: ~$0.80/1M tokens

Use `--max-tokens` to control costs by limiting output length.

## Best Practices

1. **Model Selection**: 
   - Use Llama 3.1 8B for fast, simple tasks
   - Use Llama 3.1 70B for complex reasoning and general tasks
   - Use Mistral models for code and technical content
   - Use DeepSeek Coder for specialized code generation

2. **Temperature**: Together AI models support wider temperature ranges (0.0-2.0) than some providers

3. **System Instructions**: Most models respond well to clear, specific system instructions

4. **Inference Speed**: Together AI optimizes for fast inference, making it ideal for real-time applications

## Together AI-Specific Features

### Model Variety
Together AI provides access to a vast array of open-source models, including:
- Language models (Llama, Mistral, Qwen, etc.)
- Code models (DeepSeek, CodeLlama, StarCoder)
- Specialized models for specific tasks

### Fast Inference
Together AI specializes in optimized inference for open-source models:
- Turbo variants for faster response times
- Optimized serving infrastructure
- Lower latency compared to self-hosting

### Flexible Deployment
- Access the same models via API that you could self-host
- No vendor lock-in
- Easy migration between providers

### Community Models
Together AI often adds new open-source models quickly after release, providing early access to cutting-edge models.

## Advanced Features

### Model Switching
Easily switch between models to find the best fit:

```bash
# Try different models for the same task
llm-together-ai-query "Explain recursion" --model meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo
llm-together-ai-query "Explain recursion" --model mistralai/Mistral-8x7B-Instruct-v0.1
```

### Code Generation
For code-specific tasks, use specialized models:

```bash
llm-together-ai-query "Write a Ruby class for a binary tree" --model deepseek-ai/deepseek-coder-33b-instruct
```

## See Also

- [Together AI API Documentation](https://docs.together.ai/reference)
- [Together AI Pricing](https://www.together.ai/pricing)
- [Together AI Model List](https://docs.together.ai/docs/models)
- [Together AI Blog](https://www.together.ai/blog)