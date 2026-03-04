# ace-review

Automated review tool for the ACE framework. Provides preset-based analysis using LLM-powered insights with configurable focus areas and flexible prompt composition.

**Version:** 0.23.0

## What's New in 0.23.0

- **PR Comment Developer Feedback**: Extract and include developer feedback from PR comments and inline review threads
  - New `--[no-]pr-comments` flag (default: true for `--pr` reviews)
  - Creates `review-dev-feedback.md` alongside LLM reviews
  - Integrates with multi-model synthesis for complete picture

## What's New in 0.22.0

- **Auto-Save Feature**: Automatically save reviews to task directories based on git branch name
  - Enable with `auto_save: true` in `.ace/review/config.yml`
  - Configurable branch patterns via `auto_save_branch_patterns`
  - Release directory fallback via `auto_save_release_fallback`
  - Disable per-command with `--no-auto-save` CLI flag

## What's New in 0.21.0

- **Multi-Model Report Synthesis**: Automatically synthesize reviews from multiple LLM models into a unified, actionable report
  - Standalone command: `ace-review synthesize --session <dir>`
  - Auto-triggered after multi-model execution with 2+ models
  - Identifies consensus findings, strong recommendations, unique insights, and conflicting views
  - Configurable synthesis model via `synthesis.model` config
  - Disable feedback extraction with `--no-feedback` flag

## What's New in 0.16.0

- **Preset Composition**: Support for composing review presets from reusable base configurations
  - Use `presets:` array to build DRY review configurations
  - Recursive loading with circular dependency detection
  - Smart merging strategies for arrays, hashes, and scalars
  - See [CHANGELOG.md](CHANGELOG.md) for full details

## What's New in 0.15.0

- **Section-Based Presets**: A new `instructions` format in presets allows for structured, section-based content organization for more powerful and readable reviews. See examples below.
- **Enhanced ace-bundle Integration**: Deeper integration with `ace-bundle` for processing structured review content.
- **Backward Compatibility**: The legacy `prompt_composition` format continues to work alongside the new `instructions` format.
- For full details, see the [CHANGELOG.md](CHANGELOG.md).

## Changes in 0.9.8

- **Workflow Documentation Updated**: Updated `review.wf.md` for ace-bundle integration
  - Added comprehensive configuration schema section documenting unified YAML keys
  - Enhanced examples showing `files:`, `diffs:`, `commands:`, and `presets:` usage
  - Improved troubleshooting guidance for common configuration issues
  - All command examples now use correct ace-bundle schema

## Changes in 0.9.7

- **ace-llm Integration Fixed**: Updated to work with ace-llm v0.9.1+ API (formerly ace-llm-query)
  - Fixed command construction with proper `--prompt` flag (replaces non-existent `--file`)
  - Added PROVIDER:MODEL positional argument as first parameter
  - Review reports now saved directly to session directory via `--output` flag
  - Added 10-minute timeout (`--timeout 600`) for long reviews
  - Consistent markdown output via `--format markdown`
  - Output filename pattern: `review-report-{model-short}.md` (e.g., `review-report-gemini-2.5-flash.md`)
- **API Updates**: LlmExecutor now requires `session_dir:` parameter and returns `output_file` path

## Changes in 0.9.6

- **ace-bundle Integration**: Refactored to use ace-bundle for unified content aggregation
  - SubjectExtractor and ContextExtractor now delegate to ace-bundle
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
- **Task integration** - Save review reports to task directories with `--task` flag
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
- `ace-bundle` (~> 0.29) - Unified content aggregation and context loading
- `ace-nav` (~> 0.9) - Universal resource navigation and prompt resolution

## Quick Start

```bash
# Review with default preset (code)
ace-review

# Security-focused review
ace-review --preset security

# Save review report to task directory
ace-review --preset code-pr --task 114

# Auto-execute with task integration
ace-review --preset security --task 114 --auto-execute

# List available presets
ace-review --list-presets

# List available prompt modules
ace-review --list-prompts

# Execute review with LLM automatically
ace-review --preset code-pr --auto-execute
```

## Multi-Model Reviews

Run code reviews against multiple LLM models simultaneously for diverse perspectives.

### CLI Usage

```bash
# Comma-separated models
ace-review --preset code-pr --model "gemini,gpt-4,claude" --auto-execute

# Multiple --model flags
ace-review --preset code-pr --model gemini --model gpt-4 --auto-execute

# Full provider:model format
ace-review --preset security --model "google:gemini-2.5-flash,openai:gpt-4" --auto-execute
```

