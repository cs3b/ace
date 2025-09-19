---
id: v.0.9.0+task.007
status: pending
priority: medium
estimate: 6h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002, v.0.9.0+task.003, v.0.9.0+task.004]
---

# Create ace-git Gem with ace-gc Only

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

- ace-git/ace-git.gemspec
- ace-git/lib/ace/git.rb
- ace-git/lib/ace/git/version.rb
- ace-git/lib/ace/git/commit_builder.rb
- ace-git/lib/ace/git/intention_parser.rb
- ace-git/lib/ace/git/message_formatter.rb
- ace-git/exe/ace-gc
- ace-git/config/git.yml (gem defaults)
- ace-git/test/test_helper.rb
- ace-git/test/commit_builder_test.rb
- ace-git/test/intention_parser_test.rb
- ace-git/test/message_formatter_test.rb
- ace-git/Rakefile
- ace-git/README.md
- .ace/git/config/git.yml (project sample)

#### Modify

- Gemfile (add ace-git entry)

## Implementation Plan

### Planning Steps

* [ ] Review current git-commit complexity
* [ ] Design simplified monorepo approach
* [ ] Plan intention-based commit system
* [ ] Define commit message conventions

### Execution Steps

- [ ] Create gem skeleton
  ```bash
  mkdir -p ace-git/{lib/ace/git,test,config,exe}
  ```

- [ ] Create ace-git.gemspec
  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-git"
    spec.version = "0.9.0"
    spec.summary = "Git tools for ACE"

    spec.add_dependency "ace-core", "~> 0.9.0"

    spec.add_development_dependency "minitest"
    spec.add_development_dependency "rake"
  end
  ```

- [ ] Implement commit builder (simplified)
  ```ruby
  # lib/ace/git/commit_builder.rb
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

- [ ] Write integration test
  > TEST: ace-gc command
  > Type: Integration
  > Assert: Creates proper git commits
  > Command: cd test-repo && ace-gc feat

- [ ] Update root Gemfile
  ```ruby
  gem "ace-git", path: "ace-git"
  ```

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