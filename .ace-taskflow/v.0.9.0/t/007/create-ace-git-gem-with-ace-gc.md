---
id: v.0.9.0+task.007
status: pending
priority: medium
estimate: 6h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002, v.0.9.0+task.003, v.0.9.0+task.004]
needs_review: true
sort: 981
---

# Create ace-git Gem with ace-gc Only

## Review Questions (Pending Human Input)

### [HIGH] Critical Implementation Questions

- [ ] **LLM Integration Migration Strategy**: The existing dev-tools git commit implementation includes sophisticated LLM integration (314-line GitOrchestrator, CommitMessageGenerator with multi-provider support, system prompts). Should this be:
  - **Research conducted**: Analyzed dev-tools implementation - full LLM integration with provider factory, multiple models (Google/Anthropic/OpenAI/etc), system prompt templates, intention-based generation
  - **Current complexity**: GitOrchestrator handles multi-repo operations, concurrent execution, LLM message generation, template loading, provider management
  - **Task specification**: Claims "simplified" and "Remove submodule-specific code" but unclear if this includes removing LLM features entirely
  - **Option A**: Migrate full LLM functionality to ace-git (complex, ~300+ lines)
  - **Option B**: Create simplified ace-gc without LLM (task examples show only basic intentions like 'feat', 'fix')
  - **Option C**: Hybrid approach - basic intentions with optional LLM enhancement
  - **Why needs human input**: Business decision on feature scope vs simplicity

- [ ] **Multi-Repository vs Mono-Repository Scope**: The current implementation handles complex multi-repository operations (submodules, cross-repo coordination, execution ordering). The task states "monorepo use" and "Remove all submodule and multi-repo complexity":
  - **Research conducted**: GitOrchestrator includes submodule detection, repository scanning, path dispatching, concurrent/sequential execution across repos
  - **Current features**: Multi-repo coordinator, path dispatcher, submodule-first execution ordering, cross-repository operations
  - **Task requirement**: "simplified git-commit (ace-gc) designed for monorepo use"
  - **Question**: Does "monorepo" mean single git repository operations only, or does it still need to handle the ace-meta monorepo structure with multiple ace-* gems?
  - **Why needs human input**: Scope clarification affects architecture significantly

- [ ] **Configuration and Intention System Design**: The task shows basic intention parsing (feat/fix/docs) but current implementation has rich configuration:
  - **Research conducted**: Current system loads configuration from multiple sources, supports complex intention contexts, has sophisticated message formatting
  - **Current features**: Configuration cascade (.ace/), intention-based prompting, commit message templates, multi-provider LLM selection
  - **Task examples**: Simple intentions ('feat', 'fix') with basic scope detection
  - **Design question**: Should ace-git configuration follow ace-core pattern with .ace/git/config/ cascade, or use simpler embedded defaults?
  - **Why needs human input**: Configuration complexity vs simplicity trade-off decision

### [MEDIUM] Implementation Approach Questions

- [ ] **ATOM Architecture Mapping**: How should the complex git operations map to ATOM layers?
  - **Research conducted**: Current GitOrchestrator is a large organism (~936 lines) handling multiple concerns
  - **ATOM pattern**: atoms/ (pure functions), molecules/ (operations), organisms/ (orchestration), models/ (data)
  - **Current mixing**: GitOrchestrator handles command building, execution, formatting, LLM integration, multi-repo coordination
  - **Suggested breakdown**:
    - Atoms: git command builders, message cleaners, intention parsers
    - Molecules: commit message formatter, config loader
    - Organisms: commit builder (simplified orchestration)
    - Models: commit options, commit result
  - **Why needs human input**: Architecture decisions affect maintainability and testing

- [ ] **Dependencies and Integration**: Should ace-git depend on any dev-tools components for LLM functionality?
  - **Research conducted**: dev-tools has extensive LLM infrastructure (ClientFactory, ProviderModelParser, multiple provider clients)
  - **Current approach**: Task specifies "ace-core dependency (~> 0.9.0)" only
  - **Integration options**: Pure ace-git implementation vs leveraging existing dev-tools LLM infrastructure
  - **Why needs human input**: Dependency strategy affects gem isolation and maintenance

### [LOW] Enhancement Questions

- [ ] **Test Strategy Alignment**: The task mentions "reuse TestEnvironment and ConfigHelpers" from ace-core:
  - **Research conducted**: ace-context uses ace-test-support via test_helper.rb, ace-core has established test patterns
  - **Current test infrastructure**: 29 passing tests in ace-core, shared test support infrastructure
  - **Suggested approach**: Follow ace-context pattern with test/test_helper.rb requiring ace/test_support
  - **Default assumption**: Use ace-test-support for consistency with other ace-* gems

- [ ] **Git Command Interface Design**: Should ace-gc follow git's interface patterns or create a more semantic interface?
  - **Research conducted**: Current implementation supports extensive git options (force, dry-run, concurrent, etc.)
  - **Task examples**: Simple `ace-gc feat` vs `git commit -m "feat: message"`
  - **Suggested default**: Keep simple semantic interface as shown in task examples
  - **Why low priority**: Implementation detail that can be refined during development

