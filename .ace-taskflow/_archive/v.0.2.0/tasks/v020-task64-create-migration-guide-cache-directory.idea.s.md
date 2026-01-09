---
id: v.0.2.0+task.64
status: done
priority: critical
estimate: 1.5h
dependencies: []
---

# Create Migration Guide for Cache Directory Location Change

## Objective / Problem

The XDG-compliant caching system has moved the cache directory from legacy `~/.coding-agent-tools-cache` to the standards-compliant `~/.cache/coding-agent-tools` (or as defined by `XDG_CACHE_HOME`). Users must be aware of this change to avoid confusion during the automatic migration process. Without proper documentation, users may not understand why their cache location has changed or how to handle migration issues.

## Directory Audit

Current documentation structure:
```
docs/
├── README.md
├── SETUP.md
├── MIGRATION.md (needs new section)
└── other guides...

docs-project/current/v.0.2.1-synapse/doc_review/task-61/
└── dr-report-gpro-final.md (source of this requirement)
```

## Scope of Work

Create comprehensive migration documentation for the cache directory location change, including automatic migration behavior and manual recovery procedures.

## Deliverables

1. **MIGRATION.md Updates**:
   - Add new section: "Cache Directory Location Change"
   - Explain the move from `~/.coding-agent-tools-cache` to XDG-compliant location
   - Document automatic migration behavior
   - Provide manual migration and troubleshooting steps

2. **README.md Updates**:
   - Reference the migration guide for users upgrading
   - Brief mention of the cache location change

## Phases

1. **Research Migration Behavior**: Understand the exact automatic migration process
2. **Write Migration Guide**: Create comprehensive documentation
3. **Update Cross-References**: Ensure other docs point to the migration guide

## Implementation Plan

### Planning Steps
* [x] Review the XDGDirectoryResolver and CacheManager implementation to understand migration behavior
* [x] Identify all scenarios where migration might occur or fail
* [x] Determine what environment variables affect the new cache location

### Execution Steps
- [x] Add "Cache Directory Location Change" section to docs/MIGRATION.md
- [x] Document the path change from `~/.coding-agent-tools-cache` to `~/.cache/coding-agent-tools`
- [x] Explain automatic migration triggers (first run of cache-using commands)
- [x] Document environment variables that affect cache location (`XDG_CACHE_HOME`, `HOME`)
- [x] Provide manual migration instructions for edge cases
- [x] Add troubleshooting section for migration failures
- [x] Update README.md to reference the migration guide
- [x] Validate that all documented procedures work correctly

## Acceptance Criteria

- [x] MIGRATION.md contains comprehensive cache directory migration documentation
- [x] Users understand the path change and automatic migration behavior
- [x] Manual migration procedures are documented for edge cases
- [x] Environment variable influences on cache location are explained
- [x] Troubleshooting steps are provided for migration failures
- [x] README.md references the migration guide appropriately
- [x] All documented procedures have been tested and work correctly

## Out of Scope

- Changes to the migration implementation itself
- Documentation of other XDG compliance features
- Updates to API documentation

## References & Risks

- **Source**: `docs-project/current/v.0.2.1-synapse/doc_review/task-61/dr-report-gpro-final.md` section 9 (Critical priority item)
- **Risk**: Users may be confused by unexpected cache location changes without proper documentation
- **Risk**: Manual cache management workflows may break without migration guidance
- **Testing**: Manual verification of migration procedures and environment variable behavior