---
id: v.0.9.0+task.009
status: pending
priority: low
estimate: 4h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.005, v.0.9.0+task.006, v.0.9.0+task.007, v.0.9.0+task.008]
sort: 969
---

# Create Migration Documentation

## Objective

Document the new gem structure, config approach, and migration process. Create READMEs for each gem and write an ADR (Architecture Decision Record) for the monorepo approach. This documentation enables future phases of migration and helps developers understand the new structure.

## Scope of Work

- Document gem structure and config approach
- Create simple README per gem
- Write ADR for monorepo decision
- Document config cascade resolution
- Create migration notes for future phases
- Update main project documentation

### Deliverables

#### Create

- ace-core/README.md
- ace-context/README.md
- ace-git/README.md
- ace-capture/README.md
- docs/decisions/ADR-015-monorepo-with-multiple-gems.md
- docs/migrations/v0.9.0-monorepo-phase1.md
- docs/gem-structure.md

#### Modify

- README.md (update with new structure info)
- docs/architecture.md (add monorepo section)

## Implementation Plan

### Planning Steps

* [ ] Review existing documentation structure
* [ ] Identify key concepts to document
* [ ] Plan migration guide sections
* [ ] Determine ADR number and format

### Execution Steps

- [ ] Create ace-core/README.md
  ```markdown
  # ace-core

  Foundation gem providing config cascade resolution and shared utilities for ACE.

  ## Installation

  Add to your gem's gemspec:
  ```ruby
  spec.add_dependency "ace-core", "~> 0.9.0"
  ```

  ## Usage

  ### Config Loading
  ```ruby
  config = Ace::Core::ConfigResolver.load('mypackage')
  # Searches: ./.ace/mypackage/ → ~/.ace/mypackage/ → gem defaults
  ```

  ### Environment Handling
  ```ruby
  Ace::Core::EnvHandler.load('.env')
  ```

  ## Configuration

  Default config location: `config/core.yml`
  Override locations:
  - Project: `./.ace/core/config/core.yml`
  - User: `~/.ace/core/config/core.yml`

  ## Development

  ```bash
  bundle install
  rake test
  ```
  ```

- [ ] Create ace-context/README.md
  ```markdown
  # ace-context

  Context loading and preset management for ACE projects.

  ## Installation

  ```bash
  gem install ace-context
  ```

  ## Usage

  ```bash
  # Load default preset
  context

  # Load specific preset
  context --preset project

  # List available presets
  context --list
  ```

  ## Configuration

  Configure presets in `.ace/context/config/context.yml`

  ## Dependencies

  - ace-core for config management
  ```

- [ ] Create ace-git/README.md
  ```markdown
  # ace-git

  Simplified git tools for monorepo development.

  ## Installation

  ```bash
  gem install ace-git
  ```

  ## Commands

  ### ace-gc - Git Commit

  ```bash
  # Auto-detect intention from staged changes
  ace-gc

  # Specify intention
  ace-gc feat
  ace-gc fix
  ace-gc docs

  # Commit specific files
  ace-gc feat README.md
  ```

  ## Configuration

  Configure in `.ace/git/config/git.yml`

  ## Why Simplified?

  - No submodule complexity
  - Single repository focus
  - Clean conventional commits
  ```

- [ ] Create ace-capture/README.md
  ```markdown
  # ace-capture

  Quick idea capture for development.

  ## Installation

  ```bash
  gem install ace-capture
  ```

  ## Usage

  ```bash
  capture "Your idea here"
  ```

  Ideas are saved with timestamps to configured directory.

  ## Configuration

  Configure in `.ace/capture/config/capture.yml`
  ```

