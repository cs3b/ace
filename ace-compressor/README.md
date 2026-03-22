# ace-compressor

Compresses Markdown and text files into compact `ContextPack/3` records for LLM consumption.

## Purpose

`ContextPack/3` preserves source structure in a compact record format so agent workflows can load
reliable context with less token overhead.

## Installation

Add to your `Gemfile`:

```ruby
gem "ace-compressor"
```

Or install directly:

```bash
gem install ace-compressor
```

## Quick Start

```bash
# Single file
ace-compressor docs/vision.md --mode exact

# Compact narrative-heavy docs with policy metadata
ace-compressor docs/vision.md --mode compact --format stdio

# Directory
ace-compressor docs/ --mode exact

# Multiple files
ace-compressor docs/vision.md docs/architecture.md --mode exact

# Print content instead of cache path
ace-compressor docs/vision.md --format stdio

# Save to a specific file
ace-compressor docs/vision.md --output /tmp/vision.pack
```

## Documentation

See [docs/usage.md](docs/usage.md) for the full usage guide: output format, scenarios, error
conditions, configuration, and troubleshooting.

Part of [ACE](../README.md) - Modular CLI toolkit for AI-assisted development.
