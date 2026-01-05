# ace-docs CLI Interface

## Current Implementation

- **Framework**: Thor (compliant)
- **Entry Point**: `ace-docs/lib/ace/docs/cli.rb`
- **Lines of Code**: ~200
- **Migration Needed**: No (reference implementation)

## Commands

### status
Show status of all managed documents.

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--type TYPE` | string | Filter by document type |
| `--needs-update` | flag | Show only stale documents |
| `--freshness LEVEL` | enum | current, stale, outdated |

### discover
Find and list all managed documents.

### update [FILE]
Update document frontmatter.

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--set KEY=VALUE` | string | Set frontmatter field |
| `--preset NAME` | string | Use update preset |

### analyze FILE
Analyze changes for a document with LLM.

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--since DATE` | string | Changes since date/commit |
| `--exclude-renames` | flag | Exclude rename changes |
| `--exclude-moves` | flag | Exclude move changes |

### validate [FILE|PATTERN]
Validate documents against rules.

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--syntax` | flag | Syntax validation only |
| `--semantic` | flag | Semantic validation only |
| `--all` | flag | All validations |

### analyze-consistency [PATTERN]
Analyze cross-document consistency.

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--terminology` | flag | Check terminology |
| `--duplicates` | flag | Check duplicates |
| `--versions` | flag | Check versions |
| `--all` | flag | All checks |
| `--threshold N` | integer | Similarity threshold |
| `--output FORMAT` | enum | markdown, json, text |
| `--save` | flag | Save results |
| `--model MODEL` | string | LLM model |
| `--timeout SECONDS` | integer | Timeout |
| `--strict` | flag | Strict mode |
| `--verbose` | flag | Verbose output |

**Examples**:
```bash
ace-docs status --needs-update          # Check stale docs
ace-docs update file.md --set last-updated=today
ace-docs analyze file.md --since HEAD~5
ace-docs validate "**/*.md" --all
ace-docs analyze-consistency --all --save
```

## Reference for Thor Migration

This CLI serves as a **reference implementation** for Thor patterns:
- Uses `method_option` for command-specific options
- Delegates to command classes
- Returns exit codes (0/1)
- Provides `--help` via Thor
