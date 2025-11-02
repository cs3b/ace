---
description: Context aggregation for LLM-based slug generation
context:
  presets:
    - project-base  # Includes project structure and components dynamically
  params:
    output: cache
    format: markdown
    max_size: 102400
    timeout: 30
  files:
    # Include the slug generation rules/prompt
    - ace-taskflow/handbook/prompts/slug-generation.md
  embed_document_source: false
---

# Slug Generation Context

This preset aggregates project-specific context with slug generation rules for use by the LLM slug generator in ace-taskflow.

## How It Works

1. **Project Context**: Loaded dynamically from `project-base` preset
   - Project structure and components
   - Architecture and terminology
   - Common patterns and conventions

2. **Slug Rules**: Loaded from `handbook/prompts/slug-generation.md`
   - Generic formatting rules
   - Goal type definitions
   - Response format specification

3. **Combined Output**: Sent to LLM for intelligent slug generation
   - LLM understands the specific project context
   - Applies consistent slug generation rules
   - Produces project-appropriate slugs

## Usage

This preset is automatically loaded by `ace-taskflow` when generating slugs with LLM support:

```bash
ace-taskflow task create --llm "task title"
ace-taskflow idea create --llm "idea description"
```

The preset can be tested manually:

```bash
ace-context slug-generation
```