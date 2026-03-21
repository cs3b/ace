---
doc-type: workflow
title: B36ts Workflow
purpose: b36ts workflow instruction
ace-docs:
  last-updated: 2026-02-14
  last-checked: 2026-03-21
---

# B36ts Workflow

## Purpose

Work with Base36 compact timestamp IDs using the ace-b36ts gem - encode timestamps to 6-character IDs, decode IDs back to timestamps, and validate format.

## Primary Tool: ace-b36ts

Use the **ace-b36ts** command for all timestamp operations.

## Commands

### Encode
Convert timestamps to compact IDs:
```bash
# Encode current time
ace-b36ts encode now

# Encode specific time
ace-b36ts encode "2025-01-06 12:30:00"
ace-b36ts encode "2025-01-06T12:30:00Z"

# With custom year_zero
ace-b36ts encode "2025-01-06" --year-zero 2020
```

### Decode
Convert compact IDs back to timestamps:
```bash
# Decode to readable format (default)
ace-b36ts decode i50jj3
# => 2025-01-06 12:30:00 UTC

# Decode to ISO format
ace-b36ts decode i50jj3 --format iso
# => 2025-01-06T12:30:00Z

# Decode to timestamp format
ace-b36ts decode i50jj3 --format timestamp
# => 20250106-123000
```

### Config
Show current configuration:
```bash
ace-b36ts config
ace-b36ts config --verbose
```

## Format Specification

The 6-character Base36 ID encodes:

| Positions | Field | Range | Description |
|-----------|-------|-------|-------------|
| 1-2 | Month offset | 0-1295 | Months since year_zero (108 years) |
| 3 | Day | 0-30 | Day of month (maps to 1-31) |
| 4 | Block | 0-35 | 40-minute block of day (36 per day) |
| 5-6 | Precision | 0-1295 | Position within 40-min block (~1.85s) |

## Command Options

### encode
- `--year-zero YEAR`: Base year for encoding (default: 2000)
- `--verbose`: Show detailed encoding information

### decode
- `--format FORMAT`: Output format (readable, iso, timestamp)
- `--verbose`: Show detailed decoding information

### config
- `--verbose`: Show detailed configuration

## Important Notes

- IDs are chronologically sortable (string sort = time sort)
- Default year_zero is 2000, covering 2000-2107
- Precision is approximately 1.85 seconds
- All times are handled in UTC

## Examples

### Current Time Encoding
```bash
$ ace-b36ts encode now
i50jj3
```

### Specific Date Encoding
```bash
$ ace-b36ts encode "2025-01-06 12:30:00"
i50jj3
```

### Decode to Different Formats
```bash
$ ace-b36ts decode i50jj3
2025-01-06 12:30:00 UTC

$ ace-b36ts decode i50jj3 --format iso
2025-01-06T12:30:00Z

$ ace-b36ts decode i50jj3 --format timestamp
20250106-123000
```

### Custom Year Zero
```bash
$ ace-b36ts encode "2030-01-01" --year-zero 2020
k00000
```

## Response Format

When providing results:
1. Show the input and output clearly
2. Explain the encoding/decoding if asked
3. Note any precision limitations