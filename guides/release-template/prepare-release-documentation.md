# Release Documentation Structure

## Overview
This document describes the standard structure for release documentation. Each release version follows this template to ensure consistent documentation.

## Core Directories
Each release version (v.x.x.x) contains the following directories:

- `codemods/`: Code migration scripts and transformation tools
- `decisions/`: Architecture Decision Records (ADRs) and technical choices
- `docs/`: Feature specifications and API documentation
- `researches/`: Technical investigation findings and prototypes
- `retro/`: Release retrospective notes and lessons learned
- `test-cases/`: Test scenarios and validation criteria
- `user-experience/`: Usage examples, tutorials and UX flows

## Release Types and Required Documentation

### Bug Fix Release (v.0.0.x)
Minimum required directories:
- `docs/` - Bug description and fix details
- `test-cases/` - Regression tests
- `retro/` - What we learned

### Feature Release (v.0.x.0)
Required directories:
- `docs/` - Feature specification
- `decisions/` - Technical decisions
- `test-cases/` - Feature validation
- `user-experience/` - Usage examples
- `retro/` - Release learnings

### Major Release (v.x.0.0)
All directories should be included, with special attention to:
- `codemods/` - Migration tooling
- `decisions/` - Major architectural changes
- `docs/` - Complete feature documentation
- `researches/` - Investigation results
- `test-cases/` - Comprehensive test suite
- `user-experience/` - Detailed tutorials
- `retro/` - In-depth retrospective

## Using Templates
1. Create a new version directory: `v.x.x.x/`
2. Copy relevant directories from `_template/`
3. Remove any unnecessary directories based on release type
4. Create `v.x.x.x-codename.md` for release overview
5. Fill in templates using standardized formats

## Version Directory Structure
```
v.x.x.x/
├── codemods/
├── decisions/
├── docs/
├── researches/
├── retro/
├── test-cases/
├── user-experience/
└── v.x.x.x-codename.md
```
