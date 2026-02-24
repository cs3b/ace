# Goal 1 — Help Survey Observations

## Tool Overview
- **Tool**: ace-b36ts v0.7.3
- **Purpose**: Encode timestamps to compact base-36 IDs (2-8 characters) and decode them back
- **Base Year**: Default 2000 (configurable via `--year-zero`)

## Subcommands

### 1. encode
**Purpose**: Convert timestamp to compact ID
- **Arguments**: Optional TIMESTAMP (ISO, readable, 'now', or empty for current time)
- **Key Formats**: 2sec (default), month, week, day, 40min, 50ms, ms
- **Notable Flags**:
  - `--count/-n`: Generate N sequential IDs
  - `--split`: Hierarchical output (month,week,day,block)
  - `--path-only`: Output only split path
  - `--json`: Output as JSON (with --split or --count)
  - `--format/-f`: Choose output granularity
  - `--year-zero/-y`: Custom base year
  - `-q/--quiet`, `-v/--verbose`, `-d/--debug`: Verbosity control

### 2. decode
**Purpose**: Convert compact ID back to timestamp
- **Arguments**: COMPACT_ID (required, 2-8 characters, auto-detects format)
- **Notable Flags**:
  - `--format/-f`: Output format (readable, iso, timestamp)
  - `--split`: Force hierarchical split decoding
  - `--year-zero/-y`: Custom base year (must match encode)
  - `-q/--quiet`, `-v/--verbose`, `-d/--debug`: Verbosity control

### 3. config
**Purpose**: Show current configuration
- **Arguments**: None
- **Flags**: `--verbose/-v` for detailed output

## Global Options
- `--help/-h`: Print help
- `--version`: Print version (0.7.3)

## Key Observations

1. **Format Auto-Detection**: Decode auto-detects ID format based on length/content
2. **Multiple Formats**: Different time resolutions available (ms to month)
3. **Split Paths**: IDs can be encoded hierarchically for directory-like structure
4. **JSON Output**: Structured output support for integration with tools
5. **Verbosity Control**: Quiet, default, verbose, and debug modes
6. **Base Year Flexibility**: Year-zero configurable for custom epoch

## Examples
- Basic: `ace-b36ts encode` (now) → compact ID
- Specific: `ace-b36ts encode '2025-01-06 12:30:00'` → compact ID
- Decode: `ace-b36ts decode i50jj3` → readable timestamp
- Formats: Month, week, day, 40min, 50ms, ms granularity
- Sequential: `ace-b36ts encode --count 10 --format ms now` → 10 sequential IDs

## Potential Areas for Clarification
- Default output format when `--format` not specified (appears to be 2sec format)
- Exact timestamp precision of each format level
- Behavior when decoding with wrong `--year-zero`
