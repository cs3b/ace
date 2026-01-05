# ace-git CLI Interface

## Current Implementation

- **Framework**: Thor (compliant with magic routing)
- **Entry Point**: `ace-git/lib/ace/git/cli.rb`
- **Lines of Code**: ~250
- **Migration Needed**: No (reference implementation)

## Commands

### diff [RANGE] (default)
Generate git diff with filtering.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--format` | `-f` | enum | summary, diff (default: diff) |
| `--since` | `-s` | string | Time reference (e.g., "7d") |
| `--paths` | `-p` | array | Include paths/globs |
| `--exclude` | `-e` | array | Exclude paths/globs |
| `--output` | `-o` | string | Output file |
| `--config` | `-c` | string | Config file |
| `--raw` | | flag | Raw output |

### status
Show repository context.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--format` | `-f` | enum | markdown, json |
| `--with-diff` | | flag | Include diff |
| `--no-pr` | `-n` | flag | Skip PR lookups |
| `--commits` | `-c` | integer | Recent commits count |

### branch
Show current branch information.

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--format` | enum | text, json |

### pr [NUMBER]
Show PR information.

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--format` | enum | markdown, json |
| `--with-diff` | flag | Include diff |

**Examples**:
```bash
ace-git HEAD~5..HEAD              # Diff (magic routing)
ace-git diff origin/main...HEAD   # Explicit diff
ace-git status                    # Repository context
ace-git status --no-pr            # Skip PR lookups
ace-git branch --format json      # Branch as JSON
ace-git pr 123                    # PR info
```

## Magic Range Routing

Unrecognized arguments matching git range patterns are auto-routed to `diff`:
- `..` or `...` (range operators)
- `~` or `^` (relative refs)
- `@{}` (reflog syntax)

This allows: `ace-git HEAD~5..HEAD` instead of `ace-git diff HEAD~5..HEAD`

## Reference for Thor Migration

This CLI demonstrates:
- `default_task :diff` for default command
- `method_missing` for magic range routing
- Option aliases (`-f`, `-n`, etc.)
- Array options (`--paths`, `--exclude`)
