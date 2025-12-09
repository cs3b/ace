---
id: v.0.9.0+task.149
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# Compact Sortable ID Format with ASCII Encoding (6 chars vs 14)

## Behavioral Specification

### User Experience
- **Input**: Users create timestamped resources (ideas, sessions, tasks) that need unique identifiers
- **Process**: System automatically generates compact, sortable IDs that maintain chronological ordering while reducing path length
- **Output**: 6-character IDs (vs current 14-character timestamps) that are URL-friendly, human-readable, and chronologically sortable

### Expected Behavior

Users should be able to work with compact identifiers that:
- Replace 14-character timestamps (YYYYMMDD-HHMMSS) with 6-character encoded IDs
- Maintain exact chronological sort order (year/month/day/hour/minute/second precision)
- Use ASCII encoding for each time component to maximize compression
- Remain unique within the system (collision-free for practical use cases)
- Are reversible (decode back to original timestamp for debugging/display)
- Work seamlessly in file paths, URLs, and directory names

The system should generate these IDs automatically when creating timestamped resources, with the compact format reducing path lengths significantly while maintaining all chronological benefits.

### Interface Contract

```bash
# Research and Design Phase
# 1. Research existing compact sortable ID formats
#    - Lexicographically sortable identifiers
#    - Base-N encoding schemes for timestamps
#    - URL-safe character sets
#    - Collision resistance approaches

# 2. Design format specification
#    - Define ASCII character mapping for each component
#    - Document encoding/decoding algorithm
#    - Specify sort order guarantees
#    - Define valid character ranges

# 3. Validation interface (proposed utility)
ace-id-encode "2025-11-17 23:10:38"
# Output: "X5KN2E" (example - actual encoding TBD)

ace-id-decode "X5KN2E"
# Output: "2025-11-17 23:10:38"

ace-id-validate "X5KN2E"
# Output: "Valid: sortable, unique, timestamp: 2025-11-17 23:10:38"

# Usage in taskflow
ace-taskflow idea create "My new idea"
# Creates: .ace-taskflow/v.0.9.0/ideas/X5KN2E-my-new/X5KN2E-my-new-idea.s.md
# Instead of: .ace-taskflow/v.0.9.0/ideas/20251117-231038-my-new/...
```

**Error Handling:**
- Invalid timestamp input: Clear error message with format requirements
- Decode of invalid ID: Report which character/position is invalid
- Collision detection: Report if ID already exists (unlikely but possible)

**Edge Cases:**
- Year 2100+: Consider encoding scheme limits
- Timezone handling: All IDs should be UTC-based
- Microsecond precision: Not needed (second precision sufficient)
- Legacy timestamp conversion: Support migrating existing 14-char IDs

### Success Criteria

- [ ] **Research Complete**: Documented analysis of existing sortable ID formats, base-N encoding schemes, and best practices for compact timestamps
- [ ] **Format Specification**: Complete specification document defining the encoding algorithm, character mapping, and sort guarantees
- [ ] **Validation**: Proof that 6-character IDs maintain chronological sort order across year/month/day/hour/minute/second boundaries
- [ ] **Uniqueness Guarantee**: Mathematical proof or testing showing collision resistance for practical timeframes (100+ years at 1 ID/second)
- [ ] **Reversibility**: Ability to decode any valid compact ID back to original timestamp
- [ ] **Path Length Reduction**: Measured reduction from 14 chars to 6 chars (57% compression) in actual file paths

### Validation Questions

- [ ] **Encoding Scheme**: Which base-N encoding provides optimal balance of compactness, readability, and URL-safety? (Base62, Base64, custom mapping?)
- [ ] **Character Set**: Should we use alphanumeric only, or include URL-safe symbols? Case-sensitive or case-insensitive?
- [ ] **Sort Order**: How do we guarantee lexicographic sort matches chronological sort across all component boundaries?
- [ ] **Year Encoding**: Can we encode years 2000-2099 in a single character? What about beyond 2099?
- [ ] **Collision Handling**: What happens if two IDs are generated in the same second? Increment counter, microsecond precision, or accept rare collision?
- [ ] **Migration Strategy**: How do we handle existing 14-character timestamp IDs? Convert in-place, support both formats, or grandfather old format?
- [ ] **Human Readability**: Should IDs be somewhat readable (recognize year/month patterns) or purely compact?

## Objective

Reduce file path lengths and improve system ergonomics by replacing 14-character timestamps with 6-character compact sortable IDs, while maintaining all chronological ordering benefits and ensuring uniqueness. This research task will evaluate existing approaches and design a specification for implementation.

## Scope of Work

- **Research Scope**: Analysis of existing compact sortable ID formats, base-N encoding schemes, and timestamp compression techniques
- **Design Scope**: Complete format specification with encoding/decoding algorithms, sort order guarantees, and collision resistance
- **Validation Scope**: Testing methodology to prove sort order preservation and uniqueness guarantees
- **Documentation Scope**: Format specification, usage examples, and migration considerations

### Deliverables

#### Behavioral Specifications
- Format specification document defining the 6-character encoding scheme
- Character mapping table (e.g., 0-9, A-Z, a-z to values 0-61)
- Encoding/decoding algorithm pseudocode
- Sort order proof or demonstration

#### Validation Artifacts
- Test cases showing chronological sort preservation
- Uniqueness analysis (collision probability calculations)
- Comparison with existing approaches (Snowflake, ULID, KSUID, etc.)
- Migration strategy for existing timestamp-based IDs

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby/Python/shell script implementation
- ❌ **Integration Work**: Updating ace-taskflow or other tools to use new format
- ❌ **Migration Execution**: Actually converting existing timestamp IDs
- ❌ **Performance Optimization**: Encoding/decoding performance tuning
- ❌ **UI/Display Changes**: How compact IDs are displayed to users
- ❌ **Related Features**: Other ID format improvements not related to timestamp compression

## References

- Original idea: `.ace-taskflow/v.0.9.0/ideas/done/20251117-231038-search-add/convert-timestamp-to-id-2025-10-12-use.s.md`
- Related work: Lexicographically sortable identifiers (ULID, KSUID, Snowflake)
- Current timestamp format: `YYYYMMDD-HHMMSS` (14 characters)
- Target format: 6 ASCII characters with chronological sort preservation
