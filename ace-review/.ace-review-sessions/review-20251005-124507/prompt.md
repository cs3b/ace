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



## Review Request

Please review the provided code according to the guidelines and format specified above.

Pay special attention to the focus areas specified above.

Provide actionable feedback with specific suggestions for improvement. Reference line numbers or file locations where applicable.
