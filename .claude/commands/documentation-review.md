# Documentation Review Workflow

Automated documentation review workflow using multiple LLM providers for comprehensive analysis.

**When providing a commit hash as argument**: The commit is used as the starting point (exclusive) - the review will include all commits from AFTER that commit up to HEAD.

## Prerequisites

- Ensure all changes are committed or stashed
- Available providers: `google:gemini-2.5-pro` (gpro), `anthropic:claude-4-0-sonnet-latest` (csonet), `openai:gpt-4o` (o4), `mistral:mistral-large-latest` (mistral)
- Scripts: `bin/cr-docs` (prompt generator), `exe/llm-query` (LLM interface)

## Default Configuration

**Default parameters for documentation reviews:**
- **Include content**: Use `--include-content` for detailed analysis when needed
- **Timeout**: 300 seconds (5 minutes) for complex reviews
- **System prompt**: `docs-dev/guides/code-review/_doc-review-system.md`
- **Default provider**: `gpro` (Google Gemini 2.5 Pro)
- **Filtered paths**: Only include `lib/**` changes in diff
- **Context**: All `docs/*.md` files included as context

## Quick Start (Staged/Uncommitted Changes)

```bash
# 1. Create timestamped review directory
mkdir -p docs-project/current/v.0.2.0-synapse/doc_review/uncommitted-changes-$(date +%Y%m%d-%H%M%S)
cd docs-project/current/v.0.2.0-synapse/doc_review/uncommitted-changes-*

# 2. Ensure all changes are staged
git add -A  # Stages all changes (new, modified, and deleted files)

# 3. Generate diff from staged changes (lib only)
git diff --cached -- 'lib/**' > input.diff

# 4. Generate review prompt with documentation context
bin/cr-docs -d input.diff -o dr-prompt.md

# 5. Run review with default provider (gpro)
exe/llm-query gpro dr-prompt.md \
  --system docs-dev/guides/code-review/_doc-review-system.md \
  --timeout 300 \
  --output dr-report-gpro.md
```

## Workflow Steps

### 1. Prepare Review Environment
```bash
# Create review directory with timestamp (default for uncommitted changes)
mkdir -p docs-project/current/v.0.2.0-synapse/doc_review/uncommitted-changes-$(date +%Y%m%d-%H%M%S)
cd docs-project/current/v.0.2.0-synapse/doc_review/uncommitted-changes-*

# Or use specific task/release naming
mkdir -p docs-project/current/v.X.X.X-release/doc_review/task-N/
cd docs-project/current/v.X.X.X-release/doc_review/task-N/
```

### 2. Generate Diff (lib directory only)
```bash
# Option A: From staged (uncommitted) changes (DEFAULT)
git add -A  # Ensure all changes are staged first
git diff --cached -- 'lib/**' > input.diff

# Option B: From all uncommitted changes (staged + unstaged)
git diff HEAD -- 'lib/**' > input.diff

# Option C: From specific commits/branches  
git diff HEAD~3..HEAD -- 'lib/**' > input.diff
git diff main..feature-branch -- 'lib/**' > input.diff

# Option D: From tag/reference to HEAD (RECOMMENDED for releases)
git diff v.0.2.1+task.61..HEAD -- 'lib/**' > input.diff
git diff v.0.2.1..HEAD -- 'lib/**' > input.diff

# Option E: From commit hash to HEAD (exclusive of starting commit)
git diff <commit-hash>..HEAD -- 'lib/**' > input.diff

# Option F: From commit hash (single commit only - NOT recommended for reviews)
git show <commit-hash> -- 'lib/**' > input.diff
```

### 3. Generate Review Prompt
```bash
# Default: Basic prompt generation
bin/cr-docs -d input.diff -o dr-prompt.md

# With full documentation content (for detailed analysis)
bin/cr-docs -d input.diff -o dr-prompt.md --include-content
```

