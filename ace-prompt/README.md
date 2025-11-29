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

## What It Does

1. Reads `.cache/ace-prompt/prompts/the-prompt.md`
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
