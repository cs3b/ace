# ace-lint CLI Interface

## Current Implementation

- **Framework**: Thor (compliant with magic default)
- **Entry Point**: `ace-lint/lib/ace/lint/cli.rb`
- **Lines of Code**: ~100
- **Migration Needed**: No (reference implementation)

## Commands

### lint [FILES...] (default)
Lint markdown, YAML, and frontmatter files.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--fix` | `-f` | flag | Auto-fix issues |
| `--format` | | flag | Format output |
| `--type` | `-t` | string | File type (markdown, yaml, frontmatter) |
| `--quiet` | `-q` | flag | Quiet output |
| `--line-width` | | integer | Line width for formatting |

**Examples**:
```bash
ace-lint file.md                  # Lint single file
ace-lint file.md --fix            # Auto-fix issues
ace-lint "**/*.md" --type markdown # Lint all markdown
ace-lint file.yml -t yaml         # Lint YAML
ace-lint file.md --line-width 100 # Custom line width
```

## Magic Default Command

Auto-prepends `lint` command when first argument looks like a file/path:
- `ace-lint file.md` → `ace-lint lint file.md`

## Reference for Thor Migration

This CLI demonstrates:
- `default_task :lint` for default command
- Simple single-command pattern
- File type detection
- Auto-fix capability
