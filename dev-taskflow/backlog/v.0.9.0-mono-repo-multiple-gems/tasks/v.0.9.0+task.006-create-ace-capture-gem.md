---
id: v.0.9.0+task.006
status: pending
priority: medium
estimate: 4h
dependencies: [v.0.9.0+task.001, v.0.9.0+task.002, v.0.9.0+task.003, v.0.9.0+task.004]
---

# Create ace-capture Gem

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

- ace-capture/ace-capture.gemspec
- ace-capture/lib/ace/capture.rb
- ace-capture/lib/ace/capture/version.rb
- ace-capture/lib/ace/capture/idea_writer.rb
- ace-capture/lib/ace/capture/file_namer.rb
- ace-capture/exe/capture
- ace-capture/config/capture.yml (gem defaults)
- ace-capture/test/test_helper.rb
- ace-capture/test/idea_writer_test.rb
- ace-capture/test/file_namer_test.rb
- ace-capture/Rakefile
- ace-capture/README.md
- .ace/capture/config/capture.yml (project sample)

#### Modify

- Gemfile (add ace-capture entry)

## Implementation Plan

### Planning Steps

* [ ] Review current capture-it implementation
* [ ] Design simple file naming scheme
* [ ] Plan directory structure for captured ideas
* [ ] Determine minimal feature set

### Execution Steps

- [ ] Create gem skeleton
  ```bash
  mkdir -p ace-capture/{lib/ace/capture,test,config,exe}
  ```

- [ ] Create ace-capture.gemspec
  ```ruby
  Gem::Specification.new do |spec|
    spec.name = "ace-capture"
    spec.version = "0.9.0"
    spec.summary = "Idea capture for ACE"

    spec.add_dependency "ace-core", "~> 0.9.0"

    spec.add_development_dependency "minitest"
    spec.add_development_dependency "rake"
  end
  ```

- [ ] Implement idea writer
  ```ruby
  # lib/ace/capture/idea_writer.rb
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
  require 'ace/capture'
  require 'tmpdir'
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

- [ ] Run bundle install and test
  > TEST: Capture command works
  > Type: Integration
  > Assert: Ideas captured to files
  > Command: bundle install && bundle exec capture "Test idea"

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