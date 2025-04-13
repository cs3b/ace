# Release Documentation Structure

## Overview
This document describes the standard structure for release documentation. Each release version follows this template to ensure consistent documentation.

## Core Directories
Each release version (v.x.x.x) contains the following directories:
Each release version follows semantic versioning (MAJOR.MINOR.PATCH) format with an incremental sequence number. For example:
- v.0.1.0-001/
- v.0.1.0-002/
- v.0.1.1-003/

This ensures proper chronological ordering of release documentation regardless of version numbers.

- `codemods/`: Code migration scripts and transformation tools
- `decisions/`: Architecture Decision Records (ADRs) and technical choices
- `docs/`: Feature specifications and API documentation
- `researches/`: Technical investigation findings and prototypes
- `retro/`: Release retrospective notes and lessons learned
- `tasks/`: Implementation tasks and development sessions
- `test-cases/`: Test scenarios and validation criteria
- `user-experience/`: Usage examples, tutorials and UX flows

## Release Types and Required Documentation

### Bug Fix Release (v.0.0.x)
Minimum required directories:
- `docs/` - Bug description and fix details
- `tasks/` - Implementation tasks
- `test-cases/` - Regression tests
- `retro/` - What we learned

### Feature Release (v.0.x.0)
Required directories:
- `docs/` - Feature specification
- `decisions/` - Technical decisions
- `tasks/` - Implementation tasks and sessions
- `test-cases/` - Feature validation
- `user-experience/` - Usage examples
- `retro/` - Release learnings

### Major Release (v.x.0.0)
All directories should be included, with special attention to:
- `codemods/` - Migration tooling
- `decisions/` - Major architectural changes
- `docs/` - Complete feature documentation
- `researches/` - Investigation results
- `tasks/` - Detailed implementation plan and sessions
- `test-cases/` - Comprehensive test suite
- `user-experience/` - Detailed tutorials
- `retro/` - In-depth retrospective

## Using Templates
1. Create a new version directory: `v.x.x.x/`
2. Copy relevant directories from template structure
3. Remove any unnecessary directories based on release type
4. Create `v.x.x.x-codename.md` for release overview
5. Create task templates in `tasks/` directory
6. Fill in templates using standardized formats

## Version Directory Structure
```
docs-dev/guides/release-template/
├── prepare-release-documentation.md
└── v.x.x.x
    ├── codemods
    │   └── _template.md
    ├── decisions
    │   └── _template.md
    ├── docs
    │   └── _template.md
    ├── researches
    │   └── _template.md
    ├── retro
    │   └── _template.md
    ├── tasks
    │   └── _tempalte.md
    ├── test-cases
    │   └── _template.md
    ├── user-expierience
    │   └── _template.md
    └── v.x.x.x-codename.md

10 directories, 10 files

```

## Task Management
Tasks are managed in the `tasks/` directory with:
- `_template.md`: Base template for new tasks
- Individual task files for specific implementation work
- Development session records and progress tracking
