---
id: v.0.9.0+task.006
status: pending
priority: medium
estimate: 4h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002, v.0.9.0+task.003, v.0.9.0+task.004]
needs_review: true
---

# Create ace-capture Gem

## Review Questions (Pending Human Input)

### [HIGH] Implementation Scope Questions
- [ ] Should ace-capture be simple file writing only or include LLM enhancement?
  - **Research conducted**: Current capture-it is complex with LLM integration, templates, git commits
  - **Found implementation**: 314-line organism with context loading, idea enhancement, git integration
  - **Task specification**: "simple file writing" and "simple idea capture"
  - **Conflict**: Task scope vs existing capture-it complexity
  - **Suggested default**: Start with simple file writing, plan LLM features for future version
  - **Why needs human input**: This fundamentally changes the gem's purpose and implementation

- [ ] What is the relationship between ace-capture and existing capture-it command?
  - **Research conducted**: capture-it is sophisticated tool in dev-tools
  - **Current features**: LLM enhancement, clipboard input, file input, git integration, context loading
  - **Migration scope unclear**: Should ace-capture replace capture-it or complement it?
  - **Why needs human input**: Migration strategy affects feature scope and timeline

### [HIGH] Architecture Alignment Questions
- [ ] Should executable be named "capture" or "ace-capture" for consistency?
  - **Research conducted**: All other ace-* gems use "ace-" prefix in executables
  - **Pattern found**: ace-context uses "ace-context", ace-test uses "ace-test"
  - **Task specification**: "exe/capture"
  - **Suggested default**: Use "ace-capture" for consistency with other gems
  - **Why needs human input**: Naming affects user experience and CLI conventions

- [ ] Should configuration use .ace/capture/ or integrate with .ace/context/?
  - **Research conducted**: ace-context uses .ace/context/ for preset-based loading
  - **Pattern found**: Configuration cascade with nearest-wins resolution
  - **Task specification**: ".ace/capture/config/capture.yml"
  - **Integration consideration**: Should capture presets work with context system?
  - **Why needs human input**: Configuration strategy affects user workflow

### [MEDIUM] Missing ATOM Components
- [ ] What atoms/ components are needed for the simple implementation?
  - **Research conducted**: ace-context has clear atom/molecule/organism separation
  - **Task gap**: No atoms/ specified despite ATOM architecture requirement
  - **Suggested atoms**: timestamp_generator, content_formatter, path_validator
  - **Why needs human input**: ATOM compliance requires proper component design

### [MEDIUM] API Design Questions
- [ ] Should ace-capture follow class method API pattern like ace-context?
  - **Research conducted**: ace-context provides Ace::Context.load_preset() class methods
  - **Pattern found**: Main module with class methods for primary operations
  - **Task specification**: Only shows instance-based API
  - **Suggested API**: Ace::Capture.write_idea(content, options = {})
  - **Why needs human input**: API design affects gem usage patterns

## Objective

Create the ace-capture gem that provides simple idea capture functionality, migrating the capture-it command. This gem depends on ace-core for config loading and uses simple file writing to a configured directory.

## Scope of Work

- Set up gem skeleton
- Add dependency on ace-core in gemspec
- Port capture-it functionality as simple idea capture
- Use ace-core for config from .ace/capture/
- Simple file writing to designated directory
- Write tests using shared infrastructure

### Deliverables

#### Create

- ace-capture/.bundle/config (BUNDLE_GEMFILE pointing to parent)
- ace-capture/ace-capture.gemspec
- ace-capture/lib/ace/capture.rb
- ace-capture/lib/ace/capture/version.rb
- ace-capture/lib/ace/capture/atoms/ (pure functions - pending review answers)
- ace-capture/lib/ace/capture/molecules/file_namer.rb
- ace-capture/lib/ace/capture/organisms/idea_writer.rb
- ace-capture/lib/ace/capture/models/ (data structures)
- ace-capture/exe/ace-capture
- ace-capture/config/capture.yml (gem defaults)
- ace-capture/test/test_helper.rb
- ace-capture/test/support/ (copy from ace-core)
- ace-capture/test/organisms/idea_writer_test.rb
- ace-capture/test/molecules/file_namer_test.rb
- ace-capture/test/integration/capture_integration_test.rb
- ace-capture/Rakefile
- ace-capture/README.md
- .ace/capture/config/capture.yml (project sample)

#### Modify

- Gemfile (add ace-capture entry)

## Implementation Plan

### Planning Steps

* [x] Review current capture-it implementation
  - **Found**: Complex 314-line organism with LLM enhancement, git integration, clipboard support
  - **Location**: `/dev-tools/lib/coding_agent_tools/organisms/idea_capture.rb`
  - **Dependencies**: context_loader, idea_enhancer, path_resolver, llm_client molecules
  - **Features**: Raw input capture, LLM enhancement, git commits, SOURCE section appending
* [ ] Design simple file naming scheme
* [ ] Plan directory structure for captured ideas
* [ ] Determine minimal feature set based on review questions answers

### Execution Steps

