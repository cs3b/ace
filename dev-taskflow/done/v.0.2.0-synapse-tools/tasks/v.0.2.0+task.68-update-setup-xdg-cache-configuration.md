---
id: v.0.2.0+task.68
status: done
priority: high
estimate: 1h
dependencies: []
---

# Update SETUP.md - XDG Cache Directory Configuration

## Objective / Problem

The XDG-compliant caching system implementation has changed the cache directory location and introduced environment variable configuration options, but SETUP.md doesn't explain the new cache directory configuration. Users need to understand where cache files are stored and how to configure the cache location using XDG environment variables.

## Directory Audit

Current documentation structure:
```
docs/
├── SETUP.md (needs XDG cache section)
└── other docs...

lib/coding_agent_tools/atoms/
└── xdg_directory_resolver.rb (handles XDG cache resolution)

docs-project/current/v.0.2.1-synapse/doc_review/task-61/
└── dr-report-gpro-final.md (source of this requirement)
```

## Scope of Work

Update SETUP.md to explain the new XDG-compliant cache directory configuration, including default locations, environment variable influences, and configuration options.

## Deliverables

1. **New XDG Cache Section**:
   - Explain default cache directory location (`~/.cache/coding-agent-tools`)
   - Document environment variables that affect cache location
   - Provide configuration examples for different scenarios

2. **Setup Integration**:
   - Integrate cache configuration with existing setup instructions
   - Reference migration guide for users with existing caches

## Phases

1. **Configuration Research**: Understand XDG cache implementation and options
2. **Documentation Writing**: Create comprehensive cache configuration section
3. **Integration Review**: Ensure new section fits with existing SETUP.md structure

## Implementation Plan

### Planning Steps
* [x] Review `XDGDirectoryResolver` implementation to understand cache path resolution
* [x] Test environment variable behavior (`XDG_CACHE_HOME`, `HOME`)
* [x] Identify default cache location and fallback behaviors
* [x] Plan integration with existing SETUP.md structure

### Execution Steps
- [x] Add new section to SETUP.md explaining XDG-compliant cache directory
- [x] Document default cache location: `~/.cache/coding-agent-tools`
- [x] Explain `XDG_CACHE_HOME` environment variable configuration
- [x] Document `HOME` environment variable fallback behavior
- [x] Provide examples of cache directory configuration for different environments
- [x] Add note about automatic migration from legacy cache location
- [x] Reference migration guide for users with existing caches
- [x] Integrate cache configuration with existing setup workflow

## Acceptance Criteria

- [x] SETUP.md contains comprehensive XDG cache directory documentation
- [x] Default cache location (`~/.cache/coding-agent-tools`) is clearly documented
- [x] Environment variables that affect cache location are explained
- [x] Configuration examples are provided for common scenarios
- [x] Migration from legacy cache is referenced appropriately
- [x] New section integrates well with existing SETUP.md structure
- [x] All documented environment variable behaviors work as described

## Out of Scope

- Implementation changes to XDG cache system
- Detailed migration procedures (covered by migration guide task)
- Performance considerations of cache configuration
- Advanced cache management topics

## References & Risks

- **Source**: `docs-project/current/v.0.2.1-synapse/doc_review/task-61/dr-report-gpro-final.md` section 9 (High priority item)
- **XDG Base Directory Specification**: Reference for standard compliance
- **Migration Guide**: Task 64 - should be referenced for migration procedures
- **Risk**: Users may not understand cache location changes without proper setup documentation
- **Testing**: Manual verification of environment variable configuration examples