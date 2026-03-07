# ace-compressor

Compresses Markdown and text files into compact `ContextPack/3` records for LLM consumption.

## Quick Start

```bash
# Single file
ace-compressor docs/vision.md --mode exact

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
