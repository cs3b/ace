# Minimal Context Example

A simple example showing the minimal required configuration for the enhanced context tool.

## Basic Configuration

<context-tool-config>
files:
  - README.md

format: markdown-xml
</context-tool-config>

## Usage

```bash
# Minimal usage with auto-detection
context docs/context/minimal-example.md
```

This demonstrates the simplest possible configuration:
- Only one file included
- Default format (markdown-xml)
- No embedding (embed_document_source defaults to false)
- No commands executed

Perfect for testing or when you need a quick context load of just one file.