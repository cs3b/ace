# Code Review Workflow

Automated code review workflow using multiple LLM providers for comprehensive analysis.

**When providing a commit hash as argument**: The commit is used as the starting point (exclusive) - the review will include all commits from AFTER that commit up to HEAD.

## Prerequisites

- Ensure all changes are committed or stashed
- Available providers: `google:gemini-2.5-pro` (gpro), `anthropic:claude-4-0-sonnet-latest` (csonet), `openai:gpt-4o` (o4), `mistral:mistral-large-latest` (mistral)
- Scripts: `bin/cr` (prompt generator), `exe/llm-query` (LLM interface)

## Default Configuration

**Default parameters for code reviews:**

- **Include dependencies**: Always use `--include-dependencies` for comprehensive context
- **Timeout**: 300 seconds (5 minutes) for complex reviews
- **System prompt**: `dev-handbook/guides/code-review/_code-review-system.md`
- **Default provider**: `gpro` (Google Gemini 2.5 Pro)
- **Default filtered paths**: `.claude/**`, `docs/**`, `dev-taskflow/**`, `.*`, `spec/cassettes/**/*`

## Quick Start (Staged/Uncommitted Changes)

```bash
# 1. Create timestamped review directory
mkdir -p dev-taskflow/current/v.0.2.0-synapse/code_review/uncommitted-changes-$(date +%Y%m%d-%H%M%S)
cd dev-taskflow/current/v.0.2.0-synapse/code_review/uncommitted-changes-*

# 2. Ensure all changes are staged
git add -A  # Stages all changes (new, modified, and deleted files)

# 3. Generate diff from staged changes
git diff --cached > input.diff

# 4. Filter out unnecessary files (docs, tests, etc.)
ruby dev-tools/exe-old/filter-diff.rb input.diff \
  ".claude/**" "docs/**" "dev-taskflow/**" ".*" "spec/cassettes/**/*" \
  -o input-filtered.diff

# 5. Generate review prompt with dependencies
bin/cr -d input-filtered.diff -o cr-prompt.md --include-dependencies

# 6. Run review with default provider (gpro)
exe/llm-query gpro cr-prompt.md \
  --system dev-handbook/guides/code-review/_code-review-system.md \
  --timeout 300 \
  --output cr-report-gpro.md
```

## Workflow Steps

### 1. Prepare Review Environment

```bash
# Create review directory with timestamp (default for uncommitted changes)
mkdir -p dev-taskflow/current/v.0.2.0-synapse/code_review/uncommitted-changes-$(date +%Y%m%d-%H%M%S)
cd dev-taskflow/current/v.0.2.0-synapse/code_review/uncommitted-changes-*

# Or use specific task/release naming
mkdir -p dev-taskflow/current/v.X.X.X-release/code_review/task-N/
cd dev-taskflow/current/v.X.X.X-release/code_review/task-N/
```

### 2. Generate Diff

```bash
# Option A: From staged (uncommitted) changes (DEFAULT)
git add -A  # Ensure all changes are staged first
git diff --cached > input.diff

# Option B: From all uncommitted changes (staged + unstaged)
git diff HEAD > input.diff

# Option C: From specific commits/branches  
git diff HEAD~3..HEAD > input.diff
git diff main..feature-branch > input.diff

# Option D: From commit hash (single commit)
git show <commit-hash> > input.diff

# Option E: From commit hash to HEAD (exclusive of starting commit)
git diff <commit-hash>..HEAD > input.diff

# Option F: Using stash (if you need to stash changes)
git stash push -m "Code review stash $(date +%Y%m%d-%H%M%S)"
git stash show -p > input.diff
```

### 3. Filter Diff (Optional but Recommended)

```bash
# Default: Filter out documentation, test cassettes, and hidden files
ruby dev-tools/exe-old/filter-diff.rb input.diff \
  ".claude/**" "docs/**" "dev-taskflow/**" ".*" "spec/cassettes/**/*" \
  -o input-filtered.diff

# With additional custom patterns
ruby dev-tools/exe-old/filter-diff.rb input.diff \
  ".claude/**" "docs/**" "dev-taskflow/**" ".*" "spec/cassettes/**/*" \
  "tmp/**" "log/**" "vendor/**" \
  -o input-filtered.diff

# Using a pattern file
echo -e ".claude/**\ndocs/**\ndev-taskflow/**\n.*\nspec/cassettes/**/*" > .ignore-patterns
ruby dev-tools/exe-old/filter-diff.rb input.diff -p .ignore-patterns -o input-filtered.diff
```

