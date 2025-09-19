---
id: v.0.9.0+task.005
status: pending
priority: medium
estimate: 6h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002, v.0.9.0+task.003, v.0.9.0+task.004]
---

# Create ace-context Gem

## Objective

Create the ace-context gem that provides context loading functionality, migrating the essential parts of the current context command. This gem depends on ace-core for config cascade resolution.

## Scope of Work

- Set up gem skeleton with proper structure
- Add dependency on ace-core in gemspec
- Port minimal context command functionality
- Use ace-core for config loading from .ace/context/
- Include default config with basic presets
- Write tests using shared infrastructure from ace-core

### Deliverables

#### Create

- ace-context/ace-context.gemspec
- ace-context/lib/ace/context.rb
- ace-context/lib/ace/context/version.rb
- ace-context/lib/ace/context/loader.rb
- ace-context/lib/ace/context/preset_manager.rb
- ace-context/exe/context
- ace-context/config/context.yml (gem defaults)
- ace-context/test/test_helper.rb
- ace-context/test/context_loader_test.rb
- ace-context/test/preset_manager_test.rb
- ace-context/Rakefile
- ace-context/README.md
- .ace/context/config/context.yml (project sample)

#### Modify

- Gemfile (add ace-context entry)

## Implementation Plan

### Planning Steps

* [ ] Review current context command implementation
* [ ] Identify minimal functionality to port
* [ ] Design preset structure
* [ ] Plan config schema for context

### Execution Steps

- [ ] Create gem skeleton
  ```bash
  mkdir -p ace-context/{lib/ace/context,test,config,exe}
  ```

- [ ] Create ace-context.gemspec
  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-context"
    spec.version = "0.9.0"
    spec.summary = "Context loading for ACE"

    spec.add_dependency "ace-core", "~> 0.9.0"

    spec.add_development_dependency "minitest"
    spec.add_development_dependency "rake"
  end
  ```

- [ ] Implement context loader
  ```ruby
  # lib/ace/context/loader.rb
  module Ace
    module Context
      class Loader
        def initialize(config = nil)
          @config = config || Ace::Core::ConfigResolver.load('context')
        end

        def load_preset(name)
          # Load context based on preset
        end
      end
    end
  end
  ```
  > TEST: Context loader functionality
  > Type: Unit Test
  > Assert: Presets load correctly
  > Command: cd ace-context && rake test TEST=test/context_loader_test.rb

- [ ] Create context executable
  ```ruby
  #!/usr/bin/env ruby
  # exe/context
  require 'ace/context'

  preset = ARGV[0] || 'default'
  loader = Ace::Context::Loader.new
  puts loader.load_preset(preset)
  ```

- [ ] Create default config/context.yml
  ```yaml
  context:
    presets:
      default:
        include:
          - "README.md"
          - "docs/blueprint.md"
      project:
        include:
          - "README.md"
          - "docs/**/*.md"
          - "CLAUDE.md"
    output:
      format: markdown
      cache: true
  ```

- [ ] Create sample .ace/context/config/context.yml
  ```yaml
  context:
    presets:
      ace-meta:
        include:
          - "README.md"
          - "docs/architecture.md"
          - "dev-taskflow/roadmap.md"
  ```

- [ ] Set up test helper
  ```ruby
  # test/test_helper.rb
  require 'minitest/autorun'
  require 'ace/context'
  # Reuse test utilities from ace-core
  ```

- [ ] Write context loader tests
  ```ruby
  class ContextLoaderTest < Minitest::Test
    def test_loads_default_preset
      # Test default preset loading
    end

    def test_loads_custom_preset
      # Test custom preset from config
    end
  end
  ```

- [ ] Write preset manager tests
  > TEST: Preset management
  > Type: Unit Test
  > Assert: Presets merge and resolve correctly
  > Command: cd ace-context && rake test

- [ ] Update root Gemfile
  ```ruby
  gem "ace-context", path: "ace-context"
  ```

- [ ] Run bundle install
  > TEST: Gem integration
  > Type: Integration
  > Assert: ace-context loads with ace-core
  > Command: bundle install && bundle exec context --help

- [ ] Create README with usage
  ```markdown
  # ace-context

  Context loading for ACE projects.

  ## Usage
  ```
  context --preset project
  ```
  ```

## Acceptance Criteria

- [ ] Gem structure follows conventions
- [ ] Depends on ace-core for config loading
- [ ] Context command works with presets
- [ ] Config loads from .ace/context/
- [ ] Tests pass using minitest
- [ ] README documents usage
- [ ] Integrates with root Gemfile

## Out of Scope

- ❌ Full template parsing functionality
- ❌ Complex file embedding
- ❌ Command execution in templates
- ❌ Cache management (basic only)