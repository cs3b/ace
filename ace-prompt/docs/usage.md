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

## Exit Codes

- `0` - Success
- `1` - Error
