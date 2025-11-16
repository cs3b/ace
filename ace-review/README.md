# ace-review

Automated review tool for the ACE framework. Provides preset-based analysis using LLM-powered insights with configurable focus areas and flexible prompt composition.

**Version:** 0.16.1

## What's New in 0.16.1

- **Git Worktree Support**: ace-review now works seamlessly in git worktrees created by ace-git-worktree (v0.16.1+)
  - Cache directories are created at the correct project root location
  - Each worktree maintains its own review cache
  - No configuration needed - it just works!

## What's New in 0.16.0

- **Preset Composition**: Support for composing review presets from reusable base configurations
  - Use `presets:` array to build DRY review configurations
  - Recursive loading with circular dependency detection
  - Smart merging strategies for arrays, hashes, and scalars
  - See [CHANGELOG.md](CHANGELOG.md) for full details

## What's New in 0.15.0

- **Section-Based Presets**: A new `instructions` format in presets allows for structured, section-based content organization for more powerful and readable reviews. See examples below.
- **Enhanced ace-context Integration**: Deeper integration with `ace-context` for processing structured review content.
- **Backward Compatibility**: The legacy `prompt_composition` format continues to work alongside the new `instructions` format.
- For full details, see the [CHANGELOG.md](CHANGELOG.md).

## Changes in 0.9.8

- **Workflow Documentation Updated**: Updated `review.wf.md` for ace-context v0.9.6+ integration
  - Added comprehensive configuration schema section documenting unified YAML keys
  - Enhanced examples showing `files:`, `diffs:`, `commands:`, and `presets:` usage
  - Improved troubleshooting guidance for common configuration issues
  - All command examples now use correct ace-context schema

## Changes in 0.9.7

- **ace-llm-query Integration Fixed**: Updated to work with ace-llm-query v0.9.1+ API
  - Fixed command construction with proper `--prompt` flag (replaces non-existent `--file`)
  - Added PROVIDER:MODEL positional argument as first parameter
  - Review reports now saved directly to session directory via `--output` flag
  - Added 10-minute timeout (`--timeout 600`) for long reviews
  - Consistent markdown output via `--format markdown`
  - Output filename pattern: `review-report-{model-short}.md` (e.g., `review-report-gemini-2.5-flash.md`)
- **API Updates**: LlmExecutor now requires `session_dir:` parameter and returns `output_file` path

## Changes in 0.9.6

- **ace-context Integration**: Refactored to use ace-context for unified content aggregation
  - SubjectExtractor and ContextExtractor now delegate to ace-context
  - Eliminated duplicated file/command/git extraction logic
  - Enabled `presets:` support in context configuration
  - Added support for `diffs:` key in subject/context configs
- **Simplified Architecture**: Removed redundant atoms (git_extractor, file_reader)
- **Enhanced Composition**: Can now combine files + commands + diffs + presets in unified configs

## Features

- **ace-nav integration** - Universal prompt resolution with user overrides via ace-nav protocol
- **Preset-based reviews** - Predefined configurations for common scenarios (PR, security, docs, etc.)
- **Flexible prompt composition** - Modular prompts with base, format, focus, and guidelines
- **Prompt cascade** - Override built-in prompts at project or user level through ace-nav
- **Multiple focus modules** - Combine architecture, language, and quality focuses
- **Release integration** - Stores reviews in `.ace-taskflow/<release>/reviews/`
- **LLM provider support** - Works with any provider supported by ace-llm
- **Custom presets** - Create team-specific review configurations
- **Secure command execution** - Protected against command injection vulnerabilities

## Installation

Add this gem to your Gemfile:

```ruby
gem 'ace-review'
```

Or install it directly:

```bash
gem install ace-review
```

### Dependencies

- `ace-core` (~> 0.9) - Core ACE framework utilities
- `ace-context` (~> 0.9) - Unified content aggregation and context loading
- `ace-nav` (~> 0.9) - Universal resource navigation and prompt resolution

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

## Subject and Context Configuration

Since v0.9.6, ace-review uses ace-context for unified content aggregation. Both `--subject` and `--context` accept YAML configuration with these keys:

```yaml
# ✅ CORRECT: Use these keys (both diff: and diffs: work identically)
files: ["lib/**/*.rb", "docs/*.md"]      # File paths and glob patterns
diff: {ranges: ["origin/main...HEAD"]}   # Git diff via ace-git-diff
commands: ["git log --oneline -5"]       # Shell commands to execute
presets: [project, architecture]         # ace-context preset names
```