## Objective

Create the ace-git gem with a simplified git-commit command (ace-gc) designed for monorepo use. Remove all submodule and multi-repo complexity, focusing on clean, intention-based commits for a single repository.

## Scope of Work

- Set up gem skeleton
- Add dependency on ace-core in gemspec
- Create simplified git-commit (ace-gc) for monorepo
- Remove submodule-specific code
- Include default config for commit conventions
- Write tests using shared infrastructure

### Deliverables

#### Create

- ace-git/.bundle/config (BUNDLE_GEMFILE pointing to parent)
- ace-git/ace-git.gemspec
- ace-git/lib/ace/git.rb
- ace-git/lib/ace/git/version.rb
- ace-git/lib/ace/git/organisms/commit_builder.rb
- ace-git/lib/ace/git/molecules/intention_parser.rb
- ace-git/lib/ace/git/molecules/message_formatter.rb
- ace-git/lib/ace/git/models/ (data structures)
- ace-git/exe/ace-gc
- ace-git/config/git.yml (gem defaults)
- ace-git/test/test_helper.rb
- ace-git/test/support/ (copy from ace-core)
- ace-git/test/organisms/commit_builder_test.rb
- ace-git/test/molecules/intention_parser_test.rb
- ace-git/test/molecules/message_formatter_test.rb
- ace-git/test/integration/git_commit_integration_test.rb
- ace-git/Rakefile
- ace-git/README.md
- .ace/git/config/git.yml (project sample)

#### Modify

- Gemfile (add ace-git entry)

## Implementation Plan

### Planning Steps

- [ ] Review current git-commit complexity
- [ ] Design simplified monorepo approach
- [ ] Plan intention-based commit system
- [ ] Define commit message conventions

### Execution Steps

- [ ] Create gem skeleton following ATOM architecture

  ```bash
  mkdir -p ace-git/{lib/ace/git/{atoms,molecules,organisms,models},test/{atoms,molecules,organisms,integration,support},config,exe,.bundle}
  ```

- [ ] Create .bundle/config for ace-git

  ```yaml
  # ace-git/.bundle/config
  ---
  BUNDLE_GEMFILE: "../Gemfile"
  ```

  > NOTE: This follows the Option C pattern established with ace-core
  > Allows ace-git to use shared root Gemfile for all dependencies

- [ ] Create ace-git.gemspec

  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-git"
    spec.version = "0.9.0"
    spec.summary = "Git tools for ACE"

    spec.add_dependency "ace-core", "~> 0.9.0"

    # No development dependencies - managed in root Gemfile
  end
  ```

- [ ] Copy test support from ace-core

  ```bash
  cp -r ../ace-core/test/support ace-git/test/
  ```

  > NOTE: Reuse TestEnvironment and ConfigHelpers for integration testing

- [ ] Implement commit builder (simplified)

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

- [ ] Implement intention parser

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

- [ ] Implement message formatter

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

- [ ] Create ace-gc executable

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

- [ ] Create default config/git.yml

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

- [ ] Create sample .ace/git/config/git.yml

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

- [ ] Set up test helper

  ```ruby
  # test/test_helper.rb
  require 'minitest/autorun'
  require 'minitest/reporters' # Available from root Gemfile
  require 'ace/git'
  # Reuse test utilities from ace-core which already has 29 passing tests
  ```

- [ ] Write commit builder tests

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

- [ ] Run bundle install from root
  > TEST: Gem integration
  > Type: Integration
  > Assert: ace-git loads with ace-core
  > Command: bundle install && bundle exec ace-gc --help
  > NOTE: Run from project root, not ace-git directory
  > The .bundle/config will ensure proper Gemfile resolution

- [ ] Write integration test
  > TEST: ace-gc command
  > Type: Integration
  > Assert: Creates proper git commits
  > Command: cd test-repo && ace-gc feat

- [ ] Update root Gemfile

  ```ruby
  gem "ace-git", path: "ace-git"
  ```

  > NOTE: Root Gemfile configuration:
  > - No vendor/bundle (gems install to mise Ruby location)
  > - Shared dev dependencies (minitest ~> 5.20, rake ~> 13.0, minitest-reporters ~> 1.6)
  > - All gems use .bundle/config to reference parent Gemfile

- [ ] Create README

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

- [ ] Gem structure follows conventions
- [ ] Depends on ace-core for config
- [ ] ace-gc command creates commits
- [ ] Intentions parsed correctly
- [ ] No submodule/multi-repo code
- [ ] Config loads from .ace/git/
- [ ] Tests pass using minitest
- [ ] README documents usage
- [ ] Integrates with root Gemfile

## Out of Scope

- ❌ Submodule handling
- ❌ Multi-repo coordination
- ❌ Other git commands (add, push, etc.)
- ❌ Complex commit templating
- ❌ AI-generated messages
