# LLM Providers Overview

The Coding Agent Tools gem supports multiple LLM (Large Language Model) providers, allowing you to choose the best model for your specific use case. This document provides an overview of all supported providers.

## Supported Providers

### 1. Google Gemini
- **Command**: `llm-gemini-query`
- **Models**: Gemini 2.0 Flash Lite, Gemini 1.5 Flash, Gemini 1.5 Pro
- **Key**: `GEMINI_API_KEY`
- **Best for**: General-purpose tasks, multimodal capabilities
- **Documentation**: [Gemini Integration Guide](./gemini.md)

### 2. LM Studio
- **Command**: `llm-lmstudio-query`
- **Models**: Any locally loaded model
- **Key**: Not required (local)
- **Best for**: Privacy-sensitive tasks, offline usage
- **Documentation**: [LM Studio Integration Guide](./lmstudio.md)

### 3. OpenAI
- **Command**: `llm-openai-query`
- **Models**: GPT-4o, GPT-4o-mini, GPT-4 Turbo, GPT-3.5 Turbo
- **Key**: `OPENAI_API_KEY`
- **Best for**: Advanced reasoning, code generation, general tasks
- **Documentation**: [OpenAI Integration Guide](./providers/openai.md)

### 4. Anthropic (Claude)
- **Command**: `llm-anthropic-query`
- **Models**: Claude 3.5 Sonnet, Claude 3.5 Haiku, Claude 3 Opus/Sonnet/Haiku
- **Key**: `ANTHROPIC_API_KEY`
- **Best for**: Long context tasks, nuanced responses, safety
- **Documentation**: [Anthropic Integration Guide](./providers/anthropic.md)

### 5. Mistral AI
- **Command**: `llm-mistral-query`
- **Models**: Mistral Large/Medium/Small, Mistral 8x7B/8x22B
- **Key**: `MISTRAL_API_KEY`
- **Strengths**: Open-source options, multilingual, code generation
- **Documentation**: [Mistral Integration Guide](./providers/mistral.md)

### 6. Together AI
- **Command**: `llm-together-ai-query`
- **Models**: Llama 3.1, Mistral, DeepSeek, and many more open-source models
- **Key**: `TOGETHER_API_KEY`
- **Best for**: Open-source models, fast inference, cost-effectiveness
- **Documentation**: [Together AI Integration Guide](./providers/together-ai.md)

## Quick Start

### 1. Set up your API key
```bash
export PROVIDER_API_KEY="your-api-key-here"
```

### 2. List available models
```bash
llm-models provider_name
```

### 3. Make a query
```bash
llm-provider-query "Your prompt here"
```

## Common Features

All providers support the following features:

- **File input**: Read prompts from files
- **System instructions**: Set context with `--system`
- **Output formatting**: JSON, Markdown, or plain text with `--format`
- **File output**: Save responses with `--output`
- **Model selection**: Choose specific models with `--model`
- **Temperature control**: Adjust creativity with `--temperature`
- **Token limits**: Control output length with `--max-tokens`
- **Debug mode**: Troubleshoot with `--debug`

## Choosing a Provider

### By Use Case

| Use Case | Recommended Providers |
|----------|----------------------|
| General chat/assistance | OpenAI (GPT-4o), Anthropic (Claude 3.5 Sonnet) |
| Code generation | OpenAI (GPT-4o), Mistral, Together AI (DeepSeek) |
| Long documents | Anthropic (Claude - 200k context) |
| Budget-conscious | Together AI, OpenAI (GPT-3.5 Turbo) |
| Privacy/offline | LM Studio |
| Multilingual | Mistral AI, Gemini |
| Creative writing | Anthropic (Claude), OpenAI with high temperature |

### By Cost (Approximate)

| Provider | Model | Input Cost | Output Cost |
|----------|-------|------------|-------------|
| OpenAI | GPT-3.5 Turbo | $0.50/1M | $1.50/1M |
| OpenAI | GPT-4o-mini | $0.15/1M | $0.60/1M |
| OpenAI | GPT-4o | $5/1M | $15/1M |
| Anthropic | Claude 3 Haiku | $0.25/1M | $1.25/1M |
| Anthropic | Claude 3.5 Sonnet | $3/1M | $15/1M |
| Mistral | Small | $0.20/1M | $0.60/1M |
| Mistral | Large | $4/1M | $12/1M |
| Together AI | Llama 3.1 8B | $0.18/1M | $0.18/1M |
| Together AI | Llama 3.1 70B | $0.88/1M | $0.88/1M |
| LM Studio | Any | Free | Free |

### By Speed

1. **Fastest**: LM Studio (local), Mistral Small, GPT-3.5 Turbo
2. **Fast**: Claude 3 Haiku, GPT-4o-mini, Together AI Turbo models
3. **Moderate**: Claude 3.5 Sonnet, GPT-4o, Mistral Large
4. **Slower**: Claude 3 Opus, GPT-4 Turbo

## Unified Models Command

The `llm-models` command works with all providers:

```bash
# List all Google Gemini models
llm-models google

# List all OpenAI models
llm-models openai

# List all Anthropic models
llm-models anthropic

# Filter models by name
llm-models openai --filter gpt-4

# Get JSON output
llm-models anthropic --format json
```

## Environment Setup

### Using .env file

Create a `.env` file in your project root:

```env
GEMINI_API_KEY=your-gemini-key
OPENAI_API_KEY=your-openai-key
ANTHROPIC_API_KEY=your-anthropic-key
MISTRAL_API_KEY=your-mistral-key
TOGETHER_API_KEY=your-together-key
```

### Using shell exports

Add to your shell configuration file (`.bashrc`, `.zshrc`, etc.):

```bash
export GEMINI_API_KEY="your-gemini-key"
export OPENAI_API_KEY="your-openai-key"
export ANTHROPIC_API_KEY="your-anthropic-key"
export MISTRAL_API_KEY="your-mistral-key"
export TOGETHER_API_KEY="your-together-key"
```

## Advanced Usage

### Comparing Providers

Test the same prompt across multiple providers:

```bash
# Create a test prompt
echo "Explain the concept of recursion in programming" > prompt.txt

# Test with different providers
llm-openai-query prompt.txt --output openai-response.md
llm-anthropic-query prompt.txt --output anthropic-response.md
llm-mistral-query prompt.txt --output mistral-response.md
```

### Provider-Specific Features

Some providers have unique capabilities:

- **Gemini**: Multimodal support (images, etc.)
- **Anthropic**: Constitutional AI, very large context windows
- **Together AI**: Access to many open-source models
- **LM Studio**: Complete privacy, offline usage

## Troubleshooting

### Common Issues

1. **API Key Not Found**
   - Ensure the environment variable is set correctly
   - Check for typos in the variable name
   - Restart your terminal after setting the variable

2. **Rate Limiting**
   - Wait a few moments before retrying
   - Consider upgrading your plan
   - Use a different provider temporarily

3. **Model Not Available**
   - Run `llm-models provider_name` to see available models
   - Check if the model name has changed
   - Ensure your API key has access to the model

### Debug Mode

Use the `--debug` flag with any provider to see detailed error information:

```bash
llm-openai-query "test" --debug
```

## See Also

- [Architecture Overview](../../architecture.md)
- [CLI Command Reference](../cli-reference.md)
- [Ruby API Documentation](../ruby-api.md)