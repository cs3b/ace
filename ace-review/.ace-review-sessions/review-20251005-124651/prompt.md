# Code Review System Prompt Base

You are a senior software engineer conducting a thorough code review.
Your task: perform a *structured* code review on the diff (or repo snapshot) supplied by the user.

## Core Review Principles

Your review must be:
1. **Constructive**: Focus on improvement, not criticism
2. **Specific**: Provide exact locations and examples
3. **Actionable**: Every issue should have a suggested fix
4. **Educational**: Help the author learn best practices
5. **Balanced**: Acknowledge both strengths and weaknesses

## Review Approach

- Be specific with line numbers and file references
- Provide code examples for suggested improvements
- Explain the "why" behind your feedback
- Balance criticism with recognition of good work
- Consider the PR's scope and avoid scope creep
- Check for consistency with existing codebase patterns

## Output Constraints

Output MUST follow the exact section order and Markdown anchors given below so that automated comparison scripts can parse it.
If a section has nothing to report, write "*No issues found*".

Tone: concise, professional, actionable.
Assume reviewers will aggregate multiple provider outputs; avoid personal opinions or references to other models.

## Output Format

# Detailed Review Format

## Enhanced Output Structure

### Deep Diff Analysis
For each significant change:
- **Intent**: What the change aims to achieve
- **Impact**: Effects on the codebase
- **Alternatives**: Other approaches considered

### Code Quality Assessment
- **Complexity metrics**: Cyclomatic complexity, cognitive load
- **Maintainability index**: Based on code patterns
- **Test coverage delta**: Change in coverage percentage

### Architectural Analysis
- **Pattern compliance**: Adherence to design patterns
- **Dependency changes**: New or modified dependencies
- **Component boundaries**: Interface changes

### Documentation Impact Assessment
- **Required updates**: What documentation needs updating
- **API changes**: Breaking or non-breaking changes
- **Migration notes**: For breaking changes

### Quality Assurance Requirements
- **Test scenarios**: Additional test cases needed
- **Integration points**: Areas requiring integration testing
- **Performance benchmarks**: Metrics to monitor

### Security Review
- **Attack vectors**: Potential security issues
- **Data flow**: How sensitive data is handled
- **Compliance**: Regulatory requirements

### Refactoring Opportunities
- **Technical debt**: Areas that could be improved
- **Code smells**: Patterns that suggest refactoring
- **Future-proofing**: Preparing for upcoming changes


## Review Focus

# ATOM Architecture Focus

## Architectural Compliance (ATOM)

The project follows the ATOM architecture (Atoms → Molecules → Organisms → Ecosystem).

### Review Requirements
- Verify ATOM pattern adherence across all layers
- Check component boundaries and responsibilities
- Assess dependency injection and testing patterns
- Validate separation of concerns
- Ensure proper layering: Atoms have no dependencies, Molecules depend only on Atoms, etc.

### Critical Success Factors
- **Atoms**: Pure, stateless, single-responsibility units
- **Molecules**: Composable business logic components
- **Organisms**: Complex features combining molecules
- **Ecosystem**: Application-level orchestration

### Common Issues to Check
- Atoms containing business logic (should be pure)
- Molecules with external dependencies (should use injection)
- Organisms directly accessing atoms (should go through molecules)
- Circular dependencies between layers

---

# Ruby Language Focus

## Ruby-Specific Review Criteria

You are reviewing Ruby code with expertise in Ruby best practices and idioms.

### Ruby Gem Best Practices
- Proper gem structure and organization
- Semantic versioning compliance
- Dependency management and version constraints
- README and documentation standards

### Code Quality Standards
- **Style**: StandardRB compliance (note justified exceptions)
- **Idioms**: Ruby idioms and conventions
- **Performance**: Efficient use of Ruby features
- **Memory**: Proper object lifecycle management

### Testing with RSpec
- Target: 90%+ test coverage
- Test organization and naming conventions
- Proper use of RSpec features (contexts, let, before/after)
- Mock and stub usage appropriateness

### Ruby-Specific Checks
- Proper use of blocks, procs, and lambdas
- Metaprogramming appropriateness
- Module and class design
- Exception handling patterns
- String interpolation vs concatenation
- Symbol vs string usage
- Enumerable method selection
- Proper use of attr_accessor/reader/writer


## Guidelines

# Review Tone Guidelines

## Communication Style

### Professional Tone
- Concise and direct feedback
- Focus on code, not the coder
- Use "we" instead of "you" when suggesting improvements
- Acknowledge good practices before critiquing

### Constructive Feedback
- Start with positives when possible
- Frame issues as opportunities for improvement
- Provide specific examples and alternatives
- Explain the reasoning behind suggestions

### Educational Approach
- Share knowledge without condescension
- Link to relevant documentation or resources
- Explain best practices and patterns
- Help the author learn and grow

# Icon Usage Guidelines

## Visual Indicators

### Status Icons
- ✅ **Success/Good**: Working correctly, best practice followed
- ⚠️ **Warning**: Potential issue, needs attention
- ❌ **Error/Blocking**: Must fix, prevents merge
- 💡 **Suggestion**: Improvement opportunity
- ❓ **Question**: Needs clarification
- 📝 **Note**: Important information
- 🎯 **Focus**: Key area for review

### Severity Colors
- 🔴 **Critical**: Blocking issues requiring immediate fix
- 🟡 **High**: Important issues that should be addressed
- 🟢 **Medium**: Improvements that would enhance quality
- 🔵 **Low**: Nice-to-have enhancements
- ⚪ **Info**: Neutral information or context


## Project Context

File: README.md
----------------------------------------
# ace-review

Automated review tool for the ACE framework. Provides preset-based analysis using LLM-powered insights with configurable focus areas and flexible prompt composition.

## Features

- **Preset-based reviews** - Predefined configurations for common scenarios (PR, security, docs, etc.)
- **Flexible prompt composition** - Modular prompts with base, format, focus, and guidelines
- **Prompt cascade** - Override built-in prompts at project or user level
- **Multiple focus modules** - Combine architecture, language, and quality focuses
- **Release integration** - Stores reviews in `.ace-taskflow/<release>/reviews/`
- **LLM provider support** - Works with any provider supported by ace-llm
- **Custom presets** - Create team-specific review configurations

## Installation

Add this gem to your Gemfile:

```ruby
gem 'ace-review'
```

Or install it directly:

```bash
gem install ace-review
```

## Quick Start

