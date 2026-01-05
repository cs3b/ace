# ace-prompt CLI Interface

## Current Implementation

- **Framework**: Thor (compliant)
- **Entry Point**: `ace-prompt/lib/ace/prompt/cli.rb`
- **Lines of Code**: ~150
- **Migration Needed**: No (reference implementation)

## Commands

### process (default)
Read prompt, optionally enhance with LLM, archive, and output.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--output` | `-o` | string | Output file |
| `--context` | `-c` | flag | Include context |
| `--no-context` | | flag | Exclude context |
| `--enhance` | `-e` | flag | Enhance via LLM |
| `--no-enhance` | | flag | Skip enhancement |
| `--model` | | string | LLM model for enhancement |
| `--system-prompt` | | string | Custom system prompt |
| `--task` | | string | Task ID for prompt location |

### setup
Initialize prompt workspace with template.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--template` | `-t` | string | Template name or URI |
| `--no-archive` | | flag | Skip archiving existing |
| `--force` | `-f` | flag | Force overwrite |
| `--task` | | string | Task ID for setup |

**Examples**:
```bash
ace-prompt                        # Process and archive
ace-prompt --enhance              # Enhance via LLM
ace-prompt --task 121             # Task-specific prompt
ace-prompt setup                  # Initialize workspace
ace-prompt setup --task 117       # Setup in task directory
ace-prompt setup -t tmpl://custom # Use custom template
```

## Default Behavior

- Reads from `.cache/ace-prompt/prompts/the-prompt.md`
- Archives to `.cache/ace-prompt/prompts/archive/`
- Updates symlink to latest

## Reference for Thor Migration

This CLI demonstrates:
- `default_task :process` for default command
- Boolean options with negation (`--context` / `--no-context`)
- Task integration pattern
- Template URI support
