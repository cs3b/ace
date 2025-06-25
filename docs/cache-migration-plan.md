# Cache Migration Strategy

## Current State Analysis

The current cache implementation uses:
- **Cache Directory**: `~/.coding-agent-tools-cache` (hardcoded in `lib/coding_agent_tools/cli/commands/llm/models.rb:450`)
- **Cache Files**: `{provider}_models.yml` (e.g., `google_models.yml`, `lmstudio_models.yml`)
- **Cache Data Structure**: YAML format with cached_at timestamp, provider, and models array

## Migration Strategy

### Phase 1: Backward-Compatible Introduction
1. Create XDGDirectoryResolver and CacheManager
2. Detect existing cache location (`~/.coding-agent-tools-cache`)
3. If found, continue using old location with deprecation warning
4. If not found, use XDG-compliant location

### Phase 2: Data Migration
1. On first run with XDG system:
   - Check for old cache directory
   - If found, copy all files to new XDG location
   - Create migration marker file to avoid repeated migrations
   - Preserve timestamps and data integrity

### Phase 3: Cleanup (Future Release)
1. Remove old cache directory after successful migration
2. Remove backward compatibility code
3. Clean up any temporary migration artifacts

## Migration Implementation Details

### Directory Structure Mapping
```
OLD: ~/.coding-agent-tools-cache/
├── google_models.yml
├── lmstudio_models.yml
└── other_provider_models.yml

NEW: $XDG_CACHE_HOME/coding-agent-tools/ or ~/.cache/coding-agent-tools/
├── models/
│   ├── google_models.yml
│   ├── lmstudio_models.yml
│   └── other_provider_models.yml
├── http/ (for future HTTP caching)
└── temp/ (for temporary files)
```

### Migration Process
1. **Detection**: Check if `~/.coding-agent-tools-cache` exists
2. **Create Target**: Ensure XDG cache directory exists
3. **Copy Files**: Copy all cache files preserving timestamps
4. **Verify**: Confirm data integrity after migration
5. **Mark Complete**: Create `.migration_complete` marker
6. **Cleanup**: Optionally remove old directory (with user consent)

### Error Handling
- Handle insufficient disk space
- Handle permission errors
- Provide clear error messages
- Allow manual migration if automatic fails
- Fall back to old location if migration fails

### User Communication
- Log migration process at INFO level
- Notify user of cache location change
- Provide option to disable migration warnings
- Document new cache location in user documentation

### Rollback Strategy
- Keep old cache directory until migration is verified
- Provide command to revert to old cache location if needed
- Support both cache locations during transition period

## Data Integrity Considerations

### File Validation
- Verify YAML structure after migration
- Check file timestamps and sizes
- Validate model data consistency
- Handle corrupted cache files gracefully

### Atomic Operations
- Use temporary directories during migration
- Atomic moves to prevent partial migrations
- Lock files to prevent concurrent access
- Rollback mechanism for failed migrations

## Testing Strategy

### Unit Tests
- Test XDGDirectoryResolver path resolution
- Test CacheManager migration functionality
- Test error handling scenarios
- Test file operation edge cases

### Integration Tests
- Test full migration workflow
- Test concurrent access scenarios
- Test migration rollback scenarios
- Test different filesystem permissions

### Manual Testing
- Test on different operating systems
- Test with various XDG_CACHE_HOME configurations
- Test with existing cache data
- Test with corrupted cache files