```bash
# Review pull request changes (default)
ace-review

# Security-focused review
ace-review --preset security

# List available presets
ace-review --list-presets

# List available prompt modules
ace-review --list-prompts

# Execute review with LLM automatically
ace-review --preset pr --auto-execute
```

## Configuration

### Main Configuration

Create `.ace/review/code.yml` in your project:

```yaml
defaults:
  model: "google:gemini-2.5-flash"
  output_format: "markdown"
  context: "project"

storage:
  base_path: ".ace-taskflow/%{release}/reviews"
  auto_organize: true

presets:
  pr:
    description: "Pull request review"
    prompt_composition:
      base: "prompt://base/system"
      format: "prompt://format/standard"
      guidelines:
        - "prompt://guidelines/tone"
        - "prompt://guidelines/icons"
    context: "project"
    subject:
      commands:
        - "git diff origin/main...HEAD"
```

### Custom Presets

Create preset files in `.ace/review/presets/`:

```yaml
# .ace/review/presets/team-review.yml
description: "Team-specific review criteria"
prompt_composition:
  base: "prompt://base/system"
  format: "prompt://format/detailed"
  focus:
    - "prompt://focus/architecture/atom"
    - "prompt://focus/languages/ruby"
    - "prompt://project/focus/team/standards"  # Custom team focus
  guidelines:
    - "prompt://guidelines/tone"
context:
  files:
    - "docs/team-guidelines.md"
subject:
  commands:
    - "git diff HEAD~1..HEAD"
```

## Prompt System

### Prompt Cascade

Prompts are resolved in this order:
1. Project: `./.ace/review/prompts/`
2. User: `~/.ace/review/prompts/`
3. Built-in: Gem's internal prompts

### Prompt Structure

```
.ace/review/prompts/
├── base/           # Core system prompts
├── format/         # Output formats
├── focus/          # Review focus areas
│   ├── architecture/
│   ├── languages/
│   ├── quality/
│   └── scope/
└── guidelines/     # Style guidelines
```

### prompt:// Protocol

Reference prompts using URIs:

```yaml
prompt_composition:
  base: "prompt://base/system"              # Cascade lookup
  base: "prompt://project/base/custom"      # Project only
  base: "./my-prompt.md"                    # Relative to config
  base: "prompts/my-prompt.md"              # From project root
```

## Focus Modules

Combine multiple focus modules for comprehensive reviews:

```yaml
focus:
  - "prompt://focus/architecture/atom"      # ATOM pattern
  - "prompt://focus/languages/ruby"         # Ruby best practices
  - "prompt://focus/quality/security"       # Security analysis
```

Available focus modules:
- **Architecture**: atom, microservices, mvc
- **Languages**: ruby, javascript, python
- **Frameworks**: rails, vue-firebase
- **Quality**: security, performance
- **Scope**: tests, docs

## CLI Reference

### ace-review

```bash
ace-review [options]
```

Options:
- `--preset <name>` - Use specific preset (default: pr)
- `--output-dir <path>` - Custom output directory
- `--output <file>` - Specific output file path
- `--model <model>` - Override LLM model
- `--auto-execute` - Execute LLM query automatically
- `--dry-run` - Prepare review without executing
- `--list-presets` - List available presets
- `--list-prompts` - List available prompt modules
- `--verbose` - Enable verbose output

Advanced options for prompt composition:
- `--prompt-base <module>` - Override base prompt
- `--prompt-format <module>` - Override format module
- `--prompt-focus <modules>` - Set focus modules (comma-separated)
- `--add-focus <modules>` - Add focus to preset
- `--prompt-guidelines <modules>` - Set guideline modules

## Migration from code-review

This gem replaces the previous `code-review` commands:

| Old Command | New Command |
|-------------|-------------|
| `code-review` | `ace-review` |
| `code-review-synthesize` | Use workflow: `wfi://synthesize-reviews` |

### Migration Steps

1. **Install ace-review gem**
   ```bash
   gem install ace-review
   ```

2. **Copy configuration**
   ```bash
   cp .coding-agent/code-review.yml .ace/review/code.yml
   ```

3. **Update workflow files**
   - Replace `code-review` with `ace-review`
   - Remove `code-review-synthesize` CLI usage

## Architecture

ace-review follows the ATOM architecture pattern:

- **Atoms**: Pure functions (git_extractor, file_reader)
- **Molecules**: Composed operations (preset_manager, prompt_composer)
- **Organisms**: Business orchestration (review_manager)
- **Models**: Data structures (review_config, preset)

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rake test

# Run with local changes
bundle exec exe/ace-review --list-presets

# Console for debugging
bundle exec rake console
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Create a Pull Request

## License

MIT License - see LICENSE.txt for details



## Code to Review

File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/atoms/file_reader.rb
----------------------------------------
# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Pure functions for reading files
      module FileReader
        module_function

        # Read a file with error handling
        def read(path)
          return { success: false, content: nil, error: "Path is nil" } unless path
          return { success: false, content: nil, error: "File not found: #{path}" } unless File.exist?(path)

          {
            success: true,
            content: File.read(path),
            error: nil
          }
        rescue StandardError => e
          {
            success: false,
            content: nil,
            error: e.message
          }
        end

        # Read multiple files
        def read_multiple(paths)
          results = {}
          paths.each do |path|
            results[path] = read(path)
          end
          results
        end

        # Read files matching a pattern
        def read_pattern(pattern, base_dir: nil)
          base = base_dir || Dir.pwd
          full_pattern = File.join(base, pattern)

          files = Dir.glob(full_pattern)
          read_multiple(files)
        end

        # Check if a file exists
        def exists?(path)
          File.exist?(path)
        end

        # Get file size
        def size(path)
          return nil unless exists?(path)
          File.size(path)
        end

        # Get file modification time
        def mtime(path)
          return nil unless exists?(path)
          File.mtime(path)
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/atoms/git_extractor.rb
----------------------------------------
# frozen_string_literal: true

require "open3"

