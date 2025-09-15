---
id: v.0.3.0+task.233
status: done
priority: low
estimate: 6h
dependencies: [v.0.3.0+task.225, v.0.3.0+task.226, v.0.3.0+task.227, v.0.3.0+task.228, v.0.3.0+task.229, v.0.3.0+task.230, v.0.3.0+task.231, v.0.3.0+task.232]
---

# Update PathResolver for Future Integration

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools/lib/coding_agent_tools/molecules | grep -A2 -B2 path_resolver
```

_Result excerpt:_

```
├── path_autocorrector.rb
├── path_config_loader.rb
├── path_resolver.rb
├── project_sandbox.rb
├── provider_model_parser.rb
```

## Objective

Prepare PathResolver to use ReleaseManager for release-relative path resolution. This foundation work enables future nav-path and create-path commands to support patterns like `release:reflections/file.md`, creating a unified path resolution system across all tools.

## Scope of Work

- Add ReleaseManager as optional dependency to PathResolver
- Design release-relative path pattern (e.g., `release:path`)
- Implement pattern detection and routing
- Integrate with existing path resolution logic
- Maintain backward compatibility
- Document new patterns for future use

### Deliverables

#### Create

- None

#### Modify

- dev-tools/lib/coding_agent_tools/molecules/path_resolver.rb
- dev-tools/spec/coding_agent_tools/molecules/path_resolver_spec.rb

#### Delete

- None

## Phases

1. Design release-relative pattern syntax
2. Add ReleaseManager integration
3. Implement pattern routing
4. Update existing resolution logic
5. Document for future nav-path/create-path updates

## Implementation Plan

### Planning Steps

* [ ] Review current PathResolver implementation
* [ ] Design pattern syntax (release:path vs other options)
* [ ] Plan integration points with ReleaseManager
* [ ] Consider impact on existing functionality

### Execution Steps

- [ ] Add ReleaseManager dependency injection
  ```ruby
  def initialize(config_loader = nil, sandbox = nil, release_manager = nil)
    @release_manager = release_manager || ReleaseManager.new
  end
  ```
- [ ] Add pattern detection for release-relative paths
  ```ruby
  def is_release_relative?(path)
    path.start_with?("release:")
  end
  ```
- [ ] Implement release-relative resolution
  ```ruby
  def resolve_release_relative(path)
    subpath = path.sub(/^release:/, "")
    @release_manager.resolve_path(subpath)
  end
  ```
- [ ] Update main resolve_path method to route appropriately
- [ ] Add comprehensive tests for new functionality
- [ ] Document pattern usage for future reference

## Acceptance Criteria

- [x] PathResolver can resolve release:reflections patterns
- [x] Integration with ReleaseManager is clean
- [x] Existing path resolution still works
- [x] New pattern is well-documented
- [x] Tests cover new functionality
- [x] Foundation is ready for nav-path/create-path integration

## Completion Summary

**Status**: ✅ **COMPLETED**

All acceptance criteria have been met:

1. **Release-relative pattern support**: Implemented `release:subpath` syntax that resolves paths relative to current release directory
2. **Clean ReleaseManager integration**: Added optional dependency injection with proper fallback to default instance
3. **Backward compatibility maintained**: All existing tests pass (86 examples, 0 failures)
4. **Comprehensive documentation**: Added detailed class documentation with examples and usage patterns
5. **Full test coverage**: Added 17 new tests covering all scenarios including error handling and edge cases
6. **Ready for future integration**: Clean API design ready for nav-path and create-path command enhancements

**Key Features Implemented**:
- Pattern detection: `is_release_relative?(path)` method
- Path resolution: `resolve_release_relative(path_input)` method
- Integration with main resolver: Updated `resolve_path` to route release-relative patterns appropriately
- Security: Inherits ReleaseManager's path validation and sandbox restrictions
- Error handling: Comprehensive error handling for SecurityError and StandardError scenarios

## Out of Scope

- ❌ Actually updating nav-path command
- ❌ Actually updating create-path command
- ❌ Changing existing path resolution behavior
- ❌ Adding CLI interface for new patterns

## References

- PathResolver: dev-tools/lib/coding_agent_tools/molecules/path_resolver.rb
- Future integration: This prepares for nav-path and create-path enhancements
- Pattern design: Consider consistency with existing scoped patterns
- Depends on all previous tasks being completed