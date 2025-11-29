# ace-prompt Usage

Prompt workspace management with template support and archiving.

## Quick Start

```bash
# Initialize prompt workspace (v0.2.0)
ace-prompt setup

# Process prompt: archive and output (v0.1.0)
ace-prompt
```

## Commands

### setup (v0.2.0)

Initialize or reset prompt workspace with a template.

```bash
ace-prompt setup                    # Default template, archives existing
ace-prompt setup --template bug     # Short form: tmpl://ace-prompt/the-prompt-bug
ace-prompt setup --no-archive       # Skip archiving existing prompt
ace-prompt setup --force            # Alias for --no-archive
```

**Behavior:**
- Creates `{project_root}/.cache/ace-prompt/prompts/the-prompt.md`
- Archives existing prompt by default (to `archive/the-prompt-YYYYMMDD-HHMMSS.md`)
- Resolves templates via ace-nav `tmpl://` protocol

### process (v0.1.0)

Read prompt, archive it, and output content.

```bash
ace-prompt                          # Output to stdout (default command)
ace-prompt process                  # Explicit process command
ace-prompt -o /tmp/prompt.md        # Output to file
```

**Behavior:**
- Reads `the-prompt.md` from prompt directory
- Archives with timestamp
- Updates `_previous.md` symlink
- Outputs content to stdout or file

### version

```bash
ace-prompt version
ace-prompt -v
```

## File Locations

All files relative to project root:

```
{project_root}/.cache/ace-prompt/prompts/
├── the-prompt.md           # Active prompt
├── _previous.md            # Symlink to latest archive
└── archive/
    └── the-prompt-YYYYMMDD-HHMMSS.md
```

## Templates

**Default:** `tmpl://the-prompt-base`

**Short form:** `--template bug` resolves to `tmpl://the-prompt-bug`

**Full URI:** `--template tmpl://the-prompt-bug`

## Configuration

Configuration follows the ace-* gem pattern using ace-core config cascade.

**Config path:** `.ace/prompt/config.yml`

**Cascade:** `{project}/.ace/prompt/config.yml` → `~/.ace/prompt/config.yml`

### Options

```yaml
# .ace/prompt/config.yml
context:
  enabled: false  # Enable context loading via ace-context
  sources:
    - file: "docs/what-do-we-build.md"  # Default sources when enabled
    - preset: "project-overview"
```

### Context Loading

When context loading is enabled, ace-prompt integrates with [ace-context](https://github.com/your-org/ace-context) to automatically expand prompts with relevant project information.

**How it works:**
1. Parse YAML frontmatter in the prompt file
2. Look for `context:` block with sources configuration
3. Load context via ace-context (handles actual file reading and formatting)
4. Prepend formatted context to output before the original prompt content

**CLI Flag Precedence:**
The precedence order for context loading is:
1. **CLI flags** (`--context` / `--no-context`) - highest priority
2. **Project config** (`.ace/prompt/config.yml`)
3. **Frontmatter context block** in the prompt file
4. **Default behavior** (context disabled) - lowest priority

**CLI overrides:**

```bash
ace-prompt --context      # Enable context loading (overrides config)
ace-prompt --no-context   # Disable context loading (overrides config and frontmatter)
ace-prompt -c             # Short flag for --context
ace-prompt                # Uses config file or frontmatter settings
```

**Context Configuration Sources:**

```yaml
---
context:
  enabled: true
  sources:
    # Load specific files
    - file: "docs/architecture.md"
    - file: "README.md"

    # Use ace-context presets
    - preset: "project-overview"
    - preset: "coding-standards"

    # Run commands and include output
    - command: "git status --short"
    - command: "git log --oneline -5"

    # Mix different source types
    - file: "CHANGELOG.md"
    - preset: "project-goals"
    - command: "git tag --sort=-version:refname | head -3"
---

Your prompt content here...
```

**Context Loading Scenarios:**

#### Scenario 1: Configuration File Default
```yaml
# .ace/prompt/config.yml
context:
  enabled: true
  sources:
    - file: "docs/what-do-we-build.md"
    - preset: "project-context"
```
```bash
ace-prompt  # Uses config file settings
```

#### Scenario 2: Frontmatter Override
```markdown
---
context:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - command: "git log --oneline -3"
---
```
```bash
ace-prompt  # Uses frontmatter (overrides config)
```

#### Scenario 3: CLI Override
```bash
ace-prompt --context  # Force enable (ignores config/frontmatter)
ace-prompt --no-context  # Force disable (ignores everything)
```

#### Scenario 4: Complex Context
```markdown
---
context:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - preset: "coding-standards"
    - command: "git diff --name-only HEAD~5"
    - command: "find . -name '*.rb' | head -10"
---

Review this code change considering our architecture, standards, recent changes, and affected files.
```

**Note**: The actual context loading and formatting is performed by the ace-context gem. ace-prompt only handles the orchestration and integration.

## Exit Codes

- `0` - Success
- `1` - Error
