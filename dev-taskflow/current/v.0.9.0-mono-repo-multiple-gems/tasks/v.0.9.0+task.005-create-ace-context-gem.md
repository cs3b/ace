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

- ace-context/.bundle/config (BUNDLE_GEMFILE pointing to parent)
- ace-context/ace-context.gemspec
- ace-context/lib/ace/context.rb
- ace-context/lib/ace/context/version.rb
- ace-context/lib/ace/context/organisms/context_loader.rb
- ace-context/lib/ace/context/molecules/preset_manager.rb
- ace-context/lib/ace/context/atoms/ (utilities as needed)
- ace-context/lib/ace/context/models/ (data structures)
- ace-context/exe/context
- ace-context/config/context.yml (gem defaults)
- ace-context/test/test_helper.rb
- ace-context/test/support/test_environment.rb
- ace-context/test/support/config_helpers.rb
- ace-context/test/organisms/context_loader_test.rb
- ace-context/test/molecules/preset_manager_test.rb
- ace-context/test/integration/context_integration_test.rb
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

- [ ] Create gem skeleton following ATOM architecture
  ```bash
  mkdir -p ace-context/{lib/ace/context/{atoms,molecules,organisms,models},test/{atoms,molecules,organisms,integration,support},config,exe,.bundle}
  ```

- [ ] Create .bundle/config for ace-context
  ```yaml
  # ace-context/.bundle/config
  ---
  BUNDLE_GEMFILE: "../Gemfile"
  ```
  > NOTE: This follows the Option C pattern established with ace-core
  > Allows ace-context to use shared root Gemfile for all dependencies

- [ ] Create ace-context.gemspec
  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-context"
    spec.version = "0.9.0"
    spec.summary = "Context loading for ACE"

    spec.add_dependency "ace-core", "~> 0.9.0"

    # No development dependencies - managed in root Gemfile
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
  require 'minitest/reporters' # Available from root Gemfile
  require 'ace/context'
  # Reuse test utilities from ace-core which now has 80 passing tests
  # Task 003 established Minitest infrastructure with:
  #   - AceTestCase base class with fixtures support
  #   - TestHelper module with temp dir/file utilities
  #   - Minitest::Reporters for better output
  # Task 004 added integration test infrastructure with:
  #   - TestEnvironment for isolated test environments
  #   - ConfigHelpers for config testing utilities
  #   - Integration test patterns for config cascade testing
  ```

- [ ] Copy test support utilities from ace-core
  ```bash
  cp -r ../ace-core/test/support ace-context/test/
  ```
  > NOTE: Reuse TestEnvironment and ConfigHelpers for integration testing

- [ ] Write context loader tests
  ```ruby
  # test/organisms/context_loader_test.rb
  class ContextLoaderTest < AceTestCase
    def test_loads_default_preset
      # Test default preset loading
    end

    def test_loads_custom_preset
      # Test custom preset from config
    end
  end
  ```

- [ ] Write integration tests
  ```ruby
  # test/integration/context_integration_test.rb
  class ContextIntegrationTest < AceTestCase
    include Ace::Core::TestSupport::ConfigHelpers

    def setup
      @env = Ace::Core::TestSupport::TestEnvironment.new
      @env.setup
    end

    def teardown
      @env.teardown
    end

    def test_full_context_loading_with_config_cascade
      # Test context loading with ace-core config cascade
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
  > NOTE: Root Gemfile configuration:
  > - No vendor/bundle (gems install to mise Ruby location)
  > - Shared dev dependencies (minitest ~> 5.20, rake ~> 13.0, minitest-reporters ~> 1.6)
  > - All gems use .bundle/config to reference parent Gemfile

- [ ] Run bundle install from root
  > TEST: Gem integration
  > Type: Integration
  > Assert: ace-context loads with ace-core
  > Command: bundle install && bundle exec context --help
  > NOTE: Run from project root, not ace-context directory
  > The .bundle/config will ensure proper Gemfile resolution

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