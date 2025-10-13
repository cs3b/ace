---
id: v.0.9.0+task.007
status: done
estimate: 6h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002, v.0.9.0+task.003, v.0.9.0+task.004]
needs_review: true
sort: 967
---

# Create ace-git-commit Gem with LLM Integration

## Design Decisions

### Resolved Based on User Feedback

1. **LLM Integration**: Use ace-llm Ruby classes directly (not subprocess)
2. **Repository Scope**: Single repository only (true monorepo)
3. **Default Model**: Use alias 'glite' from ace-llm config
4. **Template Location**: Store system prompts in dev-handbook/templates/prompts/
5. **Default Behavior**: Stage all changes by default unless --only-staged flag is used
6. **Interface**: Similar to existing git-commit with -i (intention) and -m (message) flags
7. **ace-llm QueryInterface**: Create new interface in ace-llm with named parameters matching CLI

## Objective

Create the ace-git-commit gem with LLM-powered commit message generation using ace-llm-query. Provide a clean interface for monorepo commits with automatic staging by default.

## Scope of Work

- Set up gem skeleton following ATOM architecture
- Add dependencies on ace-core and ace-llm in gemspec
- First: Create QueryInterface in ace-llm with named parameters
- Integrate with ace-llm QueryInterface (not subprocess)
- Copy system prompt from dev-tools to dev-handbook/templates/prompts/
- Support intention-based (-i) and direct message (-m) commits
- Default to staging all changes (explicit --only-staged for current staging)
- Include configuration with 'glite' as default model
- Write comprehensive tests using ace-test-support

## ace-llm Integration Plan

### QueryInterface Addition to ace-llm

Create a new QueryInterface in ace-llm that provides a simple Ruby API with named parameters matching the CLI:

```ruby
# ace-llm/lib/ace/llm/query_interface.rb
module Ace
  module LLM
    class QueryInterface
      # Named parameters match CLI flags exactly
      def self.query(provider_model, prompt,
                    output: nil,           # --output FILE
                    format: "text",        # --format FORMAT
                    temperature: nil,      # --temperature FLOAT
                    max_tokens: nil,       # --max-tokens INT
                    system: nil,           # --system TEXT
                    timeout: 30,           # --timeout SECONDS
                    force: false,          # --force
                    debug: false)          # --debug

        # Implementation that mirrors CLI behavior
        registry = Molecules::ClientRegistry.new
        parser = Molecules::ProviderModelParser.new(registry: registry)

        # Parse model/alias
        parse_result = parser.parse(provider_model)
        raise Error, parse_result.error unless parse_result.valid?

        # Build messages
        messages = []
        messages << { role: "system", content: system } if system
        messages << { role: "user", content: prompt }

        # Get client with options
        client = registry.get_client(
          parse_result.provider,
          model: parse_result.model,
          timeout: timeout
        )

        # Generate with optional parameters
        generation_opts = {}
        generation_opts[:temperature] = temperature if temperature
        generation_opts[:max_tokens] = max_tokens if max_tokens

        response = client.generate(messages, **generation_opts)

        # Handle output option if provided
        if output
          handler = Molecules::FormatHandlers.get_handler(format)
          formatted = handler.format(response)

          file_handler = Molecules::FileIoHandler.new
          file_handler.write_content(formatted, output, format: format, force: force)
        end

        response
      end
    end
  end
end
```

### ace-git-commit MessageGenerator Implementation

```ruby
# lib/ace/git_commit/molecules/message_generator.rb
module Ace
  module GitCommit
    class MessageGenerator
      def generate(diff, intention = nil)
        system_prompt = load_system_prompt
        user_prompt = build_user_prompt(diff, intention)

        # Direct Ruby call with named parameters matching CLI
        response = Ace::LLM::QueryInterface.query(
          @model,              # e.g., "glite"
          user_prompt,
          system: system_prompt,
          temperature: 0.7,
          timeout: 60
        )

        clean_commit_message(response[:text])
      end
    end
  end
end
```

### Benefits of This Approach

1. **One-to-one CLI mapping**: Named parameters match CLI flags exactly
2. **No subprocess overhead**: Direct Ruby method calls
3. **Better error handling**: Ruby exceptions instead of shell errors
4. **Easier testing**: Can mock QueryInterface.query
5. **Consistent interface**: Same parameter names as CLI users know

### Deliverables