### 4. Generate Review Prompt (DEFAULT: with dependencies)

```bash
# Default: With full context and dependencies (using filtered diff)
bin/cr -d input-filtered.diff -o cr-prompt.md --include-dependencies

# If not using filter, use original diff
bin/cr -d input.diff -o cr-prompt.md --include-dependencies

# Basic prompt generation (without dependencies - faster but less comprehensive)
bin/cr -d input-filtered.diff -o cr-prompt.md
```

### 5. Run Code Review (DEFAULT: gpro)

```bash
# Default: Run with gpro only
exe/llm-query gpro cr-prompt.md \
  --system dev-handbook/guides/code-review/_code-review-system.md \
  --timeout 300 \
  --output cr-report-gpro.md

# Multiple providers (for critical changes)
for provider in gpro csonet; do
  exe/llm-query $provider cr-prompt.md \
    --system dev-handbook/guides/code-review/_code-review-system.md \
    --timeout 300 \
    --output "cr-report-${provider}.md"
done

# All providers
providers=(gpro csonet o4 mistral)
for provider in "${providers[@]}"; do
  exe/llm-query $provider cr-prompt.md \
    --system dev-handbook/guides/code-review/_code-review-system.md \
    --timeout 300 \
    --output "cr-report-${provider}.md"
done
```

## Example Usage

### Basic Review

```bash
# Quick review of current working directory changes
mkdir -p dev-taskflow/current/v.0.2.0-synapse/code_review/task-42/
cd dev-taskflow/current/v.0.2.0-synapse/code_review/task-42/
git diff > input.diff
bin/cr -d input.diff -o cr-prompt.md
exe/llm-query gpro cr-prompt.md --system dev-handbook/guides/code-review/_code-review-system.md --timeout 300 -o cr-report-gpro.md
```

### Comprehensive Review

```bash
# Full context review with multiple providers
mkdir -p dev-taskflow/current/v.0.2.0-synapse/code_review/task-42/
cd dev-taskflow/current/v.0.2.0-synapse/code_review/task-42/
git diff HEAD~5..HEAD > input.diff
bin/cr -d input.diff -o cr-prompt.md --include-dependencies

# Run multiple providers
for provider in gpro csonet o4; do
  exe/llm-query $provider cr-prompt.md \
    --system dev-handbook/guides/code-review/_code-review-system.md \
    --timeout 300 \
    --output "cr-report-${provider}.md"
done
```

### Review PR Changes

```bash
# Review specific PR changes
gh pr checkout 123
git diff main..HEAD > input.diff
bin/cr -d input.diff -o cr-prompt.md
exe/llm-query csonet cr-prompt.md --system dev-handbook/guides/code-review/_code-review-system.md --timeout 300 -o cr-report-csonet.md
```

## Provider Selection Guide

- **google:gemini-2.5-pro (gpro)**: Excellent at architectural analysis and Ruby best practices
- **anthropic:claude-4-0-sonnet-latest (csonet)**: Strong security analysis and detailed feedback  
- **openai:gpt-4o (o4)**: Good general code review with performance insights
- **mistral:mistral-large-latest (mistral)**: Fast reviews, good at catching basic issues

## Output Files Structure

```
dev-taskflow/current/v.X.X.X-release/code_review/task-N/
├── input.diff              # Git diff (DO NOT load into session - too large)
├── cr-prompt.md            # Generated review prompt (DO NOT load into session - too large)  
├── cr-report-gpro.md       # Google Gemini review
├── cr-report-csonet.md     # Claude Sonnet review
├── cr-report-o4.md         # OpenAI GPT-4o review
└── cr-report-mistral.md    # Mistral review
```

## Important Notes

- **DO NOT** load `input.diff` or `cr-prompt.md` into Claude sessions - they are typically very large
- Use `--timeout 300` for complex reviews to avoid timeouts
- Include `--include-dependencies` flag for architectural changes
- Archive completed reviews in appropriate release folders
- Multiple provider reviews recommended for critical features or security-sensitive changes
