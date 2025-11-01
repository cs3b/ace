---
id: v.0.9.0+task.091
status: draft
priority: high
estimate: 2 weeks
dependencies: []
sort: 999
---

# Replace legacy filter flags with unified --filter key:value syntax

## Behavioral Specification

### User Experience

- **Input**: User provides filtering preferences via `--filter key:value` flags and optional `--filter-clear` flag
- **Process**:
  - Multiple filters are parsed from key:value syntax
  - Filters are merged with preset defaults unless `--filter-clear` is used
  - Filters support flexible syntax: simple values, OR combinations, negation, and array matching
  - All filters apply with AND logic (all must match)
- **Output**: Filtered list of items (tasks, ideas, releases) matching all specified criteria

### Expected Behavior

The system provides a unified, flexible filtering interface across all ace-taskflow list commands. Users can filter on any frontmatter field without restriction, with support for complex operations like negation and array matching.

Key behaviors:
- Accept `--filter key:value` flags (repeatable for multiple filters)
- Support OR values using pipe syntax: `--filter status:pending|in-progress`
- Support negation with exclamation: `--filter status:!done`
- Support array matching: `--filter dependencies:v.0.9.0+task.081` matches if array contains value
- Support `--filter-clear` to bypass preset default filters
- Merge parsed filters with preset filters (unless cleared)
- Apply all filters with AND logic
- Work with any frontmatter field without enforced key list
- Case-insensitive matching with whitespace trimming

### Interface Contract

**Unified Syntax (ONLY - All Legacy Flags Removed):**

```bash
# Single filter
ace-taskflow tasks --filter status:pending

# Multiple filters (AND logic)
ace-taskflow tasks --filter status:pending --filter priority:high

# OR values within filter (pipe-separated)
ace-taskflow tasks --filter status:pending|in-progress

# Negation (NOT operator)
ace-taskflow tasks --filter status:!done --filter priority:!low

# Clear preset filters, keep release/scope
ace-taskflow ideas --filter-clear --filter status:done

# Array matching (value present in array)
ace-taskflow tasks --filter dependencies:v.0.9.0+task.081

# Custom frontmatter fields
ace-taskflow tasks --filter team:backend --filter sprint:12

# Combine with presets
ace-taskflow tasks recent --filter priority:high --filter status:!blocked
```

**Breaking Changes - Legacy Flags REMOVED:**
```
❌ Removed: --status <statuses>        → Use: --filter status:value
❌ Removed: --priority <priorities>    → Use: --filter priority:value
❌ Removed: --context <context>        → Use: --filter context:value
❌ Removed: --backlog, --current       → Use: --filter context:backlog or preset
❌ Removed: --active (releases)        → Use: --filter status:active
❌ Removed: --done (releases)          → Use: --filter status:done
```

**Retained Flags (Not Filter-Related):**
```
✅ --limit <n>           → Result limiting (not filtering)
✅ --days <n>            → Maps to --filter recent_days:n
✅ --sort <field>        → Sorting (not filtering)
✅ --all                  → Maps to 'all' preset
✅ Presets (next, all, recent, etc.)
```

**Filter Operators:**

1. **Simple Match**: `key:value`
   - Exact match (case-insensitive)
   - Works with strings, numbers, booleans
   - Example: `--filter status:pending`

2. **Array Matching**: `key:value` where frontmatter has array
   - Matches if value is present in array
   - Example: `--filter dependencies:v.0.9.0+task.081`
   - Example: `--filter tags:api`

3. **Negation**: `key:!value`
   - Negates the match
   - Example: `--filter status:!done`
   - Example: `--filter tags:!frontend`

4. **OR Values**: `key:value1|value2|value3`
   - Pipe-separated alternatives (OR logic within filter)
   - Example: `--filter status:pending|in-progress`
   - Example: `--filter priority:high|critical`

5. **Multiple Filters**: `--filter key1:value1 --filter key2:value2`
   - AND logic across different filters
   - All filters must match
   - Example: `--filter status:pending --filter priority:high`

**Complex Examples:**

```bash
# High/critical priority tasks NOT done or blocked
ace-taskflow tasks --filter priority:high|critical --filter status:!done --filter status:!blocked

# Custom metadata filtering
ace-taskflow tasks --filter team:backend --filter sprint:12 --filter status:pending

# Recent pending ideas in specific release
ace-taskflow ideas recent --filter status:pending --filter context:v.0.9.0

# Tasks with specific dependency
ace-taskflow tasks --filter dependencies:v.0.9.0+task.081 --filter status:!done

# Ideas done by specific date or with custom tags
ace-taskflow ideas --filter-clear --filter status:done --filter author:john
```

**Error Handling:**

- **Invalid syntax**: "Error: Invalid filter syntax. Use: --field key:value"
- **Parsing error**: Show helpful message with examples
- **No matches**: Return empty list (not an error)
- **Unknown keys**: Allow gracefully (supports custom frontmatter fields)

**Edge Cases:**

- **Empty value**: `--filter description=""` sets filter for empty string (not allowed - syntax error)
- **Special characters**: `--filter title="Task: API 'review'"` properly escaped in shell
- **Deep frontmatter nesting**: Not supported in filter key (flat keys only)
- **Array with special values**: Works normally, value matched as-is
- **Multiple OR values**: `--filter status:pending|in-progress|blocked` matches any
- **Whitespace handling**: Spaces around colons and values are trimmed

