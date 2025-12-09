---
id: v.0.9.0+task.152
status: draft
priority: medium
estimate: TBD
dependencies: []
---

# ace-context: Auto-format output based on line count threshold

## Behavioral Specification

### User Experience
- **Input**: Users invoke `ace-context` with a preset, file path, or protocol (e.g., `ace-context project`)
- **Process**: System retrieves context and evaluates output format - if content is below 500 lines and no explicit output format is specified, content is returned directly; otherwise, file path is returned
- **Output**: Either context content displayed inline (< 500 lines) or file path provided for reading (>= 500 lines or explicit format specified)

### Expected Behavior

When users run `ace-context` without specifying an explicit output format:
- For content below 500 lines: Display content directly to stdout
- For content at or above 500 lines: Display file path to stdout
- When explicit output format is defined: Honor the specified format regardless of line count

This provides intelligent defaults that balance immediate usability (short content shown inline) with performance (long content via file path).

### Interface Contract

```bash
# Default behavior - auto-format based on line count
ace-context project
# If result < 500 lines: prints content directly
# If result >= 500 lines: prints file path

# Explicit format overrides auto-formatting
ace-context project --format content
# Always prints content regardless of size

ace-context project --format path
# Always prints file path regardless of size

# Protocol-based invocation
ace-context wfi://load-context
# Follows same auto-format logic
```

**Error Handling:**
- Invalid preset/file: Display clear error message
- File not found: Report missing resource
- Format parsing errors: Fall back to file path output

**Edge Cases:**
- Exactly 500 lines: Treat as >= 500 (return file path)
- Empty content: Return content directly (0 lines < 500)
- Multiple formats specified: Last format takes precedence

### Success Criteria

- [ ] **Auto-format behavior**: Content < 500 lines returns inline, >= 500 lines returns path (when no format specified)
- [ ] **Explicit format override**: --format flag overrides automatic behavior
- [ ] **Backward compatibility**: Existing explicit format specifications continue to work
- [ ] **User feedback**: Clear indication when file path is returned (e.g., "Context saved to: <path>")

### Validation Questions

- [ ] **Threshold value**: Is 500 lines the right threshold, or should it be configurable?
- [ ] **Format detection**: Should we consider terminal size/capabilities when auto-formatting?
- [ ] **Default behavior**: Should default favor content or path for edge cases?
- [ ] **Transition experience**: How do we communicate this change to existing users?

## Objective

Improve ace-context UX by providing intelligent output formatting that balances immediate usability (showing short content inline) with performance and readability (providing file paths for long content). Users shouldn't need to manually specify format for common use cases.

## Scope of Work

- **User Experience Scope**: ace-context command behavior when output format is not explicitly specified
- **System Behavior Scope**: Automatic output format selection based on content line count
- **Interface Scope**: ace-context CLI command and its --format flag behavior

### Deliverables

#### Behavioral Specifications
- Auto-format logic specification (line count threshold)
- Format override behavior specification
- User feedback for path-based output

#### Validation Artifacts
- Test scenarios for < 500 lines (expect content)
- Test scenarios for >= 500 lines (expect path)
- Test scenarios for explicit format flags
- Backward compatibility validation

## Out of Scope

- ❌ **Implementation Details**: How line counting is performed, file storage mechanisms
- ❌ **Performance Optimization**: Caching strategies, content processing optimizations
- ❌ **Configuration System**: User-configurable thresholds (future enhancement)
- ❌ **Alternative Formats**: JSON, YAML, or other structured output formats

## References

- Source idea: `.ace-taskflow/v.0.9.0/ideas/done/20251102-104953-context-enhance/auto-format-based-on-line-count.s.md`
- Related to: ace-context tool enhancement for better UX