### Preset Configuration

Configure multi-model in preset files:

```yaml
# .ace/review/presets/code-multi.yml
presets:
  - code

description: "Multi-model code review"

models:
  - claude:opus
  - codex:gpt-5.1-codex-max
  - gpro
```

### Reviewers Format

The `reviewers` format provides fine-grained control over individual reviewers in a multi-model review.

#### Reviewer Configuration

```yaml
# .ace/review/presets/my-preset.yml
reviewers:
  - name: "code-fit"
    model: "google:gemini-2.5-pro"
    focus: "code_quality"
    system_prompt_additions: "Focus on SOLID principles..."
    file_patterns:
      include: ["lib/**/*.rb"]
      exclude: ["**/*_test.rb"]
    weight: 1.0
    critical: false

  - name: "security"
    model: "openai:gpt-4o"
    focus: "security"
    weight: 0.8
    critical: true
```

#### Reviewer Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `name` | String | Human-readable identifier for the reviewer |
| `model` | String | LLM model identifier (e.g., "google:gemini-2.5-pro") |
| `focus` | String | Review focus area (code_quality, security, etc.) |
| `system_prompt_additions` | String | Additional text appended to system prompt |
| `file_patterns` | Hash | Include/exclude patterns for file filtering |
| `weight` | Float | Contribution weight 0.0-1.0 (default: 1.0) |
| `critical` | Boolean | Always highlight findings (default: false) |

#### File Patterns

Filter which files each reviewer sees:

```yaml
file_patterns:
  include:
    - "lib/**/*.rb"        # Only Ruby files in lib/
    - "src/**/*.ts"        # TypeScript files in src/
  exclude:
    - "**/*_test.rb"       # Skip test files
    - "**/*.spec.ts"       # Skip spec files
```

- **Include patterns**: File must match at least one (if any specified)
- **Exclude patterns**: File must not match any

#### Migration from Legacy Format

```yaml
# Legacy format (still supported)
models:
  - claude:opus
  - codex:gpt-5.1-codex-max

# New reviewers format
reviewers:
  - name: "reviewer-1"
    model: "claude:opus"
  - name: "reviewer-2"
    model: "codex:gpt-5.1-codex-max"
```

### Configuration Options

Set defaults in `.ace/review/config.yml`:

```yaml
defaults:
  preset: code                       # Default preset (basic code review)
  auto_execute: false                # Prompt for confirmation before LLM queries
  max_concurrent_models: 3           # Parallel model limit
  llm_timeout: 300                   # Per-model timeout (seconds)
```

**Note**: The gem ships with conservative defaults (`code` preset, confirmation prompts). Override these in your project's `.ace/review/config.yml` for different behavior.

### Output Structure

Multi-model reviews save separate files per model:

```
.ace-local/ace-review/sessions/review-20251202-104235/
├── system.prompt.md
├── user.prompt.md
├── metadata.yml
├── review-google-gemini-2-5-flash.md
├── review-openai-gpt-4.md
└── review-anthropic-claude-3-opus.md
```

## GitHub Pull Request Review Mode

Review GitHub Pull Requests directly from the command line using the integrated `gh` CLI.

### Prerequisites

- **GitHub CLI** (`gh`) must be installed and authenticated
  ```bash
  # Install gh CLI (macOS)
  brew install gh

  # Authenticate with GitHub
  gh auth login

  # Verify authentication
  gh auth status
  ```

### Basic Usage

```bash
# Review a PR by number (uses current repository)
ace-review --pr 123 --auto-execute

# Review with specific preset
ace-review --pr 456 --preset security --auto-execute

# Review PR from full GitHub URL
ace-review --pr https://github.com/owner/repo/pull/789 --auto-execute

# Review PR from different repository
ace-review --pr owner/repo#123 --auto-execute
```

### Developer Feedback from PR Comments

By default, PR reviews include developer feedback extracted from PR comments and review threads. This creates a `review-dev-feedback.md` file alongside the LLM reviews.

```bash
# Include PR comments in review (default)
ace-review --pr 123 --auto-execute

# Explicitly include PR comments
ace-review --pr 123 --pr-comments --auto-execute

# Skip PR comments (LLM analysis only)
ace-review --pr 123 --no-pr-comments --auto-execute
```

The developer feedback includes:
- **Issue comments**: General PR discussion
- **Review comments**: Inline code review threads with file:line references
- **Review state**: Approvals and change requests