module Ace
  module Review
    module Atoms
      # Pure functions for extracting git information
      module GitExtractor
        module_function

        # Execute a git diff command
        def git_diff(range_or_target)
          execute_git_command("git diff #{range_or_target}")
        end

        # Get git log for a range
        def git_log(range, format: "--oneline")
          execute_git_command("git log #{range} #{format}")
        end

        # Get staged changes
        def staged_diff
          execute_git_command("git diff --cached")
        end

        # Get working directory changes
        def working_diff
          execute_git_command("git diff")
        end

        # Get list of changed files
        def changed_files(range_or_target)
          output = execute_git_command("git diff --name-only #{range_or_target}")
          return [] unless output[:success]

          output[:output].split("\n").map(&:strip).reject(&:empty?)
        end

        # Check if we're in a git repository
        def in_git_repo?
          result = execute_git_command("git rev-parse --git-dir")
          result[:success]
        end

        # Get current branch name
        def current_branch
          result = execute_git_command("git rev-parse --abbrev-ref HEAD")
          result[:success] ? result[:output].strip : nil
        end

        # Get remote tracking branch
        def tracking_branch
          result = execute_git_command("git rev-parse --abbrev-ref --symbolic-full-name @{u}")
          result[:success] ? result[:output].strip : nil
        end

        private

        def execute_git_command(command)
          stdout, stderr, status = Open3.capture3(command)

          {
            success: status.success?,
            output: stdout,
            error: stderr,
            exit_code: status.exitstatus
          }
        rescue StandardError => e
          {
            success: false,
            output: "",
            error: e.message,
            exit_code: -1
          }
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/cli.rb
----------------------------------------
# frozen_string_literal: true

require "optparse"

module Ace
  module Review
    # CLI interface for ace-review
    class CLI
      def initialize
        @options = {
          preset: "pr",
          save_session: true
        }
      end

      def run(argv)
        parse_options(argv)

        # Handle list commands
        if @options[:list_presets]
          list_presets
          return
        elsif @options[:list_prompts]
          list_prompts
          return
        elsif @options[:help]
          show_help
          return
        end

        # Execute review
        execute_review
      rescue StandardError => e
        puts "✗ Error: #{e.message}"
        puts e.backtrace if @options[:verbose]
        exit 1
      end

      private

      def parse_options(argv)
        @parser = OptionParser.new do |opts|
          opts.banner = "Usage: ace-review [options]"
          opts.separator ""
          opts.separator "Execute review using presets or custom configuration"
          opts.separator ""
          opts.separator "Options:"

          opts.on("--preset NAME", "Review preset from configuration (default: pr)") do |v|
            @options[:preset] = v
          end

          opts.on("--output-dir DIR", "Custom output directory for review") do |v|
            @options[:output_dir] = v
          end

          opts.on("--output FILE", "Specific output file path") do |v|
            @options[:output] = v
          end

          opts.on("--context CONFIG", "Context configuration (preset name or YAML)") do |v|
            @options[:context] = v
          end

          opts.on("--subject CONFIG", "Subject configuration (git range or YAML)") do |v|
            @options[:subject] = v
          end

          opts.on("--prompt-base MODULE", "Base prompt module") do |v|
            @options[:prompt_base] = v
          end

          opts.on("--prompt-format MODULE", "Format module") do |v|
            @options[:prompt_format] = v
          end

          opts.on("--prompt-focus MODULES", "Focus modules (comma-separated)") do |v|
            @options[:prompt_focus] = v
          end

          opts.on("--add-focus MODULES", "Add focus modules to preset") do |v|
            @options[:add_focus] = v
          end

          opts.on("--prompt-guidelines MODULES", "Guideline modules (comma-separated)") do |v|
            @options[:prompt_guidelines] = v
          end

          opts.on("--model MODEL", "LLM model to use") do |v|
            @options[:model] = v
          end

          opts.on("--list-presets", "List available presets") do
            @options[:list_presets] = true
          end

          opts.on("--list-prompts", "List available prompt modules") do
            @options[:list_prompts] = true
          end

          opts.on("--dry-run", "Prepare review without executing") do
            @options[:dry_run] = true
          end

          opts.on("-v", "--verbose", "Verbose output") do
            @options[:verbose] = true
          end

          opts.on("--auto-execute", "Execute LLM query automatically") do
            @options[:auto_execute] = true
          end

          opts.on("--[no-]save-session", "Save session files (default: true)") do |v|
            @options[:save_session] = v
          end

          opts.on("--session-dir DIR", "Custom session directory") do |v|
            @options[:session_dir] = v
          end

          opts.on("-h", "--help", "Show this help") do
            @options[:help] = true
          end
        end

        @parser.parse!(argv)
      end

      def show_help
        puts @parser
        puts
        puts "Examples:"
        puts "  ace-review --preset pr"
        puts "  ace-review --preset security --auto-execute"
        puts "  ace-review --preset docs --output-dir ./reviews"
        puts "  ace-review --list-presets"
        puts "  ace-review --list-prompts"
      end

      def list_presets
        manager = Ace::Review::Organisms::ReviewManager.new

        presets = manager.list_presets
        if presets.empty?
          puts "No presets found"
          puts "Create presets in .ace/review/code.yml or .ace/review/presets/"
          return
        end

        puts "Available Review Presets:"
        puts

        # Header
        puts format("%-20s %-50s %-10s", "Preset", "Description", "Source")
        puts "-" * 80

        # Load preset manager to get descriptions
        preset_manager = Ace::Review::Molecules::PresetManager.new

        presets.each do |name|
          preset = preset_manager.load_preset(name)
          description = preset&.dig("description") || "-"

          # Determine source
          source = if preset_manager.send(:load_preset_from_file, name)
                     "file"
                   elsif preset_manager.send(:load_preset_from_config, name)
                     "config"
                   else
                     "default"
                   end

          puts format("%-20s %-50s %-10s", name, description, source)
        end
      end

      def list_prompts
        manager = Ace::Review::Organisms::ReviewManager.new

        prompts = manager.list_prompts
        if prompts.empty?
          puts "No prompt modules found"
          return
        end

        puts "Available Prompt Modules:"
        puts

        prompts.each do |category, items|
          puts "  #{category}/"
          format_prompt_items(items, "    ")
        end
      end

      def format_prompt_items(items, indent)
        case items
        when Hash
          items.each do |name, value|
            if value.is_a?(Array)
              puts "#{indent}#{name}/"
              value.each do |item|
                source = item.is_a?(Hash) ? " (#{item[:source]})" : ""
                item_name = item.is_a?(Hash) ? item[:name] : item
                puts "#{indent}  #{item_name}#{source}"
              end
            else
              source = value.is_a?(String) ? " (#{value})" : ""
              puts "#{indent}#{name}#{source}"
            end
          end
        when Array
          items.each { |item| puts "#{indent}#{item}" }
        when String
          puts "#{indent}#{items}"
        end
      end

      def execute_review
        puts "Analyzing code with preset '#{@options[:preset]}'..." if @options[:verbose]

        manager = Ace::Review::Organisms::ReviewManager.new
        result = manager.execute_review(@options)

        if result[:success]
          handle_success(result)
        else
          handle_error(result)
        end
      end

      def handle_success(result)
        if result[:output_file]
          puts "✓ Review saved: #{result[:output_file]}"
        elsif result[:session_dir]
          puts "✓ Review session prepared: #{result[:session_dir]}"
          puts "  Prompt: #{result[:prompt_file]}"
          unless @options[:dry_run]
            puts
            puts "To execute with LLM:"
            puts "  ace-llm query --file #{result[:prompt_file]}"
          end
        end
      end

      def handle_error(result)
        puts "✗ Error: #{result[:error]}"
        exit 1
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/context_extractor.rb
----------------------------------------
# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Extracts context (background information) for reviews
      class ContextExtractor
        DEFAULT_PROJECT_DOCS = [
          "README.md",
          "docs/architecture.md",
          "docs/what-do-we-build.md",
          "docs/blueprint.md",
          ".github/CONTRIBUTING.md",
          "ARCHITECTURE.md"
        ].freeze

        def initialize
          @file_reader = Atoms::FileReader
          @preset_manager = nil # Lazy load to avoid circular dependency
        end

        # Extract context from configuration
        # @param context_config [String, Hash, nil] context configuration
        # @return [String] extracted context content
        def extract(context_config)
          case context_config
          when nil, "none", false
            ""
          when "project", "auto", true
            extract_project_context
          when String
            extract_from_string(context_config)
          when Hash
            extract_from_hash(context_config)
          else
            ""
          end
        end

        private

        def extract_from_string(input)
          # Try to parse as YAML first
          parsed = YAML.safe_load(input)
          return extract_from_hash(parsed) if parsed.is_a?(Hash)

          # Check if it's a preset name
          if preset_context = load_preset_context(input)
            return extract(preset_context)
          end

          # Treat as file path
          extract_file(input)
        rescue Psych::SyntaxError
          # If YAML parsing fails, treat as file path
          extract_file(input)
        end

        def extract_from_hash(config)
          parts = []

          # Read specified files
          if config["files"]
            files = config["files"]
            files = [files] unless files.is_a?(Array)

            files.each do |file|
              content = extract_file(file)
              parts << content unless content.empty?
            end
          end

          # Include inline content
          if config["content"]
            parts << config["content"]
          end

          # Execute commands for dynamic context
          if config["commands"]
            config["commands"].each do |command|
              output = execute_command(command)
              parts << format_command_context(command, output) if output
            end
          end

          parts.join("\n\n" + "=" * 80 + "\n\n")
        end

        def extract_project_context
          parts = []

          DEFAULT_PROJECT_DOCS.each do |doc_path|
            content = extract_file(doc_path)
            parts << content unless content.empty?
          end

          if parts.empty?
            # If no standard docs found, try to find any markdown files
            fallback_docs = Dir.glob("{*.md,docs/*.md}").first(3)
            fallback_docs.each do |doc|
              content = extract_file(doc)
              parts << content unless content.empty?
            end
          end

          parts.join("\n\n" + "=" * 80 + "\n\n")
        end

        def extract_file(path)
          result = @file_reader.read(path)
          return "" unless result[:success]

          <<~CONTENT
            File: #{path}
            #{"-" * 40}
            #{result[:content]}
          CONTENT
        end

        def load_preset_context(preset_name)
          # Lazy load preset manager
          @preset_manager ||= PresetManager.new

          preset = @preset_manager.load_preset(preset_name)
          preset&.dig("context")
        end

        def execute_command(command)
          require "open3"
          stdout, stderr, status = Open3.capture3(command)
          return nil unless status.success?

          stdout
        rescue StandardError => e
          warn "Failed to execute context command '#{command}': #{e.message}" if Ace::Review.debug?
          nil
        end

        def format_command_context(command, output)
          <<~CONTEXT
            Command Output: #{command}
            #{"-" * 40}
            #{output}
          CONTEXT
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/llm_executor.rb
----------------------------------------
# frozen_string_literal: true

