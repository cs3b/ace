---
id: v.0.9.0+task.020
status: done
estimate: 4h
dependencies: [v.0.9.0+task.018]
---

# Refactor ace-nav to follow standard ace configuration cascade pattern

## Behavioral Context

**Issue**: ace-nav was initially implemented to scan .ace.example/protocols/ directories in installed gems, which violated the ace configuration cascade pattern and could lead to automatic code loading from gems without user consent.

**Key Behavioral Requirements**:
- Configuration should follow standard ace cascade (project > user, no automatic gem loading)
- Users must explicitly enable protocols/sources by copying to .ace/ directories
- Support environment variable expansion in source paths ($PROJECT_ROOT_PATH, $HOME)
- Each protocol source defines its complete path (no default directories)

## Objective

Refactored ace-nav to follow the standard ace configuration cascade pattern, removing automatic gem scanning and implementing explicit protocol/source registration.

## Scope of Work

- Removed automatic gem discovery from ConfigLoader and SourceRegistry
- Integrated ace-core for standard directory traversal
- Created modular protocol/source separation
- Fixed environment variable expansion
- Added support for legacy file extensions

### Deliverables

#### Create
- ace-nav/lib/ace/nav/molecules/source_registry.rb
- ace-nav/lib/ace/nav/molecules/protocol_scanner.rb
- ace-nav/lib/ace/nav/models/protocol_source.rb
- .ace/protocols/*.yml (protocol definitions)
- .ace/protocols/{protocol}-sources/*.yml (source registrations)

#### Modify
- ace-nav/lib/ace/nav/molecules/config_loader.rb (removed gem discovery)
- ace-nav/lib/ace/nav/molecules/resource_resolver.rb (use ProtocolScanner directly)
- ace-nav/lib/ace/nav/organisms/navigation_engine.rb (use ProtocolScanner)
- ace-nav/.ace.example/protocols/*.yml (removed directory field)

#### Delete
- Gem discovery methods from ConfigLoader
- Hardcoded protocol lists from UriParser

## Implementation Summary

### What Was Done

- **Problem Identification**: Discovered that scanning .ace.example/protocols/ in gems violated security and configuration principles
- **Investigation**: Studied ace-core's ConfigDiscovery and ProjectRootFinder patterns
- **Solution**: Implemented standard cascade using DirectoryTraverser from ace-core
- **Validation**: Tested with multiple sources and protocols

### Technical Details

The refactoring separated protocol definitions (what) from source registrations (where):
- Protocols define: extensions, capabilities, templates
- Sources define: complete paths to resources
- Discovery follows: project .ace/ > user ~/.ace/ (no gem scanning)

### Testing/Validation

Successfully tested:
- Protocol discovery from .ace/protocols/
- Source registration from .ace/protocols/{protocol}-sources/
- Environment variable expansion ($PROJECT_ROOT_PATH)
- Legacy .wf.md extension support
- Task protocol still functional

## Out of Scope

- ❌ Performance optimization with caching (follow-up task needed)
- ❌ Migration scripts for existing gem-based configurations
- ❌ Additional protocol types beyond current workflow and task

## References

- Commits: cb533f87 "refactor(taskflow): implement release and task management commands"
- Related: task.018 (original ace-nav implementation)
- Follow-up needed: Performance optimization with caching

```