#### Create in ace-llm

- ace-llm/lib/ace/llm/query_interface.rb (new QueryInterface class)

#### Modify in ace-llm

- ace-llm/lib/ace/llm.rb (require the new query_interface)

#### Create in ace-git-commit

- ace-git-commit/.bundle/config (BUNDLE_GEMFILE pointing to parent)
- ace-git-commit/ace-git-commit.gemspec (with ace-llm dependency)
- ace-git-commit/lib/ace/git_commit.rb
- ace-git-commit/lib/ace/git_commit/version.rb
- ace-git-commit/lib/ace/git_commit/organisms/commit_orchestrator.rb
- ace-git-commit/lib/ace/git_commit/molecules/diff_analyzer.rb
- ace-git-commit/lib/ace/git_commit/molecules/message_generator.rb
- ace-git-commit/lib/ace/git_commit/molecules/file_stager.rb
- ace-git-commit/lib/ace/git_commit/atoms/git_executor.rb
- ace-git-commit/lib/ace/git_commit/models/commit_options.rb
- ace-git-commit/exe/ace-git-commit
- ace-git-commit/config/git.yml (gem defaults with glite model)
- dev-handbook/templates/prompts/git-commit.system.md (system prompt)
- ace-git-commit/test/test_helper.rb
- ace-git-commit/test/support/ (copy from ace-core)
- ace-git-commit/test/organisms/commit_orchestrator_test.rb
- ace-git-commit/test/molecules/diff_analyzer_test.rb
- ace-git-commit/test/molecules/message_generator_test.rb
- ace-git-commit/test/integration/git_commit_integration_test.rb
- ace-git-commit/Rakefile
- ace-git-commit/README.md
- .ace/git/config/git.yml (project sample with glite)
- .ace-taskflow/v.0.9.0/t/007-feat-git-ace-git-gem-ace-gc-only/ux/usage.md

#### Modify

- ace-llm/lib/ace/llm.rb (require query_interface)
- Gemfile (add ace-git-commit entry)

## Implementation Plan

### Planning Steps

- [x] Review current git-commit complexity
- [x] Design simplified monorepo approach
- [x] Plan intention-based commit system
- [x] Define commit message conventions

### Execution Steps

- [x] Create gem skeleton following ATOM architecture

  ```bash
  mkdir -p ace-git/{lib/ace/git/{atoms,molecules,organisms,models},test/{atoms,molecules,organisms,integration,support},config,exe,.bundle}
  ```

- [x] Create .bundle/config for ace-git-commit

  ```yaml
  # ace-git/.bundle/config
  ---
  BUNDLE_GEMFILE: "../Gemfile"
  ```

  > NOTE: This follows the Option C pattern established with ace-core
  > Allows ace-git to use shared root Gemfile for all dependencies