require "open3"
require "json"

module Ace
  module Review
    module Molecules
      # Executes LLM queries for code reviews
      class LlmExecutor
        def initialize
          @default_model = Ace::Review.get("defaults", "model") || "google:gemini-2.5-flash"
        end

        # Execute an LLM query
        # @param prompt [String] the prompt to send
        # @param model [String] the model to use
        # @return [Hash] result with success, response, and error keys
        def execute(prompt:, model: nil)
          model ||= @default_model

          # Check if ace-llm is available
          unless command_exists?("ace-llm")
            return {
              success: false,
              response: nil,
              error: "ace-llm not found. Please install ace-llm gem or use --dry-run"
            }
          end

          # Execute via ace-llm
          result = execute_ace_llm(prompt, model)

          if result[:success]
            {
              success: true,
              response: result[:output],
              error: nil
            }
          else
            {
              success: false,
              response: nil,
              error: result[:error] || "LLM execution failed"
            }
          end
        end

        private

        def command_exists?(command)
          system("which #{command} > /dev/null 2>&1")
        end

        def execute_ace_llm(prompt, model)
          # Write prompt to temp file
          require "tempfile"
          temp_file = Tempfile.new(["review-prompt", ".md"])
          temp_file.write(prompt)
          temp_file.close

          begin
            # Execute ace-llm
            cmd = [
              "ace-llm",
              "query",
              "--model", model,
              "--file", temp_file.path
            ]

            stdout, stderr, status = Open3.capture3(*cmd)

            {
              success: status.success?,
              output: stdout,
              error: stderr
            }
          ensure
            temp_file.unlink
          end
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/preset_manager.rb
----------------------------------------
# frozen_string_literal: true

require "yaml"
require "pathname"