### Examples

```bash
# Review specific files
ace-review --subject 'files: ["lib/ace/review/**/*.rb"]' --auto-execute

# Review git diff range
ace-review --subject 'diff: {ranges: ["origin/main...HEAD"]}' --auto-execute

# Review with context from presets
ace-review \
  --subject 'diff: {ranges: ["HEAD~5..HEAD"]}' \
  --context 'presets: [project]' \
  --auto-execute

# Compose multiple sources
ace-review \
  --subject 'files: ["new-feature/**/*.rb"], diff: {ranges: ["HEAD~3..HEAD"]}' \
  --context 'presets: [project], files: ["docs/architecture.md"]' \
  --auto-execute
```

### Simple Shortcuts

For `--subject`, you can use simple string shortcuts:
- `staged` → staged changes
- `working` → unstaged changes
- `pr` → changes vs tracking branch
- `HEAD~1..HEAD` → git range (auto-detected)
- `lib/**/*.rb` → file pattern (auto-detected)

## Configuration

### Main Configuration

Create `.ace/review/config.yml` in your project:

```yaml
defaults:
  model: "google:gemini-2.5-flash"
  output_format: "markdown"
  context: "project"

storage:
  base_path: ".ace-taskflow/%{release}/reviews"
  auto_organize: true

# Review presets - load from .ace/review/presets/*.yml
# Individual preset files provide better organization and shareability
```

### Custom Presets

Create preset files in `.ace/review/presets/`:

#### New Section-Based Format (Recommended)

```yaml
# .ace/review/presets/team-review.yml
description: "Team-specific review criteria"

# New instructions format with section-based organization
instructions:
  base: "prompt://base/system"
  context:
    sections:
      review_focus:
        title: "Review Focus Areas"
        description: "Architecture and code quality focus"
        files:
          - "prompt://focus/architecture/atom"
          - "prompt://focus/languages/ruby"
          - "prompt://project/focus/team/standards"  # Custom team focus

      format_guidelines:
        title: "Format Guidelines"
        description: "Output formatting and structure"
        files:
          - "prompt://format/detailed"

      communication_guidelines:
        title: "Communication Style"
        description: "Review communication guidelines"
        files:
          - "prompt://guidelines/tone"
          - "prompt://guidelines/icons"

      team_context:
        title: "Team Context"
        description: "Team-specific background information"
        files:
          - "docs/team-guidelines.md"
        presets:
          - "project"

# Context: additional background information
context: "project"

# Subject: what to review
subject:
  diff: {ranges: ["HEAD~1..HEAD"]}        # Recent changes
  files: ["lib/**/*.rb"]                  # Ruby files
```

#### Legacy Format (Backward Compatible)

```yaml
# .ace/review/presets/legacy-review.yml
description: "Legacy format preset"

prompt_composition:
  base: "prompt://base/system"
  format: "prompt://format/detailed"
  focus:
    - "prompt://focus/architecture/atom"
    - "prompt://focus/languages/ruby"
  guidelines:
    - "prompt://guidelines/tone"

# Context: background information for the review
context:
  presets: [project]                      # Load project preset
  files: ["docs/team-guidelines.md"]      # Team-specific docs

# Subject: what to review
subject:
  diff: {ranges: ["HEAD~1..HEAD"]}        # Recent changes
  files: ["lib/**/*.rb"]                  # Ruby files
```

**Note**: The new `instructions` format provides section-based organization that ace-context processes into structured XML-tagged output. The legacy `prompt_composition` format continues to work for backward compatibility.

### Preset Composition (DRY Configuration)

Create reusable base presets and compose specialized presets from them, reducing duplication and improving maintainability.

#### Basic Composition

Use the `presets:` array at the root level to compose from other presets:

```yaml
# .ace/review/presets/code.yml - Base preset
description: "Base code review configuration"
instructions:
  context:
    base: "prompt://base/system"
    sections:
      review_focus:
        files:
          - "prompt://focus/languages/ruby"
          - "prompt://focus/architecture/atom"
model: gpro
```

```yaml
# .ace/review/presets/code-pr.yml - Specialized for PRs
presets:
  - code                    # Inherit from base preset

description: "Pull request review"
subject:
  context:
    sections:
      code_changes:
        diffs:
          - "origin...HEAD"
```

#### Composition Rules

- **Merge Strategy**: Base presets loaded first, then composing preset (last wins for scalars)
- **Arrays**: Concatenated and deduplicated (first occurrence wins)
- **Hashes**: Deep merged recursively
- **Scalars**: Last value wins (override behavior)

