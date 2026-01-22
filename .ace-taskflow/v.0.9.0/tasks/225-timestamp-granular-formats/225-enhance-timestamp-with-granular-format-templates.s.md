---
id: v.0.9.0+task.225
status: planned
priority: medium
estimate: 2-3h
dependencies: []
---

# Enhance ace-support-timestamp with Granular Format Templates

## Description

The `ace-support-timestamp` gem (v0.2.2) currently provides 6-character Base36 compact IDs with ~1.85s precision. This task adds support for granular and high-precision timestamp formats to enable month-only, week-based, day-only, hour-level, and high-precision timestamps.

This enhancement supports use cases like monthly grouping, weekly tracking (ISO week), daily grouping, hourly tracking, and high-precision operations requiring ~50ms or ~1.4ms accuracy.

## Behavioral Specification

### Input
CLI commands with optional `--format` flag:
- `ace-timestamp encode --format month` (2-char output)
- `ace-timestamp encode --format week` (3-char output with ISO week)
- `ace-timestamp encode --format day` (3-char output)
- `ace-timestamp encode --format hour` (4-char output)
- `ace-timestamp encode --format high-7` (7-char ~50ms precision)
- `ace-timestamp encode --format high-8` (8-char ~1.4ms precision)
- `ace-timestamp encode` (default: 6-char compact format, unchanged)

### Process
1. Parse format flag (default: `compact`)
2. Encode timestamp using format-specific algorithm
3. For 3-char formats, use self-describing 3rd character encoding:
   - Values 0-30 = day of month (days 1-31)
   - Values 31-35 = ISO week within month (up to 5 weeks)
4. Return encoded timestamp in specified format

### Output
Chronologically sortable timestamp string of specified length.

## Interface Contract

```bash
# Default (unchanged behavior)
ace-timestamp encode
# → 8oilpn (6-char, ~1.85s precision)

# Month format
ace-timestamp encode --format month
# → 8o (2-char, month precision)

# Week format (ISO week, 3rd char uses 31-35)
ace-timestamp encode --format week
# → 8oz (3-char, 3rd char is ISO week indicator 31-35)

# Day format (3rd char uses 0-30 for day 1-31)
ace-timestamp encode --format day
# → 8o5 (3-char, 3rd char is day: 5 = day 6)

# Hour format
ace-timestamp encode --format hour
# → 8o5c (4-char, hour precision)

# High precision formats
ace-timestamp encode --format high-7
# → 8oilpnx (7-char, ~50ms precision)

ace-timestamp encode --format high-8
# → 8oilpnxy (8-char, ~1.4ms precision)
```

## Format Specifications

| Format | Length | Precision | 3rd Char Encoding | Use Case |
|--------|--------|-----------|-------------------|----------|
| `compact` | 6 chars | ~1.85s | N/A | Default (unchanged) |
| `month` | 2 chars | Month | N/A | Monthly grouping |
| `week` | 3 chars | ISO week | 31-35 (week in month) | Weekly tracking |
| `day` | 3 chars | Day | 0-30 (day 1-31) | Daily grouping |
| `hour` | 4 chars | Hour | N/A | Hourly tracking |
| `high-7` | 7 chars | ~50ms | N/A | Higher precision (1.85s/36) |
| `high-8` | 8 chars | ~1.4ms | N/A | Highest precision (1.85s/36²) |

**Self-describing 3rd character for 3-char formats:**
- Values 0-30: day format (representing days 1-31)
- Values 31-35: week format (ISO week within month, up to 5 weeks)
- No ambiguity: value range determines format automatically during decode

## Acceptance Criteria

- [ ] All new formats are chronologically sortable within their granularity
- [ ] Backward compatible - existing 6-char format unchanged as default
- [ ] CLI accepts `--format` flag with valid format names
- [ ] Invalid format names produce helpful error message
- [ ] Configuration supports default format selection via `.ace/timestamp/config.yml`
- [ ] ISO week calculation correct (standard ISO 8601 week numbering)
- [ ] 3rd character encoding is self-describing (decoder can distinguish week vs day)
- [ ] High precision formats: 7-char (~50ms), 8-char (~1.4ms) working
- [ ] Round-trip encoding/decoding works for all formats
- [ ] Comprehensive test coverage for all formats
- [ ] Documentation updated in README and usage.md

## Implementation Notes

### Technical Context

**Current Architecture:**
```
ace-support-timestamp/
├── lib/ace/support/timestamp/
│   ├── atoms/
│   │   ├── compact_id_encoder.rb  # Core encoding logic
│   │   ├── formats.rb             # Format detection
│   │   └── ...
│   ├── molecules/
│   │   └── ...
│   └── commands/
│       └── encode.rb              # CLI encode command
└── test/
    ├── atoms/
    ├── molecules/
    └── commands/
```

### Files to Create

| File | Purpose |
|------|---------|
| `lib/ace/support/timestamp/atoms/format_templates.rb` | Define format specifications (lengths, precision) |
| `lib/ace/support/timestamp/atoms/week_calculator.rb` | ISO week calculation (pure function) |
| `test/atoms/format_templates_test.rb` | Unit tests for format specs |
| `test/atoms/week_calculator_test.rb` | Unit tests for ISO week calc |

### Files to Modify

| File | Purpose |
|------|---------|
| `lib/ace/support/timestamp/atoms/compact_id_encoder.rb` | Add format-aware encoding methods |
| `lib/ace/support/timestamp/atoms/formats.rb` | Add detection for new format types |
| `lib/ace/support/timestamp/commands/encode.rb` | Add `--format` option |
| `.ace-defaults/timestamp/config.yml` | Add `formats:` section with defaults |
| `README.md` | Document new formats |

### Key Implementation Points

1. **Self-describing encoding**: 3rd character value range determines format type
2. **ISO week calculation**: Use standard ISO 8601 (week starts Monday, week 1 contains Jan 4)
3. **No breaking changes**: Default behavior must remain identical
4. **Configuration cascade**: Format defaults via `.ace/timestamp/config.yml`
5. **Precision math**:
   - 7-char: 1.85s / 36 ≈ 51.4ms
   - 8-char: 1.85s / 36² ≈ 1.43ms

### Test Coverage Requirements

- Unit tests for each format encoding
- Round-trip validation (encode → decode → verify)
- Sortability verification per format level
- ISO week edge cases (year boundaries, week 53)
- 3rd character disambiguation tests
- Configuration override tests

## Source

Idea: `.ace-taskflow/v.0.9.0/ideas/maybe/8oilpn-core-feat/add-granular-high-precision-timestamp-formats.idea.s.md`
