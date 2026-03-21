---
doc-type: user
title: ace-b36ts
purpose: Documentation for ace-b36ts/README.md
ace-docs:
  last-updated: 2026-02-17
  last-checked: 2026-03-21
---

# ace-b36ts

Base36 compact ID generation for timestamps. Provides 6-character IDs as a replacement for 14-character timestamp formats (YYYYMMDD-HHMMSS).

## Features

- **7 granular format options** - From 2-character monthly to 8-character ultra-high precision
- **6-character Base36 IDs** - Compact, URL-safe identifiers (default format)
- **108-year coverage** - From year_zero (default: 2000) to +107 years
- **~1.85s precision** - Sufficient for most task/ID use cases
- **Chronologically sortable** - String sorting equals time sorting
- **Configurable year_zero** - Customize the base year for your needs

## Installation

Add to your Gemfile:

```ruby
gem 'ace-b36ts', '~> 0.4'
```

## Format Options

The gem supports 7 timestamp formats with varying precision and length:

| Format | Length | Precision | Description |
|--------|--------|-----------|-------------|
| `month` | 2 chars | Month | Monthly grouping |
| `week` | 3 chars | Week | Weekly tracking |
| `day` | 3 chars | Day | Daily grouping |
| `40min` | 4 chars | 40-min block | 40-minute block precision |
| `2sec` | 6 chars | ~1.85s | Default format |
| `50ms` | 7 chars | ~50ms | High precision |
| `ms` | 8 chars | ~1.4ms | Ultra high precision |

**Self-describing 3-char IDs**: Day format uses 3rd char 0-30, week format uses 31-35.

## Usage

### Ruby API

```ruby
require 'ace/b36ts'

# Encode current time
Ace::B36ts.now
# => "i50jj3"

# Encode a specific time
Ace::B36ts.encode(Time.utc(2025, 1, 6, 12, 30, 0))
# => "i50jj3"

# Encode with specific format
Ace::B36ts.encode(Time.utc(2025, 1, 6, 12, 30, 0), format: :day)
# => "i50"
Ace::B36ts.encode(Time.utc(2025, 1, 6, 12, 30, 0), format: :week)
# => "i5v"
Ace::B36ts.encode(Time.utc(2025, 1, 6, 12, 30, 0), format: :ms)
# => "i50jj3kmp"

# Encode split output for hierarchical paths
Ace::B36ts.encode_split(Time.utc(2025, 1, 6, 12, 30, 0), levels: [:month, :week, :day])
# => { month: "i5", week: "1", day: "5", rest: "jj3", path: "i5/1/5/jj3", full: "i515jj3" }
Ace::B36ts.encode_split(Time.utc(2025, 1, 6, 12, 30, 0), levels: [:month, :day], path_only: true)
# => "i5/5/jj3"

# Auto-detect format and decode
Ace::B36ts.decode_auto("i50")   # Detects :day format
Ace::B36ts.decode_auto("i5v")   # Detects :week format
Ace::B36ts.decode_auto("i50jj3") # Detects :"2sec" format

# Decode from a split path
Ace::B36ts.decode_path("i5/1/5/j/j3")
# => 2025-01-06 12:30:00 UTC

# Decode a compact ID (explicit format)
Ace::B36ts.decode("i50jj3")
# => 2025-01-06 12:30:00 UTC

# Validate format (6-char IDs only - legacy method)
Ace::B36ts.valid?("i50jj3")  # => true
Ace::B36ts.valid?("invalid") # => false

# Validate any format length (2-8 chars)
Ace::B36ts.valid_any_format?("i50")    # => true (3-char day)
Ace::B36ts.valid_any_format?("i50jj3") # => true (6-char 2sec)
Ace::B36ts.valid_any_format?("x")      # => false (invalid length)

# Detect format type
Ace::B36ts.detect_format("i50jj3")         # => :"2sec"
Ace::B36ts.detect_format("i50")            # => :day
Ace::B36ts.detect_format("20250106-123000") # => :timestamp

# Override year_zero
Ace::B36ts.encode(time, year_zero: 2025)
Ace::B36ts.decode(compact_id, year_zero: 2025)
```

