---
id: v.0.6.0+task.003
status: completed
priority: high
estimate: 3h
actual: 1h
completed_at: 2025-09-16
dependencies: [v.0.6.0+task.001, v.0.6.0+task.002]
---

# Update Configuration Files

## Objective

Update all configuration files to reflect the new `.ace/*` structure and `AceTools` module naming, including gem specifications, linting configs, and shell setup scripts.

## Scope of Work

- Update gemspec with new gem name and module
- Update Ruby linting configurations
- Update shell environment setup scripts
- Update YAML configuration files in .coding-agent/

### Deliverables

#### Create

- None

#### Modify

- `.ace/tools/coding_agent_tools.gemspec` → `.ace/tools/ace_tools.gemspec`
- `.ace/tools/.rubocop.yml`
- `.ace/tools/.standard.yml`
- `.ace/tools/config/bin-setup-env/setup.fish`
- `.ace/tools/config/bin-setup-env/setup.sh`
- `.coding-agent/*.yml` files
- `.gitmodules`

#### Delete

- `.ace/tools/coding_agent_tools.gemspec` (after renaming)

## Implementation Plan

### Planning Steps

* [x] List all configuration files requiring updates
* [x] Document current gem version for proper versioning
* [x] Plan backward compatibility strategy

### Execution Steps

- [x] Rename and update gemspec file:
  - Rename file to `ace_tools.gemspec`
  - Update gem name to "ace-tools"
  - Update module references
  - Update file lists
  - Update version constant path
  > TEST: Gemspec Validity
  > Type: Ruby Validation
  > Assert: Gemspec loads without errors
  > Command: cd .ace/tools && ruby -e "require './ace_tools.gemspec'"

- [x] Update .rubocop.yml:
  - Update module namespaces
  - Update file patterns
  - Update exclusion patterns

- [x] Update .standard.yml:
  - Update project paths
  - Update ignore patterns

- [x] Update shell setup scripts:
  - setup.fish: Update PATH additions and function definitions
  - setup.sh: Update PATH exports and aliases
  > TEST: Shell Setup
  > Type: Shell Test
  > Assert: Setup scripts execute without errors
  > Command: bash -n .ace/tools/config/bin-setup-env/setup.sh

- [x] Update .coding-agent/*.yml configurations:
  - context.yml: Update template paths
  - task-manager.yml: Update taskflow paths
  - path.yml: Update all path references
  - tree.yml: Update exclusion patterns
  > TEST: YAML Validity
  > Type: YAML Parse Test
  > Assert: All YAML files parse correctly
  > Command: ruby -ryaml -e "Dir['.coding-agent/*.yml'].each {|f| YAML.load_file(f)}"

- [x] Update .gitmodules:
  - Update submodule paths from dev-* to .ace/*
  - Ensure submodule URLs remain correct

## Acceptance Criteria

- [x] Gemspec loads and builds successfully
- [x] Linting tools recognize new structure
- [x] Shell setup scripts work correctly
- [x] All YAML configurations are valid
- [x] Git submodules properly configured

## Out of Scope

- ❌ Running the actual configuration updates (task 004)
- ❌ Testing the gem installation (task 005)
- ❌ Documentation updates (task 006)