module Ace
  module Review
    module Molecules
      # Manages loading and resolving review presets from configuration
      class PresetManager
        DEFAULT_CONFIG_PATHS = [
          ".ace/review/code.yml",
          ".ace/review.yml", # Fallback
          ".coding-agent/code-review.yml" # Legacy support
        ].freeze

        attr_reader :config_path, :config, :project_root

        def initialize(config_path: nil, project_root: nil)
          @project_root = project_root || find_project_root
          @config_path = resolve_config_path(config_path)
          @config = load_configuration
          @preset_cache = {}
        end

        # Load a specific preset by name
        def load_preset(preset_name)
          return nil unless preset_name

          # Check cache first
          return @preset_cache[preset_name] if @preset_cache.key?(preset_name)

          # Try preset files first
          preset = load_preset_from_file(preset_name) || load_preset_from_config(preset_name)
          return nil unless preset

          # Merge with defaults and cache
          @preset_cache[preset_name] = merge_with_defaults(preset)
        end

        # Get list of available preset names
        def available_presets
          presets = []

          # Add presets from main config
          presets.concat(config_presets) if config

          # Add presets from preset directory
          presets.concat(file_presets)

          # Add default presets if no config exists
          presets.concat(Ace::Review.default_presets.keys) if presets.empty?

          presets.uniq.sort
        end

        # Check if a preset exists
        def preset_exists?(preset_name)
          available_presets.include?(preset_name.to_s)
        end

        # Get the default model from configuration
        def default_model
          config&.dig("defaults", "model") ||
            Ace::Review.get("defaults", "model")
        end

        # Get the default context from configuration
        def default_context
          config&.dig("defaults", "context") ||
            Ace::Review.get("defaults", "context")
        end

        # Get the default output format
        def default_output_format
          config&.dig("defaults", "output_format") ||
            Ace::Review.get("defaults", "output_format") ||
            "markdown"
        end

        # Resolve a preset configuration into actionable components
        def resolve_preset(preset_name, overrides = {})
          preset = load_preset(preset_name)
          return nil unless preset

          {
            description: preset["description"],
            prompt_composition: resolve_prompt_composition(preset["prompt_composition"], overrides),
            context: resolve_context_config(preset["context"], overrides[:context]),
            subject: resolve_subject_config(preset["subject"], overrides[:subject]),
            model: overrides[:model] || preset["model"] || default_model,
            output_format: overrides[:output_format] || preset["output_format"] || default_output_format
          }
        end

        # Get storage configuration
        def storage_config
          config&.dig("storage") || Ace::Review.get("storage") || {}
        end

        # Get the base path for storing reviews
        def review_base_path
          path_template = storage_config["base_path"] || ".ace-taskflow/%{release}/reviews"

          # Replace placeholders
          path_template.gsub("%{release}", current_release)
        end

        private

        def find_project_root
          # Try ace-core first
          if defined?(Ace::Core)
            require "ace/core"
            discovery = Ace::Core::ConfigDiscovery.new
            return discovery.project_root if discovery.project_root
          end

          # Fallback to current directory
          Dir.pwd
        end

        def resolve_config_path(custom_path)
          if custom_path
            path = Pathname.new(custom_path)
            return path.absolute? ? custom_path : File.join(project_root, custom_path)
          end

          # Try each default path
          DEFAULT_CONFIG_PATHS.each do |default_path|
            full_path = File.join(project_root, default_path)
            return full_path if File.exist?(full_path)
          end

          nil
        end

        def load_configuration
          return {} unless config_path && File.exist?(config_path)

          content = File.read(config_path)
          YAML.safe_load(content, permitted_classes: [Symbol]) || {}
        rescue StandardError => e
          warn "Failed to load configuration from #{config_path}: #{e.message}" if Ace::Review.debug?
          {}
        end

        def load_preset_from_file(preset_name)
          preset_dir = File.join(project_root, ".ace/review/presets")
          preset_file = File.join(preset_dir, "#{preset_name}.yml")

          return nil unless File.exist?(preset_file)

          content = File.read(preset_file)
          YAML.safe_load(content, permitted_classes: [Symbol])
        rescue StandardError => e
          warn "Failed to load preset from #{preset_file}: #{e.message}" if Ace::Review.debug?
          nil
        end

        def load_preset_from_config(preset_name)
          return nil unless config && config["presets"]
          config["presets"][preset_name.to_s]
        end

        def config_presets
          config["presets"]&.keys || []
        end

        def file_presets
          preset_dir = File.join(project_root, ".ace/review/presets")
          return [] unless Dir.exist?(preset_dir)

          Dir.glob("#{preset_dir}/*.yml").map do |file|
            File.basename(file, ".yml")
          end
        end

        def merge_with_defaults(preset)
          defaults = config&.dig("defaults") || {}
          deep_merge(defaults, preset)
        end

        def deep_merge(base, override)
          return override unless base.is_a?(Hash) && override.is_a?(Hash)

          base.merge(override) do |_key, base_val, override_val|
            deep_merge(base_val, override_val)
          end
        end

        def resolve_prompt_composition(composition, overrides)
          return {} unless composition

          result = composition.dup

          # Apply overrides
          result["base"] = overrides[:prompt_base] if overrides[:prompt_base]
          result["format"] = overrides[:prompt_format] if overrides[:prompt_format]

          if overrides[:prompt_focus]
            result["focus"] = overrides[:prompt_focus].split(",").map(&:strip)
          elsif overrides[:add_focus]
            result["focus"] ||= []
            result["focus"].concat(overrides[:add_focus].split(",").map(&:strip))
            result["focus"].uniq!
          end

          if overrides[:prompt_guidelines]
            result["guidelines"] = overrides[:prompt_guidelines].split(",").map(&:strip)
          end

          result
        end

        def resolve_context_config(preset_context, override_context)
          return override_context if override_context
          preset_context || default_context
        end

        def resolve_subject_config(preset_subject, override_subject)
          return override_subject if override_subject
          preset_subject
        end

        def current_release
          # Try to get current release from ace-taskflow
          if system("which ace-taskflow > /dev/null 2>&1")
            release = `ace-taskflow release --current 2>/dev/null`.strip
            return release unless release.empty?
          end

          # Fallback to v.0.0.0
          "v.0.0.0"
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/prompt_composer.rb
----------------------------------------
# frozen_string_literal: true

