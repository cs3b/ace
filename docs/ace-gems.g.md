---
update:
  update_frequency: weekly
  max_lines: 150
  required_sections:
  - overview
  - scope
  frequency: weekly
  last-updated: '2025-10-13'
---

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
├── test/                   # FLAT structure (not nested!)
│   ├── test_helper.rb
│   ├── atoms/              # Test atoms: *_test.rb
│   ├── molecules/          # Test molecules: *_test.rb
│   ├── organisms/          # Test organisms: *_test.rb
│   ├── models/             # Test models: *_test.rb
│   └── integration/        # Integration tests: *_test.rb
├── exe/
│   └── ace-your-gem       # Executable script
├── bin/
│   └── test               # Test runner for workspace context
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

### Configuration Pattern Overview

**CRITICAL**: All ace-* gems MUST use ace-core's config cascade system. Never use hardcoded file paths or custom config loaders.

**Config Cascade**: `./.ace/{gem}/ → ~/.ace/{gem}/ → defaults`

### Configuration Directory Structure

```
.ace/
└── your-gem/
    ├── config.yml         # General gem settings (optional)
    └── tool.yml           # Tool-specific config (if gem has multiple tools)
```

**Example Configs** (in gem directory):
```
ace-your-gem/
└── .ace.example/
    └── your-gem/
        ├── config.yml     # Example general config
        └── tool.yml       # Example tool config
```

### Configuration File Patterns

#### Single-Purpose Gems (Simple Config)

For gems with one main configuration:

```yaml
# .ace/your-gem/config.yml (user's project or home directory)
ace:
  your_gem:
    features:
      verbose: false
    processing:
      timeout: 30
```

#### Multi-Tool Gems (Separate Configs)

For gems supporting multiple tools (like ace-lint):

```yaml
# .ace/lint/config.yml (general ace-lint settings)
ace:
  lint:
    enabled_linters:
      - markdown
      - yaml

# .ace/lint/kramdown.yml (kramdown tool config - FLAT structure)
input: GFM
line_width: 120
auto_ids: false
hard_wrap: false
parse_block_html: true
parse_span_html: true
```

**Key Pattern**: Tool-specific configs use **flat structure** (no `ace:` nesting).

#### Config Structure Rules

**IMPORTANT**: Understanding when to use flat vs. nested config structure:

- ✅ **FLAT structure** (no `ace:` nesting):
  - Main/primary config for single-purpose gems (e.g., `.ace/docs/config.yml` for ace-docs)
  - Tool-specific configs (e.g., `.ace/lint/kramdown.yml` for kramdown linter)
  - Direct tool configuration that maps to tool options

- ✅ **NESTED structure** (`ace: { gem: {...} }`):
  - General gem settings when gem has multiple tools/configs
  - Configuration loaded via `Ace::Core.config.get('ace', 'gem_name')`

**Examples**:
```yaml
# FLAT - ace-docs main config (.ace/docs/config.yml)
document_types:
  guide:
    update_frequency: monthly

# FLAT - ace-lint tool config (.ace/lint/kramdown.yml)
input: GFM
line_width: 120

# NESTED - ace-lint general config (.ace/lint/config.yml)
ace:
  lint:
    enabled_linters:
      - markdown
```

### Loading Configuration

#### Simple Config Loading

```ruby
# lib/ace/your_gem.rb
module Ace
  module YourGem
    class Error < StandardError; end

    # Load configuration using ace-core config cascade
    # Follows ace-* pattern: ./.ace/your-gem/config.yml → ~/.ace/your-gem/config.yml
    # @return [Hash] Configuration hash
    def self.config
      @config ||= begin
        base_config = Ace::Core.config
        base_config.get('ace', 'your_gem') || default_config
      rescue StandardError => e
        warn "Warning: Could not load ace-your-gem config: #{e.message}"
        default_config
      end
    end

    # Default configuration when no config file exists
    # @return [Hash] Default configuration
    def self.default_config
      {
        'features' => { 'verbose' => false },
        'processing' => { 'timeout' => 30 }
      }
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
    end
  end
end
```

#### Multi-Tool Config Loading

For gems with multiple tool configs:

```ruby
# lib/ace/your_gem.rb
module Ace
  module YourGem
    # Load general gem configuration
    def self.config
      @config ||= begin
        base_config = Ace::Core.config
        base_config.get('ace', 'your_gem') || {}
      rescue StandardError => e
        warn "Warning: Could not load config: #{e.message}"
        {}
      end
    end

    # Load tool-specific configuration
    # Config location: .ace/your-gem/tool.yml
    # @return [Hash] Tool configuration
    def self.tool_config
      @tool_config ||= begin
        base_config = Ace::Core.config
        base_config.get('ace', 'your_gem', 'tool') || default_tool_config
      rescue StandardError => e
        warn "Warning: Could not load tool config: #{e.message}"
        default_tool_config
      end
    end

    def self.default_tool_config
      {
        'option1' => 'default',
        'option2' => true
      }
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
      @tool_config = nil
    end
  end
end
```

