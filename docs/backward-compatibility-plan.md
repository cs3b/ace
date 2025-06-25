# Backward Compatibility Plan

## Overview

Ensure smooth transition to XDG-compliant caching and retry middleware without breaking existing functionality or user workflows.

## Compatibility Phases

### Phase 1: Dual Support (Current Implementation)
- **Duration**: Initial release with new features
- **Behavior**: Support both old and new cache locations
- **Cache Priority**: 
  1. Use existing `~/.coding-agent-tools-cache` if present
  2. Fall back to XDG-compliant location for new installations
- **User Impact**: Zero - existing users see no change

### Phase 2: Migration Encouragement (Next Release)
- **Duration**: 1-2 releases after Phase 1
- **Behavior**: 
  - Auto-migrate cache data to XDG location
  - Show deprecation warning for old cache location
  - Continue supporting old location as fallback
- **User Impact**: Minimal - users see migration message

### Phase 3: XDG Default (Future Release)  
- **Duration**: 2-3 releases after Phase 2
- **Behavior**:
  - Default to XDG location for all operations
  - Read-only access to old cache location
  - Clear deprecation warnings
- **User Impact**: Low - old cache still accessible but not updated

### Phase 4: XDG Only (Long-term)
- **Duration**: 6+ months after Phase 3
- **Behavior**: Remove old cache location support entirely
- **User Impact**: Breaking change for users who haven't migrated

## Cache Location Compatibility

### Current Behavior (Baseline)
```ruby
def cache_dir
  @cache_dir ||= File.expand_path("~/.coding-agent-tools-cache")
end
```

### Phase 1: Detection Logic
```ruby
def cache_dir
  # Check for existing old cache first
  old_cache = File.expand_path("~/.coding-agent-tools-cache")
  if File.directory?(old_cache)
    return old_cache
  end
  
  # Use XDG-compliant location for new installations
  xdg_cache_dir
end
```

### Phase 2: Migration Logic
```ruby
def cache_dir
  old_cache = File.expand_path("~/.coding-agent-tools-cache")
  xdg_cache = xdg_cache_dir
  
  # Migrate if old cache exists and XDG doesn't
  if File.directory?(old_cache) && !File.directory?(xdg_cache)
    migrate_cache_data(old_cache, xdg_cache)
    show_migration_notice
  elsif File.directory?(old_cache)
    show_deprecation_warning
  end
  
  # Always prefer XDG location after migration
  xdg_cache
end
```

## API Compatibility

### Existing Public Interfaces
All existing CLI commands and options must continue to work:
- `llm-models google --refresh`
- `llm-models lmstudio --format json`
- All existing flags and behaviors

### New Features (Additive Only) 
- New context_size field in model info (nullable for compatibility)
- Enhanced retry behavior (configurable, default enabled)
- Better error messages and logging

### Configuration Compatibility
- Existing environment variables continue to work
- New environment variables for XDG and retry config
- Configuration files remain backward compatible

## Migration Safety Measures

### Data Integrity
```ruby
def migrate_cache_safely(source, target)
  # Create backup before migration
  backup_dir = "#{source}.backup.#{Time.now.to_i}"
  FileUtils.cp_r(source, backup_dir)
  
  begin
    # Perform migration with verification
    migrate_cache_data(source, target)
    verify_migration(source, target)
    
    # Clean up backup on success
    FileUtils.rm_rf(backup_dir)
  rescue => e
    # Restore from backup on failure
    FileUtils.rm_rf(target) if File.exist?(target)
    FileUtils.mv(backup_dir, source)
    raise e
  end
end
```

### Rollback Support
- Keep old cache directory until migration is verified
- Provide manual rollback command if needed
- Log all migration operations for debugging

## User Communication Strategy

### Migration Notices
```
INFO: Migrating cache from ~/.coding-agent-tools-cache to XDG-compliant location
INFO: Cache migrated to ~/.cache/coding-agent-tools (X files, Y MB)
INFO: Old cache directory preserved for safety
```

### Deprecation Warnings
```
WARN: Using deprecated cache location ~/.coding-agent-tools-cache
WARN: Please consider migrating to XDG-compliant location
WARN: Run 'llm-models --migrate-cache' to migrate data
WARN: Support for old location will be removed in future version
```

### Documentation Updates
- Update README with new cache location information
- Add migration guide to documentation
- Update troubleshooting guide with cache-related issues

## Testing Backward Compatibility

### Compatibility Test Matrix
- Test with existing cache data
- Test with no existing cache (new installation)
- Test with corrupted cache data
- Test with permission issues
- Test with XDG_CACHE_HOME set/unset

### Regression Tests
- Ensure all existing CLI commands continue to work
- Verify cache data format compatibility
- Test performance doesn't degrade
- Verify no breaking changes in JSON output

### Migration Tests
- Test successful migration scenarios
- Test failed migration recovery
- Test concurrent access during migration
- Test migration with disk space issues

## Error Handling Strategy

### Graceful Degradation
- Fall back to in-memory cache if filesystem issues
- Continue operation with reduced functionality
- Provide clear error messages for troubleshooting

### Error Recovery
- Automatic retry for transient filesystem errors
- Manual recovery commands for complex issues
- Comprehensive logging for debugging

## Long-term Maintenance

### Deprecation Timeline
- Phase 1: 0-3 months (dual support)
- Phase 2: 3-6 months (migration encouragement)  
- Phase 3: 6-12 months (XDG default)
- Phase 4: 12+ months (XDG only)

### Support Policy
- Maintain compatibility for at least 2 major versions
- Provide migration tools throughout transition
- Clear communication about breaking changes

### Cleanup Strategy
- Remove deprecated code paths after sufficient notice
- Clean up configuration options
- Simplify codebase once migration is complete