- [ ] Write ADR for monorepo decision
  ```markdown
  # ADR-015: Adopt Monorepo Structure with Multiple Gems

  ## Status
  Accepted

  ## Context
  The ACE project has grown complex with mixed directory structures,
  submodules, and duplicated functionality. We need a cleaner
  organization that maintains modularity while simplifying development.

  ## Decision
  Transform ACE into a monorepo with multiple Ruby gems at the root,
  each prefixed with `ace-`. Start with minimal migration of 4 core
  gems, then incrementally migrate remaining functionality.

  ## Consequences

  ### Positive
  - Clear gem boundaries and dependencies
  - Reusable components
  - Simplified config management
  - Easier testing and CI/CD
  - No submodule complexity

  ### Negative
  - Migration effort required
  - Temporary dual structure during transition
  - Need to update all documentation

  ## Implementation
  Phase 1 (v0.9.0): ace-core, ace-context, ace-git, ace-capture
  Phase 2: ace-handbook, ace-taskflow
  Phase 3: ace-llm, remaining tools
  ```

- [ ] Create migration guide
  ```markdown
  # Monorepo Migration - Phase 1

  ## Overview
  Version 0.9.0 begins the transformation to a monorepo structure
  with modular Ruby gems.

  ## What Changed

  ### New Structure
  ```
  ace-meta/
  ├── ace-core/      # Config and shared utilities
  ├── ace-context/   # Context loading
  ├── ace-git/       # Git tools (simplified)
  ├── ace-capture/   # Idea capture
  └── .ace/          # Project configs
  ```

  ### Config System
  - Cascade resolution: project → home → gem defaults
  - Each gem has own config namespace
  - Deep merge with configurable array handling

  ## Migration Steps

  ### For Developers
  1. Pull latest changes
  2. Run `bundle install` in root
  3. Test new commands

  ### For CI/CD
  1. Update build scripts to use root Gemfile
  2. Run tests per gem
  3. Package gems separately

  ## Breaking Changes
  - No submodule commands in ace-git
  - Config paths changed to .ace/
  - Some commands renamed

  ## Next Phases
  - Phase 2: Migrate handbook and taskflow
  - Phase 3: Migrate LLM tools
  - Phase 4: Remove legacy structure
  ```

- [ ] Create gem structure documentation
  ```markdown
  # ACE Gem Structure

  ## Gem Dependency Graph
  ```
  ace-core (standalone)
    ├── ace-context
    ├── ace-git
    └── ace-capture
  ```

  ## Gem Responsibilities

  | Gem | Purpose | Key Commands |
  |-----|---------|--------------|
  | ace-core | Config, utilities | (library only) |
  | ace-context | Context loading | context |
  | ace-git | Git tools | ace-gc |
  | ace-capture | Idea capture | capture |

  ## Adding New Gems

  1. Create gem structure
  2. Add ace-core dependency
  3. Update root Gemfile
  4. Add config support
  5. Write tests
  6. Document

  ## Testing

  ```bash
  # Test individual gem
  cd ace-core && rake test

  # Test all gems
  for gem in ace-*; do
    echo "Testing $gem"
    cd $gem && rake test && cd ..
  done
  ```
  ```

- [ ] Update main README.md
  > TEST: Documentation complete
  > Type: Manual review
  > Assert: All sections accurate
  > Command: grep -c "ace-core" README.md

- [ ] Update docs/architecture.md
  ```markdown
  ## Monorepo Architecture

  As of v0.9.0, ACE is transitioning to a monorepo structure...
  ```

- [ ] Create documentation index
  ```markdown
  ## Documentation Guide

  - Project Overview: README.md
  - Architecture: docs/architecture.md
  - Gem Structure: docs/gem-structure.md
  - Migration Guide: docs/migrations/v0.9.0-monorepo-phase1.md
  - ADRs: docs/decisions/
  ```

## Acceptance Criteria

- [ ] Each gem has clear README
- [ ] ADR documents monorepo decision
- [ ] Migration guide explains changes
- [ ] Config cascade documented
- [ ] Gem structure diagram created
- [ ] Main docs updated with new info
- [ ] Examples provided for common tasks

## Out of Scope

- ❌ API documentation generation
- ❌ Video tutorials
- ❌ Interactive documentation site
- ❌ Automated migration scripts
- ❌ Detailed class documentation