### 4. Run Documentation Review (DEFAULT: gpro)
```bash
# Default: Run with gpro only
exe/llm-query gpro dr-prompt.md \
  --system docs-dev/guides/code-review/_doc-review-system.md \
  --timeout 300 \
  --output dr-report-gpro.md

# Multiple providers (for critical documentation updates)
for provider in gpro csonet; do
  exe/llm-query $provider dr-prompt.md \
    --system docs-dev/guides/code-review/_doc-review-system.md \
    --timeout 300 \
    --output "dr-report-${provider}.md"
done

# All providers
providers=(gpro csonet o4 mistral)
for provider in "${providers[@]}"; do
  exe/llm-query $provider dr-prompt.md \
    --system docs-dev/guides/code-review/_doc-review-system.md \
    --timeout 300 \
    --output "dr-report-${provider}.md"
done
```

## Example Usage

### Basic Review
```bash
# Quick review of current lib changes
mkdir -p docs-project/current/v.0.2.0-synapse/doc_review/task-42/
cd docs-project/current/v.0.2.0-synapse/doc_review/task-42/
git diff -- 'lib/**' > input.diff
bin/cr-docs -d input.diff -o dr-prompt.md
exe/llm-query gpro dr-prompt.md --system docs-dev/guides/code-review/_doc-review-system.md --timeout 300 -o dr-report-gpro.md
```

### Comprehensive Review
```bash
# Full content review with multiple providers
mkdir -p docs-project/current/v.0.2.0-synapse/doc_review/task-42/
cd docs-project/current/v.0.2.0-synapse/doc_review/task-42/
git diff HEAD~5..HEAD -- 'lib/**' > input.diff
bin/cr-docs -d input.diff -o dr-prompt.md --include-content

# Run multiple providers
for provider in gpro csonet; do
  exe/llm-query $provider dr-prompt.md \
    --system docs-dev/guides/code-review/_doc-review-system.md \
    --timeout 300 \
    --output "dr-report-${provider}.md"
done
```

### Review PR Changes
```bash
# Review specific PR lib changes
gh pr checkout 123
git diff main..HEAD -- 'lib/**' > input.diff
bin/cr-docs -d input.diff -o dr-prompt.md
exe/llm-query csonet dr-prompt.md --system docs-dev/guides/code-review/_doc-review-system.md --timeout 300 -o dr-report-csonet.md
```

## Provider Selection Guide

- **google:gemini-2.5-pro (gpro)**: Excellent at comprehensive documentation analysis
- **anthropic:claude-4-0-sonnet-latest (csonet)**: Strong at identifying documentation gaps  
- **openai:gpt-4o (o4)**: Good at structured documentation recommendations
- **mistral:mistral-large-latest (mistral)**: Fast reviews for quick documentation checks

## Output Files Structure

```
docs-project/current/v.X.X.X-release/doc_review/task-N/
├── input.diff              # Git diff of lib changes
├── dr-prompt.md            # Generated review prompt with docs context  
├── dr-report-gpro.md       # Google Gemini review
├── dr-report-csonet.md     # Claude Sonnet review
├── dr-report-o4.md         # OpenAI GPT-4o review
└── dr-report-mistral.md    # Mistral review
```

## Important Notes

- **Focus**: Only reviews changes in `lib/**` directory
- **Context**: Automatically includes all `docs/*.md` files for reference
- Use `--include-content` flag for detailed documentation analysis
- Use `--timeout 300` for complex reviews to avoid timeouts
- Archive completed reviews in appropriate release folders
- Multiple provider reviews recommended for major documentation updates

## Meta-Review for Documentation

After running multiple providers, combine and compare their recommendations:

```bash
# Combine all documentation review reports
exe/llm-query gpro docs-dev/guides/code-review/_meta-doc-review-combine.md \
  --input "dr-report-*.md" \
  --timeout 300 \
  --output dr-meta-review.md
```