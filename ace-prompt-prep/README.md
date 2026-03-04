# ace-prompt-prep

Prompt workspace with automatic archiving and history management.

## Base36 Compact ID Format

**New in v0.9.0**: ace-prompt-prep now uses 6-character Base36 compact IDs for archived prompts (e.g., `i50jj3.md`) instead of 14-character timestamps (e.g., `20251129-143000.md`).

### Key Features

- **Compact**: 6 characters vs 14 characters (57% shorter)
- **Sortable**: String sorting equals chronological sorting
- **Precision**: ~1.85 seconds per increment (sufficient for prompt archiving)
- **Coverage**: 108 years from configured year_zero (default: 2000)

### What Changed

- Archive filenames changed from `YYYYMMDD-HHMMSS.md` to `BASE36ID.md`
- Example: `20251129-143000.md` → `i50jj3.md`
- Existing archives with timestamp format remain accessible as regular files (no migration needed)
- `_previous.md` symlink now points to Base36-formatted archives

### Precision Notes

The Base36 format has approximately **1.85 seconds of precision**:
- Two prompts archived within ~1.85 seconds may share the same ID
- The system appends a counter (e.g., `i50jj3-1.md`, `i50jj3-2.md`) to handle collisions
- This precision is intentional for compactness

For more details on the encoding scheme, see the [ace-b36ts README](https://github.com/cs3b/ace-meta/tree/main/ace-b36ts).

## Quick Start

```bash
# Create a prompt
mkdir -p .ace-local/ace-prompt-prep/prompts
echo "Review this code for security issues" > .ace-local/ace-prompt-prep/prompts/the-prompt.md

# Process it (archives and outputs to stdout)
ace-prompt-prep

# Output to file
ace-prompt-prep --output /tmp/prompt.md
```

## LLM Enhancement

ace-prompt-prep can enhance your prompts using LLM before output. This helps improve prompt quality by adding clarity, structure, and detail.

### Enable Enhancement

```bash
# Enhance prompt via LLM (uses default model: glite)
ace-prompt-prep --enhance

# Use short flag
ace-prompt-prep -e

# Specify a different model
ace-prompt-prep --enhance --model claude

# Use a custom system prompt
ace-prompt-prep --enhance --system-prompt /path/to/system-prompt.md

# Combine with output file
ace-prompt-prep --enhance --output /tmp/enhanced-prompt.md
```

### Configuration

Configure default enhancement behavior in `.ace/prompt-prep/config.yml`:

```yaml
enhance:
  enabled: false           # Default: disabled
  model: glite             # Model alias (glite, claude, haiku) or provider:model
  temperature: 0.3         # LLM temperature for generation
  system_prompt: prompt://prompt-enhance-instructions.system  # System prompt URI
```

### Migration from ace-prep (v0.15.x → v0.16.0)

If you were previously using `ace-prep`, update your configurations:

1. **Rename config directory**:
   ```bash
   mv .ace/prep .ace/prompt-prep
   ```

2. **Update cache references** (optional - old cache will be orphaned):
   ```bash
   # In your scripts or code
   .ace-local/ace-prep  # Old
   .ace-local/ace-prompt-prep  # New
   ```

3. **Update command references**:
   ```bash
   ace-prep    # Old
   ace-prompt-prep      # New
   ```

4. **Update require statements**:
   ```ruby
   require 'ace/prep'       # Old
   require 'ace/prompt_prep'  # New
   ```

1. Reads your prompt from `the-prompt.md`
2. Archives the original prompt with Base36 compact ID
3. Sends to LLM with enhancement system prompt
4. Archives enhanced version with `_eNNN` suffix (e.g., `i50jj3_e001.md`)
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

ace-prompt-prep supports automatic context loading via [ace-bundle](https://github.com/your-org/ace-bundle). This allows prompts to automatically include relevant project context.

### Enable Context Loading

```bash
# Enable context for a single run
ace-prompt-prep --context

# Disable context when enabled by config
ace-prompt-prep --no-context

# Use short flag
ace-prompt-prep -c
```

### Prompt with Context Configuration

Create prompts with YAML frontmatter to control context loading:

```markdown
---
bundle:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - preset: "project-overview"
    - command: "git status --short"
---

Please review this code for security issues, considering the project architecture and current git status.
```

### Configuration File

Configure default context behavior in `.ace/prompt-prep/config.yml`:

```yaml
bundle:
  enabled: true  # Default: false
  sources:
    - file: "docs/vision.md"
    - preset: "project-context"
```

### Context Loading Examples

```bash
# Create a prompt with frontmatter
cat > .ace-local/ace-prompt-prep/prompts/feature-review.md << 'EOF'
---
bundle:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - preset: "coding-standards"
---

Review this new feature for adherence to our architecture and coding standards.
EOF

# Process with automatic context expansion
ace-prompt-prep --context

# The output will include:
# 1. The original prompt content
# 2. Content from docs/architecture.md
# 3. Project coding standards from the preset
# 4. Properly formatted context section
```

### Template Usage Scenarios

ace-prompt-prep works well with different prompt templates:

#### Bug Report Template
```markdown
---
bundle:
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
bundle:
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

ace-prompt-prep integrates with [ace-taskflow](https://github.com/your-org/ace-taskflow) to manage prompts per task. This keeps your prompts organized alongside task documentation.

### Using Task-Specific Prompts

```bash
# Use prompts from a specific task directory
ace-prompt-prep --task 121

# Works with subtask IDs
ace-prompt-prep --task 121.01

# Works with qualified task references
ace-prompt-prep --task v.0.9.0+task.121

# Setup a new prompt in task directory
ace-prompt-prep setup --task 117
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
# .ace/prompt-prep/config.yml
task:
  detection: true
```

With this enabled, if your branch is named `121-feature-name`, ace-prompt-prep automatically uses the prompts directory for task 121. No `--task` flag needed.

```bash
# On branch 121.06-task-folder-support
ace-prompt-prep  # Automatically uses task 121 prompts
```

### Task Resolution

Task IDs are resolved using ace-taskflow's API, which means:
- Tasks in `tasks/`, `tasks/maybe/`, and `tasks/done/` are all found
- Subtasks (e.g., `121.01`) fall back to parent task directory if needed
- Full qualified references (e.g., `v.0.9.0+task.121`) are supported

## What It Does

1. Reads `.ace-local/ace-prompt-prep/prompts/the-prompt.md` (or task-specific directory)
2. Archives it to `archive/BASE36ID.md` (e.g., `i50jj3.md`)
3. Updates `_previous.md` symlink
4. Outputs content to stdout (or file with `--output`)

## Installation

Add to your Gemfile:

```ruby
gem 'ace-prompt-prep'
```

## Usage

See the examples above for basic usage. For detailed documentation, see [docs/usage.md](docs/usage.md).

## Development

Run tests:

```bash
cd ace-prompt-prep
ace-test
```

Build gem:

```bash
gem build ace-prompt-prep.gemspec
```

## License

MIT