module Ace
  module Review
    module Molecules
      # Composes final prompt from modular components
      class PromptComposer
        attr_reader :resolver

        def initialize(resolver: nil)
          @resolver = resolver || PromptResolver.new
        end

        # Compose a full prompt from composition configuration
        # @param composition [Hash] prompt composition with base, format, focus, guidelines
        # @param config_dir [String] directory for relative path resolution
        # @return [String] composed prompt
        def compose(composition, config_dir: nil)
          return "" unless composition

          sections = []

          # Add base prompt (required)
          if composition["base"]
            base_content = resolver.resolve(composition["base"], config_dir: config_dir)
            sections << base_content if base_content
          end

          # Add format section
          if composition["format"]
            format_content = resolver.resolve(composition["format"], config_dir: config_dir)
            sections << wrap_section("Output Format", format_content) if format_content
          end

          # Add focus modules (can be multiple)
          if composition["focus"] && !composition["focus"].empty?
            focus_contents = composition["focus"].map do |focus_ref|
              resolver.resolve(focus_ref, config_dir: config_dir)
            end.compact

            unless focus_contents.empty?
              combined_focus = focus_contents.join("\n\n---\n\n")
              sections << wrap_section("Review Focus", combined_focus)
            end
          end

          # Add guidelines
          if composition["guidelines"] && !composition["guidelines"].empty?
            guideline_contents = composition["guidelines"].map do |guideline_ref|
              resolver.resolve(guideline_ref, config_dir: config_dir)
            end.compact

            unless guideline_contents.empty?
              combined_guidelines = guideline_contents.join("\n\n")
              sections << wrap_section("Guidelines", combined_guidelines)
            end
          end

          sections.join("\n\n")
        end

        # Build a complete review prompt with context and subject
        def build_review_prompt(composition, context, subject, config_dir: nil)
          prompt_parts = []

          # Add composed system prompt
          system_prompt = compose(composition, config_dir: config_dir)
          prompt_parts << system_prompt if system_prompt && !system_prompt.empty?

          # Add context section
          if context && !context.empty?
            prompt_parts << wrap_section("Project Context", context)
          end

          # Add subject section
          if subject && !subject.empty?
            prompt_parts << wrap_section("Code to Review", subject)
          end

          # Add review request
          prompt_parts << generate_review_request(composition)

          prompt_parts.join("\n\n")
        end

        private

        def wrap_section(title, content)
          return "" unless content && !content.strip.empty?

          <<~SECTION
            ## #{title}

            #{content}
          SECTION
        end

        def generate_review_request(composition)
          focus_areas = if composition["focus"] && !composition["focus"].empty?
                          "\n\nPay special attention to the focus areas specified above."
                        else
                          ""
                        end

          <<~REQUEST
            ## Review Request

            Please review the provided code according to the guidelines and format specified above.#{focus_areas}

            Provide actionable feedback with specific suggestions for improvement. Reference line numbers or file locations where applicable.
          REQUEST
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/prompt_resolver.rb
----------------------------------------
# frozen_string_literal: true

require "pathname"

module Ace
  module Review
    module Molecules
      # Resolves prompt:// URIs and file paths with cascade lookup
      class PromptResolver
        PROTOCOL_PREFIX = "prompt://"

        attr_reader :project_root

        def initialize(project_root: nil)
          @project_root = project_root || find_project_root
          @cache = {}
        end

        # Resolve a prompt reference to actual content
        # Supports:
        # - prompt://category/path - cascade lookup
        # - prompt://project/path - project only
        # - prompt://gem/path - gem built-in only
        # - ./file.md - relative to config file directory
        # - file.md - relative to project root
        def resolve(reference, config_dir: nil)
          return nil unless reference

          # Check cache
          cache_key = "#{reference}:#{config_dir}"
          return @cache[cache_key] if @cache.key?(cache_key)

          content = if reference.start_with?(PROTOCOL_PREFIX)
                      resolve_protocol_uri(reference)
                    else
                      resolve_file_path(reference, config_dir)
                    end

          @cache[cache_key] = content
          content
        end

        # List available prompt modules in a category
        def list_available(category = nil)
          prompts = {}

          # Collect from all locations
          locations = [
            { path: project_prompt_dir, label: "project" },
            { path: user_prompt_dir, label: "user" },
            { path: gem_prompt_dir, label: "built-in" }
          ]

          locations.each do |location|
            next unless location[:path] && Dir.exist?(location[:path])

            if category
              category_dir = File.join(location[:path], category)
              next unless Dir.exist?(category_dir)

              prompts[category] ||= {}
              collect_prompts_from_dir(category_dir, prompts[category], location[:label])
            else
              Dir.glob("#{location[:path]}/*").select { |f| File.directory?(f) }.each do |cat_dir|
                cat_name = File.basename(cat_dir)
                prompts[cat_name] ||= {}
                collect_prompts_from_dir(cat_dir, prompts[cat_name], location[:label])
              end
            end
          end

          prompts
        end

        private

        def find_project_root
          if defined?(Ace::Core)
            require "ace/core"
            discovery = Ace::Core::ConfigDiscovery.new
            return discovery.project_root if discovery.project_root
          end
          Dir.pwd
        end

        def resolve_protocol_uri(uri)
          path = uri.sub(PROTOCOL_PREFIX, "")

          # Handle forced location prefixes
          if path.start_with?("project/")
            prompt_path = path.sub("project/", "")
            return read_prompt_file(File.join(project_prompt_dir, "#{prompt_path}.md"))
          elsif path.start_with?("user/")
            prompt_path = path.sub("user/", "")
            return read_prompt_file(File.join(user_prompt_dir, "#{prompt_path}.md"))
          elsif path.start_with?("gem/")
            prompt_path = path.sub("gem/", "")
            return read_prompt_file(File.join(gem_prompt_dir, "#{prompt_path}.md"))
          end

          # Default cascade: project → user → gem
          cascade_paths = [
            File.join(project_prompt_dir, "#{path}.md"),
            File.join(user_prompt_dir, "#{path}.md"),
            File.join(gem_prompt_dir, "#{path}.md")
          ].compact

          cascade_paths.each do |prompt_path|
            content = read_prompt_file(prompt_path)
            return content if content
          end

          nil
        end

        def resolve_file_path(path, config_dir)
          # Handle relative paths starting with ./
          if path.start_with?("./")
            base_dir = config_dir || project_root
            full_path = File.expand_path(path, base_dir)
            return read_prompt_file(full_path)
          end

          # Treat as relative to project root
          full_path = File.join(project_root, path)
          read_prompt_file(full_path)
        end

        def read_prompt_file(path)
          return nil unless path && File.exist?(path)

          File.read(path).strip
        rescue StandardError => e
          warn "Failed to read prompt file #{path}: #{e.message}" if Ace::Review.debug?
          nil
        end

        def project_prompt_dir
          @project_prompt_dir ||= File.join(project_root, ".ace/review/prompts")
        end

        def user_prompt_dir
          @user_prompt_dir ||= File.expand_path("~/.ace/review/prompts")
        end

        def gem_prompt_dir
          @gem_prompt_dir ||= File.expand_path("../../../../handbook/prompts", __dir__)
        end

        def collect_prompts_from_dir(dir, collection, label)
          Dir.glob("#{dir}/**/*.md").each do |file|
            rel_path = file.sub("#{dir}/", "").sub(/\.md$/, "")

            # Handle nested directories
            parts = rel_path.split("/")
            if parts.length > 1
              # Nested prompt (e.g., architecture/atom)
              category = parts[0]
              name = parts[1..-1].join("/")
              collection[category] ||= []
              collection[category] << { name: name, source: label }
            else
              # Top-level prompt
              collection[rel_path] = label
            end
          end
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/subject_extractor.rb
----------------------------------------
# frozen_string_literal: true

