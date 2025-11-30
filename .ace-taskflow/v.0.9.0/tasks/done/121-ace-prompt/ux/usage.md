# ace-prompt Usage Guide

> **Status**: This guide evolves with each subtask. Sections marked [TODO] will be completed as features are implemented.

## Overview

`ace-prompt` provides a **Prompt Workspace** - a single active prompt file with automatic history. Write prompts in your editor, run `ace-prompt`, get automatic archiving with optional context loading and LLM enhancement.

**Concept**: One active workspace per project (or per task). Archive = history preservation, not a queue.

## Quick Start

```bash
# Setup (121.02)
ace-prompt setup

# Edit prompt
vim .cache/ace-prompt/prompts/the-prompt.md

# Process (121.01)
ace-prompt
```

---

## Basic Usage (121.01)

### Read, Archive, Output

```bash
# Default: read, archive, output to stdout
ace-prompt

# Output to file
ace-prompt --output /path/to/file.md

# Explicit stdout
ace-prompt --output -
```

### File Structure

```
.cache/ace-prompt/prompts/
├── the-prompt.md         # Your active prompt
├── _previous.md          # Symlink to last archived
└── archive/
    └── YYYYMMDD-HHMMSS.md
```

### Example

```bash
# Create prompt
echo "Review this code for security issues" > .cache/ace-prompt/prompts/the-prompt.md

# Process
ace-prompt
# Output: Review this code for security issues

# Check archive
ls .cache/ace-prompt/prompts/archive/
# Output: 20251127-143022.md
```

---

## Setup & Reset (121.02)

[TODO: Add after 121.02 implementation]

```bash
# Initialize with template
ace-prompt setup

# Custom template
ace-prompt setup --template tmpl://custom/template

# Reset to template
ace-prompt reset

# Force reset (no archive)
ace-prompt reset --force
```

---

## Context Loading (121.03)

[TODO: Add after 121.03 implementation]

```bash
# Enable context loading
ace-prompt --context
ace-prompt -c

# Disable context loading (if enabled in config)
ace-prompt --no-context
```

### Frontmatter Format

```yaml
---
context:
  files:
    - path/to/file.rb
  commands:
    - git diff HEAD~1
  presets:
    - project
---
[Your prompt here]
```

---

## Enhancement (121.04)

[TODO: Add after 121.04 implementation]

```bash
# Enable LLM enhancement
ace-prompt --enhance
ace-prompt -e

# Disable enhancement (if enabled in config)
ace-prompt --no-enhance

# Combine context + enhance
ace-prompt -ce
```

---

## System Prompt Customization (121.05)

[TODO: Add after 121.05 implementation]

---

## Task Support (121.06)

[TODO: Add after 121.06 implementation]

```bash
# Use task-specific prompt folder
ace-prompt --task 117
ace-prompt -t 117
```

---

## Configuration

```yaml
# .ace/prompt/config.yml
prompt:
  # File locations (non-flaggable)
  default-dir: .cache/ace-prompt/prompts
  default-file: the-prompt.md
  archive-subdir: archive
  template: tmpl://ace-prompt/base-prompt

  # Flaggable params (CLI flags override these)
  params:
    context: false              # --context / --no-context
    enhance: false              # --enhance / --no-enhance
    model: glite                # --model (alias for google:gemini-2.0-flash-lite)
    temperature: 0.3            # --temperature
    system-prompt: prompt://prompt-enhance-instructions  # --system-prompt
    task-detection: false       # --task / auto-detect from branch
```

---

## Changelog

- **121.01**: Basic archive + output
- **121.02**: Setup & reset commands
- **121.03**: ace-context integration
- **121.04**: LLM enhancement
- **121.05**: System prompt frontmatter
- **121.06**: Task-id folder support
