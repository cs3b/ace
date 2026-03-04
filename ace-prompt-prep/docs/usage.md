# ace-prompt-prep Usage

Prompt workspace management with template support and archiving.

## Quick Start

```bash
# Initialize prompt workspace (v0.2.0)
ace-prompt-prep setup

# Process prompt: archive and output (v0.1.0)
ace-prompt-prep
```

## Commands

### setup (v0.2.0)

Initialize or reset prompt workspace with a template.

```bash
ace-prompt-prep setup                    # Default template, archives existing
ace-prompt-prep setup --template bug     # Short form: tmpl://ace-prompt-prep/the-prompt-bug
ace-prompt-prep setup --no-archive       # Skip archiving existing prompt
ace-prompt-prep setup --force            # Alias for --no-archive
```

**Behavior:**
- Creates `{project_root}/.ace-local/prompt-prep/prompts/the-prompt.md`
- Archives existing prompt by default (to `archive/{base36_id}.md`)
- Resolves templates via ace-nav `tmpl://` protocol

### process (v0.1.0)

Read prompt, archive it, and output content.

```bash
ace-prompt-prep                          # Output to stdout (default command)
ace-prompt-prep process                  # Explicit process command
ace-prompt-prep -o /tmp/prompt.md        # Output to file
```

**Behavior:**
- Reads `the-prompt.md` from prompt directory
- Archives with Base36 session ID (6-character compact ID)
- Updates `_previous.md` symlink
- Outputs content to stdout or file

### Enhancement Options (v0.3.0)

Enhance prompts via LLM before output:

```bash
ace-prompt-prep --enhance                # Enhance with default model (glite)
ace-prompt-prep -e                       # Short flag
ace-prompt-prep -e --model claude        # Use specific model
ace-prompt-prep -e --model google:gemini-2.0-flash  # Use provider:model format
ace-prompt-prep -e --system-prompt /path/to/prompt.md  # Custom system prompt
```

**Enhancement Behavior:**
- Archives original prompt first
- Sends to LLM with enhancement system prompt
- Archives enhanced version with `_eNNN` suffix
- Updates symlink to point to enhanced version
- Outputs enhanced content

**Supported Models:**
- `glite` - Google Gemini 2.0 Flash Lite (default, fast)
- `claude` - Anthropic Claude Sonnet 4
- `haiku` - Anthropic Claude 3 Haiku
- Or use full `provider:model` format (e.g., `google:gemini-pro`)

### version

```bash
ace-prompt-prep version
ace-prompt-prep -v
```

## File Locations

All files relative to project root:

```
{project_root}/.ace-local/prompt-prep/prompts/
├── the-prompt.md           # Active prompt
├── _previous.md            # Symlink to latest archive
└── archive/
    └── {base36_id}.md      # e.g., i50jj3.md (6-char compact ID)
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
bundle:
  enabled: false  # Enable context loading via ace-bundle
  sources:
    - file: "docs/vision.md"  # Default sources when enabled
    - preset: "project-overview"

enhance:
  enabled: false  # Enable LLM enhancement by default
  model: glite    # Default model alias (glite, claude, haiku) or provider:model
  temperature: 0.3  # LLM temperature (0.0-1.0)
  system_prompt: prompt://prompt-enhance-instructions.system  # System prompt URI
```

### Enhancement Configuration

The `enhance` section controls LLM-powered prompt improvement:

- **enabled**: When `true`, `ace-prompt-prep` enhances by default (use `--no-enhance` to skip)
- **model**: Default model for enhancement. Accepts:
  - Aliases: `glite`, `claude`, `haiku`
  - Full format: `provider:model` (e.g., `google:gemini-pro`, `anthropic:claude-3-opus`)
- **temperature**: Controls randomness (lower = more focused, higher = more creative)
- **system_prompt**: URI or path to system prompt. Use `prompt://` protocol for built-in prompts

### Context Loading

When context loading is enabled, ace-prompt-prep integrates with [ace-bundle](https://github.com/your-org/ace-bundle) to automatically expand prompts with relevant project information.

**How it works:**
1. Parse YAML frontmatter in the prompt file
2. Look for `context:` block with sources configuration
3. Load context via ace-bundle (handles actual file reading and formatting)
4. Prepend formatted context to output before the original prompt content

**CLI Flag Precedence:**
The precedence order for context loading is:
1. **CLI flags** (`--context` / `--no-context`) - highest priority
2. **Project config** (`.ace/prompt/config.yml`)
3. **Frontmatter context block** in the prompt file
4. **Default behavior** (context disabled) - lowest priority

**CLI overrides:**

```bash
ace-prompt-prep --context      # Enable context loading (overrides config)
ace-prompt-prep --no-context   # Disable context loading (overrides config and frontmatter)
ace-prompt-prep -c             # Short flag for --context
ace-prompt-prep                # Uses config file or frontmatter settings
```

**Context Configuration Sources:**

```yaml
---
bundle:
  enabled: true
  sources:
    # Load specific files
    - file: "docs/architecture.md"
    - file: "README.md"

    # Use ace-bundle presets
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
bundle:
  enabled: true
  sources:
    - file: "docs/vision.md"
    - preset: "project-context"
```
```bash
ace-prompt-prep  # Uses config file settings
```

#### Scenario 2: Frontmatter Override
```markdown
---
bundle:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - command: "git log --oneline -3"
---
```
```bash
ace-prompt-prep  # Uses frontmatter (overrides config)
```

#### Scenario 3: CLI Override
```bash
ace-prompt-prep --context  # Force enable (ignores config/frontmatter)
ace-prompt-prep --no-context  # Force disable (ignores everything)
```

#### Scenario 4: Complex Context
```markdown
---
bundle:
  enabled: true
  sources:
    - file: "docs/architecture.md"
    - preset: "coding-standards"
    - command: "git diff --name-only HEAD~5"
    - command: "find . -name '*.rb' | head -10"
---

Review this code change considering our architecture, standards, recent changes, and affected files.
```

**Note**: The actual context loading and formatting is performed by the ace-bundle gem. ace-prompt-prep only handles the orchestration and integration.

## Exit Codes

- `0` - Success
- `1` - Error
