# Goal 1: Help Survey — Observations

**Tool**: ace-b36ts v0.7.3

## Overview

`ace-b36ts` is a compact ID encoder/decoder that converts timestamps to base-36 identifiers. It supports multiple time resolutions (from 2-second granularity up to millisecond precision) and hierarchical path-based output.

## Main Command Interface

### Root Help
- **Version**: 0.7.3
- **Global options**: `--help`, `--version`

### Subcommands Discovered

#### 1. `encode`
Encode a timestamp (or current time) to a compact base-36 ID.

**Arguments:**
- `[TIMESTAMP]` (optional) — ISO format, readable format, 'now', or empty (defaults to current time)

**Key Format Options:**
- `--format=VALUE, -f VALUE` — Output granularity
  - Values: `2sec` (default), `month`, `week`, `day`, `40min`, `50ms`, `ms`

**Sequential/Batch Options:**
- `--count=VALUE, -n VALUE` — Generate N sequential IDs
- `--split=VALUE` — Hierarchical split output (month,week,day,block)
- `--path-only` — Output only the split path

**Output Format Options:**
- `--json` — Output as JSON (pairs with --split or --count)

**Configuration:**
- `--year-zero=VALUE, -y VALUE` — Base year for encoding (default: 2000)

**Verbosity:**
- `--quiet, -q` — Suppress non-essential output
- `--verbose, -v` — Show verbose output
- `--debug, -d` — Show debug output

#### 2. `decode`
Decode a compact base-36 ID back to a timestamp.

**Arguments:**
- `COMPACT_ID` (required) — 2-8 character compact ID

**Format Detection:**
- Auto-detects format based on length/structure
- Can accept split paths (e.g., `i5/1/5/j/j3`)

**Output Format:**
- `--format=VALUE, -f VALUE` — Output format
  - Values: `readable`, `iso`, `timestamp` (YYYYMMDD-HHMMSS format)

**Options:**
- `--split` — Force hierarchical split decoding
- `--year-zero=VALUE, -y VALUE` — Base year for decoding (default: 2000)

**Verbosity:**
- `--quiet, -q`, `--verbose, -v`, `--debug, -d`

#### 3. `config`
Show current configuration.

**Options:**
- `--verbose, -v` — Show full config with sources

**Output:**
- `year_zero: 2000` (base year for calculations)
- `alphabet: 0123456789abcdefghijklmnopqrstuvwxyz` (base-36 characters)

## Key Observations

### Strengths
1. **Flexible timestamp input** — Accepts ISO, readable, 'now', or empty (current time)
2. **Multiple granularities** — From 2-second to millisecond precision
3. **Hierarchical output** — Can split IDs into semantic paths (month/week/day/block)
4. **Configurable base year** — Allows custom epoch
5. **Multiple output formats** — JSON, plain, split paths, readable/ISO/timestamp formats
6. **Batch generation** — Can generate sequential IDs in one call
7. **Auto-detection** — Decode auto-detects format based on token structure

### Potential Confusion Points
1. **Format names are domain-specific** — `2sec`, `40min`, `50ms`, `ms` are time resolutions, not output formats
2. **Split path syntax** — Can be `month,week,day` or `/` or auto-detected; may be unclear which separators work
3. **Hierarchical vs flat output** — The difference between `--split month,week` and regular output could be clearer
4. **Year-zero default** — Default year is 2000; affects all calculations
5. **Auto-format detection in decode** — Relies on token length; may be ambiguous for certain values
6. **Verbose/debug/quiet interactions** — Unclear what each level produces (e.g., if both --verbose and --quiet are used)

### Test Surface
- Root help + 3 subcommands + 2 config modes = comprehensive help structure
- Encode has extensive options for granularity and output format
- Decode mirrors encode in reverse but is simpler
- Config is minimal but shows critical defaults

### Notable Flags Not Yet Tested
- Boolean flags: `--[no-]json`, `--[no-]quiet`, etc. (need to test both --json and --no-json)
- Verbosity levels in combination (do they stack or override?)
- Multiple format options together (what if both --format and --split are used?)

### Example Commands from Help
All examples are valid and illustrate key workflows:
- Simple encode: `ace-b36ts encode`
- Encode specific time: `ace-b36ts encode '2025-01-06 12:30:00'`
- Different granularities: `--format day`, `--format month`, `--format ms`
- Batch generation: `--count 10 --format ms now`
- Hierarchical output: `--split month,week now`
- Decode examples show range of token lengths (2-8 characters) and split paths

---

**Status**: All help output captured. Foundation ready for Goals 2-8.