#### Multi-Level Composition

Compose from multiple presets or create nested composition chains:

```yaml
# .ace/review/presets/code-security.yml
presets:
  - code
  - security-base

description: "Security-focused code review"
# Merges instructions from both base presets
```

#### Performance Features

- **Intermediate Caching**: Shared base presets composed once and cached
- **Circular Detection**: Prevents infinite loops with MAX_DEPTH=10 limit
- **Debug Mode**: Enable `ACE_REVIEW_DEBUG=1` to see composition metrics

```bash
# View composition performance
ACE_REVIEW_DEBUG=1 ace-review --preset complex-nested

# Example output:
# [COMPOSITION] Composed 'base' in 1.23ms (depth: 1, refs: 0)
# [COMPOSITION] Composed 'code-pr' in 2.45ms (depth: 2, refs: 1)
```

#### Migration Example

**Before** (duplicated configuration):

```yaml
# pr.yml - 150 lines
description: "PR review"
instructions:
  context:
    # ... many lines ...
subject:
  diffs: ["origin...HEAD"]

# wip.yml - 145 lines (95% duplicate)
description: "WIP review"
instructions:
  context:
    # ... same lines ...
subject:
  commands: ["git diff HEAD"]
```

**After** (DRY with composition):

```yaml
# code.yml - 40 lines (shared base)
description: "Base code review"
instructions:
  context:
    # ... shared configuration ...

# code-pr.yml - 10 lines
presets: [code]
description: "PR review"
subject:
  diffs: ["origin...HEAD"]

# code-wip.yml - 10 lines
presets: [code]
description: "WIP review"
subject:
  commands: ["git diff HEAD"]
```

#### Error Handling

Composition failures are handled gracefully:

- **Missing Preset**: Clear error with available preset list
- **Circular Reference**: Shows dependency chain (e.g., `a -> b -> a`)
- **Max Depth**: Prevents deeply nested chains (limit: 10 levels)

#### Why Preset Composition Over YAML Anchors?

While YAML anchors (`&ref`, `*ref`) provide similar functionality, preset composition offers several advantages:

- **Cross-File Reuse**: Reference presets across different files (YAML anchors limited to single file)
- **Semantic Clarity**: Explicit `presets:` array shows intent and dependencies
- **Validation**: Built-in circular dependency detection and error handling
- **Caching**: Automatic performance optimization for shared base presets
- **Debugging**: Debug mode shows composition chain and timing metrics
- **Version Control**: Each preset file can be versioned independently

**YAML anchors are still useful** for repetition within a single preset file, while preset composition handles cross-file modularity.

## Prompt System

### Prompt Cascade

ace-review uses ace-nav for prompt resolution, enabling universal override capability:

1. **ace-nav resolution** (when available):
   - Project overrides: `./.ace/review/prompts/`
   - User overrides: `~/.ace/review/prompts/`
   - Gem built-in: `handbook/prompts/` within the gem

2. **Fallback resolution** (when ace-nav unavailable):
   - Direct file path resolution
   - Relative to configuration file or project root

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
- `--subject <config>` - What to review (YAML config, git range, keyword, or file pattern)
- `--context <config>` - Background information (YAML config or preset name)
- `--output-dir <path>` - Custom output directory
- `--output <file>` - Specific output file path
- `--model <model>` - Override LLM model
- `--auto-execute` - Execute LLM query automatically
- `--dry-run` - Prepare review without executing
- `--list-presets` - List available presets
- `--list-prompts` - List available prompt modules
- `--verbose` - Enable verbose output
- `--[no-]save-session` - Save session files (default: true)
- `--session-dir <dir>` - Custom session directory

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
   cp .coding-agent/code-review.yml .ace/review/config.yml
   ```

3. **Update workflow files**
   - Replace `code-review` with `ace-review`
   - Remove `code-review-synthesize` CLI usage

## Architecture

ace-review follows the ATOM architecture pattern:

- **Atoms**: Pure functions (git_extractor, file_reader)
  - Secure command execution with array-based parameter passing
- **Molecules**: Composed operations (preset_manager, prompt_composer, nav_prompt_resolver)
  - Integration with ace-nav for universal prompt resolution
- **Organisms**: Business orchestration (review_manager)
  - Decomposed into clear, testable steps
- **Models**: Data structures (review_options)
  - Clean parameter objects replacing hash options

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