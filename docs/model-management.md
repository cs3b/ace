# Model Management Guide

This comprehensive guide covers the model discovery and management features in Coding Agent Tools v.0.2.0. Learn how to discover available models from Google Gemini and LM Studio services, filter results, and integrate model selection with query commands for seamless LLM interactions.

## Table of Contents

1. [Introduction](#introduction)
2. [Available Commands](#available-commands)
   - [llm-gemini-models](#llm-gemini-models)
   - [llm-lmstudio-models](#llm-lmstudio-models)
3. [Basic Usage](#basic-usage)
   - [Listing Google Gemini Models](#listing-google-gemini-models)
   - [Listing LM Studio Models](#listing-lm-studio-models)
4. [Filtering Models](#filtering-models)
5. [Output Formats](#output-formats)
   - [Text Output (Default)](#text-output-default)
   - [JSON Output](#json-output)
6. [Integration with Query Commands](#integration-with-query-commands)
   - [Using Models with Gemini Queries](#using-models-with-gemini-queries)
   - [Using Models with LM Studio Queries](#using-models-with-lm-studio-queries)
7. [Advanced Usage](#advanced-usage)
   - [Scripting and Automation](#scripting-and-automation)
   - [Model Information Parsing](#model-information-parsing)
8. [Troubleshooting](#troubleshooting)
   - [Connection Issues](#connection-issues)
   - [Empty Results](#empty-results)
   - [Authentication Problems](#authentication-problems)
9. [Cross-References](#cross-references)

---

## Introduction

The model management system in Coding Agent Tools provides a unified interface for discovering and selecting Large Language Models (LLMs) from both cloud-based and local services. This system consists of two primary commands:

- **`llm-gemini-models`**: Discovers available Google Gemini models via the Gemini API
- **`llm-lmstudio-models`**: Discovers available models from your local LM Studio installation

These commands help you identify which models are available, understand their capabilities, and select the appropriate model for your specific use case before making queries.

## Available Commands

### llm-gemini-models

Discovers and lists available Google Gemini AI models from the cloud service.

**Usage:**
```bash
llm-gemini-models [OPTIONS]
```

**Key Features:**
- Fetches live model information from Google's Gemini API
- Supports filtering by model name
- Provides detailed model descriptions
- Shows which model is currently set as default
- Fallback to cached models when API is unavailable

### llm-lmstudio-models

Discovers and lists available models from your local LM Studio installation.

**Usage:**
```bash
llm-lmstudio-models [OPTIONS]
```

**Key Features:**
- Connects to local LM Studio instance (default: localhost:1234)
- Lists currently loaded models
- Shows model availability status
- No authentication required for local usage
- Fallback to cached models when LM Studio is offline

## Basic Usage

### Listing Google Gemini Models

To see all available Gemini models:

```bash
llm-gemini-models
```

**Example Output:**
```
Available Gemini Models:
==================================================

ID: gemini-2.0-flash-lite
Name: Gemini 2.0 Flash Lite
Description: Gemini 2.0 Flash-Lite
Status: Default model

ID: gemini-1.5-flash
Name: Gemini 1.5 Flash
Description: Fast and versatile multimodal model for scaling across diverse tasks

ID: gemini-1.5-pro
Name: Gemini 1.5 Pro
Description: Mid-size multimodal model that supports up to 2 million tokens

Usage: llm-gemini-query "your prompt" --model MODEL_ID
```

### Listing LM Studio Models

To see all available LM Studio models:

```bash
llm-lmstudio-models
```

**Example Output:**
```
Available LM Studio Models:
==================================================

Note: Models must be loaded in LM Studio before use.

ID: mistralai/devstral-small-2505
Name: Devstral Small 2505
Description: LM Studio model
Status: Default model

ID: deepseek/deepseek-r1-0528-qwen3-8b
Name: Deepseek R1 0528 Qwen3 8b
Description: LM Studio model

Usage: llm-lmstudio-query "your prompt" --model MODEL_ID

Server: Ensure LM Studio is running at http://localhost:1234
```

## Filtering Models

Both commands support filtering models by name using the `--filter` (or `-f`) option. The filter performs fuzzy matching against model names and IDs.

### Filtering Gemini Models

```bash
# Find all Flash models
llm-gemini-models --filter flash

# Find Pro models
llm-gemini-models --filter pro

# Find specific version
llm-gemini-models --filter "2.0"
```

### Filtering LM Studio Models

```bash
# Find Mistral models
llm-lmstudio-models --filter mistral

# Find DeepSeek models
llm-lmstudio-models --filter deepseek

# Find models with specific capabilities
llm-lmstudio-models --filter "reasoning"
```

## Output Formats

### Text Output (Default)

The default text format provides human-readable output with model details formatted for easy reading. This format is ideal for interactive use and manual model selection.

Features of text output:
- Clear model identification and descriptions
- Highlights default model
- Includes usage instructions
- Server information for LM Studio

### JSON Output

Use the `--format json` option to get structured JSON output suitable for programmatic processing and automation scripts.

#### Gemini JSON Output

```bash
llm-gemini-models --format json
```

**Example JSON Structure:**
```json
{
  "models": [
    {
      "id": "gemini-2.0-flash-lite",
      "name": "Gemini 2.0 Flash Lite",
      "description": "Gemini 2.0 Flash-Lite",
      "default": true
    },
    {
      "id": "gemini-1.5-flash",
      "name": "Gemini 1.5 Flash",
      "description": "Fast and versatile multimodal model",
      "default": false
    }
  ],
  "count": 2,
  "default_model": "gemini-2.0-flash-lite"
}
```

#### LM Studio JSON Output

```bash
llm-lmstudio-models --format json
```

**Example JSON Structure:**
```json
{
  "models": [
    {
      "id": "mistralai/devstral-small-2505",
      "name": "Devstral Small 2505",
      "description": "LM Studio model",
      "default": true
    }
  ],
  "count": 1,
  "default_model": "mistralai/devstral-small-2505",
  "server_url": "http://localhost:1234"
}
```

## Integration with Query Commands

The primary purpose of model management commands is to help you select appropriate models for use with query commands. Both services provide query commands that accept a `--model` parameter.

### Using Models with Gemini Queries

After discovering available models, use them with the `llm-gemini-query` command:

```bash
# Use default model
llm-gemini-query "Explain quantum computing"

# Use specific model
llm-gemini-query "Write a poem" --model gemini-1.5-pro

# Use latest Flash model for speed
llm-gemini-query "Quick question" --model gemini-1.5-flash
```

### Using Models with LM Studio Queries

Similarly, use discovered models with the `llm-lmstudio-query` command:

```bash
# Use default model
llm-lmstudio-query "Help me debug this code"

# Use specific model for coding tasks
llm-lmstudio-query "Optimize this function" --model mistralai/devstral-small-2505

# Use reasoning model for complex problems
llm-lmstudio-query "Solve this logic puzzle" --model deepseek/deepseek-r1-0528-qwen3-8b
```

## Advanced Usage

### Scripting and Automation

The JSON output format enables powerful scripting and automation scenarios:

#### Extract Default Model

```bash
# Get default Gemini model ID
DEFAULT_MODEL=$(llm-gemini-models --format json | jq -r '.default_model')
echo "Default model: $DEFAULT_MODEL"
```

#### List Models by Capability

```bash
# Find all Flash models and extract IDs
llm-gemini-models --filter flash --format json | jq -r '.models[].id'
```

#### Check Model Availability

```bash
# Check if specific model is available
llm-gemini-models --format json | jq -r '.models[] | select(.id=="gemini-1.5-pro") | .id'
```

### Model Information Parsing

Use the structured JSON output to build model selection logic:

```bash
#!/bin/bash
# Model selection script

# Get all available models
MODELS=$(llm-gemini-models --format json)

# Select fastest model (Flash variants)
FAST_MODEL=$(echo "$MODELS" | jq -r '.models[] | select(.id | contains("flash")) | .id' | head -1)

# Use selected model for query
llm-gemini-query "Quick summary of the news" --model "$FAST_MODEL"
```

## Troubleshooting

### Connection Issues

#### Gemini API Connection Problems

If you encounter connection issues with the Gemini API:

1. **Check Internet Connection**: Ensure you have a stable internet connection
2. **Verify API Key**: Confirm your `GEMINI_API_KEY` environment variable is set correctly
3. **Check API Status**: Visit [Google AI Studio](https://aistudio.google.com/) to verify service status

**Error Example:**
```
Error: Failed to connect to Gemini API
```

**Solution:**
```bash
# Check if API key is set
echo $GEMINI_API_KEY

# Test connection with debug output
llm-gemini-models --debug
```

#### LM Studio Connection Problems

If you encounter connection issues with LM Studio:

1. **Verify LM Studio is Running**: Ensure LM Studio is started and listening on port 1234
2. **Check Port Configuration**: Confirm LM Studio is using the default port (1234)
3. **Test Local Connection**: Verify localhost connectivity

**Error Example:**
```
Error: Cannot connect to LM Studio at localhost:1234
```

**Solution:**
```bash
# Check if LM Studio is running
curl http://localhost:1234/v1/models

# Test with debug output
llm-lmstudio-models --debug
```

### Empty Results

#### No Gemini Models Found

If the command returns no models:

1. **API Key Issues**: Invalid or expired API key
2. **Regional Restrictions**: Some models may not be available in your region
3. **API Limits**: You may have exceeded rate limits

**Debugging Steps:**
```bash
# Test with fallback models
llm-gemini-models --debug

# Check API key permissions
llm-gemini-query "test" --debug
```

#### No LM Studio Models Found

If the command returns no models:

1. **No Models Loaded**: LM Studio has no models currently loaded
2. **Server Not Started**: LM Studio server is not running
3. **Wrong Port**: LM Studio is running on a different port

**Debugging Steps:**
```bash
# Check LM Studio status
curl http://localhost:1234/v1/models

# Load a model in LM Studio interface
# Then retry the command
llm-lmstudio-models
```

### Authentication Problems

#### Gemini API Key Issues

Common authentication problems and solutions:

1. **Missing API Key**:
   ```bash
   export GEMINI_API_KEY="your-api-key-here"
   ```

2. **Invalid API Key Format**:
   - Ensure the key is copied correctly without extra spaces
   - Verify the key is active in Google AI Studio

3. **Permissions Issues**:
   - Check that your API key has the necessary permissions
   - Verify your Google Cloud project settings

#### LM Studio Authentication

LM Studio typically doesn't require authentication for local use, but if you encounter issues:

1. **Check Server Configuration**: Ensure LM Studio server is configured for local access
2. **Firewall Issues**: Verify that port 1234 is not blocked by firewall
3. **Process Conflicts**: Make sure no other process is using port 1234

## Cross-References

For complete setup and usage information, refer to these related guides:

- **[Setup Guide](SETUP.md)**: Initial configuration and API key setup
- **[Gemini Query Guide](llm-integration/gemini-query-guide.md)**: Detailed information about using Gemini models
- **[Main README](../README.md)**: Project overview and quick start
- **[Development Guide](DEVELOPMENT.md)**: Development environment setup and testing

### Related Commands

- **`llm-gemini-query`**: Execute queries using Google Gemini models
- **`llm-lmstudio-query`**: Execute queries using LM Studio models

---

*This guide covers the model management features introduced in v.0.2.0. For the latest updates and additional features, refer to the project's main documentation.*