require "yaml"
require "open3"

module Ace
  module Review
    module Molecules
      # Extracts review subject (code to review) from various sources
      class SubjectExtractor
        def initialize
          @git = Atoms::GitExtractor
          @file_reader = Atoms::FileReader
        end

        # Extract subject from configuration
        # @param subject_config [String, Hash] subject configuration
        # @return [String] extracted subject content
        def extract(subject_config)
          return "" unless subject_config

          case subject_config
          when String
            extract_from_string(subject_config)
          when Hash
            extract_from_hash(subject_config)
          else
            ""
          end
        end

        private

        def extract_from_string(input)
          # Try to parse as YAML first
          parsed = YAML.safe_load(input)
          return extract_from_hash(parsed) if parsed.is_a?(Hash)

          # Check if it's a git range
          if looks_like_git_range?(input)
            return extract_git_diff(input)
          end

          # Check if it's a file pattern
          if input.include?("*") || input.include?("/")
            return extract_files(input)
          end

          # Check for special keywords
          case input.downcase
          when "staged"
            @git.staged_diff[:output] || ""
          when "working", "unstaged"
            @git.working_diff[:output] || ""
          when "pr", "pull-request"
            extract_pr_diff
          else
            # Default to git diff
            extract_git_diff(input)
          end
        rescue Psych::SyntaxError
          # If YAML parsing fails, treat as git range
          extract_git_diff(input)
        end

        def extract_from_hash(config)
          parts = []

          # Execute commands
          if config["commands"]
            config["commands"].each do |command|
              result = execute_command(command)
              parts << format_command_output(command, result) if result[:success]
            end
          end

          # Read files
          if config["files"]
            files = config["files"]
            files = [files] unless files.is_a?(Array)

            files.each do |file_pattern|
              content = extract_files(file_pattern)
              parts << content unless content.empty?
            end
          end

          # Git diff
          if config["diff"]
            diff_output = extract_git_diff(config["diff"])
            parts << diff_output unless diff_output.empty?
          end

          parts.join("\n\n" + "=" * 80 + "\n\n")
        end

        def extract_git_diff(range)
          result = @git.git_diff(range)
          return "" unless result[:success]

          <<~OUTPUT
            Git Diff: #{range}
            #{"-" * 40}
            #{result[:output]}
          OUTPUT
        end

        def extract_files(pattern)
          results = @file_reader.read_pattern(pattern)
          return "" if results.empty?

          output = []
          results.each do |path, result|
            next unless result[:success]

            output << <<~FILE
              File: #{path}
              #{"-" * 40}
              #{result[:content]}
            FILE
          end

          output.join("\n\n")
        end

        def extract_pr_diff
          # Try to get diff against tracking branch
          tracking = @git.tracking_branch
          return extract_git_diff("#{tracking}...HEAD") if tracking

          # Fall back to origin/main
          extract_git_diff("origin/main...HEAD")
        end

        def execute_command(command)
          stdout, stderr, status = Open3.capture3(command)

          {
            success: status.success?,
            output: stdout,
            error: stderr
          }
        rescue StandardError => e
          {
            success: false,
            output: "",
            error: e.message
          }
        end

        def format_command_output(command, result)
          <<~OUTPUT
            Command: #{command}
            #{"-" * 40}
            #{result[:output]}
          OUTPUT
        end

        def looks_like_git_range?(input)
          input.include?("..") ||
            input.include?("HEAD") ||
            input.include?("~") ||
            input.include?("^") ||
            input.match?(/^[a-f0-9]{6,40}/)
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/organisms/review_manager.rb
----------------------------------------
# frozen_string_literal: true

require "fileutils"
require "time"

