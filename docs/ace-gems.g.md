# ACE Gem Development Guide

Quick guide for creating ace-* gems that integrate with the ACE framework.

## Available Shared Packages

Before implementing functionality, leverage these existing ace-* gems:

### ace-core
Zero-dependency foundation providing configuration cascade, environment management, and utilities.

```ruby
require 'ace/core'

# Configuration cascade (./.ace → ~/.ace → defaults)
config = Ace::Core.config
value = Ace::Core.get('ace', 'settings', 'key')
Ace::Core.get_env('API_KEY', 'default')  # Env vars without polluting ENV

# Discovery API
discovery = Ace::Core::ConfigDiscovery.new
discovery.project_root
discovery.find_config_file('config.yml')

# Common atoms (require explicitly for tree-shaking)
require 'ace/core/atoms/yaml_parser'
require 'ace/core/atoms/deep_merger'
require 'ace/core/atoms/file_reader'

Ace::Core::Atoms::YamlParser.parse(yaml)
Ace::Core::Atoms::DeepMerger.merge(base, override)
Ace::Core::Atoms::FileReader.read(path)
```
*See ace-core/README.md for complete API documentation.*

### ace-test-support
Testing utilities and base test case:

```ruby
require 'ace/test_support'

class MyTest < AceTestCase
  def test_cli
    result = run_subprocess(['ace-your-gem', 'process'])
    assert_equal 0, result.exit_code
  end
end
```

### Other Useful Gems
- **ace-nav**: Resource navigation (`wfi://` protocol)
- **ace-llm**: Multi-provider LLM integration
- **ace-taskflow**: Task and release management

## Gem Structure

All ace-* gems follow the ATOM architecture pattern - see [architecture.md](../docs/architecture.md) for details.

### Standard Directory Layout

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
│           ├── models/     # Data structures
│           └── version.rb
├── test/
│   ├── test_helper.rb
│   └── (test files matching lib structure)
├── exe/
│   └── ace-your-gem       # Executable script
├── ace-your-gem.gemspec
├── Rakefile
└── README.md
```

### Quick Example Structure

```ruby
# lib/ace/your_gem/atoms/parser.rb - Pure function
module Ace::YourGem::Atoms
  module Parser
    module_function
    def parse(input)
      JSON.parse(input)
    end
  end
end

# lib/ace/your_gem/molecules/loader.rb - Composed operation
class Ace::YourGem::Molecules::Loader
  def self.load_file(path)
    content = Ace::Core::Atoms::FileReader.read(path)
    Atoms::Parser.parse(content)
  end
end
```

## Configuration

### Example Configuration (.ace.example)

```yaml
# .ace.example/your-gem/config.yml
ace:
  your_gem:
    features:
      verbose: false
    processing:
      timeout: 30
```

### Loading Configuration

```ruby
# lib/ace/your_gem.rb
module Ace
  module YourGem
    def self.config
      @config ||= begin
        base_config = Ace::Core.config
        base_config.get('ace', 'your_gem') || default_config
      end
    end

    def self.default_config
      { 'features' => { 'verbose' => false }, 'processing' => { 'timeout' => 30 } }
    end
  end
end
```

## CLI Implementation

```ruby
# exe/ace-your-gem
#!/usr/bin/env ruby
require 'ace/your_gem'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ace-your-gem [options]"
  opts.on("-v", "--verbose", "Verbose output") { options[:verbose] = true }
  opts.on("-h", "--help", "Show help") { puts opts; exit }
end.parse!

config = Ace::YourGem.config
verbose = options[:verbose] || config['features']['verbose']

begin
  # Your gem logic here
  result = Ace::YourGem::Organisms::Processor.new.process(ARGV[0])
  puts result
rescue => e
  $stderr.puts "Error: #{e.message}"
  exit 1
end
```

## Claude Code Integration

Create command files in `.claude/commands/`:

```markdown
# .claude/commands/your-gem-process.md
---
description: Process data with ace-your-gem
allowed-tools: Read, Write, Bash
argument-hint: "[file-path]"
---

Process the file using ace-your-gem functionality.
```

## Testing

### Setup

```ruby
# test/test_helper.rb
require 'ace/test_support'
require 'ace/your_gem'

class YourGemTestCase < AceTestCase
end
```

### Essential Testing Patterns

```ruby
# Test atoms (pure functions)
class ParserTest < YourGemTestCase
  def test_parse_valid
    result = Ace::YourGem::Atoms::Parser.parse('{"key": "value"}')
    assert_equal({ "key" => "value" }, result)
  end
end

# Test CLI commands
class CLITest < YourGemTestCase
  def test_command
    result = run_subprocess(['ace-your-gem', 'process', 'file.json'])
    assert_equal 0, result.exit_code
  end
end

# Test with fixtures
def test_with_fixture
  data = fixture_path('sample.json')  # Provided by AceTestCase
  result = process(data)
  assert result.success?
end
```

### Coverage

```ruby
# Rakefile
require 'rake/testtask'
Rake::TestTask.new(:test) do |t|
  t.test_files = FileList['test/**/*_test.rb']
end
```

**Key Principles:**
- Test isolation - each test independent
- Use fixtures from `test/fixtures/`
- Mock external services
- Test edge cases and error paths

## Quick Start

### Create New Gem

```bash
#!/bin/bash
# create-ace-gem.sh
GEM_NAME=$1
bundle gem "ace-$GEM_NAME" --no-exe --no-coc --no-ext --no-mit
cd "ace-$GEM_NAME"

# Create structure
mkdir -p lib/ace/$GEM_NAME/{atoms,molecules,organisms,models}
mkdir -p test/fixtures exe .ace.example/$GEM_NAME

# Create executable
cat > exe/ace-$GEM_NAME << 'EOF'
#!/usr/bin/env ruby
require 'ace/your_gem'
require 'optparse'

OptionParser.new do |opts|
  opts.banner = "Usage: ace-your-gem [options]"
  opts.on("-h", "--help", "Show help") { puts opts; exit }
end.parse!

# Main logic
EOF
chmod +x exe/ace-$GEM_NAME

# Update gemspec dependencies
echo "Add to gemspec: ace-core and ace-test-support"
```

### Minimal Gemspec

```ruby
# ace-your-gem.gemspec
Gem::Specification.new do |spec|
  spec.name = "ace-your-gem"
  spec.version = "0.1.0"
  spec.summary = "Your gem description"
  spec.files = Dir.glob(%w[lib/**/*.rb exe/* README.md])
  spec.bindir = "exe"
  spec.executables = ["ace-your-gem"]
  spec.add_dependency "ace-core", "~> 0.9"
  spec.add_development_dependency "ace-test-support", "~> 0.9"
end
```

## Key Guidelines

- **Reuse existing gems** - Check ace-core, ace-test-support first
- **Follow ATOM pattern** - See [architecture.md](../docs/architecture.md)
- **Test thoroughly** - Use AceTestCase for consistent testing
- **Keep focused** - Single purpose per gem
- **Document clearly** - README with examples

*For existing gem examples, see any ace-* directory in the repository.*