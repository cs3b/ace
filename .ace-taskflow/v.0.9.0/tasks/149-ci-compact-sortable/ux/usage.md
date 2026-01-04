# Compact Sortable ID Format - Usage Guide

## Overview

Compact Sortable IDs replace 14-character timestamps (YYYYMMDD-HHMMSS) with 6-character encoded IDs that maintain lexicographic sortability.

## Format Specification

### Encoding Algorithm

The format uses packed binary encoding with Base62 representation:

1. **Pack timestamp into 33-bit integer**:
   - Year (2000-2099): 7 bits (offset from 2000)
   - Month (1-12): 4 bits (0-indexed)
   - Day (1-31): 5 bits (0-indexed)
   - Hour (0-23): 5 bits
   - Minute (0-59): 6 bits
   - Second (0-59): 6 bits

2. **Encode as Base62** (6 characters):
   - Alphabet: `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz`
   - ASCII-sorted for lexicographic ordering

### Character Mapping

| Range | Characters | Count |
|-------|------------|-------|
| 0-9   | 0-9        | 10    |
| 10-35 | A-Z        | 26    |
| 36-61 | a-z        | 26    |
| **Total** |        | **62** |

## Usage Examples

### Encoding

```ruby
require 'ace/support/core/atoms/compact_id_encoder'

# Encode current time
id = Ace::Core::Atoms::CompactIdEncoder.encode(Time.now)
# => "1sWjZu"

# Encode specific time
id = Ace::Core::Atoms::CompactIdEncoder.encode(Time.new(2025, 11, 17, 23, 10, 38))
# => "1sWjZu"
```

### Decoding

```ruby
# Decode back to Time
time = Ace::Core::Atoms::CompactIdEncoder.decode("1sWjZu")
# => 2025-11-17 23:10:38 +0000

# Validate format
Ace::Core::Atoms::CompactIdEncoder.valid?("1sWjZu")
# => true
```

### File Path Examples

| Context | Old Format | New Format |
|---------|------------|------------|
| Idea directory | `20251117-231038-my-idea/` | `1sWjZu-my-idea/` |
| Prompt session | `20251117-231038/` | `1sWjZu/` |
| Test report | `test-20251117-231038.xml` | `test-1sWjZu.xml` |

### Chronological Sorting

IDs sort correctly by lexicographic order:

```
1sdtfe  → 2025-11-30 23:59:58
1sdtff  → 2025-11-30 23:59:59
1sf8SW  → 2025-12-01 00:00:00
1sf8SX  → 2025-12-01 00:00:01
1u586q  → 2026-01-01 00:00:00
```

Standard `sort` command produces chronological order:
```bash
ls -1 | sort  # Sorts by creation time
```

## Configuration

### Enabling Compact IDs

```yaml
# .ace/taskflow/config.yml
file_naming:
  id_format: compact  # Use compact 6-char IDs (default: timestamp)
  # id_format: timestamp  # Use traditional YYYYMMDD-HHMMSS
```

### Per-Tool Override

```yaml
# .ace/prompt/config.yml
file_naming:
  id_format: compact  # Enable for ace-prompt only
```

## Migration

### Legacy Support

Both formats are supported during transition:

```ruby
# Detect format automatically
Ace::Core::Atoms::CompactIdEncoder.detect_format("1sWjZu")
# => :compact

Ace::Core::Atoms::CompactIdEncoder.detect_format("20251117-231038")
# => :timestamp
```

### Converting Existing IDs

```ruby
# Convert timestamp to compact
old_id = "20251117-231038"
time = Time.strptime(old_id, "%Y%m%d-%H%M%S")
new_id = Ace::Core::Atoms::CompactIdEncoder.encode(time)
# => "1sWjZu"
```

## Technical Details

### Bit Layout

```
  Year (7)   Month (4)  Day (5)  Hour (5)  Min (6)  Sec (6)
 [0000000]   [0000]    [00000]  [00000]   [000000] [000000]
 Bits 26-32  22-25     17-21    12-16     6-11     0-5
```

### Year Range

- Minimum: 2000-01-01 00:00:00 → `000000`
- Maximum: 2099-12-31 23:59:59 → `7J16uB`
- Year 2100+ requires format extension

### Collision Resistance

- Unique to the second (same as current format)
- For sub-second precision, append random suffix: `1sWjZu-a3`

### URL Safety

All characters are URL-safe (alphanumeric only):
- No special characters that require encoding
- Works in file paths, URLs, and shell commands

## Error Handling

```ruby
# Invalid ID format
begin
  Ace::Core::Atoms::CompactIdEncoder.decode("invalid!")
rescue Ace::Core::Atoms::CompactIdEncoder::InvalidIdError => e
  puts e.message  # "Invalid compact ID format: contains non-Base62 characters"
end

# Out of range year
begin
  Ace::Core::Atoms::CompactIdEncoder.encode(Time.new(2100, 1, 1))
rescue Ace::Core::Atoms::CompactIdEncoder::RangeError => e
  puts e.message  # "Year 2100 is outside supported range (2000-2099)"
end
```

## Comparison with Other Formats

| Format | Length | Sortable | Human-Readable | Example |
|--------|--------|----------|----------------|---------|
| **Compact ID** | 6 | Yes | Decode needed | `1sWjZu` |
| YYYYMMDD-HHMMSS | 14 | Yes | Yes | `20251117-231038` |
| ULID | 26 | Yes | No | `01ARZ3NDEKTSV4RRFFQ69G5FAV` |
| UUID | 36 | No | No | `550e8400-e29b-41d4-a716-446655440000` |
| KSUID | 27 | Yes | No | `0ujsswThIGTUYm2K8FjOOfXtY1K` |

## Tips

1. **Use compact IDs for new resources** - reduces path length by 57%
2. **Keep timestamp format for display** - decode for human-readable output
3. **Migration is optional** - existing timestamps continue to work
4. **Test sorting** - verify lexicographic order in your file manager
