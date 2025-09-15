---
id: v.0.3.0+task.31
status: done
priority: high
estimate: 6h
dependencies: [v.0.3.0+task.08]
---

# Implement Binstub Installation System

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-tools | sed 's/^/    /'
```

_Result excerpt:_

```
    dev-tools
    ├── bin
    │   ├── build
    │   ├── console
    │   ├── lint
    │   ├── lint-cassettes
    │   ├── lint-security
    │   ├── setup
    │   └── test
    ├── coding_agent_tools.gemspec
    ├── coverage
    │   ├── assets
    │   └── index.html
    ├── docs
    │   └── tools.md
    ├── exe
    │   ├── coding_agent_tools
    │   ├── generate-review-prompt
    │   ├── llm-models
    │   ├── llm-query
    │   ├── llm-usage-report
    │   └── task-manager
    ├── exe-old
    │   ├── _binstubs
    │   ├── diff-list-modified-files.rb
    │   ├── fetch-github-pr-data.rb
    │   ├── get-all-tasks
    │   ├── get-current-release-path.sh
    │   ├── get-next-task
    │   ├── get-next-task-id
    │   ├── get-recent-git-log
    │   ├── get-recent-tasks
    │   ├── lint-md-links.rb
    │   ├── lint-task-metadata
    │   ├── markdown-sync-embedded-documents
    │   ├── show-directory-tree
    │   └── test-get-current-release-path.sh
    ├── Gemfile
    ├── Gemfile.lock
    ├── lib
    │   ├── coding_agent_tools
    │   └── coding_agent_tools.rb
    ├── LICENSE
    ├── Rakefile
    ├── README.md
    ├── sig
    │   └── coding_agent_tools.rbs
    └── spec
        ├── cassettes
        ├── cli
        ├── coding_agent_tools
        ├── coding_agent_tools_spec.rb
        ├── integration
        ├── README.md
        ├── spec_helper.rb
        ├── support
        └── vcr_setup.rb
```

## Objective

Create a modern, configuration-driven binstub installation system that allows easy management and generation of shell binstubs for the coding_agent_tools gem. This system replaces manual binstub maintenance with an automated, scalable approach that follows the gem's ATOM architecture and shell binstub patterns.

## Scope of Work

* Create configuration file for binstub aliases mapping
* Implement CLI command to install/generate binstubs
* Build ATOM-based architecture for binstub generation
* Replace legacy task management binstubs with generated ones
* Provide extensible system for future binstub additions

### Deliverables

#### Create

* dev-tools/config/binstub-aliases.yml
* lib/coding_agent_tools/cli/commands/install_binstubs.rb
* lib/coding_agent_tools/atoms/yaml_reader.rb
* lib/coding_agent_tools/molecules/binstub_generator.rb
* lib/coding_agent_tools/organisms/binstub_installer.rb
* spec files for all new components

#### Modify

* bin/tn (regenerate using new system)
* bin/tr (regenerate using new system)
* bin/tal (regenerate using new system)
* bin/tnid (regenerate using new system)
* lib/coding_agent_tools/cli.rb (register new command)

#### Delete

* bin/rc (moved to release-manager, no longer needed)

## Phases

1. Configuration and Architecture Setup
2. ATOM Components Implementation
3. CLI Command Integration
4. Binstub Generation and Replacement
5. Testing and Validation

## Implementation Plan

### Planning Steps

* [x] Analyze existing shell binstub patterns from dev-handbook guide
  > TEST: Pattern Understanding
  > Type: Pre-condition Check
  > Assert: Shell binstub template structure is understood
  > Command: head -20 dev-handbook/.meta/gds/shell-binstub-patterns.g.md
* [x] Design YAML configuration schema for binstub aliases
* [x] Plan ATOM component architecture for binstub generation
* [x] Review existing legacy binstubs to understand current behavior

### Execution Steps

- [x] Create YAML configuration file with task-manager and llm aliases
  > TEST: Configuration File Creation
  > Type: File Validation
  > Assert: YAML file exists and is valid
  > Command: ruby -e "require 'yaml'; puts YAML.load_file('dev-tools/config/binstub-aliases.yml')" 
- [x] Implement YamlReader atom for configuration loading
- [x] Implement BinstubGenerator molecule for shell script generation
- [x] Implement BinstubInstaller organism for orchestrating installation
- [x] Create InstallBinstubs CLI command class
- [x] Register command in main CLI module
- [x] Generate and replace legacy task management binstubs
  > TEST: Binstub Functionality
  > Type: Integration Test
  > Assert: Generated binstubs work identically to legacy ones
  > Command: bin/tn --help && bin/tr --help && bin/tal --help && bin/tnid --help
- [x] Remove bin/rc as it's moved to release-manager
- [x] Create comprehensive test suite for all components
- [x] Test argument passing and backward compatibility

## Acceptance Criteria

* [x] Configuration file defines all current binstub mappings
* [x] CLI command successfully generates binstubs from configuration
* [x] Generated binstubs follow shell binstub patterns exactly
* [x] All legacy task management binstubs replaced and functional
* [x] New system is extensible for future command additions
* [x] Comprehensive test coverage for all components
* [x] Documentation updated to reflect new installation process

## Out of Scope

* ❌ Migrating other binstub types beyond task management
* ❌ Creating GUI or interactive installation interface  
* ❌ Modifying the core shell binstub pattern structure
* ❌ Adding features to existing CLI commands

## References

* Dependency: v.0.3.0+task.08 (CLI commands implementation)
* Shell binstub patterns: dev-handbook/.meta/gds/shell-binstub-patterns.g.md
* Current legacy binstubs: bin/tn, bin/tr, bin/tal, bin/tnid
* ATOM architecture: docs/architecture.md