# Goal 1 — Help Survey Observations

## Tool Overview

**ace-b36ts v0.7.3** — Encodes timestamps to compact base-36 IDs (2-8 characters) and decodes them back.

## Subcommands

| Subcommand | Purpose |
|------------|---------|
| `encode`   | Encode timestamp to compact ID |
| `decode`   | Decode compact ID to timestamp |
| `config`   | Show current configuration |

## Root Options

- `--help, -h` — Print help
- `--version` — Print version

## Encode Subcommand

**Usage**: `ace-b36ts encode [TIMESTAMP] [OPTIONS]`

**Arguments**: Optional timestamp (ISO, readable, 'now', or empty for current time)

**Key flags**:
- `--format=VALUE, -f VALUE` — Output format: 2sec (default), month, week, day, 40min, 50ms, ms
- `--count=VALUE, -n VALUE` — Generate N sequential IDs
- `--split=VALUE` — Split levels for hierarchical output (month,week,day,block)
- `--path-only` — Output only the split path
- `--json` — Output split data as JSON (works with --split or --count)
- `--year-zero=VALUE, -y VALUE` — Base year for encoding (default: 2000)
- `--quiet, -q` — Suppress non-essential output
- `--verbose, -v` — Show verbose output
- `--debug, -d` — Show debug output

## Decode Subcommand

**Usage**: `ace-b36ts decode COMPACT_ID [OPTIONS]`

**Arguments**: Required 2-8 character compact ID (auto-detects format)

**Key flags**:
- `--year-zero=VALUE, -y VALUE` — Base year for decoding (default: 2000)
- `--format=VALUE, -f VALUE` — Output format: readable, iso, timestamp
- `--split` — Force hierarchical split decoding
- `--quiet, -q` — Suppress non-essential output
- `--verbose, -v` — Show verbose output
- `--debug, -d` — Show debug output

## Config Subcommand

**Usage**: `ace-b36ts config [OPTIONS]`

Shows: year_zero (2000) and alphabet (0123456789abcdefghijklmnopqrstuvwxyz)

## Observations / Notes for First-Time User

1. **Format hierarchy is well-designed**: 2-char (month) through 8-char (ms) gives clear precision tiers.
2. **Auto-detection on decode**: The tool auto-detects format based on ID length, which is convenient.
3. **Split path support**: Decode accepts both path format (`i5/1/5/j/j3`) and flat with `--split` flag.
4. **JSON output**: Available for both `--split` and `--count` operations — useful for downstream tooling.
5. **Year-zero default**: Base year is 2000 by default, configurable via `--year-zero`.
6. **Decode output formats differ from encode formats**: Encode `--format` controls precision (2sec, month, etc.), while decode `--format` controls representation (readable, iso, timestamp).
7. **No explicit "default output format" for decode**: Help doesn't state what the default decode output format is (likely "readable").