### Using Config in Code

```ruby
# lib/ace/your_gem/molecules/processor.rb
module Ace::YourGem::Molecules
  class Processor
    def initialize(options = {})
      config = Ace::YourGem.config

      # Merge: config file < CLI options
      @verbose = options[:verbose] || config['features']['verbose']
      @timeout = options[:timeout] || config['processing']['timeout']
    end
  end
end
```

### Configuration Best Practices

#### ✅ DO:
- Use `Ace::Core.config.get('ace', 'your_gem')` for loading
- Add `ace-core` dependency to gemspec: `spec.add_dependency "ace-core", "~> 0.9"`
- Provide sensible defaults in `default_config` method
- Create example configs in `.ace.example/your-gem/` within gem directory
- Create detailed config docs in `docs/config.md`
- Add brief config overview in README with link to docs/config.md
- Add `reset_config!` method for testing
- Handle loading errors gracefully with warnings
- Use FLAT structure for main/tool configs, NESTED for general gem configs

#### ❌ DON'T:
- **Never** use hardcoded file paths: `File.expand_path('~/.ace/your-gem/config.yml')`
- **Never** create custom ConfigLoader classes
- **Never** put config files in project root: `.your-gem.yml`
- **Never** skip example configs in `.ace.example/`
- **Never** put detailed config in README (use docs/config.md instead)
- **Never** create `CONFIGURATION.md` at root (use `docs/config.md`)

### Configuration Documentation Pattern

**IMPORTANT**: Each ACE gem should have two levels of configuration documentation:

1. **README.md Configuration Section** - Brief overview with defaults
2. **docs/config.md** - Comprehensive configuration reference

#### README.md Configuration Section (Brief)

Add to your gem's README.md:

```markdown
## Configuration

ace-your-gem uses the ace-core config cascade system.

**Quick Start**: Default configuration works out of the box. For customization, see [docs/config.md](docs/config.md).

### Default Settings

- Verbose mode: disabled
- Timeout: 30 seconds
- Config location: `.ace/your-gem/config.yml`

### Config Cascade

Configuration loaded in order (later overrides earlier):

1. Built-in defaults
2. User config (`~/.ace/your-gem/config.yml`)
3. Project config (`./.ace/your-gem/config.yml`)
4. CLI options

For detailed configuration options, see [docs/config.md](docs/config.md).
```

#### docs/config.md (Comprehensive)

Create detailed configuration reference in `docs/config.md`:

```markdown
# Configuration Reference

Complete guide for configuring ace-your-gem.

## Configuration Files

- **Main config**: `.ace/your-gem/config.yml` - General settings
- **Example**: `.ace.example/your-gem/config.yml` - Reference implementation

## Configuration Options

### Full Configuration Example

\```yaml
ace:
  your_gem:
    features:
      verbose: false    # Enable verbose output
      debug: false      # Enable debug logging
    processing:
      timeout: 30       # Processing timeout in seconds
      parallel: true    # Enable parallel processing
\```

### Options Reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `features.verbose` | boolean | `false` | Enable verbose output |
| `features.debug` | boolean | `false` | Enable debug logging |
| `processing.timeout` | integer | `30` | Processing timeout (seconds) |
| `processing.parallel` | boolean | `true` | Enable parallel processing |

## Configuration Patterns

### Development vs Production

\```yaml
# Development (.ace/your-gem/config.yml)
ace:
  your_gem:
    features:
      verbose: true
      debug: true

# Production (~/.ace/your-gem/config.yml)
ace:
  your_gem:
    features:
      verbose: false
      debug: false
\```

## Troubleshooting

**Config not loading**: Verify file location and YAML syntax
**Unexpected values**: Check config cascade order
```

### Configuration Testing

```ruby
# test/your_gem_test.rb
class YourGemTest < YourGemTestCase
  def setup
    Ace::YourGem.reset_config!  # Reset between tests
  end

  def test_default_config
    config = Ace::YourGem.config
    assert_equal false, config['features']['verbose']
    assert_equal 30, config['processing']['timeout']
  end

  def test_config_loading_error
    # Test graceful handling when config loading fails
    Ace::Core.stub :config, proc { raise "Config error" } do
      config = Ace::YourGem.config
      assert_equal Ace::YourGem.default_config, config
    end
  end
end
```

### Anti-Patterns to Avoid

Based on real implementation mistakes:

