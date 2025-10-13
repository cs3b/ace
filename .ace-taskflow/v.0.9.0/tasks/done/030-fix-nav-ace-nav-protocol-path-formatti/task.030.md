---
id: v.0.9.0+task.030
status: done
estimate: 1h
dependencies: []
sort: 997
---

# Fix ace-nav protocol path formatting and support protocol-only queries

## Behavioral Context

**Issue**: ace-nav was displaying incorrect URIs with full absolute paths and didn't support protocol-only queries for resource discovery.

**Key Behavioral Requirements**:
- URIs should show relative paths from the protocol's base directory
- Protocol-only URIs (e.g., `tmpl://`) should list all resources of that type
- Maintain backward compatibility with specific resource lookups

## Objective

Fixed ace-nav to properly format protocol URIs with relative paths and added automatic wildcard support for protocol-only queries.

## Scope of Work

- Fixed path calculation in protocol scanner to properly compute relative paths
- Added CLI support for protocol-only URIs to automatically append wildcards
- Ensured resource resolver uses relative paths in URI construction

### Deliverables

#### Modify
- `ace-nav/lib/ace/nav/cli.rb` - Added protocol-only URI detection and auto-wildcard
- `ace-nav/lib/ace/nav/molecules/protocol_scanner.rb` - Fixed relative path calculation

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported that `ace-nav "tmpl://*" --list` showed URIs like `tmpl:///Users/mc/Ps/ace-meta/dev-handbook/templates/user-docs/user-guide` instead of `tmpl://user-docs/user-guide`
- **Investigation**: Found that the path substitution in `protocol_scanner.rb` wasn't properly removing the base path
- **Solution**:
  - Normalized search paths to ensure consistent path separator handling
  - Used string slicing instead of substitution for more reliable path extraction
  - Added regex pattern matching in CLI to detect protocol-only URIs
- **Validation**: Tested with multiple protocols to ensure both fixes work correctly

### Technical Details

In `protocol_scanner.rb`:
```ruby
# Ensure search_path ends with a separator for proper substitution
normalized_search_path = search_path.end_with?("/") ? search_path : "#{search_path}/"

# Calculate relative path from the search path
if file_path.start_with?(normalized_search_path)
  relative_path = file_path[normalized_search_path.length..]
else
  # Fallback to original logic
  relative_path = file_path.sub("#{search_path}/", "")
end
```

In `cli.rb`:
```ruby
# Check if it's a protocol-only URI (e.g., "tmpl://")
if path_or_uri.match?(/^\w+:\/\/$/)
  # Protocol-only URI, add wildcard and force list mode
  path_or_uri = "#{path_or_uri}*"
  @options[:list] = true
end
```

### Testing/Validation

```bash
# Test wildcard listing with correct paths
ace-nav "tmpl://*" --list
# Result: tmpl://binstubs/build → /Users/mc/Ps/ace-meta/dev-handbook/templates/binstubs/build.template.md

# Test protocol-only query
ace-nav tmpl://
# Result: Same as above, automatically lists all templates

# Test specific resource lookup still works
ace-nav tmpl://user-docs/user-guide
# Result: /Users/mc/Ps/ace-meta/dev-handbook/templates/user-docs/user-guide.template.md
```

**Results**: All tests passed. URIs now show relative paths and protocol-only queries work as expected.

## References

- Commit: 12a90e7c - fix(ace-nav): improve protocol path formatting and support protocol-only queries
- Related issues: User-reported formatting issue with `ace-nav "tmpl://*" --list`
- Documentation: May need to update ace-nav usage docs to mention protocol-only query support
- Follow-up needed: None - issue fully resolved