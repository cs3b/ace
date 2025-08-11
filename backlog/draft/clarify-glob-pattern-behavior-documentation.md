---
id: v.0.5.0+task.009
status: draft
priority: medium
estimate: 2h
dependencies: ["v.0.5.0+task.006"]
needs_review: false
---

# Clarify glob pattern behavior in documentation

## Summary

Update documentation to clearly explain glob pattern behavior, particularly the difference between `spec/**` and `spec/**/*`, to prevent user confusion when using the search tool.

## Context

Following the search tool simplification work (task.006), user feedback has identified confusion around glob pattern behavior. Users are unclear about the difference between patterns like `spec/**` and `spec/**/*`, which can lead to unexpected search results and frustration.

The current documentation lacks clear examples and explanations of how different glob patterns behave, making it difficult for users to construct effective search queries.

## Behavioral Specification

### User Experience
- **Input**: User reads documentation about glob patterns
- **Process**: Clear examples and explanations guide proper pattern usage
- **Output**: User can confidently construct glob patterns for their search needs

### Expected Behavior

The documentation should provide comprehensive guidance on glob pattern usage with practical examples and clear explanations of behavior differences.

Specifically:
1. **Pattern differences** should be clearly explained with examples
2. **Common use cases** should be documented with recommended patterns
3. **Troubleshooting section** should help users debug pattern issues
4. **Best practices** should guide effective pattern construction

### Interface Contract

```bash
# Documentation should clearly explain these differences:

# Matches directories and files at any depth under spec/
spec/**

# Matches only files (not directories) at any depth under spec/
spec/**/*

# Matches files directly in spec/ directory
spec/*

# Matches only Ruby files at any depth
spec/**/*.rb
```

### Success Criteria

- [ ] Add clear examples of glob pattern behavior to docs/tools.md
- [ ] Include explanation of trailing slash vs asterisk behavior
- [ ] Provide common use case examples with recommended patterns
- [ ] Add troubleshooting section for glob patterns
- [ ] Document the difference between `**` and `**/*` patterns
- [ ] Include examples for file type filtering patterns
- [ ] Add section on pattern performance considerations

## Technical Details

### Documentation Areas

**Core Pattern Explanation**
- Basic glob syntax and wildcards
- Directory traversal patterns (`**` vs `*`)
- File vs directory matching behavior
- Escaping special characters

**Common Patterns**
- Language-specific file filtering
- Directory-specific searches
- Mixed pattern combinations
- Exclusion patterns (if supported)

**Troubleshooting Guide**
- Pattern not matching expected files
- Too many or too few results
- Performance issues with broad patterns
- Platform-specific behavior differences

### Documentation Structure

```markdown
## Glob Pattern Guide

### Basic Patterns
- `*` - matches any characters except path separators
- `**` - matches any characters including path separators (recursive)
- `?` - matches any single character
- `[]` - matches any character inside brackets

### Directory vs File Matching
- `spec/**` - matches both directories and files
- `spec/**/*` - matches files only (not directories)
- `spec/*/` - matches directories only (with trailing slash)

### Common Use Cases
[Examples for typical search scenarios]

### Troubleshooting
[Solutions for common pattern issues]
```

## Implementation Approach

### Documentation Analysis
1. Review current glob pattern documentation in docs/tools.md
2. Identify gaps and unclear explanations
3. Collect common user confusion points from feedback
4. Research glob pattern standards and best practices

### Content Creation
1. **Core explanation**: Write clear basic pattern descriptions
2. **Comparative examples**: Show pattern differences side-by-side
3. **Use case scenarios**: Document common search patterns
4. **Troubleshooting guide**: Address typical user issues
5. **Performance notes**: Include pattern efficiency considerations

### Validation
1. Test all documented patterns against the actual search tool
2. Verify examples produce expected results
3. Review with users who reported confusion
4. Ensure consistency with tool implementation

## Risk Assessment

### Technical Risks
- **Risk:** Documentation may contradict actual tool behavior
  - **Probability:** Medium
  - **Impact:** High
  - **Mitigation:** Test all examples against real tool implementation
  - **Monitoring:** Regular validation of documented patterns

- **Risk:** Platform differences in glob behavior may cause confusion
  - **Probability:** Low
  - **Impact:** Medium
  - **Mitigation:** Document platform-specific differences if they exist
  - **Testing:** Validate patterns across different operating systems

### User Experience Risks
- **Risk:** Over-complex documentation may increase confusion
  - **Probability:** Medium
  - **Impact:** Medium
  - **Mitigation:** Use progressive disclosure, simple examples first
  - **Feedback:** Gather user feedback on documentation clarity

## Out of Scope

- ❌ **Tool Implementation Changes**: Modifying glob pattern behavior in the search tool
- ❌ **New Pattern Features**: Adding new glob pattern capabilities
- ❌ **Performance Optimization**: Improving glob pattern matching speed
- ❌ **Alternative Pattern Syntaxes**: Supporting regex or other pattern types

## References

- Task v.0.5.0+task.006: Search tool simplification that highlighted documentation gaps
- Current docs/tools.md documentation structure
- User feedback on glob pattern confusion
- Standard glob pattern specifications and best practices