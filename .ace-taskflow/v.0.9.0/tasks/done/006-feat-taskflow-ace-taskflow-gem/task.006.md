---
id: v.0.9.0+task.006
status: done
estimate: 4h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002, v.0.9.0+task.003, v.0.9.0+task.004]
needs_review: true
---

# Create ace-taskflow Gem

## Review Questions (Resolved)

### Migration Strategy Clarification
- **Decision**: Create ace-taskflow package with ace-tf command and subcommands
- **First subcommand**: `ace-tf idea` to replace capture-it functionality
- **Future subcommands**: task, release, and other task management operations
- **Rationale**: Consolidates all task management tools into unified package

## Objective

Create the ace-taskflow gem that provides task and idea management functionality. The initial implementation includes the `ace-tf idea` subcommand to migrate capture-it functionality, with architecture designed to support future task and release subcommands.

## Scope of Work

- Set up gem skeleton with subcommand architecture
- Add dependency on ace-core in gemspec
- Port capture-it functionality as `ace-tf idea` subcommand
- Use ace-core for config from .ace/taskflow/
- Implement idea capture with file writing
- Design extensible architecture for future subcommands (task, release)
- Write tests using shared infrastructure

### Deliverables

#### Create

- ace-taskflow/.bundle/config (BUNDLE_GEMFILE pointing to parent)
- ace-taskflow/ace-taskflow.gemspec
- ace-taskflow/lib/ace/taskflow.rb
- ace-taskflow/lib/ace/taskflow/version.rb
- ace-taskflow/lib/ace/taskflow/cli.rb (main CLI with subcommands)
- ace-taskflow/lib/ace/taskflow/commands/idea_command.rb
- ace-taskflow/lib/ace/taskflow/atoms/ (pure functions)
- ace-taskflow/lib/ace/taskflow/molecules/file_namer.rb
- ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb
- ace-taskflow/lib/ace/taskflow/models/ (data structures)
- ace-taskflow/exe/ace-tf
- ace-taskflow/config/taskflow.yml (gem defaults)
- ace-taskflow/test/test_helper.rb
- ace-taskflow/test/support/ (copy from ace-core)
- ace-taskflow/test/organisms/idea_writer_test.rb
- ace-taskflow/test/molecules/file_namer_test.rb
- ace-taskflow/test/integration/taskflow_integration_test.rb
- ace-taskflow/test/commands/idea_command_test.rb
- ace-taskflow/Rakefile
- ace-taskflow/README.md
- .ace/taskflow/config/taskflow.yml (project sample)

#### Modify

- Gemfile (add ace-taskflow entry)

## Implementation Plan

### Planning Steps

* [x] Review current capture-it implementation
  - **Found**: Complex 314-line organism with LLM enhancement, git integration, clipboard support
  - **Location**: `/dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb`
  - **Dependencies**: context_loader, idea_enhancer, path_resolver, llm_client molecules
  - **Features**: Raw input capture, LLM enhancement, git commits, SOURCE section appending
* [x] Clarified package structure: ace-taskflow with ace-tf command
* [x] Design subcommand architecture for ace-tf (idea, task, release)
* [x] Plan migration path for capture-it to ace-tf idea
* [x] Design extensible structure for future subcommands

### Execution Steps

- [x] Create gem skeleton following ATOM architecture
  ```bash
  mkdir -p ace-taskflow/{lib/ace/taskflow/{atoms,molecules,organisms,models,commands},test/{atoms,molecules,organisms,integration,commands,support},config,exe,.bundle}
  ```

- [x] Create .bundle/config for ace-taskflow
  ```yaml
  # ace-taskflow/.bundle/config
  ---
  BUNDLE_GEMFILE: "../Gemfile"
  ```
  > NOTE: This follows the Option C pattern established with ace-core
  > Allows ace-taskflow to use shared root Gemfile for all dependencies

