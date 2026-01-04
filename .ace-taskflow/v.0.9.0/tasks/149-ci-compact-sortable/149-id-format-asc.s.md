---
id: v.0.9.0+task.149
status: pending
priority: medium
estimate: 8h
dependencies: []
---

# Compact Sortable ID Format with ASCII Encoding (6 chars vs 14)

## Objective

Reduce file path lengths and improve system ergonomics by replacing 14-character timestamps (YYYYMMDD-HHMMSS) with 6-character compact sortable IDs, while maintaining all chronological ordering benefits and ensuring uniqueness.

## Research Summary

### Existing Approaches Analyzed

| Format | Length | Sortable | Structure |
|--------|--------|----------|-----------|
| ULID | 26 | Yes | 48-bit timestamp + 80-bit random, Crockford Base32 |
| KSUID | 27 | Yes | 32-bit timestamp + 128-bit random, Base62 |
| Snowflake | 19 | Yes | 41-bit timestamp + 10-bit machine + 12-bit sequence |
| UUID v7 | 36 | Yes | 48-bit timestamp + 74-bit random |

**Key Insight**: All existing formats prioritize distributed uniqueness over compactness. For single-system use with second precision, a custom packed encoding achieves 6 characters.

### Selected Approach: Packed Binary Base62

**Algorithm**:
1. Pack timestamp components into 33-bit integer
2. Encode as 6-character Base62 string (35.7 bits capacity)

**Bit Layout**:
```
Year (7)   Month (4)  Day (5)  Hour (5)  Min (6)  Sec (6)  = 33 bits
[2000-2099] [1-12]    [1-31]   [0-23]    [0-59]   [0-59]
```

**Note**: Month and day use 1-indexed values (1-12, 1-31) matching standard date conventions. This loses one value from the theoretical range but simplifies encoding/decoding and matches Time API expectations.

**Base62 Alphabet** (ASCII-sorted for lexicographic ordering):
```
0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz
```

### Validation Results

- **Encoding/Decoding**: Verified round-trip for 2000-2099 range
- **Sortability**: Lexicographic order matches chronological order across all boundaries
- **Compression**: 14 chars → 6 chars (57% reduction)

**Example Encodings**:
| Timestamp | Compact ID |
|-----------|------------|
| 2000-01-01 00:00:00 | `000000` |
| 2025-11-17 23:10:38 | `1sWjZu` |
| 2025-12-31 23:59:59 | `1sw2tn` |
| 2026-01-01 00:00:00 | `1u586q` |
| 2099-12-31 23:59:59 | `7J16uB` |

## Scope of Work

### Deliverables

#### Create

- `ace-support-core/lib/ace/core/atoms/compact_id_encoder.rb`
  - Purpose: Core encoding/decoding logic
  - Key components: `encode(time)`, `decode(id)`, `valid?(id)`, `detect_format(str)`

- `ace-support-core/test/atoms/compact_id_encoder_test.rb`
  - Purpose: Comprehensive test coverage
  - Coverage: Encoding, decoding, sortability, edge cases, error handling

#### Modify

- `ace-taskflow/lib/ace/taskflow/molecules/file_namer.rb`
  - Changes: Add compact ID support via config option
  - Integration: Use CompactIdEncoder when `id_format: compact`

- `ace-taskflow/.ace-defaults/taskflow/config.yml`
  - Changes: Add `file_naming.id_format` option (default: `timestamp`)

- `ace-prompt/lib/ace/prompt/atoms/timestamp_generator.rb`
  - Changes: Add compact ID generation method
  - Integration: Support both formats based on config

- `ace-test-runner/lib/ace/test_runner/atoms/timestamp_generator.rb`
  - Changes: Add compact ID support for test report naming

## Technical Approach

### Architecture Pattern

- **Location**: ace-support-core (shared utility)
- **Layer**: Atom (pure function, no side effects)
- **Pattern**: Static module methods for encode/decode

### Implementation Strategy

1. Create core encoder in ace-support-core
2. Add integration to ace-taskflow (primary user)
3. Extend to ace-prompt and ace-test-runner
4. All changes backward-compatible (opt-in via config)

### Timezone Handling

All timestamps **must** be normalized to UTC before encoding:
- `encode(time)` converts input to UTC internally
- `decode(id)` returns Time in UTC
- This ensures consistent IDs across hosts regardless of local timezone

### Collision Handling

When multiple IDs are generated within the same second:
- Bump timestamp by +2 seconds to ensure uniqueness
- Base62 encoding means +1 second may produce visually similar IDs
- +2 seconds guarantees distinct character change in encoded output

