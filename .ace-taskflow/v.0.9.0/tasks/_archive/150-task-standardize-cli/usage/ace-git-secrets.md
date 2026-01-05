# ace-git-secrets CLI Interface

## Current Implementation

- **Framework**: Thor (compliant)
- **Entry Point**: `ace-git-secrets/lib/ace/git/secrets/cli.rb`
- **Lines of Code**: ~200
- **Migration Needed**: No (reference implementation)

## Commands

### scan
Scan Git history for authentication tokens.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--since` | | string | Scan since date/commit |
| `--format` | `-f` | enum | table, json, yaml (default: table) |
| `--report-format` | `-r` | enum | json, markdown (default: json) |
| `--confidence` | `-c` | enum | high, medium, low (default: low) |
| `--verbose` | `-v` | flag | Verbose output |
| `--quiet` | `-q` | flag | Quiet output |

### rewrite-history
Remove detected tokens from Git history.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--dry-run` | `-n` | flag | Preview changes |
| `--backup` | | boolean | Create backup (default: true) |
| `--force` | | flag | Force operation |
| `--scan-file` | | string | Use saved scan file |

### revoke
Revoke detected tokens via provider APIs.

**Options**:
| Option | Alias | Type | Description |
|--------|-------|------|-------------|
| `--service` | `-s` | string | Service name |
| `--token` | `-t` | string | Token to revoke |
| `--scan-file` | | string | Use saved scan file |

### check-release
Check release for secrets (pre-release gate).

**Options**:
| Option | Type | Description |
|--------|------|-------------|
| `--strict` | flag | Strict mode |
| `--format` | enum | table, json |

**Examples**:
```bash
ace-git-secrets scan                      # Scan full history
ace-git-secrets scan --since "1 week ago" # Recent only
ace-git-secrets rewrite-history --dry-run # Preview
ace-git-secrets revoke --scan-file scan.json
ace-git-secrets check-release --strict    # Pre-release check
```

## Exit Code Handling

Uses class variable `last_exit_code` pattern - exe wrapper handles actual exit.

## Reference for Thor Migration

This CLI demonstrates:
- Thread-safe config preloading in `self.start`
- Exit code handling via class variable
- Multiple subcommands with distinct options
- Enum options with defaults