When multi-model synthesis is enabled, developer feedback is included in the synthesis report to provide a complete picture combining LLM insights with human reviewer comments.

**Configuration**: Control PR comments in `.ace/review/config.yml`:

```yaml
defaults:
  pr_comments: true          # Include PR comments by default (default: true)
  include_resolved: false    # Include resolved review threads (default: false)
  include_bots: false        # Include bot comments (default: false)
```

### Post Reviews as PR Comments

```bash
# Review and post comment to GitHub
ace-review --pr 123 --post-comment --auto-execute

# Preview comment without posting (dry run)
ace-review --pr 123 --post-comment --dry-run --auto-execute

# Security review with comment
ace-review --pr 456 --preset security --post-comment --auto-execute
```

### Timeout Configuration

The default timeout for GitHub CLI operations is 30 seconds. For large PRs or slow network connections, you can increase the timeout:

```bash
# Increase timeout to 60 seconds for large PRs
ace-review --pr 123 --gh-timeout 60 --auto-execute

# Timeout is applied to both diff fetching and metadata retrieval
ace-review --pr 456 --gh-timeout 120 --post-comment --auto-execute
```

**Note**: The timeout applies to each `gh` CLI operation (diff fetch, metadata retrieval). Operations that fail due to network issues will be retried automatically (up to 3 attempts with exponential backoff).

### PR Identifier Formats

The `--pr` option accepts multiple formats:

- **PR number**: `123` (uses current repository from git remote)
- **Full URL**: `https://github.com/owner/repo/pull/456`
- **Qualified reference**: `owner/repo#789`

### How It Works

1. **Fetches PR diff** via `gh pr diff` command
2. **Extracts metadata** (title, state, author, etc.)
3. **Analyzes with LLM** using your selected preset
4. **Saves locally** to `.ace-local/ace-review/sessions/pr-review-{timestamp}/`
5. **Optionally posts** formatted review as PR comment (with `--post-comment`)

### Error Handling

- **gh CLI not installed**: Clear error with installation instructions
- **Not authenticated**: Directs to `gh auth login`
- **PR not found**: Reports invalid PR identifier
- **Closed/merged PR**: Blocks comment posting with clear message
- **Network issues**: Retries with exponential backoff (3 attempts)

### Cached Reviews

PR reviews are cached locally for debugging and reference:

```bash
# Review structure
.ace-local/ace-review/sessions/pr-review-20251116-140530/
├── system.prompt.md          # System prompt used
├── user.prompt.md            # User prompt with PR diff
├── metadata.yml              # Review metadata
└── review-report-*.md        # LLM analysis output
```

### Security Considerations

**Command Execution Safety**:
- All external commands (`gh` CLI) use array-based execution to prevent shell injection
- PR identifiers are validated using strict regex patterns before use
- Tempfiles are used for multiline content to avoid command-line injection
- No user input is directly interpolated into shell commands

**Authentication**:
- GitHub CLI (`gh`) handles all authentication
- Uses your existing GitHub credentials via `gh auth login`
- Never stores or transmits credentials directly
- Respects GitHub's rate limiting automatically

**Input Validation**:
- PR numbers validated as numeric only
- Repository names validated against GitHub's naming conventions (alphanumeric, hyphens, dots only)
- URL parsing uses strict regex patterns
- Invalid inputs rejected with clear error messages

**Network Safety**:
- Retry logic with exponential backoff (capped at 32 seconds)
- Maximum 3 retry attempts for transient failures
- Non-retryable errors (auth, not found) fail immediately
- Timeout protection on all network operations (default: 30 seconds)

### Troubleshooting

**"gh CLI not installed" error**:
```bash
# macOS
brew install gh

# Linux
# See https://github.com/cli/cli/blob/trunk/docs/install_linux.md

# Windows
# See https://github.com/cli/cli#installation
```

**"Not authenticated with GitHub" error**:
```bash
# Authenticate with GitHub
gh auth login

# Verify authentication
gh auth status

# Check which account is active
gh auth status --show-token
```

**"PR not found" error**:
- Verify PR number is correct
- Ensure you have access to the repository
- Check repository name format: `owner/repo#123`
- For private repos, ensure `gh` is authenticated with correct account

**"Cannot post comment to closed/merged PR" error**:
- This is expected behavior for closed or merged PRs
- Review the PR locally without `--post-comment` flag
- PR state must be "OPEN" to accept new comments