### CLI

```bash
# Encode a timestamp (default 2sec format)
ace-b36ts encode "2025-01-06 12:30:00"
# => i50jj3

# Encode with specific format
ace-b36ts encode --format day "2025-01-06"
# => i50
ace-b36ts encode --format week "2025-01-06"
# => i5v
ace-b36ts encode --format ms now
# => i50jj3kmp

# Encode current time
ace-b36ts encode now

# Encode split output for hierarchical paths
ace-b36ts encode --split month,week,day now
# => month: i5
# => week: 1
# => day: 5
# => rest: jj3
# => path: i5/1/5/jj3
# => full: i515jj3

ace-b36ts encode --split month,week now --path-only
# => i5/1/5jj3

ace-b36ts encode --split month,day now --json
# => {"month":"i5","day":"5","rest":"jj3","path":"i5/5/jj3","full":"i55jj3"}

# Decode a compact ID (auto-detect format)
ace-b36ts decode i50jj3
# => 2025-01-06 12:30:00 UTC

# Decode a split path (auto-detect separators)
ace-b36ts decode i5/1/5/j/j3
# => 2025-01-06 12:30:00 UTC

# Decode a split full string
ace-b36ts decode i515jj3 --split

# Decode with specific output format
ace-b36ts decode i50jj3 --format iso
# => 2025-01-06T12:30:00Z

# Show configuration
ace-b36ts config
# year_zero: 2000
# alphabet: 0123456789abcdefghijklmnopqrstuvwxyz
```

## Migration from ace-support-timestamp

If you're upgrading from `ace-support-timestamp`:

**Gemfile:**
```ruby
# Old
gem 'ace-support-timestamp'
# New
gem 'ace-b36ts', '~> 0.6'
```

**Requires:**
```ruby
# Old
require 'ace/support/timestamp'
# New
require 'ace/b36ts'
```

**Namespace:**
```ruby
# Old (no longer available per ADR-024)
Ace::Support::Timestamp.now
# New
Ace::B36ts.now
```

## Format Design

The 6-character Base36 ID uses hierarchical field encoding:

| Positions | Field | Range | Description |
|-----------|-------|-------|-------------|
| 1-2 | Month offset | 0-1295 | Months since year_zero (108 years) |
| 3 | Day | 0-30 | Day of month (maps to 1-31) |
| 4 | Block | 0-35 | 40-minute block of day (36 per day) |
| 5-6 | Precision | 0-1295 | Position within 40-min block (~1.85s) |

**Total capacity:** 36^6 = 2,176,782,336 unique IDs over 108 years

**Precision calculation:** 2400 seconds / 1296 combinations = ~1.85185 seconds per increment

## Configuration

Create `.ace/b36ts/config.yml` in your project:

```yaml
b36ts:
  year_zero: 2000
  alphabet: "0123456789abcdefghijklmnopqrstuvwxyz"
```

Configuration cascade (in order of precedence):
1. Runtime options (passed to methods)
2. Project config (`.ace/b36ts/config.yml`)
3. User config (`~/.ace/b36ts/config.yml`)
4. Gem defaults (`.ace-defaults/b36ts/config.yml`)

## Precision Limitations

The 6-character compact ID format has approximately **1.85 seconds** of precision (2400 seconds / 1296 combinations). This means:

- Multiple rapid operations within ~1.85 seconds may produce identical IDs
- For microsecond-precision requirements, use full timestamp formats instead
- For collision avoidance in high-frequency scenarios, consider using session IDs or appending additional entropy

The precision is intentionally designed for task management, file naming, and other use cases where exact microsecond timing is not critical.

### Week Format (ISO Thursday Rule)

The week format (3 chars) uses the ISO Thursday rule: a week belongs to the month containing its Thursday. This means boundary dates may encode to a different month than their calendar date (e.g., Feb 1 on a Saturday encodes as January week 5, because that week's Thursday is Jan 30). Decoding returns the Thursday of the week. For week 5 in months with fewer than 5 Thursdays, the result is clamped to the last Thursday of the month (lossy).

## License

MIT
