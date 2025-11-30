# ace-prompt

Prompt workspace with automatic archiving and history management.

## Quick Start

```bash
# Create a prompt
mkdir -p .cache/ace-prompt/prompts
echo "Review this code for security issues" > .cache/ace-prompt/prompts/the-prompt.md

# Process it (archives and outputs to stdout)
ace-prompt

# Output to file
ace-prompt --output /tmp/prompt.md
```

## LLM Enhancement

ace-prompt can enhance your prompts using LLM before output. This helps improve prompt quality by adding clarity, structure, and detail.

### Enable Enhancement

```bash
# Enhance prompt via LLM (uses default model: glite)
ace-prompt --enhance

# Use short flag
ace-prompt -e

# Specify a different model
ace-prompt --enhance --model claude

# Use a custom system prompt
ace-prompt --enhance --system-prompt /path/to/system-prompt.md

# Combine with output file
ace-prompt --enhance --output /tmp/enhanced-prompt.md
```

### Configuration

Configure default enhancement behavior in `.ace/prompt/config.yml`:

```yaml
enhance:
  enabled: false           # Default: disabled
  model: glite             # Model alias (glite, claude, haiku) or provider:model
  temperature: 0.3         # LLM temperature for generation
  system_prompt: prompt://prompt-enhance-instructions.system  # System prompt URI
```

### How It Works

1. Reads your prompt from `the-prompt.md`
2. Archives the original prompt with timestamp
3. Sends to LLM with enhancement system prompt
4. Archives enhanced version with `_eNNN` suffix (e.g., `20251129-143000_e001.md`)
5. Updates `_previous.md` symlink to point to enhanced version
6. Outputs enhanced content

### Caching

Enhanced prompts are cached based on:
- Original content
- Model used
- System prompt URI
- Temperature setting

Identical requests return cached results for faster iteration.

## Context Integration

ace-prompt supports automatic context loading via [ace-context](https://github.com/your-org/ace-context). This allows prompts to automatically include relevant project context.

### Enable Context Loading

```bash
# Enable context for a single run
ace-prompt --context

# Disable context when enabled by config
ace-prompt --no-context

# Use short flag
ace-prompt -c
```

### Prompt with Context Configuration

Create prompts with YAML frontmatter to control context loading:

```markdown
---
context:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - preset: "project-overview"
    - command: "git status --short"
---

Please review this code for security issues, considering the project architecture and current git status.
```

### Configuration File

Configure default context behavior in `.ace/prompt/config.yml`:

```yaml
context:
  enabled: true  # Default: false
  sources:
    - file: "docs/what-do-we-build.md"
    - preset: "project-context"
```

### Context Loading Examples

```bash
# Create a prompt with frontmatter
cat > .cache/ace-prompt/prompts/feature-review.md << 'EOF'
---
context:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - preset: "coding-standards"
---

Review this new feature for adherence to our architecture and coding standards.
EOF

# Process with automatic context expansion
ace-prompt --context

# The output will include:
# 1. The original prompt content
# 2. Content from docs/architecture.md
# 3. Project coding standards from the preset
# 4. Properly formatted context section
```

### Template Usage Scenarios

ace-prompt works well with different prompt templates:

#### Bug Report Template
```markdown
---
context:
  enabled: true
  sources:
    - file: "CHANGELOG.md"
    - command: "git log --oneline -5"
---

# Bug Report

**Issue**: [Describe the bug]

**Steps to Reproduce**:
1.
2.
3.

**Expected Behavior**: [What should happen]

**Actual Behavior**: [What actually happens]

Please analyze this bug considering the recent changes and project history.
```

#### Feature Request Template
```markdown
---
context:
  enabled: true
  sources:
    - file: "docs/roadmap.md"
    - preset: "project-goals"
    - command: "git tag --sort=-version:refname | head -5"
---

# Feature Request

**Proposal**: [Describe the feature]

**Use Case**: [Why is this needed?]

**Implementation Ideas**: [How might this be implemented?]

Please evaluate this feature request against our project goals and current roadmap.
```

## Task-Specific Prompts

ace-prompt integrates with [ace-taskflow](https://github.com/your-org/ace-taskflow) to manage prompts per task. This keeps your prompts organized alongside task documentation.

### Using Task-Specific Prompts

```bash
# Use prompts from a specific task directory
ace-prompt --task 121

# Works with subtask IDs
ace-prompt --task 121.01

# Works with qualified task references
ace-prompt --task v.0.9.0+task.121

# Setup a new prompt in task directory
ace-prompt setup --task 117
```

When using `--task`, prompts are stored in:
```
.ace-taskflow/v.X.Y.Z/tasks/{task-id}-{name}/prompts/
├── the-prompt.md      # Active prompt
├── _previous.md       # Symlink to last archived
└── archive/           # Archived prompts
```

### Auto-Detection from Git Branch

Enable automatic task detection based on your current git branch:

```yaml
# .ace/prompt/config.yml
task:
  detection: true
```

With this enabled, if your branch is named `121-feature-name`, ace-prompt automatically uses the prompts directory for task 121. No `--task` flag needed.

```bash
# On branch 121.06-task-folder-support
ace-prompt  # Automatically uses task 121 prompts
```

### Task Resolution

Task IDs are resolved using ace-taskflow's API, which means:
- Tasks in `tasks/`, `tasks/maybe/`, and `tasks/done/` are all found
- Subtasks (e.g., `121.01`) fall back to parent task directory if needed
- Full qualified references (e.g., `v.0.9.0+task.121`) are supported

## What It Does

1. Reads `.cache/ace-prompt/prompts/the-prompt.md` (or task-specific directory)
2. Archives it to `archive/YYYYMMDD-HHMMSS.md`
3. Updates `_previous.md` symlink
4. Outputs content to stdout (or file with `--output`)

## Installation

Add to your Gemfile:

```ruby
gem 'ace-prompt'
```

## Usage

See the examples above for basic usage. For detailed documentation, see [docs/usage.md](docs/usage.md).

## Development

Run tests:

```bash
cd ace-prompt
ace-test
```

Build gem:

```bash
gem build ace-prompt.gemspec
```

## License

MIT
