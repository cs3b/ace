---
id: v.0.9.0+task.008
status: pending
priority: low
estimate: 3h
dependencies: [v.0.9.0+task.005, v.0.9.0+task.006, v.0.9.0+task.007]
sort: 982
---

# Configure .ace for This Project

## Objective

Create project-specific .ace/ directory structure with configurations for all four gems (core, context, git, capture). This establishes the config cascade for the ace-meta project itself and documents config precedence.

## Scope of Work

- Create project-specific .ace/ directory structure
- Configure core settings for project needs
- Configure git conventions for ace-meta
- Configure context presets for project documentation
- Configure capture paths for ideas
- Document config precedence and cascade behavior

### Deliverables

#### Create

- .ace/settings.yml
- .ace/git.yml
- .ace/context.yml
- .ace/capture.yml
- .ace/README.md (explaining structure and precedence)

## Implementation Plan

### Planning Steps

* [ ] Review project-specific requirements
* [ ] Design config values for ace-meta project
* [ ] Plan directory organization
* [ ] Document precedence rules clearly

### Execution Steps

- [ ] Create .ace directory structure
  ```bash
  mkdir -p .ace
  ```

- [ ] Configure .ace/settings.yml
  ```yaml
  # Project-specific core configuration for ace-meta
  ace:
    project: "ace-meta"
    version: "0.9.0"
    config_cascade:
      search_paths:
        - "./.ace"
        - "~/.ace"
      merge_strategy: deep
      array_merge: replace  # or append
    logging:
      level: info
      file: "./logs/ace.log"
    cache:
      enabled: true
      directory: "./.ace/cache"
  ```

- [ ] Configure .ace/git.yml
  ```yaml
  # Git conventions for ace-meta project
  git:
    conventions:
      format: conventional
      scopes:
        enabled: true
        custom:
          - core
          - context
          - git
          - capture
          - taskflow
          - handbook
          - docs
          - release
    intentions:
      default: feat
      aliases:
        f: feat
        b: fix
        d: docs
        r: refactor
        t: test
        c: chore
    commit:
      template: |
        %{intention}%{scope}: %{description}

        %{body}
      verify: true
  ```
  > TEST: Git config loads
  > Type: Manual verification
  > Assert: ace-gc uses project conventions
  > Command: ace-gc feat "test message" --dry-run

- [ ] Configure .ace/context.yml
  ```yaml
  # Context presets for ace-meta project
  context:
    presets:
      default:
        include:
          - "README.md"
          - "docs/blueprint.md"
          - "CLAUDE.md"

      project:
        include:
          - "README.md"
          - "docs/architecture.md"
          - "docs/blueprint.md"
          - "docs/what-do-we-build.md"
          - "docs/decisions.md"
          - "CLAUDE.md"

      release:
        include:
          - "dev-taskflow/roadmap.md"
          - "dev-taskflow/backlog/v.*/README.md"
          - "CHANGELOG.md"

      gems:
        include:
          - "ace-*/README.md"
          - "ace-*/*.gemspec"
          - "Gemfile"

    output:
      format: markdown
      cache: true
      cache_dir: "./.ace/cache/context"
  ```

- [ ] Configure .ace/capture.yml
  ```yaml
  # Capture configuration for ace-meta project
  capture:
    directory: "./dev-taskflow/backlog/ideas"
    template: |
      # %{title}

      %{content}

      ## Context
      - Date: %{timestamp}
      - Project: ace-meta
      - Phase: monorepo-migration
      %{tags}

    timestamp_format: "%Y%m%d-%H%M"

    file_naming:
      pattern: "%{timestamp}-%{slug}.md"
      max_slug_length: 50

    auto_commit: false  # Don't auto-commit captured ideas
  ```

- [ ] Create .ace/README.md explaining the structure
  ```markdown
  # ACE Configuration Directory

  This directory contains project-specific configurations for ace-meta.

  ## Directory Structure

  ```
  .ace/
  ├── settings.yml    # Core gem configuration
  ├── context.yml     # Context presets
  ├── git.yml         # Git conventions
  ├── capture.yml     # Idea capture settings
  └── README.md                  # This file
  ```

  ## Configuration Precedence

  Configurations are loaded in this order (last wins):
  1. Gem defaults (in each gem's config/ directory)
  2. User home (~/.ace/*.yml)
  3. Project local (./.ace/*.yml)

  ## Merge Strategy

  - YAML files are deep-merged
  - Arrays are replaced by default (configurable)
  - Environment variables override all

  ## Testing Configuration

  ```bash
  # Test core config loading
  ruby -r ace/core -e "p Ace::Core::ConfigResolver.load('core')"

  # Test context presets
  context --preset project

  # Test capture
  capture "Test idea"

  # Test git conventions
  ace-gc feat --dry-run
  ```
  ```

- [ ] Test config loading for each gem
  > TEST: Core config loads
  > Type: Manual verification
  > Assert: Project config overrides defaults
  > Command: ruby -r ace/core -e "p Ace::Core::ConfigResolver.load('core')"

- [ ] Test precedence with home directory config
  ```bash
  # Create test config in home
  mkdir -p ~/.ace/core/config
  echo "ace:\n  test: home" > ~/.ace/core/config/core.yml

  # Verify project overrides home
  ruby -r ace/core -e "p Ace::Core::ConfigResolver.load('core')"
  ```

- [ ] Document environment variable overrides
  ```bash
  # Environment variables can override configs
  export ACE_CORE_LOG_LEVEL=debug
  export ACE_GIT_INTENTION_DEFAULT=fix
  export ACE_CAPTURE_DIRECTORY=./tmp/ideas
  ```

- [ ] Verify all gems use project config
  > TEST: All gems load config
  > Type: Integration
  > Assert: Each gem uses .ace/ configs
  > Command: for gem in core context git capture; do echo "=== $gem ===" && ruby -r ace/$gem -e "p Ace::${gem^}::VERSION"; done

## Acceptance Criteria

- [ ] .ace/ directory structure created
- [ ] All four config files present and valid
- [ ] README documents structure and precedence
- [ ] Configs appropriate for ace-meta project
- [ ] Config cascade works correctly
- [ ] Each gem loads its project config
- [ ] Precedence rules documented and tested

## Out of Scope

- ❌ User home directory configs
- ❌ Environment-specific configs (dev/test/prod)
- ❌ Config validation schemas
- ❌ Config migration from old format
- ❌ GUI config editor