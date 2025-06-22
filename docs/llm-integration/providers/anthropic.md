# Anthropic Provider Integration

This guide covers the Anthropic (Claude) provider integration in the Coding Agent Tools gem.

## Prerequisites

- An Anthropic API key from [console.anthropic.com](https://console.anthropic.com/)
- Ruby 3.2+ installed
- The `coding-agent-tools` gem installed

## Configuration

### API Key Setup

Set your Anthropic API key as an environment variable:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

Alternatively, you can add it to your `.env` file:

```
ANTHROPIC_API_KEY=your-api-key-here
```

## Available Models

The Anthropic provider supports the following Claude models:

- **claude-3-5-sonnet-20241022** (default) - Most intelligent Claude model
- **claude-3-5-haiku-20241022** - Fast and cost-effective
- **claude-3-opus-20240229** - Powerful model for complex tasks
- **claude-3-sonnet-20240229** - Balanced performance and speed
- **claude-3-haiku-20240307** - Fast, compact, and cost-effective

To list all available models:

```bash
llm-models anthropic
```

## Usage Examples

### Basic Query

```bash
llm-anthropic-query "What is Ruby programming language?"
```

### Using a Specific Model

```bash
llm-anthropic-query "Explain quantum computing" --model claude-3-5-haiku-20241022
```

### With System Instruction

```bash
llm-anthropic-query "Write a haiku" --system "You are a helpful poetry assistant who specializes in Japanese poetry forms"
```

### Reading from Files

```bash
# Prompt from file
llm-anthropic-query prompt.txt

# System instruction from file
llm-anthropic-query "Analyze this code" --system instructions.md
```

### Output Formatting

```bash
# JSON output
llm-anthropic-query "List 3 programming languages" --format json

# Save to file
llm-anthropic-query "Write a README" --output readme.md

# Markdown format
llm-anthropic-query "Create a tutorial" --format markdown --output tutorial.md
```

### Advanced Options

```bash
# Adjust temperature (0.0-1.0)
llm-anthropic-query "Be creative" --temperature 0.9

# Limit output tokens
llm-anthropic-query "Summarize briefly" --max-tokens 100

# Debug mode for troubleshooting
llm-anthropic-query "Test prompt" --debug
```

## API Client Usage (Ruby)

```ruby
require 'coding_agent_tools'

# Initialize client
client = CodingAgentTools::Organisms::AnthropicClient.new(
  model: "claude-3-5-sonnet-20241022",
  api_key: ENV['ANTHROPIC_API_KEY'] # Optional, uses env by default
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
Error: Anthropic API Error (401): Invalid API key
```
**Solution**: Check that your `ANTHROPIC_API_KEY` environment variable is set correctly.

### Rate Limiting
```
Error: Anthropic API Error (429): Rate limit exceeded
```
**Solution**: Wait a moment before retrying, or contact Anthropic to increase your rate limits.

### Model Not Found
```
Error: Anthropic API Error (404): Model not found
```
**Solution**: Use `llm-models anthropic` to see available models.

### Invalid Request Format
```
Error: Anthropic API Error (400): messages: roles must alternate between "user" and "assistant"
```
**Solution**: This is handled automatically by the client, but ensure you're not manually constructing invalid message sequences.

## Cost Considerations

Anthropic models are priced per token. Approximate costs (as of 2024):

- **Claude 3.5 Sonnet**: ~$3/1M input tokens, ~$15/1M output tokens
- **Claude 3.5 Haiku**: ~$0.25/1M input tokens, ~$1.25/1M output tokens
- **Claude 3 Opus**: ~$15/1M input tokens, ~$75/1M output tokens
- **Claude 3 Sonnet**: ~$3/1M input tokens, ~$15/1M output tokens
- **Claude 3 Haiku**: ~$0.25/1M input tokens, ~$1.25/1M output tokens

Use `--max-tokens` to control costs by limiting output length.

## Best Practices

1. **Model Selection**: 
   - Use Claude 3.5 Haiku for simple, fast tasks
   - Use Claude 3.5 Sonnet for most general-purpose tasks
   - Use Claude 3 Opus only for the most complex reasoning tasks

2. **Temperature**: Use lower values (0.0-0.5) for analytical tasks, higher (0.7-1.0) for creative tasks

3. **System Instructions**: Claude responds well to detailed, specific system instructions

4. **Context Windows**: Claude models have large context windows (up to 200k tokens), making them excellent for long documents

5. **Safety**: Claude has built-in safety features and will refuse harmful requests

## Anthropic-Specific Features

### Constitutional AI
Claude is trained using Constitutional AI, making it more helpful, harmless, and honest by design.

### Long Context
Claude excels at tasks requiring long context, such as:
- Document analysis
- Code review of large files
- Multi-turn conversations
- Research synthesis

### Nuanced Responses
Claude tends to provide more nuanced, thoughtful responses compared to other models, often acknowledging uncertainty or multiple perspectives.

## See Also

- [Anthropic API Documentation](https://docs.anthropic.com/claude/reference)
- [Anthropic Pricing](https://www.anthropic.com/pricing)
- [Claude Model Card](https://www.anthropic.com/claude)
- [Constitutional AI Paper](https://www.anthropic.com/constitutional-ai)