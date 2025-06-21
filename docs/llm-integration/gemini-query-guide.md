# Gemini Query Guide

This guide provides comprehensive documentation for the `exe/llm-gemini-query` command, which allows users to interact with Google Gemini Large Language Models (LLMs) directly from the command line. It covers setup, usage patterns, advanced options, troubleshooting, and practical examples to help you effectively leverage Gemini LLM integration features. For a general overview of the project, refer to the [main README](../../README.md).

## Table of Contents
1.  [Introduction](#introduction)
2.  [Setup](#setup)
    *   [API Key Configuration](#api-key-configuration)
3.  [Basic Usage](#basic-usage)
    *   [String Prompts](#string-prompts)
    *   [File Prompts](#file-prompts)
4.  [Output Format Options](#output-format-options)
    *   [Text Output (Default)](#text-output-default)
    *   [JSON Output](#json-output)
5.  [Advanced Options](#advanced-options)
    *   [`--model`](#--model)
    *   [`--temperature`](#--temperature)
    *   [`--max-tokens`](#--max-tokens)
    *   [`--system`](#--system)
    *   [`--debug`](#--debug)
6.  [Combined Options Examples](#combined-options-examples)
7.  [Troubleshooting](#troubleshooting)
    *   [API Key Not Configured](#api-key-not-configured)
    *   [Prompt File Not Found](#prompt-file-not-found)
    *   [Common Errors](#common-errors)

---

## Introduction

The `exe/llm-gemini-query` command provides a convenient way to send prompts to Google Gemini models and receive responses directly in your terminal. It's designed for quick queries, scripting, and integrating LLM capabilities into command-line workflows.

## Setup

Before using `llm-gemini-query`, you need to obtain a Google Gemini API key and configure it for your environment.

### API Key Configuration

1.  **Obtain a Gemini API Key:**
    *   Go to the [Google AI Studio](https://aistudio.google.com/app/apikey) website.
    *   Create a new API key or use an existing one. Keep this key secure.

2.  **Configure `.env` file:**
    The `llm-gemini-query` command expects the API key to be available as an environment variable named `GEMINI_API_KEY`. The recommended way to manage this is by using a `.env` file in your project's root directory.

    *   Create a file named `.env` in the root of your project (if one doesn't exist).
    *   Add the following line to your `.env` file, replacing `YOUR_GEMINI_API_KEY` with the actual key you obtained:
        ```/dev/null/example.env#L1
        GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
        ```
    *   Ensure your shell environment is set up to load variables from `.env` files (e.g., by using `direnv` or similar tools, or by sourcing the file manually: `source .env`). Refer to the project's `.env.example` for more details on environment variable management. For general project setup instructions, including environment variable management, refer to the [Project Setup Guide](../SETUP.md).

## Basic Usage

The fundamental usage of `llm-gemini-query` involves providing a prompt, either as a direct string or from a file.

### String Prompts

To query Gemini with a direct string prompt, simply pass the text as an argument:

```/dev/null/example.sh#L1
llm-gemini-query "What is Ruby programming language?"
```

This will send the question to the default Gemini model and print the text response to your terminal.

### File Prompts

For longer prompts or to keep your prompts organized, you can use a file. Create a text file (e.g., `prompt.txt`) containing your prompt, then simply provide the file path as the prompt argument (auto-detected):

**Example `prompt.txt`:**
```/dev/null/prompt.txt#L1-3
Explain the concept of quantum entanglement in simple terms.
Provide a brief summary suitable for a high school student.
```

**Command:**
```/dev/null/example.sh#L1
llm-gemini-query prompt.txt
```

## Output Format Options

You can specify the format of the output from the Gemini model using the `--format` option.

### Text Output (Default)

By default, the command returns the response as plain text. This is suitable for general queries where you only need the model's textual answer.

```/dev/null/example.sh#L1
llm-gemini-query "Who wrote 'Romeo and Juliet'?"
```
_Expected Output (example):_
```/dev/null/output.txt#L1
William Shakespeare.
```

### JSON Output

For structured responses, particularly useful for programmatic processing or when the model is expected to return data, use `--format json`:

```/dev/null/example.sh#L1
llm-gemini-query "Explain quantum computing" --format json
```
_Expected Output (example, truncated):_
```/dev/null/output.json#L1-10
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Quantum computing is a new type of computing that uses the principles of quantum mechanics..."
          }
        ],
        "role": "model"
      },
      "finishReason": "STOP",
      "index": 0
    }
  ],
  "promptFeedback": {
    "safetyRatings": []
  }
}
```

## Advanced Options

`llm-gemini-query` offers several options to fine-tune the model's behavior and the command's execution.

### `--model`

Specifies the Gemini model to use for the query. The default model is `gemini-2.0-flash-lite`. You can specify other available models, such as `gemini-pro`.

```/dev/null/example.sh#L1
llm-gemini-query \"Hello\" --model gemini-2.0-flash-lite
```

**Note:** The availability of specific models like `gemini-pro` can vary by region or API version. To see the list of models supported by your API key and their capabilities, you may need to consult the Google Gemini API documentation or use a programmatic approach to list available models.

### `--temperature`

Controls the randomness of the output. A higher temperature (e.g., 1.0) results in more creative and diverse responses, while a lower temperature (e.g., 0.0) makes the output more deterministic and focused. The valid range is typically 0.0 to 2.0.

```/dev/null/example.sh#L1
llm-gemini-query "Write a short poem about a cat" --temperature 0.8
```

### `--max-tokens`

Sets the maximum number of tokens (words or word pieces) the model should generate in its response. This is useful for controlling the length of the output and managing costs.

```/dev/null/example.sh#L1
llm-gemini-query "Describe the solar system" --max-tokens 100
```

### `--system`

Provides a system instruction or prompt to guide the model's overall behavior or persona. This is useful for setting context that applies to the entire conversation or interaction.

```/dev/null/example.sh#L1
llm-gemini-query "List three benefits of exercise." --system "You are a helpful fitness coach. Respond concisely."
```

### `--debug`

Enables debug output, providing more verbose information, especially useful for troubleshooting issues or understanding the internal workings of the command.

```/dev/null/example.sh#L1
llm-gemini-query long_prompt.txt --format json --debug
```

## Combined Options Examples

You can combine multiple options to achieve specific behaviors.

**Example 1: Specific model, temperature, and JSON output from a file.**
```/dev/null/example.sh#L1
llm-gemini-query research_summary.txt --model gemini-pro --temperature 0.7 --format json
```

**Example 2: Concise creative poem with system instruction and limited length.**
```/dev/null/example.sh#L1
llm-gemini-query "Write a haiku about a rainy day." --system "Be playful and concise." --temperature 0.9 --max-tokens 30
```

## Troubleshooting

This section addresses common issues you might encounter when using `llm-gemini-query`.

### API Key Not Configured

If you receive an error related to authentication or a missing API key, ensure that your `GEMINI_API_KEY` environment variable is correctly set.

*   **Check `.env` file:** Verify that `GEMINI_API_KEY="YOUR_GEMINI_API_KEY"` (with your actual key) is present in your `.env` file.
*   **Load environment variables:** Make sure your shell loads the `.env` file. If not using a tool like `direnv`, you might need to manually source it: `source .env`.
*   **Validate the key:** Double-check that the API key itself is correct and has the necessary permissions in Google AI Studio.

### Prompt File Not Found

If you provide a file path and the command reports that the file was not found, it will treat the path as inline text. To ensure a file is read:

*   **Verify path:** Ensure the file path you provided is correct and that the file exists at that location relative to where you are running the command.
*   **Current Directory:** Confirm you are running the command from the correct directory or provide an absolute path to the prompt file.

### Common Errors

*   **Network Issues:** If you experience connection timeouts or failures, check your internet connection and ensure that Google's Gemini API endpoints are accessible from your network.
*   **Model Rate Limits:** If you make too many requests in a short period, you might hit API rate limits. The command should ideally handle retries, but if issues persist, pause and try again later. Refer to Google Gemini API documentation for current rate limits.
*   **Invalid Arguments:** If you encounter errors about invalid options or values, review the `--help` output of `llm-gemini-query` to ensure you are using the correct flags and value formats (e.g., temperature range).