### Success Criteria

- [ ] **Legacy Flags Removed**: All `--status`, `--priority`, `--context`, `--backlog`, `--current`, `--active`, `--done` flags removed from code
- [ ] **--filter Syntax Works**: `--filter key:value` works on tasks, ideas, and releases commands
- [ ] **Multiple Filters**: Multiple `--filter` flags combine with AND logic
- [ ] **OR Values**: Pipe syntax `value1|value2` enables OR within single filter
- [ ] **Negation**: Exclamation prefix `!value` properly negates matches
- [ ] **Array Matching**: Filters on array fields match if value is present in array
- [ ] **--filter-clear Works**: Removes only filters from preset, keeps release/scope/sort
- [ ] **Flexible Keys**: Any custom frontmatter field can be filtered
- [ ] **Preset Integration**: Presets work with new system (structure unchanged)
- [ ] **Documentation Updated**: All README and command help text updated
- [ ] **Migration Guide**: User migration guide created for breaking changes
- [ ] **Case Insensitivity**: Matching is case-insensitive with whitespace trimmed
- [ ] **Backward Incompatible**: Users using legacy flags will see clear error messages directing to new syntax

### Validation Questions

- [ ] **Scope of Legacy Removal**: Should `--days` be removed or kept as convenience alias to `--filter recent_days:n`?
- [ ] **Preset Defaults**: Should presets be updated to use new filter syntax in comments/documentation?
- [ ] **Sorting with Filters**: Should filters and sorting be independent (yes) or should certain filter combinations suggest sort order?
- [ ] **Performance**: Are there performance implications for filtering on arbitrary frontmatter fields?

## Objective

Simplify and unify the filtering interface across ace-taskflow commands by removing multiple legacy flag variations and replacing with a single, flexible `--filter key:value` syntax. This breaking change (acceptable in pre-release) provides:

- **Consistency**: Single filtering approach across all commands
- **Flexibility**: Filter on any frontmatter field, not just predefined ones
- **Expressiveness**: Support complex queries with negation, OR values, and array matching
- **Extensibility**: Works automatically with custom fields added to frontmatter
- **Clarity**: Clearer semantics with explicit key:value syntax

## Scope of Work

### User Experience Scope
- CLI filtering on tasks, ideas, and releases via `--filter` flags
- Support for single and multiple filter criteria
- Clear, helpful error messages for invalid syntax
- Migration path for users of legacy flags

### System Behavior Scope
- Parse `--filter key:value` syntax from command-line arguments
- Support OR, negation, and array matching operators
- Merge filters with preset defaults (unless cleared)
- Apply filters with AND logic across keys
- Work with arbitrary frontmatter fields

### Interface Scope
- `--filter key:value` flag on tasks, ideas, releases commands
- `--filter-clear` flag to bypass preset defaults
- Removal of legacy filtering flags
- Updated preset system documentation

### Deliverables

#### Behavioral Specifications
- Complete interface contract with all syntax variations
- Operator documentation (simple, OR, negation, array matching)
- Filter application logic (AND/OR semantics)
- Error handling specifications

#### User Experience Artifacts
- Migration guide from legacy flags to new syntax
- Updated README with new filtering syntax
- Updated command help text
- Examples for common filtering use cases

#### Breaking Change Documentation
- Clear list of removed flags and their replacements
- Migration examples for each removed flag
- Warning in release notes

## Out of Scope

- ❌ **GUI Filter Builder**: Web or visual interface for building filters
- ❌ **Filter Presets**: Saving named filter combinations (future enhancement)
- ❌ **Nested Frontmatter**: Filtering on nested keys (e.g., `metadata.review.status`)
- ❌ **Performance Optimization**: Index-based filtering (address if needed)
- ❌ **Filter History**: Saving/recalling previous filters (future enhancement)

## References

- Source Idea: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/ideas/20251007-134439-for-ace-taskflow-ideas-tasks-release-we-shou.md
- Legacy Implementation: `_legacy/dev-tools/lib/coding_agent_tools/molecules/taskflow_management/task_filter_parser.rb`
- Current Code: `ace-taskflow/lib/ace/taskflow/commands/{task,ideas,releases}_command.rb`
- Existing Filters: `ace-taskflow/lib/ace/taskflow/molecules/task_filter.rb`
- Presets: `ace-taskflow/lib/ace/taskflow/molecules/list_preset_manager.rb`

---

## Additional Notes

### Why This Breaking Change is Acceptable

We are in pre-release (v.0.9.0), so breaking changes are acceptable for:
- Improved API consistency
- Simpler user mental model (one way to filter vs multiple ways)
- Better extensibility for future frontmatter fields
- Alignment with industry standard filtering patterns (kubectl, git config, etc.)

### Migration Support

Users upgrading will see:
- Clear error: "Error: --status flag is no longer supported. Use: --filter status:value"
- Help text updated with new syntax
- Migration guide in release notes
- Examples in README updated

### Design Principles

1. **Flexibility Over Restriction**: Allow any field, don't enforce keys
2. **Consistency Over Convenience**: One way to filter, not multiple options
3. **Expressiveness Over Simplicity**: Support complex queries when needed
4. **Extensibility Over Predictability**: Custom fields work automatically
5. **Clarity Over Brevity**: Explicit `key:value` syntax beats cryptic flags