```ruby
# ❌ WRONG: Hardcoded paths
CONFIG_PATHS = [
  '.ace/your-gem/config.yml',
  File.expand_path('~/.ace/your-gem/config.yml')
].freeze

# ❌ WRONG: Custom config loader
class ConfigLoader
  def self.load
    CONFIG_PATHS.each do |path|
      return YAML.load_file(path) if File.exist?(path)
    end
  end
end

# ❌ WRONG: Project root config file
config_file = '.your-gem.yml'

# ✅ CORRECT: Use ace-core
base_config = Ace::Core.config
base_config.get('ace', 'your_gem') || default_config
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

## Development Binstubs

Create a development binstub in `bin/` for running your gem with workspace context:

```ruby
# bin/ace-your-gem
#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"

# Find the ace-meta root directory
ace_meta_root = Pathname.new(__FILE__).dirname.parent.realpath

# Set the Gemfile location
ENV["BUNDLE_GEMFILE"] = ace_meta_root.join("Gemfile").to_s

# Load bundler
require "bundler/setup"

# Now require and run the actual executable
load ace_meta_root.join("ace-your-gem/exe/ace-your-gem").to_s
```

Make it executable: `chmod +x bin/ace-your-gem`

**Usage**: Run `bin/ace-your-gem` from workspace root instead of `bundle exec ace-your-gem`

### Mono-Repo Development Pattern

**IMPORTANT**: Understanding ACE mono-repo gem dependencies:

#### Gemfile vs Gemspec Dependencies

- **Gemfile** (workspace root): Provides ALL ace-* gems locally during development
  - All gems available without individual installation
  - Workspace context with proper load paths
  - Used by binstubs via `bundle exec` or `bundler/setup`

- **Gemspec**: Declares dependencies for gem installation (via `gem install`)
  - Still add `spec.add_dependency "ace-core", "~> 0.9"` etc.
  - Required when gem is installed outside mono-repo
  - Documents external dependencies

#### Development Workflow

```bash
# All gems available via workspace Gemfile
cd ace-meta

# Run any tool via binstub (uses workspace context)
bin/ace-docs status          # ✅ Works - uses bundler/setup
bin/ace-lint file.md         # ✅ Works - uses bundler/setup

# Or use bundle exec from gem directory
cd ace-docs
bundle exec ace-docs status  # ✅ Works - uses root Gemfile

# Individual gem install NOT needed for development
# gem install ace-docs       # ❌ Not needed in mono-repo
```

#### Why This Matters

- **Development**: Workspace Gemfile provides everything
- **Testing**: Binstubs ensure proper workspace context
- **Installation**: Gemspec dependencies matter for `gem install`
- **CI/CD**: Uses workspace Gemfile for integration testing

**Rule**: Always test with binstubs (`bin/ace-*`) to ensure workspace context is correct.

## Testing

### Flat Test Structure

**IMPORTANT**: All ACE gems use a **flat test structure** that mirrors ATOM layers:

```
test/
├── test_helper.rb
├── your_gem_test.rb         # Main module test
├── atoms/
│   └── parser_test.rb       # Suffix naming: *_test.rb
├── molecules/
│   └── loader_test.rb
├── organisms/
│   └── processor_test.rb
├── models/
│   └── result_test.rb
└── integration/
    └── cli_test.rb
```

**Key conventions:**
- ✅ Flat structure: `test/atoms/`, not `test/ace/your_gem/atoms/`
- ✅ Suffix naming: `parser_test.rb`, not `test_parser.rb`
- ✅ Layer directories match ATOM architecture
- ✅ Integration tests in separate `integration/` directory

See `docs/testing-patterns.md` for complete testing guide.

### Setup

```ruby
# test/test_helper.rb
require 'ace/test_support'
require 'ace/your_gem'

# Load all components
require 'ace/your_gem/atoms/parser'
require 'ace/your_gem/molecules/loader'
# ... etc

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

### Workspace Test Suite

Add your gem to the workspace test suite to run alongside other ACE gems:

```yaml
# .ace/test/suite.yml
test_suite:
  packages:
    # ... existing gems ...

    - name: ace-your-gem
      path: ace-your-gem
      group: tools
      priority: 3
```

**Test Groups:**
- `foundation` (priority 1-2): ace-core, ace-test-support, ace-test-runner
- `tools` (priority 3): All other ace-* gems

**Run workspace tests:**
```bash
# Run all tests
ace-test

# Run specific gem
ace-test ace-your-gem

# Run with verbose output
ace-test --verbose
```

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
mkdir -p test/{atoms,molecules,organisms,models,integration,fixtures}
mkdir -p exe bin .ace.example/$GEM_NAME

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
