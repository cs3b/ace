# ace-support-timestamp

Base36 compact ID generation for timestamps. Provides 6-character IDs as a replacement for 14-character timestamp formats (YYYYMMDD-HHMMSS).

## Features

- **6-character Base36 IDs** - Compact, URL-safe identifiers
- **108-year coverage** - From year_zero (default: 2000) to +107 years
- **~1.85s precision** - Sufficient for most task/ID use cases
- **Chronologically sortable** - String sorting equals time sorting
- **Configurable year_zero** - Customize the base year for your needs

## Installation

Add to your Gemfile:

```ruby
gem 'ace-support-timestamp', '~> 0.2'
```

## Usage

### Ruby API

```ruby
require 'ace/support/timestamp'

# Encode current time
Ace::Support::Timestamp.now
# => "i50jj3"

# Encode a specific time
Ace::Support::Timestamp.encode(Time.utc(2025, 1, 6, 12, 30, 0))
# => "i50jj3"

# Decode a compact ID
Ace::Support::Timestamp.decode("i50jj3")
# => 2025-01-06 12:30:00 UTC

# Validate format
Ace::Support::Timestamp.valid?("i50jj3")  # => true
Ace::Support::Timestamp.valid?("invalid") # => false

# Detect format type
Ace::Support::Timestamp.detect_format("i50jj3")         # => :compact
Ace::Support::Timestamp.detect_format("20250106-123000") # => :timestamp

# Override year_zero
Ace::Support::Timestamp.encode(time, year_zero: 2025)
Ace::Support::Timestamp.decode(compact_id, year_zero: 2025)
```

### CLI

```bash
# Encode a timestamp
ace-timestamp encode "2025-01-06 12:30:00"
# => i50jj3

# Encode current time
ace-timestamp encode now

# Decode a compact ID
ace-timestamp decode i50jj3
# => 2025-01-06 12:30:00 UTC

# Decode with specific format
ace-timestamp decode i50jj3 --format iso
# => 2025-01-06T12:30:00Z

# Show configuration
ace-timestamp config
# year_zero: 2000
# alphabet: 0123456789abcdefghijklmnopqrstuvwxyz
```

## Migration from ace-timestamp

If you're upgrading from the old `ace-timestamp` gem:

**Gemfile:**
```ruby
# Old
gem 'ace-timestamp'
# New
gem 'ace-support-timestamp', '~> 0.2'
```

**Requires:**
```ruby
# Old
require 'ace/timestamp'
# New
require 'ace/support/timestamp'
```

**Namespace:**
```ruby
# Old (no longer available per ADR-024)
Ace::Timestamp.now
# New
Ace::Support::Timestamp.now
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

Create `.ace/timestamp/config.yml` in your project:

```yaml
timestamp:
  year_zero: 2000
  alphabet: "0123456789abcdefghijklmnopqrstuvwxyz"
```

Configuration cascade (in order of precedence):
1. Runtime options (passed to methods)
2. Project config (`.ace/timestamp/config.yml`)
3. User config (`~/.ace/timestamp/config.yml`)
4. Gem defaults (`.ace-defaults/timestamp/config.yml`)

## Precision Limitations

The 6-character compact ID format has approximately **1.85 seconds** of precision (2400 seconds / 1296 combinations). This means:

- Multiple rapid operations within ~1.85 seconds may produce identical IDs
- For microsecond-precision requirements, use full timestamp formats instead
- For collision avoidance in high-frequency scenarios, consider using session IDs or appending additional entropy

The precision is intentionally designed for task management, file naming, and other use cases where exact microsecond timing is not critical.

## License

MIT