- [ ] Create gem skeleton following ATOM architecture
  ```bash
  mkdir -p ace-capture/{lib/ace/capture/{atoms,molecules,organisms,models},test/{atoms,molecules,organisms,integration,support},config,exe,.bundle}
  ```

- [ ] Create .bundle/config for ace-capture
  ```yaml
  # ace-capture/.bundle/config
  ---
  BUNDLE_GEMFILE: "../Gemfile"
  ```
  > NOTE: This follows the Option C pattern established with ace-core
  > Allows ace-capture to use shared root Gemfile for all dependencies

- [ ] Create ace-capture.gemspec
  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-capture"
    spec.version = "0.9.0"
    spec.summary = "Idea capture for ACE"

    spec.add_dependency "ace-core", "~> 0.9.0"

    # No development dependencies - managed in root Gemfile
  end
  ```

- [ ] Copy test support from ace-core
  ```bash
  cp -r ../ace-core/test/support ace-capture/test/
  ```
  > NOTE: Reuse TestEnvironment and ConfigHelpers for integration testing

- [ ] Implement idea writer
  ```ruby
  # lib/ace/capture/organisms/idea_writer.rb
  module Ace
    module Capture
      class IdeaWriter
        def initialize(config = nil)
          @config = config || Ace::Core::ConfigResolver.load('capture')
        end

        def write(content, metadata = {})
          path = generate_path(metadata)
          File.write(path, format_idea(content, metadata))
          path
        end

        private

        def generate_path(metadata)
          FileNamer.new(@config).generate(metadata)
        end
      end
    end
  end
  ```
  > TEST: Idea writer functionality
  > Type: Unit Test
  > Assert: Ideas written to correct location
  > Command: cd ace-capture && rake test TEST=test/idea_writer_test.rb

- [ ] Implement file namer
  ```ruby
  # lib/ace/capture/file_namer.rb
  module Ace
    module Capture
      class FileNamer
        def initialize(config)
          @config = config
        end

        def generate(metadata = {})
          timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
          title = metadata[:title]&.downcase&.gsub(/\s+/, '-') || 'idea'
          dir = @config.dig('capture', 'directory') || './ideas'

          File.join(dir, "#{timestamp}-#{title}.md")
        end
      end
    end
  end
  ```

- [ ] Create capture executable
  ```ruby
  #!/usr/bin/env ruby
  # exe/capture
  require 'ace/capture'

  content = ARGV.join(' ')
  if content.empty?
    puts "Usage: capture <your idea>"
    exit 1
  end

  writer = Ace::Capture::IdeaWriter.new
  path = writer.write(content)
  puts "Idea captured: #{path}"
  ```

- [ ] Create default config/capture.yml
  ```yaml
  capture:
    directory: "./ideas"
    template: |
      # Idea

      %{content}

      ---
      Captured: %{timestamp}
    timestamp_format: "%Y-%m-%d %H:%M:%S"
  ```

- [ ] Create sample .ace/capture/config/capture.yml
  ```yaml
  capture:
    directory: "./dev-taskflow/backlog/ideas"
    template: |
      # %{title}

      %{content}

      ---
      Captured: %{timestamp}
      Tags: %{tags}
  ```

- [ ] Set up test helper
  ```ruby
  # test/test_helper.rb
  require 'minitest/autorun'
  require 'minitest/reporters' # Available from root Gemfile
  require 'ace/capture'
  require 'tmpdir'
  # Reuse test utilities from ace-core which already has 29 passing tests
  ```

- [ ] Write idea writer tests
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

- [ ] Write file namer tests
  > TEST: File naming
  > Type: Unit Test
  > Assert: Files named with timestamp and title
  > Command: cd ace-capture && rake test TEST=test/file_namer_test.rb

- [ ] Update root Gemfile
  ```ruby
  gem "ace-capture", path: "ace-capture"
  ```
  > NOTE: Root Gemfile configuration:
  > - No vendor/bundle (gems install to mise Ruby location)
  > - Shared dev dependencies (minitest ~> 5.20, rake ~> 13.0, minitest-reporters ~> 1.6)
  > - All gems use .bundle/config to reference parent Gemfile

- [ ] Run bundle install from root and test
  > TEST: Capture command works
  > Type: Integration
  > Assert: Ideas captured to files
  > Command: bundle install && bundle exec capture "Test idea"
  > NOTE: Run from project root, not ace-capture directory
  > The .bundle/config will ensure proper Gemfile resolution

- [ ] Create README
  ```markdown
  # ace-capture

  Simple idea capture for ACE projects.

  ## Usage
  ```
  capture "Your brilliant idea here"
  ```

  Ideas are saved to the configured directory with timestamps.
  ```

## Acceptance Criteria

- [ ] Gem structure follows conventions
- [ ] Depends on ace-core for config
- [ ] Capture command writes ideas to files
- [ ] File names include timestamp
- [ ] Config loads from .ace/capture/
- [ ] Tests pass using minitest
- [ ] README documents usage
- [ ] Integrates with root Gemfile

## Out of Scope

- ❌ Complex templating
- ❌ Idea categorization
- ❌ Search functionality
- ❌ Git integration