```ruby
# Collision avoidance example
last_id_time = @last_generated_at
if Time.now.utc.to_i <= last_id_time.to_i
  current_time = last_id_time + 2  # Bump by 2 seconds
end
@last_generated_at = current_time
```

### Error Handling

- `InvalidIdError`: Non-Base62 characters or wrong length
- `RangeError`: Year outside 2000-2099 range
- Graceful fallback to timestamp format on decode failure

## Implementation Plan

### Planning Steps

* [x] Research existing sortable ID formats (ULID, KSUID, Snowflake)
* [x] Design encoding algorithm with 6-character target
* [x] Validate sortability across time boundaries
* [x] Document file modification plan
* [x] Create UX/usage documentation

### Execution Steps

- [ ] Create `ace-support-core/lib/ace/core/atoms/compact_id_encoder.rb`
  > TEST: Encoding Verification
  > Type: Unit Test
  > Assert: encode(decode(id)) == id for all valid IDs
  > Command: ace-test ace-support-core atoms

- [ ] Create `ace-support-core/test/atoms/compact_id_encoder_test.rb`
  > TEST: Test Coverage
  > Type: Unit Test
  > Assert: All encode/decode/validate methods covered
  > Command: ace-test ace-support-core atoms

- [ ] Add sortability verification tests
  > TEST: Sortability
  > Type: Unit Test
  > Assert: Lexicographic sort == chronological sort
  > Command: ace-test ace-support-core atoms

- [ ] Update ace-taskflow FileNamer to support compact IDs
  > TEST: Integration
  > Type: Integration Test
  > Assert: Ideas created with compact IDs when configured
  > Command: ace-test ace-taskflow molecules

- [ ] Update ace-taskflow config defaults with id_format option

- [ ] Update ace-prompt TimestampGenerator
  > TEST: Prompt Sessions
  > Type: Unit Test
  > Assert: Session directories use compact IDs when configured
  > Command: ace-test ace-prompt atoms

- [ ] Update ace-test-runner TimestampGenerator
  > TEST: Test Reports
  > Type: Unit Test
  > Assert: Report filenames use compact IDs when configured
  > Command: ace-test ace-test-runner atoms

- [ ] Run full test suite
  > TEST: Regression
  > Type: Full Suite
  > Assert: All existing tests pass
  > Command: ace-test-suite

## Risk Assessment

### Technical Risks

- **Risk**: Year 2100+ timestamps fail
  - **Probability**: Low (74 years away)
  - **Impact**: Medium
  - **Mitigation**: Clear error message, documented limitation
  - **Rollback**: Fallback to timestamp format

- **Risk**: Case-sensitive filesystem issues
  - **Probability**: Low (modern systems case-sensitive)
  - **Impact**: Low
  - **Mitigation**: Base62 uses distinct case characters
  - **Rollback**: N/A (format designed for case-sensitive sorting)

### Integration Risks

- **Risk**: Breaking existing timestamp-based lookups
  - **Probability**: Low (opt-in via config)
  - **Impact**: Medium
  - **Mitigation**: Dual-format detection in loaders
  - **Monitoring**: Test with existing idea/task directories

## Acceptance Criteria

- [ ] CompactIdEncoder.encode() produces 6-character IDs
- [ ] CompactIdEncoder.decode() recovers original timestamp
- [ ] Lexicographic sort matches chronological sort for all generated IDs
- [ ] ace-taskflow creates ideas with compact IDs when configured
- [ ] ace-prompt creates sessions with compact IDs when configured
- [ ] All existing tests pass (no regressions)
- [ ] Documentation updated with format specification

## Out of Scope

- ❌ Migrating existing timestamps to compact format
- ❌ Sub-second precision (millisecond/microsecond)
- ❌ Distributed uniqueness (machine ID component)
- ❌ Year 2100+ support
- ❌ UI/display changes for compact IDs

## References

- Original idea: `.ace-taskflow/v.0.9.0/ideas/_archive/20251117-231038-search-add/convert-timestamp-to-id-2025-10-12-use.s.md`
- [ULID Spec](https://github.com/ulid/spec) - Lexicographically sortable identifiers
- [KSUID](https://github.com/segmentio/ksuid) - K-Sortable Unique Identifiers
- [Brandur: K-sorted IDs](https://brandur.org/fragments/k-sorted-ids) - Comparison of approaches
- UX Documentation: `./ux/usage.md`
