# XDG Base Directory Specification Implementation Plan

## XDG Specification Requirements

Based on the XDG Base Directory Specification, cache data should be stored according to these rules:

### Cache Directory Resolution
- **Primary**: `$XDG_CACHE_HOME` if set and non-empty
- **Fallback**: `$HOME/.cache` if `$XDG_CACHE_HOME` is unset or empty
- **Application subdirectory**: `/coding-agent-tools/` should be appended

### Key Requirements
1. Environment variable `XDG_CACHE_HOME` takes precedence
2. Must fall back to `~/.cache` when XDG_CACHE_HOME is not set
3. Create directories if they don't exist
4. Handle permissions appropriately (0700 for user directories)
5. Application should create its own subdirectory within the cache directory

### Implementation Path Structure
- `$XDG_CACHE_HOME/coding-agent-tools/` or `$HOME/.cache/coding-agent-tools/`
- Subdirectories for different cache types:
  - `models/` - LLM model information cache
  - `http/` - HTTP response cache (if needed)
  - `temp/` - Temporary cache files

### Migration Strategy
1. Check for existing cache at `~/.coding-agent-tools-cache`
2. If found, migrate to XDG-compliant location
3. Create symlink from old location to new location for compatibility
4. Log migration process for user visibility

### Error Handling
- Handle cases where directories cannot be created
- Fall back gracefully when permissions are insufficient
- Provide clear error messages for troubleshooting

## Implementation Components

### XDGDirectoryResolver
- Responsible for resolving XDG-compliant cache directory paths
- Handle environment variable reading and fallback logic
- Directory creation with proper permissions

### CacheManager
- Manage cache operations with XDG-compliant paths
- Handle migration from old cache locations
- Provide unified interface for cache operations

### Integration Points
- Update all existing cache usage to use CacheManager
- Ensure backward compatibility during transition
- Update documentation and user guidance