**Network timeout errors**:
- Check your internet connection
- GitHub may be experiencing issues (check https://www.githubstatus.com/)
- Tool automatically retries up to 3 times with exponential backoff
- For persistent issues, try again later or increase timeout with `--timeout` option

**Rate limiting errors**:
- GitHub API has rate limits (5000/hour for authenticated users)
- Wait an hour or check your rate limit status:
  ```bash
  gh api rate_limit
  ```

### Limitations

- **GitHub CLI Required**: Must have `gh` CLI installed and authenticated
- **Repository Access**: Can only review PRs you have read access to
- **Open PRs Only**: Comment posting requires PR to be in "OPEN" state
- **Single Repository**: Assumes `origin` remote when using PR number only
- **Public & Private Repos**: Works with both, requires appropriate authentication
- **Rate Limiting**: Subject to GitHub API rate limits (usually not an issue for normal use)
- **Network Dependent**: Requires internet connection to fetch PR data

## Subject and Context Configuration

Since v0.9.6, ace-review uses ace-bundle for unified content aggregation. Both `--subject` and `--context` accept YAML configuration with these keys:

```yaml
# ✅ CORRECT: Use these keys (both diff: and diffs: work identically)
files: ["lib/**/*.rb", "docs/*.md"]      # File paths and glob patterns
diff: {ranges: ["origin/main...HEAD"]}   # Git diff via ace-git
commands: ["git log --oneline -5"]       # Shell commands to execute
presets: [project, architecture]         # ace-bundle preset names
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

### Unified Subject Syntax (v0.24.0+)

Clean, type-safe subject specification using `type:value` syntax:

```bash
# Git diff ranges
ace-review --subject diff:origin/main..HEAD --preset code

# Commit hashes (review single commit)
ace-review --subject commit:3cd9afbf --preset code
ace-review --subject commit:abc123 --preset code  # short hash (6+ chars)

# GitHub pull requests (subject-only mode)
ace-review --subject pr:123 --preset code

# Multiple GitHub pull requests (comma-separated)
ace-review --subject pr:123,456,789 --preset code

# File patterns
ace-review --subject files:lib/**/*.rb --preset code

# Multiple files (comma-separated)
ace-review --subject files:lib/**/*.rb,test/**/* --preset code

# Task references
ace-review --subject task:145 --preset spec
ace-review --subject task:145.02 --preset spec

# Keywords (existing shortcuts)
ace-review --subject staged --preset code
ace-review --subject working --preset code
```

### Multiple --subject Flags (v0.25.0+)

Combine multiple subjects in a single review with multiple `--subject` flags:

```bash
# Review both code changes and documentation
ace-review --preset code --subject diff:HEAD~3 --subject files:docs/**/*.md

# Multiple file patterns
ace-review --preset security --subject files:lib/**/*.rb --subject files:test/**/*_test.rb

# PR with additional context files
ace-review --preset code-pr --subject pr:123 --subject files:CHANGELOG.md

# Staged changes plus specific files
ace-review --preset docs --subject staged --subject files:README.md
```

**Merge Behavior:**
- Same-type subjects are concatenated into arrays (`--subject files:a.rb --subject files:b.rb` → `{ files: ["a.rb", "b.rb"] }`)
- Different-type subjects are combined (`--subject diff:HEAD --subject files:*.md` → both in config)
- Duplicate subjects are automatically removed
- Empty or whitespace-only subjects are filtered out

**Subject Type Resolution:**

| Input | Resolves To (ace-bundle config) |
|-------|----------------------------------|
| `commit:hash` | `{ "context" => { "diffs" => ["hash~1..hash"] } }` |
| `diff:range` | `{ "context" => { "diffs" => ["range"] } }` |
| `pr:123` | `{ "context" => { "pr" => ["123"] } }` |
| `pr:123,456` | `{ "context" => { "pr" => ["123", "456"] } }` (comma splits into array) |
| `files:pattern` | `{ "context" => { "files" => ["pattern"] } }` |
| `files:a.rb,b.rb` | `{ "context" => { "files" => ["a.rb", "b.rb"] } }` (comma splits into array) |
| `task:ref` | Task lookup → `{ "context" => { "files" => ["task-dir/**/*.s.md"] } }` |
| `staged` | Auto-detect (legacy path) |
| `working` | Auto-detect (legacy path) |

**Note:** `commit:` subject format requires hexadecimal hashes (6-40 characters). Short hashes (6+ chars) and full hashes (40 chars) are both supported. The commit's changes are extracted by comparing the commit to its parent (`COMMIT~1..COMMIT`).

**Note:** Comma-separated values within a typed subject (e.g., `pr:1,2,3` or `files:a.rb,b.rb`) are split into arrays. Empty entries are automatically filtered out.

**Parsing Precedence:**

Subject input is parsed in this order (first match wins):

1. **Typed subjects** (`type:value`) - explicit, highest priority
2. **YAML detection** - starts with `{` or contains valid YAML keys
3. **Keywords** (`staged`, `working`) - convenience shortcuts
4. **Auto-detect** - git range patterns, file globs

**Backward Compatible:** YAML syntax and auto-detection still work.

**Note:** `--pr` vs `--subject pr:` - The `--pr` flag provides full PR mode (includes metadata, comments) using ace-review's GhPrFetcher. The `--subject pr:` syntax only fetches diff content through ace-bundle (subject-only mode).

**Note:** `task:` subject scope - The `task:` subject type reviews task specification files (`*.s.md`) only, not the implementation code. To review code implemented for a task, use `diff:` or `files:` subjects with the appropriate patterns.

## Subject Strategy Configuration

When review subjects exceed model context limits, ace-review uses strategies to handle them intelligently.

### Strategy Types

| Strategy | Description | Use Case |
|----------|-------------|----------|
| `adaptive` | Auto-selects full or chunked based on model capabilities | Default - works for most cases |
| `full` | Sends complete diff in single request | Large context models (Gemini, Claude) |
| `chunked` | Splits diff at file boundaries | Smaller context models or huge diffs |

### Configuration

```yaml
# .ace/review/config.yml
subject_strategy:
  type: adaptive      # or: full, chunked
  headroom: 0.15      # Reserve 15% of context for prompts/output
  chunking:
    max_tokens_per_chunk: 100000
    include_change_summary: true
```

### Strategy Selection (Adaptive Mode)

The adaptive strategy automatically selects based on:

1. **Token estimation**: Estimates tokens in subject content
2. **Model context limit**: Looks up context limit for the target model
3. **Headroom calculation**: Reserves space for system prompts and output

If subject fits within `(model_limit * (1 - headroom))`, uses full strategy; otherwise chunked.

### Chunking Behavior

When chunking is triggered:

- Diff is split at file boundaries (never mid-file)
- Each chunk stays under `max_tokens_per_chunk`
- Optional change summary provides context across chunks
- Findings are merged from all chunks in synthesis

### Model Context Limits

Context limits are resolved via ace-llm provider configuration:

```yaml
# ace-llm/.ace-defaults/llm/providers/google.yml
context_limit: 1000000  # 1M tokens for Gemini

# ace-llm/.ace-defaults/llm/providers/anthropic.yml
context_limit: 200000   # 200K tokens for Claude
```

Unknown models fall back to a conservative 128K default.

## Task Integration

The `--task` flag enables saving review reports directly to ace-task directories for improved traceability and context.

### Usage

```bash
# Save review to task directory (accepts multiple reference formats)
ace-review --preset code-pr --task 114
ace-review --preset security --task task.114
ace-review --preset comprehensive --task v.0.9.0+114

# Combine with auto-execute
ace-review --preset code-pr --task 114 --auto-execute
```

### Task Reference Formats

All ace-taskflow reference formats are supported:
- **Task number**: `114`
- **Task prefix**: `task.114`
- **Full task ID**: `v.0.9.0+114`

### Output Location

Reports are saved to `<task-dir>/reviews/` with timestamped filenames:
- **Format**: `YYYYMMDD-HHMMSS-{provider}-{preset}-review.md`
- **Examples**:
  - `20251116-134500-google-pr-review.md`
  - `20251116-140230-gpt-security-review.md`
  - `20251116-143015-claude-comprehensive-review.md`

### Error Handling

Task integration uses graceful degradation:
- **Task not found**: Warning displayed, review completes normally
- **ace-taskflow unavailable**: Warning displayed, review completes normally
- **Permission errors**: Warning displayed, review completes normally

Reviews always succeed regardless of task integration status.

## Auto-Save Feature

Auto-save automatically detects task IDs from your git branch name and saves reviews to the appropriate task directory without requiring the `--task` flag.

### Enabling Auto-Save

Auto-save is **opt-in by default**. Add to `.ace/review/config.yml`:

```yaml
defaults:
  auto_save: true                          # Enable auto-save (opt-in, default: false)
  auto_save_branch_patterns:               # Patterns to extract task ID from branch
    - '^(\d+(?:\.\d+)?)-'                  # Standard: 121-feature, 121.01-subtask
    - '^feature/(\d+)-'                    # Feature branches: feature/123-name
  auto_save_release_fallback: true         # Save to release dir when no task detected
```

See `.ace-defaults/review/config.yml` for the full example configuration.

### How It Works

1. **Branch Detection**: Reads current git branch name (e.g., `126.03-auto-save-detection`)
2. **Pattern Matching**: Extracts task ID using configured regex patterns (e.g., `126.03`)
3. **Task Resolution**: Finds the task directory via ace-taskflow
4. **Report Saving**: Saves review reports to `<task-dir>/reviews/`

### Disabling Auto-Save

```bash
# Disable for a single command
ace-review --preset code-pr --no-auto-save

# Or disable in config
defaults:
  auto_save: false
```

### Priority Order

1. **Explicit `--task` flag**: Highest priority, always used if provided
2. **Auto-detected from branch**: Used when `auto_save: true` and no explicit `--task`
3. **Release directory fallback**: Used when task not found and `auto_save_release_fallback: true`

### Default Patterns

The default pattern `'^(\d+(?:\.\d+)?)-'` matches:
- `121-feature-name` → task `121`
- `121.01-subtask-name` → task `121.01`
- `126.03-auto-save-detection` → task `126.03`

Does not match:
- `main` → no task
- `feature-123` → no task (number not at start)
- `HEAD` → no task (detached HEAD)

## Configuration

### Main Configuration

Create `.ace/review/config.yml` in your project:

```yaml
defaults:
  model: "google:gemini-2.5-flash"
  output_format: "markdown"
  bundle: "project"

# Project documentation files for auto-bundle extraction
# Used when bundle: "project" or bundle: "auto"
# Order matters: first found files are used first
project_docs:
  - "README.md"
  - "docs/architecture.md"
  - "docs/vision.md"
  - "docs/blueprint.md"
  - ".github/CONTRIBUTING.md"
  - "ARCHITECTURE.md"

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
  bundle:
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
bundle: "project"

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
bundle:
  presets: [project]                      # Load project preset
  files: ["docs/team-guidelines.md"]      # Team-specific docs

# Subject: what to review
subject:
  diff: {ranges: ["HEAD~1..HEAD"]}        # Recent changes
  files: ["lib/**/*.rb"]                  # Ruby files
```

**Note**: The new `instructions` format provides section-based organization that ace-bundle processes into structured XML-tagged output. The legacy `prompt_composition` format continues to work for backward compatibility.

### Preset Composition (DRY Configuration)

Create reusable base presets and compose specialized presets from them, reducing duplication and improving maintainability.

#### Basic Composition

Use the `presets:` array at the root level to compose from other presets:

```yaml
# .ace/review/presets/code.yml - Base preset
description: "Base code review configuration"
instructions:
  bundle:
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
  bundle:
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
  bundle:
    # ... many lines ...
subject:
  diffs: ["origin...HEAD"]

# wip.yml - 145 lines (95% duplicate)
description: "WIP review"
instructions:
  bundle:
    # ... same lines ...
subject:
  commands: ["git diff HEAD"]
```

**After** (DRY with composition):

```yaml
# code.yml - 40 lines (shared base)
description: "Base code review"
instructions:
  bundle:
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

### Preset Resolution Chain

ace-review resolves presets in this order (first match wins):

1. **Project presets**: `.ace/review/presets/*.yml` (your customizations)
2. **Gem presets**: `ace-review/.ace-defaults/review/presets/*.yml` (built-in defaults)

This allows you to:
- Override built-in presets by creating a file with the same name
- Create project-specific presets that don't exist in the gem
- See available presets with `ace-review --list-presets`

**Example**: To customize the `code-pr` preset:
```bash
# Copy and modify the default
cp ace-review/.ace-defaults/review/presets/code-pr.yml .ace/review/presets/code-pr.yml
# Edit .ace/review/presets/code-pr.yml with your changes
```

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
- `--preset <name>` - Use specific preset (default: code)
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
- `--no-auto-save` - Disable auto-save to task directory for this command

GitHub Pull Request options:
- `--pr <identifier>` - Review GitHub PR (number, URL, or owner/repo#number)
- `--[no-]pr-comments` - Include PR comments as developer feedback (default: true for --pr)
- `--post-comment` - Post review as PR comment (requires --pr)
- `--gh-timeout <seconds>` - Timeout for gh CLI operations in seconds (default: 30)

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
| `code-review-synthesize` | Use workflow: `wfi://review/run` |

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