- [x] Create ace-git-commit.gemspec

  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-git"
    spec.version = "0.9.0"
    spec.summary = "Git tools for ACE"

    spec.add_dependency "ace-core", "~> 0.9.0"

    # No development dependencies - managed in root Gemfile
  end
  ```

- [x] Set up test helper

  ```bash
  cp -r ../ace-core/test/support ace-git/test/
  ```

  > NOTE: Reuse TestEnvironment and ConfigHelpers for integration testing

- [x] Implement core components (atoms, molecules, organisms)

  ```ruby
  # lib/ace/git/organisms/commit_builder.rb
  module Ace
    module Git
      class CommitBuilder
        def initialize(config = nil)
          @config = config || Ace::Core::ConfigResolver.load('git')
        end

        def build(intention, files = nil)
          message = MessageFormatter.new(@config).format(intention)

          cmd = ['git', 'commit', '-m', message]
          cmd += files if files && !files.empty?

          system(*cmd)
        end
      end
    end
  end
  ```

  > TEST: Commit builder
  > Type: Unit Test
  > Assert: Builds correct git command
  > Command: cd ace-git && rake test TEST=test/commit_builder_test.rb

- [x] Implement GitExecutor atom

  ```ruby
  # lib/ace/git/intention_parser.rb
  module Ace
    module Git
      class IntentionParser
        INTENTIONS = {
          'feat' => 'feat',
          'fix' => 'fix',
          'docs' => 'docs',
          'style' => 'style',
          'refactor' => 'refactor',
          'test' => 'test',
          'chore' => 'chore'
        }

        def parse(input)
          return 'feat' if input.nil? || input.empty?

          INTENTIONS[input.downcase] || 'feat'
        end
      end
    end
  end
  ```

- [x] Implement DiffAnalyzer, MessageGenerator, FileStager molecules

  ```ruby
  # lib/ace/git/message_formatter.rb
  module Ace
    module Git
      class MessageFormatter
        def initialize(config)
          @config = config
        end

        def format(intention)
          diff = `git diff --cached --name-only`
          files = diff.split("\n")

          scope = detect_scope(files)
          description = generate_description(files, intention)

          "#{intention}#{scope}: #{description}"
        end

        private

        def detect_scope(files)
          # Simple scope detection based on paths
          return '' if files.empty?

          if files.all? { |f| f.start_with?('ace-') }
            gem = files.first.split('/').first
            "(#{gem})"
          else
            ''
          end
        end
      end
    end
  end
  ```

  > TEST: Message formatting
  > Type: Unit Test
  > Assert: Formats conventional commits
  > Command: cd ace-git && rake test TEST=test/message_formatter_test.rb

- [x] Create ace-git-commit executable

  ```ruby
  #!/usr/bin/env ruby
  # exe/ace-gc
  require 'ace/git'

  intention = ARGV[0] || 'feat'
  files = ARGV[1..-1]

  builder = Ace::Git::CommitBuilder.new
  success = builder.build(intention, files)

  exit(success ? 0 : 1)
  ```

- [x] Create default config/git.yml

  ```yaml
  git:
    conventions:
      format: conventional
      scopes:
        enabled: true
        detect_from_paths: true
    intentions:
      default: feat
      aliases:
        f: feat
        b: fix
        d: docs
        r: refactor
  ```

- [x] Create sample .ace/git/config/git.yml

  ```yaml
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
    intentions:
      default: feat
    signature:
      enabled: false  # No AI signature for now
  ```

- [x] Set up test helper

  ```ruby
  # test/test_helper.rb
  require 'minitest/autorun'
  require 'minitest/reporters' # Available from root Gemfile
  require 'ace/git'
  # Reuse test utilities from ace-core which already has 29 passing tests
  ```

- [x] Write comprehensive tests for all components

  ```ruby
  class CommitBuilderTest < Minitest::Test
    def test_builds_simple_commit
      # Test basic commit building
    end

    def test_includes_files_when_specified
      # Test file-specific commits
    end
  end
  ```

- [x] Run bundle install from root
  > TEST: Gem integration
  > Type: Integration
  > Assert: ace-git loads with ace-core
  > Command: bundle install && bundle exec ace-gc --help
  > NOTE: Run from project root, not ace-git directory
  > The .bundle/config will ensure proper Gemfile resolution

- [x] Write unit tests
  > TEST: ace-gc command
  > Type: Integration
  > Assert: Creates proper git commits
  > Command: cd test-repo && ace-gc feat

- [x] Update root Gemfile

  ```ruby
  gem "ace-git", path: "ace-git"
  ```

  > NOTE: Root Gemfile configuration:
  > - No vendor/bundle (gems install to mise Ruby location)
  > - Shared dev dependencies (minitest ~> 5.20, rake ~> 13.0, minitest-reporters ~> 1.6)
  > - All gems use .bundle/config to reference parent Gemfile

- [x] Create README

  ```markdown
  # ace-git

  Simplified git tools for ACE monorepo.

  ## Usage

  ```bash
  # Simple commit with auto-detection
  ace-gc

  # Commit with intention
  ace-gc feat
  ace-gc fix

  # Commit specific files
  ace-gc feat README.md
  ```

  No submodule complexity, just clean commits.

  ```

## Acceptance Criteria

- [x] Gem structure follows conventions
- [x] Depends on ace-core for config
- [x] ace-git-commit command created and functional
- [x] Direct ace-llm integration via QueryInterface
- [x] No submodule/multi-repo code
- [x] Config loads from .ace/git/
- [x] Tests pass using minitest (22 tests passing)
- [x] README documents usage
- [x] Integrates with root Gemfile
- [x] System prompt in dev-handbook/templates/prompts/

## Out of Scope

- ❌ Submodule handling
- ❌ Multi-repo coordination
- ❌ Other git commands (add, push, etc.)
- ❌ Complex commit templating
- ❌ AI-generated messages