- [x] Create ace-taskflow.gemspec
  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-taskflow"
    spec.version = "0.9.0"
    spec.summary = "Task and idea management for ACE"
    spec.description = "Unified task management including idea capture, task tracking, and release management"

    spec.add_dependency "ace-core", "~> 0.9.0"

    # No development dependencies - managed in root Gemfile
  end
  ```

- [x] Copy test support from ace-core
  ```bash
  cp -r ../ace-core/test/support ace-taskflow/test/
  ```
  > NOTE: Reuse TestEnvironment and ConfigHelpers for integration testing

- [x] Implement CLI with subcommands
  ```ruby
  # lib/ace/taskflow/cli.rb
  require 'optparse'

  module Ace
    module Taskflow
      class CLI
        def self.start(args)
          subcommand = args.shift

          case subcommand
          when 'idea'
            Commands::IdeaCommand.new.execute(args)
          when 'task'
            puts "Task management coming soon"
          when 'release'
            puts "Release management coming soon"
          else
            show_help
          end
        end

        def self.show_help
          puts "Usage: ace-tf <subcommand> [options]"
          puts "Subcommands:"
          puts "  idea     - Capture ideas (replaces capture-it)"
          puts "  task     - Task management (coming soon)"
          puts "  release  - Release management (coming soon)"
        end
      end
    end
  end
  ```

- [x] Implement idea command
  ```ruby
  # lib/ace/taskflow/commands/idea_command.rb
  module Ace
    module Taskflow
      module Commands
        class IdeaCommand
          def execute(args)
            content = args.join(' ')
            if content.empty?
              puts "Usage: ace-tf idea <your idea>"
              exit 1
            end

            writer = Organisms::IdeaWriter.new
            path = writer.write(content)
            puts "Idea captured: #{path}"
          end
        end
      end
    end
  end
  ```

- [x] Implement idea writer
  ```ruby
  # lib/ace/taskflow/organisms/idea_writer.rb
  module Ace
    module Taskflow
      module Organisms
        class IdeaWriter
          def initialize(config = nil)
            @config = config || Ace::Core::ConfigResolver.load('taskflow')
          end

          def write(content, metadata = {})
            path = generate_path(metadata)
            File.write(path, format_idea(content, metadata))
            path
          end

          private

          def generate_path(metadata)
            Molecules::FileNamer.new(@config).generate(metadata)
          end

          def format_idea(content, metadata)
            # Format using template from config
            template = @config.dig('taskflow', 'idea', 'template') || "# Idea\n\n%{content}"
            template % { content: content }
          end
        end
      end
    end
  end
  ```
  > TEST: Idea writer functionality
  > Type: Unit Test
  > Assert: Ideas written to correct location
  > Command: cd ace-taskflow && rake test TEST=test/organisms/idea_writer_test.rb

- [x] Implement file namer
  ```ruby
  # lib/ace/taskflow/molecules/file_namer.rb
  module Ace
    module Taskflow
      module Molecules
        class FileNamer
          def initialize(config)
            @config = config
          end

          def generate(metadata = {})
            timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
            title = metadata[:title]&.downcase&.gsub(/\s+/, '-') || 'idea'
            dir = @config.dig('taskflow', 'idea', 'directory') || './ideas'

            File.join(dir, "#{timestamp}-#{title}.md")
          end
        end
      end
    end
  end
  ```

- [x] Create ace-tf executable
  ```ruby
  #!/usr/bin/env ruby
  # exe/ace-tf
  require 'ace/taskflow'

  Ace::Taskflow::CLI.start(ARGV)
  ```

- [x] Create default config/taskflow.yml
  ```yaml
  taskflow:
    idea:
      directory: "./ideas"
      template: |
        # Idea

        %{content}

        ---
        Captured: %{timestamp}
      timestamp_format: "%Y-%m-%d %H:%M:%S"
    task:
      directory: "./tasks"
    release:
      directory: "./releases"
  ```

- [x] Create sample .ace/taskflow/config/taskflow.yml
  ```yaml
  taskflow:
    idea:
      directory: "./dev-taskflow/backlog/ideas"
      template: |
        # %{title}

        %{content}

        ---
        Captured: %{timestamp}
        Tags: %{tags}
    task:
      directory: "./dev-taskflow/current"
    release:
      directory: "./dev-taskflow/done"
  ```

- [x] Set up test helper
  ```ruby
  # test/test_helper.rb
  require 'minitest/autorun'
  require 'minitest/reporters' # Available from root Gemfile
  require 'ace/taskflow'
  require 'tmpdir'
  # Reuse test utilities from ace-core which already has 29 passing tests
  ```

- [x] Write idea writer tests
  ```ruby
  class IdeaWriterTest < Minitest::Test
    def setup
      @temp_dir = Dir.mktmpdir
    end

    def teardown
      FileUtils.rm_rf(@temp_dir)
    end

    def test_writes_idea_to_file
      # Test file creation
    end

    def test_uses_configured_directory
      # Test directory configuration
    end
  end
  ```

- [x] Write file namer tests
  > TEST: File naming
  > Type: Unit Test
  > Assert: Files named with timestamp and title
  > Command: cd ace-capture && rake test TEST=test/file_namer_test.rb

- [x] Update root Gemfile
  ```ruby
  gem "ace-taskflow", path: "ace-taskflow"
  ```
  > NOTE: Root Gemfile configuration:
  > - No vendor/bundle (gems install to mise Ruby location)
  > - Shared dev dependencies (minitest ~> 5.20, rake ~> 13.0, minitest-reporters ~> 1.6)
  > - All gems use .bundle/config to reference parent Gemfile

- [x] Run bundle install from root and test
  > TEST: ace-tf idea command works
  > Type: Integration
  > Assert: Ideas captured to files
  > Command: bundle install && bundle exec ace-tf idea "Test idea"
  > NOTE: Run from project root, not ace-taskflow directory
  > The .bundle/config will ensure proper Gemfile resolution

- [x] Create README
  ```markdown
  # ace-taskflow

  Unified task and idea management for ACE projects.

  ## Usage

  ### Capture ideas
  ```
  ace-tf idea "Your brilliant idea here"
  ```

  ### Task management (coming soon)
  ```
  ace-tf task create "New task description"
  ace-tf task list
  ace-tf task complete TASK_ID
  ```

  ### Release management (coming soon)
  ```
  ace-tf release create v1.0.0
  ace-tf release current
  ```

  Ideas are saved to the configured directory with timestamps.
  ```

## Acceptance Criteria

- [x] Gem structure follows conventions
- [x] Depends on ace-core for config
- [x] ace-tf idea command writes ideas to files
- [x] Subcommand architecture supports future extensions
- [x] File names include timestamp
- [x] Config loads from .ace/taskflow/
- [x] Tests pass using minitest
- [x] README documents usage
- [x] Integrates with root Gemfile

## Out of Scope (for initial release)

- ❌ Task subcommand implementation
- ❌ Release subcommand implementation
- ❌ Complex templating beyond basic substitution
- ❌ Search functionality
- ❌ Git integration for ideas