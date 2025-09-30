# ACE Gem Development Guide

This guide provides comprehensive instructions for creating new ace-* gems that integrate seamlessly with the ACE framework ecosystem.

## Table of Contents

1. [Available Shared Packages](#available-shared-packages)
2. [Gem Structure and ATOM Architecture](#gem-structure-and-atom-architecture)
3. [Configuration System](#configuration-system)
4. [Handbook Integration](#handbook-integration)
5. [Testing Best Practices](#testing-best-practices)
6. [Getting Started Template](#getting-started-template)

## Available Shared Packages

Before implementing functionality, leverage these existing ace-* gems to avoid duplication:

### ace-core (Zero Dependencies)

Core functionality available to all gems. Note that some components need explicit requires:

```ruby
require 'ace/core'  # Loads config, environment, and discovery APIs

# Configuration cascade resolution (searches ./.ace → ~/.ace → defaults)
config = Ace::Core.config
config = Ace::Core.config(search_paths: ['./.custom', '~/.myapp'])

# Get configuration values by key path
value = Ace::Core.get('ace', 'settings', 'key')

# Get configuration by namespace with file patterns
llm_config = Ace::Core.get('llm')  # Loads llm/*.yml
llm_config = Ace::Core.get('llm', file: 'providers')  # Loads llm/providers.yml

# Resolve configuration for specific patterns
resolver = Ace::Core::Organisms::ConfigResolver.new
config = resolver.resolve_for(['context/*.yml', 'context/*.yaml'])

# Environment management with cascade
Ace::Core.load_environment  # Loads .env.local, .env from cascade
env = Ace::Core.environment
env.load
env.set('MY_VAR', 'value')
env.get('MY_VAR', 'default')

# Get env variables without polluting ENV (cached cascade)
value = Ace::Core.get_env('API_KEY', 'default')
Ace::Core.clear_env_cache  # Clear cache when needed

# Create default configuration
Ace::Core.create_default_config('./.ace/core/config.yml')

# Configuration Discovery API
discovery = Ace::Core::ConfigDiscovery.new
discovery.find_config_file('config.yml')  # First match in cascade
discovery.find_all_config_files('config.yml')  # All matches
discovery.project_root  # Get project root
discovery.in_project?  # Check if in project
discovery.config_search_paths  # All search paths
discovery.relative_path('/full/path')  # Make relative to project
discovery.load_config('settings.yml')  # Load and merge from cascade

# Available Atoms (pure functions, no side effects)
# Most atoms need explicit requires:
require 'ace/core/atoms/yaml_parser'
require 'ace/core/atoms/deep_merger'
require 'ace/core/atoms/path_expander'
require 'ace/core/atoms/file_reader'
require 'ace/core/atoms/env_parser'
require 'ace/core/atoms/command_executor'
require 'ace/core/atoms/glob_expander'
require 'ace/core/atoms/template_parser'

# Then use them:
Ace::Core::Atoms::YamlParser.parse(yaml_content)
Ace::Core::Atoms::YamlParser.dump(hash)
Ace::Core::Atoms::DeepMerger.merge(base, override, array_strategy: :replace)
Ace::Core::Atoms::PathExpander.expand("~/path")
Ace::Core::Atoms::FileReader.read(path, max_size: 10_485_760)
Ace::Core::Atoms::EnvParser.parse_env_file(content)
Ace::Core::Atoms::CommandExecutor.execute(cmd, timeout: 30)
Ace::Core::Atoms::GlobExpander.expand('**/*.rb', base_dir: Dir.pwd)
Ace::Core::Atoms::GlobExpander.expand_multiple(['**/*.rb', '**/*.md'], base_dir: Dir.pwd)
Ace::Core::Atoms::GlobExpander.find_files('**/*.rb', base_dir: Dir.pwd)
Ace::Core::Atoms::TemplateParser.parse(text, variables: {})

# Available Molecules (composed operations)
# Some molecules are loaded automatically, others need explicit requires

# YAML Loading (needs explicit require)
require 'ace/core/molecules/yaml_loader'
config = Ace::Core::Molecules::YamlLoader.load_file(path)
config = Ace::Core::Molecules::YamlLoader.load_file_safe(path)  # Returns nil on error
merged = Ace::Core::Molecules::YamlLoader.load_and_merge(file1, file2, merge_strategy: :deep)

# Project Root Finding (needs explicit require)
require 'ace/core/molecules/project_root_finder'
root = Ace::Core::Molecules::ProjectRootFinder.find
root = Ace::Core::Molecules::ProjectRootFinder.find(start_path: '/some/path')
root = Ace::Core::Molecules::ProjectRootFinder.find_or_current

# Directory Traversal (needs explicit require)
require 'ace/core/molecules/directory_traverser'
traverser = Ace::Core::Molecules::DirectoryTraverser.new(config_dir_name: '.ace')
dirs_with_configs = traverser.traverse  # Returns dirs containing .ace folders
config_dirs = traverser.find_config_directories  # Returns actual .ace directories

# Configuration Finding (needs explicit require)
require 'ace/core/molecules/config_finder'
finder = Ace::Core::Molecules::ConfigFinder.new
cascade = finder.find_all  # Returns CascadePath objects
config_file = finder.find_file('settings.yml')
all_files = finder.find_all_files('settings.yml')

# File Aggregation (needs explicit require)
require 'ace/core/molecules/file_aggregator'
aggregator = Ace::Core::Molecules::FileAggregator.new(
  max_size: 10_485_760,
  base_dir: Dir.pwd,
  exclude: ['**/node_modules/**', '**/.git/**']
)
result = aggregator.aggregate(['**/*.rb', 'docs/**/*.md'])
# Returns: {files: Array, errors: Array, stats: Hash}

# Environment Loading (loaded via Ace::Core.get_env, or require explicitly)
require 'ace/core/molecules/env_loader'
env_vars = Ace::Core::Molecules::EnvLoader.load_cascade
env_vars = Ace::Core::Molecules::EnvLoader.load_file('.env')

# Output Formatting (needs explicit require)
require 'ace/core/molecules/output_formatter'
formatter = Ace::Core::Molecules::OutputFormatter.new('markdown')
output = formatter.format(data)
# Supports: markdown, yaml, xml, markdown-xml, json

# Context Processing (needs explicit require)
require 'ace/core/molecules/context_chunker'
require 'ace/core/molecules/context_merger'
chunker = Ace::Core::Molecules::ContextChunker.new(max_size: 100_000)
chunks = chunker.chunk(content, metadata: {})

merger = Ace::Core::Molecules::ContextMerger.new
merged = merger.merge(chunks)
```

### ace-test-support

Testing infrastructure for all gems:

```ruby
# In test_helper.rb
require 'ace/test_support'

# Base test case with utilities
class MyTest < AceTestCase
  def test_something
    # Automatic pwd restoration after each test
    # Access to fixture_path helper
    fixture = fixture_path('sample.yml')

    # Subprocess runner for CLI testing
    result = run_subprocess(['my-command', 'arg'])
    assert_equal 0, result.exit_code

    # Config helpers for testing
    with_temp_config(data) do
      # Test with temporary config
    end
  end
end
```

### ace-nav

Resource navigation and discovery:

```ruby
require 'ace/nav'

# Navigate to workflows
nav = Ace::Nav.new
resource = nav.navigate('wfi://workflow-name')

# Discover resources
resources = nav.list_resources('wfi://*pattern*')
```

### ace-llm

LLM provider integration:

```ruby
require 'ace/llm'

# Query LLM providers
client = Ace::Llm::Client.new
response = client.query("prompt", model: "gpt-4")

# Get model info
info = client.model_info("claude-3-opus")
```

## Gem Structure and ATOM Architecture

### Directory Layout

```
ace-your-gem/
├── .ace.example/           # Example configuration
│   └── your-gem/
│       └── config.yml
├── lib/
│   └── ace/
│       └── your_gem/
│           ├── atoms/      # Pure functions, no side effects
│           ├── molecules/  # Composed operations
│           ├── organisms/  # Business orchestration
│           ├── models/     # Data structures (no behavior)
│           ├── cli.rb      # OptionParser-based CLI (optional)
│           └── version.rb
├── test/
│   ├── atoms/
│   ├── molecules/
│   ├── organisms/
│   ├── integration/
│   ├── fixtures/
│   └── test_helper.rb
├── bin/
│   └── ace-your-gem       # Executable (optional, use exe/ dir)
├── exe/
│   └── ace-your-gem       # Executable script
├── handbook/               # Optional workflows
│   └── workflow-instructions/
├── docs/
│   └── usage.md
├── ace-your-gem.gemspec
├── Gemfile
├── Rakefile
└── README.md
```

### ATOM Pattern Rules

#### Atoms (Pure Functions)
```ruby
# lib/ace/your_gem/atoms/data_parser.rb
module Ace
  module YourGem
    module Atoms
      class DataParser
        def self.parse(input)
          # Pure function - no side effects
          # No file I/O, no external dependencies
          # Single, well-defined purpose
          JSON.parse(input)
        rescue JSON::ParserError => e
          raise Ace::YourGem::ParseError, e.message
        end
      end
    end
  end
end
```

#### Molecules (Composed Operations)
```ruby
# lib/ace/your_gem/molecules/data_loader.rb
module Ace
  module YourGem
    module Molecules
      class DataLoader
        def initialize
          @parser = Atoms::DataParser
          @reader = Ace::Core::Atoms::FileReader
        end

        def load(path)
          # Composes atoms, may have controlled side effects
          content = @reader.read(path)
          @parser.parse(content)
        end
      end
    end
  end
end
```

#### Organisms (Business Logic)
```ruby
# lib/ace/your_gem/organisms/data_processor.rb
module Ace
  module YourGem
    module Organisms
      class DataProcessor
        def initialize
          @loader = Molecules::DataLoader.new
          @transformer = Molecules::DataTransformer.new
          @validator = Molecules::DataValidator.new
        end

        def process(input_path, output_path)
          # Orchestrates molecules for complex workflows
          data = @loader.load(input_path)
          validated = @validator.validate(data)
          transformed = @transformer.transform(validated)
          save_result(transformed, output_path)
        end
      end
    end
  end
end
```

#### Models (Data Structures)
```ruby
# lib/ace/your_gem/models/result.rb
module Ace
  module YourGem
    module Models
      # Pure data carrier - no behavior
      Result = Struct.new(:status, :data, :errors, keyword_init: true) do
        def success?
          status == :success
        end

        def failed?
          !success?
        end
      end
    end
  end
end
```

## Configuration System

### .ace.example Directory

Provide example configuration showing all available options:

```yaml
# .ace.example/your-gem/config.yml
ace:
  your_gem:
    # Feature flags
    features:
      experimental_mode: false
      verbose_output: true

    # Provider settings
    providers:
      default: local
      local:
        cache_dir: ~/.cache/ace-your-gem

    # Processing options
    processing:
      batch_size: 100
      timeout: 30
      retry_count: 3
```

### Configuration Loading

```ruby
# lib/ace/your_gem.rb
module Ace
  module YourGem
    class << self
      def config
        @config ||= begin
          # Method 1: Load from main config cascade
          base_config = Ace::Core.config
          base_config.get('ace', 'your_gem') || default_config
        end
      end

      # Method 2: Load gem-specific config files from cascade
      def load_gem_config
        @gem_config ||= begin
          # This searches for your_gem/*.yml in cascade
          config = Ace::Core.get('your_gem')
          config.empty? ? default_config : config
        end
      end

      # Method 3: Load specific config file with discovery
      def load_settings
        @settings ||= begin
          discovery = Ace::Core::ConfigDiscovery.new
          settings = discovery.load_config('your_gem/settings.yml')
          settings || default_config
        end
      end

      # Method 4: Custom resolver for complex needs
      def custom_config
        @custom ||= begin
          resolver = Ace::Core::Organisms::ConfigResolver.new(
            search_paths: ['./.ace', '~/.ace', '/etc/ace'],
            file_patterns: ['your_gem/*.yml', 'your_gem.yml'],
            merge_strategy: :deep  # :deep, :shallow, :replace
          )
          config = resolver.resolve
          config.data.empty? ? default_config : config.data
        end
      end

      def default_config
        {
          'features' => {
            'experimental_mode' => false,
            'verbose_output' => false
          },
          'providers' => {
            'default' => 'local'
          }
        }
      end

      # Access environment variables through cascade
      def api_key
        Ace::Core.get_env('YOUR_GEM_API_KEY', 'default_key')
      end
    end
  end
end
```

### Using Configuration in CLI

ACE gems typically use OptionParser directly in the executable rather than a separate CLI class:

```ruby
# exe/ace-your-gem
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'ace/your_gem'
require 'optparse'

options = {
  verbose: false,
  output: 'stdio',
  format: 'json'
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ace-your-gem [FILE] [options]"

  opts.on("-v", "--verbose", "Enable verbose output") do
    options[:verbose] = true
  end

  opts.on("-o", "--output MODE", "Output mode: stdio, cache, file path") do |mode|
    options[:output] = mode
  end

  opts.on("-f", "--format FORMAT", %w[json yaml markdown],
          "Output format (default: json)") do |fmt|
    options[:format] = fmt
  end

  opts.on("-h", "--help", "Show this help message") do
    puts opts
    puts
    puts "Examples:"
    puts "  ace-your-gem data.json"
    puts "  ace-your-gem data.json --verbose"
    puts "  ace-your-gem data.json --output ./result.json"
    exit
  end
end

parser.parse!

# Get input file from remaining arguments
input_file = ARGV[0]

unless input_file
  $stderr.puts "Error: Input file required"
  $stderr.puts parser
  exit 1
end

# Load configuration and merge with CLI options
config = Ace::YourGem.config
verbose = options[:verbose] || config['features']['verbose_output']

# Process the file
begin
  processor = Ace::YourGem::Organisms::DataProcessor.new
  result = processor.process(input_file, options)

  # Handle output based on mode
  case options[:output]
  when 'stdio'
    puts result.to_json if options[:format] == 'json'
    puts result.to_yaml if options[:format] == 'yaml'
  when 'cache'
    require 'fileutils'
    cache_dir = File.join(Dir.pwd, '.cache/ace-your-gem')
    FileUtils.mkdir_p(cache_dir)
    cache_file = File.join(cache_dir, 'output.' + options[:format])
    File.write(cache_file, result.to_s)
    puts "Output saved to: #{cache_file}"
  else
    # Save to specified file
    File.write(options[:output], result.to_s)
    puts "Output saved to: #{options[:output]}"
  end
rescue => e
  $stderr.puts "Error: #{e.message}"
  $stderr.puts e.backtrace if options[:verbose]
  exit 1
end
```

## Handbook Integration

Each gem can provide workflows and agents for AI assistance:

### Workflow Structure

```markdown
# handbook/workflow-instructions/process-data.wf.md

# Process Data Workflow

## Purpose
Process data files using ace-your-gem functionality

## Instructions
1. Read input file
2. Validate data format
3. Transform according to rules
4. Save output

## Commands
- `ace-your-gem process input.json --output result.json`
- `ace-your-gem validate data.json`

## Success Criteria
- Data processed without errors
- Output matches expected format
```

### Claude Code Integration

Create markdown command files in `.claude/commands/` for Claude Code integration:

```markdown
# .claude/commands/your-gem-process.md
---
description: Process data with ace-your-gem
allowed-tools: Read, Write, Edit, Bash
argument-hint: "[file-path]"
---

Read and follow workflow @handbook/workflow-instructions/your-gem-process.wf.md

Process the specified file using ace-your-gem functionality.
```

Commands can also delegate to other commands or agents:

```markdown
# .claude/commands/your-gem-validate.md
---
description: Validate data files
allowed-tools: Read, Bash
---

Use the Task tool to launch the your-gem-validator agent for thorough validation.

After validation, run @.claude/commands/commit.md if changes were made.
```

## Testing Best Practices

### 1. Test Organization

```ruby
# test/test_helper.rb
require 'ace/test_support'
require 'ace/your_gem'

# Optional: Add gem-specific test helpers
module YourGemTestHelpers
  def sample_data
    { 'key' => 'value' }
  end
end

class YourGemTestCase < AceTestCase
  include YourGemTestHelpers
end
```

### 2. Testing Atoms (Pure Functions)

```ruby
# test/atoms/data_parser_test.rb
require 'test_helper'

class DataParserTest < YourGemTestCase
  def test_parse_valid_json
    input = '{"key": "value"}'
    result = Ace::YourGem::Atoms::DataParser.parse(input)

    assert_equal({ "key" => "value" }, result)
  end

  def test_parse_invalid_json_raises_error
    assert_raises(Ace::YourGem::ParseError) do
      Ace::YourGem::Atoms::DataParser.parse('invalid')
    end
  end

  # Test edge cases
  def test_parse_empty_input
    assert_equal({}, Ace::YourGem::Atoms::DataParser.parse('{}'))
  end
end
```

### 3. Testing Molecules (With Fixtures)

```ruby
# test/molecules/data_loader_test.rb
require 'test_helper'

class DataLoaderTest < YourGemTestCase
  def setup
    @loader = Ace::YourGem::Molecules::DataLoader.new
  end

  def test_load_valid_file
    # Use fixture_path helper from AceTestCase
    path = fixture_path('valid_data.json')
    result = @loader.load(path)

    assert_equal 'expected', result['key']
  end

  def test_load_missing_file
    assert_raises(Errno::ENOENT) do
      @loader.load('/nonexistent/file.json')
    end
  end
end
```

### 4. Testing Organisms (Integration)

```ruby
# test/organisms/data_processor_test.rb
require 'test_helper'
require 'tmpdir'

class DataProcessorTest < YourGemTestCase
  def setup
    @processor = Ace::YourGem::Organisms::DataProcessor.new
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir)
    super # Important: call parent teardown
  end

  def test_end_to_end_processing
    input = File.join(@temp_dir, 'input.json')
    output = File.join(@temp_dir, 'output.json')

    File.write(input, '{"value": 42}')

    result = @processor.process(input, output)

    assert result.success?
    assert File.exist?(output)

    output_data = JSON.parse(File.read(output))
    assert_equal 84, output_data['value'] # Assuming doubling
  end
end
```

### 5. Testing CLI Commands

```ruby
# test/integration/cli_test.rb
require 'test_helper'

class CLITest < YourGemTestCase
  def test_process_command
    result = run_subprocess(['ace-your-gem', 'process', fixture_path('input.json')])

    assert_equal 0, result.exit_code
    assert_match /Success/, result.stdout
  end

  def test_invalid_command
    result = run_subprocess(['ace-your-gem', 'invalid'])

    refute_equal 0, result.exit_code
    assert_match /not found/, result.stderr
  end

  def test_verbose_flag
    result = run_subprocess(['ace-your-gem', 'process', '--verbose', 'file.json'])

    assert_match /Processing/, result.stdout
  end
end
```

### 6. Testing with Mocks and Stubs

```ruby
# test/molecules/external_service_test.rb
require 'test_helper'
require 'minitest/mock'

class ExternalServiceTest < YourGemTestCase
  def test_api_call_with_mock
    mock_client = Minitest::Mock.new
    mock_client.expect :get, { 'status' => 'ok' }, ['/endpoint']

    service = Ace::YourGem::Molecules::ExternalService.new(client: mock_client)
    result = service.fetch_data

    assert_equal 'ok', result['status']
    mock_client.verify
  end
end
```

### 7. Test Coverage Best Practices

```ruby
# Rakefile
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.warning = false
end

# Add coverage task
namespace :test do
  desc "Run tests with coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task['test'].invoke
  end
end

# test/test_helper.rb (add at top)
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
    add_group 'Atoms', 'lib/ace/your_gem/atoms'
    add_group 'Molecules', 'lib/ace/your_gem/molecules'
    add_group 'Organisms', 'lib/ace/your_gem/organisms'
    add_group 'Models', 'lib/ace/your_gem/models'
  end
end
```

### 8. Testing Principles

1. **Test Isolation**: Each test should be independent and not rely on test execution order
2. **Fast Tests**: Keep unit tests fast by avoiding file I/O where possible
3. **Clear Naming**: Use descriptive test names that explain what is being tested
4. **Edge Cases**: Always test nil, empty, and boundary conditions
5. **Error Cases**: Test both success and failure paths
6. **Fixtures**: Use fixtures for complex test data, keep them minimal
7. **No Network Calls**: Mock external services, use VCR for recording if needed
8. **Deterministic**: Tests should produce the same result every time

## Getting Started Template

### Quick Start Script

```bash
#!/bin/bash
# create-ace-gem.sh

GEM_NAME=$1
if [ -z "$GEM_NAME" ]; then
  echo "Usage: ./create-ace-gem.sh your-gem-name"
  exit 1
fi

# Create gem structure
bundle gem "ace-$GEM_NAME" --no-exe --no-coc --no-ext --no-mit
cd "ace-$GEM_NAME"

# Create ATOM directories
mkdir -p lib/ace/$GEM_NAME/{atoms,molecules,organisms,models}
mkdir -p test/{atoms,molecules,organisms,integration,fixtures}
mkdir -p .ace.example/$GEM_NAME
mkdir -p handbook/workflow-instructions
mkdir -p docs

# Create executable stub
cat > exe/ace-$GEM_NAME << 'EOF'
#!/usr/bin/env ruby
# frozen_string_literal: true

require 'ace/your_gem'
require 'optparse'

options = {}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ace-your-gem [options]"

  opts.on("-v", "--version", "Show version") do
    puts Ace::YourGem::VERSION
    exit
  end

  opts.on("-h", "--help", "Show this help") do
    puts opts
    exit
  end
end

parser.parse!

# Main logic here
EOF

chmod +x exe/ace-$GEM_NAME

# Create test helper
cat > test/test_helper.rb << 'EOF'
require 'ace/test_support'
require 'ace/your_gem'

class YourGemTestCase < AceTestCase
end
EOF

# Update gemspec to add dependencies
echo "Add to gemspec:"
echo '  spec.add_dependency "ace-core"'
echo '  spec.add_development_dependency "ace-test-support"'
```

### Gemspec Template

```ruby
# ace-your-gem.gemspec
require_relative "lib/ace/your_gem/version"

Gem::Specification.new do |spec|
  spec.name = "ace-your-gem"
  spec.version = Ace::YourGem::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["your.email@example.com"]

  spec.summary = "Brief description of ace-your-gem"
  spec.description = "Longer description explaining what ace-your-gem does"
  spec.homepage = "https://github.com/youraccount/ace-meta"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = Dir.glob(%w[
    lib/**/*.rb
    exe/*
    README.md
    LICENSE.txt
    CHANGELOG.md
  ])
  spec.bindir = "exe"
  spec.executables = ["ace-your-gem"]
  spec.require_paths = ["lib"]

  # Core dependency
  spec.add_dependency "ace-core", "~> 0.9"

  # Optional ace-* dependencies
  # spec.add_dependency "ace-nav", "~> 0.9"
  # spec.add_dependency "ace-llm", "~> 0.9"

  # Development dependencies
  spec.add_development_dependency "ace-test-support", "~> 0.9"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "simplecov", "~> 0.22"
end
```

## Summary

When creating an ace-* gem:

1. **Check existing gems first** - Don't reinvent what's already available
2. **Follow ATOM architecture** - Maintain clean separation of concerns
3. **Use ace-core utilities** - Leverage configuration cascade and shared atoms
4. **Provide .ace.example** - Show all configuration options
5. **Include handbook workflows** - Enable AI assistance
6. **Write comprehensive tests** - Use AceTestCase and test all layers
7. **Document thoroughly** - Include README, usage docs, and inline comments
8. **Keep gems focused** - Each gem should have a single, clear purpose

Remember: The goal is to create reusable, testable, and AI-friendly development tools that integrate seamlessly with the ACE ecosystem.