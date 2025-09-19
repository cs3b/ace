---
id: v.0.9.0+task.001
status: pending
priority: high
estimate: 6h
dependencies: []
---

# Create Minimal ace-core Gem

## Objective

Create the foundational ace-core gem that provides config cascade resolution and basic shared functionality for all other ace-* gems. This gem must be standalone with no dependencies on other ace-* gems.

## Scope of Work

- Set up gem skeleton structure with standard Ruby gem conventions
- Implement .ace cascade config search mechanism (deepest wins)
- Add .env file handling for environment variables
- Create YAML config loader with deep-merge functionality
- Include default configuration and samples
- Set up basic error handling and logging

### Deliverables

#### Create

- ace-core/ace-core.gemspec
- ace-core/lib/ace/core.rb
- ace-core/lib/ace/core/version.rb
- ace-core/lib/ace/core/config_resolver.rb
- ace-core/lib/ace/core/yaml_loader.rb
- ace-core/lib/ace/core/env_handler.rb
- ace-core/lib/ace/core/errors.rb
- ace-core/config/core.yml (gem defaults)
- ace-core/test/test_helper.rb
- ace-core/Rakefile
- ace-core/README.md
- .ace/core/config/core.yml (project sample)

## Implementation Plan

### Planning Steps

* [ ] Review existing config loading code in dev-tools
* [ ] Identify minimal set of shared functionality needed
* [ ] Design config cascade resolution algorithm
* [ ] Plan directory search order (./ → ~/ → gem defaults)

### Execution Steps

- [ ] Create gem skeleton using bundle gem or manual structure
  ```bash
  mkdir -p ace-core/{lib/ace/core,test,config}
  ```

- [ ] Create ace-core.gemspec with minimal dependencies
  ```ruby
  # Only standard library and essential gems
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  ```

- [ ] Implement ConfigResolver class for cascade search
  > TEST: Config cascade resolution
  > Type: Unit Test
  > Assert: Local config overrides home, home overrides gem defaults
  > Command: cd ace-core && rake test TEST=test/config_resolver_test.rb

- [ ] Implement YAML loader with deep-merge
  > TEST: YAML deep merge
  > Type: Unit Test
  > Assert: Nested hashes merge correctly, arrays handled per config
  > Command: cd ace-core && rake test TEST=test/yaml_loader_test.rb

- [ ] Add .env file handling
  > TEST: Environment variable loading
  > Type: Unit Test
  > Assert: .env files load and override system env vars
  > Command: cd ace-core && rake test TEST=test/env_handler_test.rb

- [ ] Create default config/core.yml with structure
  ```yaml
  ace:
    version: "0.9.0"
    config_cascade:
      search_paths:
        - "./.ace"
        - "~/.ace"
      merge_strategy: deep
  ```

- [ ] Create sample .ace/core/config/core.yml for project

- [ ] Set up test helper with shared utilities

- [ ] Write README.md with usage examples

## Acceptance Criteria

- [ ] Gem structure follows Ruby conventions
- [ ] Config cascade works: ./.ace → ~/.ace → gem defaults
- [ ] YAML files load and merge correctly
- [ ] .env files are processed
- [ ] All tests pass with minitest
- [ ] No dependencies on other ace-* gems
- [ ] README documents usage and config structure

## Out of Scope

- ❌ Complex plugin system (add later as needed)
- ❌ Migration of all atoms/molecules from dev-tools
- ❌ Performance optimizations
- ❌ Compatibility shims for old commands