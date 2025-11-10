---
id: v.0.9.0+task.104
status: draft
priority: medium
estimate: 4h
dependencies: []
---

# Add context.base support to ace-context for generic base content handling

## Behavioral Specification

### User Experience
- **Input**: Context file with `context.base` field in frontmatter (e.g., `context.base: "prompt://base/system"`)
- **Process**: ace-context automatically resolves the base protocol, loads the referenced content, and uses it as the primary document body
- **Output**: Generated output file contains base content first, followed by processed sections

### Expected Behavior

When users specify a `context.base` field in their context configuration, ace-context should:

1. **Detect the base field** in the `context` section of frontmatter
2. **Resolve the protocol** (e.g., `prompt://base/system` → actual file path)
3. **Load the base content** from the resolved path
4. **Use base as primary content** - the base content becomes the main document body
5. **Append processed sections** after the base content
6. **Handle missing base gracefully** - work normally if base field is absent

This makes `base` a first-class citizen alongside `sections`, `files`, `diffs`, and `presets` in the context configuration.

### Interface Contract

**Configuration Format:**
```yaml
context:
  base: "prompt://base/system"  # Protocol-based reference
  sections:
    section_name:
      files:
        - "prompt://focus/scope/tests"
```

**Supported Base Formats:**
- Protocol references: `prompt://path/to/file`
- Relative paths: `./path/to/file.md`
- Absolute paths: `/full/path/to/file.md`

**Processing Order:**
1. Load base content (if specified)
2. Process sections
3. Output: `[base content]\n\n[processed sections]`

**Error Handling:**
- Base file not found: Clear error message with file path
- Invalid protocol: Error with supported protocol list
- Missing base field: Continue normally (base is optional)
- Empty base content: Warning but continue processing

**Edge Cases:**
- Base without sections: Output only base content
- Sections without base: Current behavior (sections only)
- Base with empty string: Treat as missing, continue normally

### Success Criteria

- [ ] **Base Field Detection**: ace-context detects `context.base` in frontmatter and processes it
- [ ] **Protocol Resolution**: `prompt://` protocols are resolved to actual file paths
- [ ] **Content Loading**: Base content is loaded and becomes primary document body
- [ ] **Proper Ordering**: Base content appears first, followed by sections
- [ ] **Backward Compatibility**: Existing configs without `base` continue to work
- [ ] **ace-review Integration**: When ace-review uses `context.base`, system.prompt.md contains both base and sections
- [ ] **Error Messages**: Clear, actionable error messages for missing files or invalid protocols

### Validation Questions

- [ ] **Protocol Support**: Should we support only `prompt://` or also other protocols like `file://`, `wfi://`?
- [ ] **Base Location**: Should base content come before or after the context metadata header?
- [ ] **Multiple Bases**: Should we support multiple base files or just one?
- [ ] **Base Caching**: Should base content be cached separately from sections?

## Objective

Enable generic base content handling in ace-context so that any tool (ace-review, ace-docs, etc.) can compose a primary document body with additional processed sections. This eliminates the need for tool-specific base handling and provides a consistent pattern across the ACE ecosystem.

## Scope of Work

### User Experience Scope
- Developers using ace-context directly with context files
- Tools like ace-review that generate context files for ace-context processing
- Any workflow that needs to combine base instructions with dynamic content

### System Behavior Scope
- Base field detection and validation in context configuration
- Protocol resolution for base content references
- Content loading and primary document composition
- Section processing and appending after base
- Error handling for missing or invalid base references

### Interface Scope
- `context.base` field in frontmatter
- Support for protocol-based references (`prompt://`)
- Backward compatibility with existing configurations

### Deliverables

#### Behavioral Specifications
- Base field processing flow definition
- Protocol resolution behavior
- Content composition rules (base + sections)
- Error handling specifications

#### Validation Artifacts
- Test scenarios for base field handling
- Integration test with ace-review
- Error condition validation

## Out of Scope

- ❌ **Multiple Base Files**: Only single base file support in initial implementation
- ❌ **Base Templating**: No variable substitution or templating within base content
- ❌ **Dynamic Base Selection**: No conditional base file selection based on runtime conditions
- ❌ **Base Content Transformation**: No processing or modification of base content itself

## References

- Current issue: ace-review `--preset pr` produces empty system.prompt.md
- Root cause: ace-context doesn't process `instructions.base` field
- Solution: Move base to `instructions.context.base` and add ace-context support
- Benefits: Generic, reusable pattern for any tool using ace-context