module Ace
  module Review
    module Organisms
      # Main orchestrator for code review workflow
      class ReviewManager
        attr_reader :preset_manager, :prompt_resolver, :prompt_composer,
                    :subject_extractor, :context_extractor

        def initialize
          @preset_manager = Ace::Review::Molecules::PresetManager.new
          @prompt_resolver = Ace::Review::Molecules::PromptResolver.new
          @prompt_composer = Ace::Review::Molecules::PromptComposer.new(resolver: @prompt_resolver)
          @subject_extractor = Ace::Review::Molecules::SubjectExtractor.new
          @context_extractor = Ace::Review::Molecules::ContextExtractor.new
        end

        # Execute a code review with the given options
        # @param options [Hash] review options
        # @return [Hash] review results
        def execute_review(options)
          # Resolve preset if specified
          preset_config = resolve_preset(options)
          return preset_config unless preset_config[:success]

          config = preset_config[:config]

          # Extract subject (what to review)
          subject = extract_subject(config[:subject] || options[:subject])
          return { success: false, error: "No code to review" } if subject.empty?

          # Extract context (background info)
          context = extract_context(config[:context] || options[:context])

          # Build complete prompt
          prompt = build_prompt(config, context, subject)

          # Prepare review data
          review_data = {
            preset: options[:preset],
            config: config,
            subject: subject,
            context: context,
            prompt: prompt,
            model: config[:model]
          }

          # Execute with LLM if requested
          if options[:auto_execute]
            execute_with_llm(review_data, options)
          else
            prepare_session(review_data, options)
          end
        end

        # List available presets
        def list_presets
          @preset_manager.available_presets
        end

        # List available prompt modules
        def list_prompts
          @prompt_resolver.list_available
        end

        private

        def resolve_preset(options)
          preset_name = options[:preset] || "pr"

          unless @preset_manager.preset_exists?(preset_name)
            available = @preset_manager.available_presets.join(", ")
            return {
              success: false,
              error: "Preset '#{preset_name}' not found. Available: #{available}"
            }
          end

          config = @preset_manager.resolve_preset(preset_name, options)
          { success: true, config: config }
        end

        def extract_subject(subject_config)
          return "" unless subject_config
          @subject_extractor.extract(subject_config)
        end

        def extract_context(context_config)
          @context_extractor.extract(context_config)
        end

        def build_prompt(config, context, subject)
          @prompt_composer.build_review_prompt(
            config[:prompt_composition],
            context,
            subject,
            config_dir: File.dirname(@preset_manager.config_path || ".")
          )
        end

        def execute_with_llm(review_data, options)
          executor = Ace::Review::Molecules::LlmExecutor.new

          result = executor.execute(
            prompt: review_data[:prompt],
            model: review_data[:model]
          )

          if result[:success]
            save_review(result[:response], review_data, options)
          else
            result
          end
        end

        def prepare_session(review_data, options)
          session_dir = create_session_directory(options)

          # Save prompt
          prompt_file = File.join(session_dir, "prompt.md")
          File.write(prompt_file, review_data[:prompt])

          # Save subject
          subject_file = File.join(session_dir, "subject.md")
          File.write(subject_file, review_data[:subject])

          # Save context if present
          unless review_data[:context].empty?
            context_file = File.join(session_dir, "context.md")
            File.write(context_file, review_data[:context])
          end

          # Save metadata
          metadata_file = File.join(session_dir, "metadata.yml")
          File.write(metadata_file, YAML.dump(create_metadata(review_data)))

          {
            success: true,
            session_dir: session_dir,
            prompt_file: prompt_file,
            message: "Review session prepared in #{session_dir}"
          }
        end

        def save_review(response, review_data, options)
          output_file = determine_output_file(options)
          ensure_output_directory(output_file)

          # Add metadata header to response
          full_content = add_review_metadata(response, review_data)

          File.write(output_file, full_content)

          {
            success: true,
            output_file: output_file,
            message: "Review saved to #{output_file}"
          }
        end

        def create_session_directory(options)
          if options[:session_dir]
            FileUtils.mkdir_p(options[:session_dir])
            return options[:session_dir]
          end

          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          session_dir = File.join(
            Dir.pwd,
            ".ace-review-sessions",
            "review-#{timestamp}"
          )
          FileUtils.mkdir_p(session_dir)
          session_dir
        end

        def determine_output_file(options)
          if options[:output]
            return options[:output]
          end

          # Use storage config
          base_path = @preset_manager.review_base_path
          FileUtils.mkdir_p(base_path)

          timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
          File.join(base_path, "review-#{timestamp}.md")
        end

        def ensure_output_directory(file_path)
          dir = File.dirname(file_path)
          FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        end

        def create_metadata(review_data)
          {
            "timestamp" => Time.now.iso8601,
            "preset" => review_data[:preset],
            "model" => review_data[:model],
            "has_context" => !review_data[:context].empty?,
            "subject_size" => review_data[:subject].length,
            "prompt_size" => review_data[:prompt].length
          }
        end

        def add_review_metadata(response, review_data)
          metadata = <<~METADATA
            ---
            timestamp: #{Time.now.iso8601}
            preset: #{review_data[:preset]}
            model: #{review_data[:model]}
            ---

          METADATA

          metadata + response
        end
      end
    end
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/version.rb
----------------------------------------
# frozen_string_literal: true

module Ace
  module Review
    VERSION = "0.9.1"
  end
end


File: /Users/mc/Ps/ace-meta/ace-review/lib/ace/review.rb
----------------------------------------
# frozen_string_literal: true

# Try to load ace-core if available
begin
  require "ace/core"
rescue LoadError
  # ace-core is optional for basic functionality
end

require_relative "review/version"

# Require all necessary components explicitly
require_relative "review/atoms/file_reader"
require_relative "review/atoms/git_extractor"

require_relative "review/molecules/context_extractor"
require_relative "review/molecules/llm_executor"
require_relative "review/molecules/preset_manager"
require_relative "review/molecules/prompt_composer"
require_relative "review/molecules/prompt_resolver"
require_relative "review/molecules/subject_extractor"

require_relative "review/organisms/review_manager"

require_relative "review/cli"

module Ace
  module Review
    class Error < StandardError; end

    # Define module namespaces
    module Atoms; end
    module Molecules; end
    module Organisms; end
    module Models; end

    class << self
      # Configuration accessor
      def config
        @config ||= begin
          base_config = Ace::Core.config
          base_config.get("ace", "review") || default_config
        rescue StandardError
          default_config
        end
      end

      # Default configuration
      def default_config
        {
          "defaults" => {
            "model" => "google:gemini-2.5-flash",
            "output_format" => "markdown",
            "context" => "project"
          },
          "storage" => {
            "base_path" => ".ace-taskflow/%{release}/reviews",
            "auto_organize" => true
          },
          "presets" => default_presets
        }
      end

      # Default presets if no configuration file exists
      def default_presets
        {
          "pr" => {
            "description" => "Pull request review",
            "prompt_composition" => {
              "base" => "prompt://base/system",
              "format" => "prompt://format/standard",
              "guidelines" => [
                "prompt://guidelines/tone",
                "prompt://guidelines/icons"
              ]
            },
            "context" => "project",
            "subject" => {
              "commands" => [
                "git diff origin/main...HEAD",
                "git log origin/main..HEAD --oneline"
              ]
            }
          },
          "security" => {
            "description" => "Security-focused review",
            "prompt_composition" => {
              "base" => "prompt://base/system",
              "format" => "prompt://format/detailed",
              "focus" => ["prompt://focus/quality/security"],
              "guidelines" => [
                "prompt://guidelines/tone",
                "prompt://guidelines/icons"
              ]
            },
            "context" => "project",
            "subject" => {
              "commands" => ["git diff HEAD~5..HEAD"]
            }
          }
        }
      end

      # Get configuration value with dot notation
      def get(*keys)
        keys.reduce(config) do |hash, key|
          hash.is_a?(Hash) ? hash[key.to_s] : nil
        end
      end

      # Check if running in debug mode
      def debug?
        ENV["ACE_DEBUG"] == "true" || ENV["DEBUG"] == "true"
      end
    end
  end
end



## Review Request

Please review the provided code according to the guidelines and format specified above.

Pay special attention to the focus areas specified above.

Provide actionable feedback with specific suggestions for improvement. Reference line numbers or file locations where applicable.
