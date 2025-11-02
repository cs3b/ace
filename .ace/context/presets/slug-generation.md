---
description: Project context for LLM-based slug generation
context:
  presets:
    - project-base  # Includes project structure and components dynamically
  params:
    output: cache
    format: markdown
    max_size: 102400
    timeout: 30
---

# Slug Generation Context

This preset loads project-specific context for the LLM slug generator in ace-taskflow.

## How It Works

1. **Project Context**: Loaded dynamically from `project-base` preset
   - Project structure and components
   - Architecture and terminology
   - Common patterns and conventions

2. **LLM Processing**: The generator combines this context with task/idea details
   - Understands the specific project context
   - Produces project-appropriate slugs
   - Uses hierarchical structure (folder + file slugs)

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