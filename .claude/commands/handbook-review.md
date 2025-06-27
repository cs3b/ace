# Documentation Review Workflow

Automated documentation review workflow using multiple LLM providers for comprehensive analysis.

**When providing a commit hash as argument**: The commit is used as the starting point (exclusive) - the review will include all commits from AFTER that commit up to HEAD.

## Prerequisites

- Ensure all changes are committed or stashed
- Available providers: `google:gemini-2.5-pro` (gpro), `anthropic:claude-4-0-sonnet-latest` (csonet), `openai:gpt-4o` (o4), `mistral:mistral-large-latest` (mistral)
- Scripts: `bin/cr-docs` (prompt generator), `dev-tools/exe/llm-query` (LLM interface)

## Default Configuration

**Default parameters for documentation reviews:**
- **Include content**: Use `--include-content` for detailed analysis when needed
- **Timeout**: 600 seconds (10 minutes) for complex reviews
- **System prompt**: `dev-local/handbook/gds/review/_system.md`
- **Default provider**: `gpro` (Google Gemini 2.5 Pro)
- **Repository**: All git operations use `git -C` to avoid directory changes
- **Handbook prompt**: `dev-local/handbook/gds/review/_handbook.md`
- **Context**: All `docs/*.md` files from main repository included as context

## Quick Start (Staged/Uncommitted Changes)

```bash
# 1. Set project root
PROJECT_ROOT="/Users/michalczyz/Projects/CodingAgent/handbook-meta"

# 2. Create timestamped review directory and switch to it
REVIEW_DIR=$("$PROJECT_ROOT/bin/handbook-review-folder")
cd "$REVIEW_DIR"

# 3. Stage all changes in dev-handbook and generate diff
git -C "$PROJECT_ROOT/dev-handbook" add -A
git -C "$PROJECT_ROOT/dev-handbook" diff --cached > input.diff

# 4. Generate review prompt with documentation context
"$PROJECT_ROOT/bin/cr-docs" -d input.diff -o dr-prompt.md

# 5. Run review with default provider (gpro)
"$PROJECT_ROOT/dev-tools/exe/llm-query" gpro dr-prompt.md \
  --system "$PROJECT_ROOT/dev-local/handbook/gds/review/_system.md" \
  --timeout 600 \
  --output dr-report-gpro.md
```

## Workflow Steps

### 1. Prepare Review Environment
```bash
# Set project root
PROJECT_ROOT="/Users/michalczyz/Projects/CodingAgent/handbook-meta"

# Create review directory with timestamp (default for uncommitted changes)
REVIEW_DIR=$("$PROJECT_ROOT/bin/handbook-review-folder")
cd "$REVIEW_DIR"

# Or for specific git ranges
REVIEW_DIR=$("$PROJECT_ROOT/bin/handbook-review-folder" "main..HEAD")
cd "$REVIEW_DIR"
```

### 2. Generate Diff (using git -C)
```bash
# Working from review directory, use git -C to target dev-handbook

# Option A: From staged (uncommitted) changes (DEFAULT)
git -C "$PROJECT_ROOT/dev-handbook" add -A  # Ensure all changes are staged first
git -C "$PROJECT_ROOT/dev-handbook" diff --cached > input.diff

# Option B: From all uncommitted changes (staged + unstaged)
git -C "$PROJECT_ROOT/dev-handbook" diff HEAD > input.diff

# Option C: From specific commits/branches
git -C "$PROJECT_ROOT/dev-handbook" diff HEAD~3..HEAD > input.diff
git -C "$PROJECT_ROOT/dev-handbook" diff main..feature-branch > input.diff

# Option D: From tag/reference to HEAD (RECOMMENDED for releases)
git -C "$PROJECT_ROOT/dev-handbook" diff v.0.2.1+task.61..HEAD > input.diff
git -C "$PROJECT_ROOT/dev-handbook" diff v.0.2.1..HEAD > input.diff

# Option E: From commit hash to HEAD (exclusive of starting commit)
git -C "$PROJECT_ROOT/dev-handbook" diff <commit-hash>..HEAD > input.diff

# Option F: From commit hash (single commit only - NOT recommended for reviews)
git -C "$PROJECT_ROOT/dev-handbook" show <commit-hash> > input.diff
```

### 3. Generate Review Prompt
```bash
# Default: Basic prompt generation
"$PROJECT_ROOT/bin/cr-docs" -d input.diff -o dr-prompt.md

# With full documentation content (for detailed analysis)
"$PROJECT_ROOT/bin/cr-docs" -d input.diff -o dr-prompt.md --include-content
```

### 4. Run Documentation Review (DEFAULT: gpro)
```bash
# Default: Run with gpro only
"$PROJECT_ROOT/dev-tools/exe/llm-query" gpro dr-prompt.md \
  --system "$PROJECT_ROOT/dev-local/handbook/gds/review/_system.md" \
  --timeout 600 \
  --output dr-report-gpro.md

# Multiple providers (for critical handbook updates)
for provider in gpro csonet; do
  "$PROJECT_ROOT/dev-tools/exe/llm-query" $provider dr-prompt.md \
    --system "$PROJECT_ROOT/dev-local/handbook/gds/review/_system.md" \
    --timeout 300 \
    --output "dr-report-${provider}.md"
done

# All providers
providers=(gpro csonet o4 mistral)
for provider in "${providers[@]}"; do
  "$PROJECT_ROOT/dev-tools/exe/llm-query" $provider dr-prompt.md \
    --system "$PROJECT_ROOT/dev-local/handbook/gds/review/_system.md" \
    --timeout 300 \
    --output "dr-report-${provider}.md"
done
```

## Example Usage

### Basic Review
```bash
# Set project root
PROJECT_ROOT="/Users/michalczyz/Projects/CodingAgent/handbook-meta"

# Quick review of current dev-handbook changes
REVIEW_DIR=$("$PROJECT_ROOT/bin/handbook-review-folder")
cd "$REVIEW_DIR"

# Generate diff and review
git -C "$PROJECT_ROOT/dev-handbook" diff > input.diff
"$PROJECT_ROOT/bin/cr-docs" -d input.diff -o dr-prompt.md
"$PROJECT_ROOT/dev-tools/exe/llm-query" gpro dr-prompt.md \
  --system "$PROJECT_ROOT/dev-local/handbook/gds/review/_system.md" \
  --timeout 300 -o dr-report-gpro.md
```

### Comprehensive Review
```bash
# Set project root
PROJECT_ROOT="/Users/michalczyz/Projects/CodingAgent/handbook-meta"

# Full content review with multiple providers
REVIEW_DIR=$("$PROJECT_ROOT/bin/handbook-review-folder" "HEAD~5..HEAD")
cd "$REVIEW_DIR"

# Generate diff with full content
git -C "$PROJECT_ROOT/dev-handbook" diff HEAD~5..HEAD > input.diff
"$PROJECT_ROOT/bin/cr-docs" -d input.diff -o dr-prompt.md --include-content

# Run multiple providers
for provider in gpro csonet; do
  "$PROJECT_ROOT/dev-tools/exe/llm-query" $provider dr-prompt.md \
    --system "$PROJECT_ROOT/dev-handbook/guides/code-review/_doc-review-system.md" \
    --timeout 300 \
    --output "dr-report-${provider}.md"
done
```

### Review PR Changes
```bash
# Set project root
PROJECT_ROOT="/Users/michalczyz/Projects/CodingAgent/handbook-meta"

# Review specific PR dev-handbook changes
REVIEW_DIR=$("$PROJECT_ROOT/bin/handbook-review-folder" "main..pr-123")
cd "$REVIEW_DIR"

# Checkout PR and generate diff
git -C "$PROJECT_ROOT/dev-handbook" fetch origin pull/123/head:pr-123
git -C "$PROJECT_ROOT/dev-handbook" checkout pr-123
git -C "$PROJECT_ROOT/dev-handbook" diff main..HEAD > input.diff

# Generate and run review
"$PROJECT_ROOT/bin/cr-docs" -d input.diff -o dr-prompt.md -t "$PROJECT_ROOT/dev-local/handbook/gds/review/_handbook.md"
"$PROJECT_ROOT/dev-tools/exe/llm-query" gpro dr-prompt.md \
  --system "$PROJECT_ROOT/dev-local/handbook/gds/review/_system.md" \
  --timeout 300 -o dr-report-csonet.md
```

## Provider Selection Guide

- **google:gemini-2.5-pro (gpro)**: Excellent at comprehensive documentation analysis
- **anthropic:claude-4-0-sonnet-latest (csonet)**: Strong at identifying documentation gaps
- **openai:gpt-4o (o4)**: Good at structured documentation recommendations
- **mistral:mistral-large-latest (mistral)**: Fast reviews for quick documentation checks

## Output Files Structure

```
dev-taskflow/current/{current-release}/handbook_review/task-N/
├── input.diff              # Git diff of dev-handbook changes
├── dr-prompt.md            # Generated review prompt with docs context
├── dr-report-gpro.md       # Google Gemini review
├── dr-report-csonet.md     # Claude Sonnet review
├── dr-report-o4.md         # OpenAI GPT-4o review
└── dr-report-mistral.md    # Mistral review
```

## Important Notes

- **Focus**: Only reviews changes in `dev-handbook/` submodule repository
- **Context**: Automatically includes all `docs/*.md` files from main repository for reference
- **Path handling**: Uses `bin/rc` for dynamic release paths and `git -C` for repository operations
- **Working directory**: All operations performed from review directory with absolute paths
- Use `--include-content` flag for detailed documentation analysis
- Use `--timeout 300` for complex reviews to avoid timeouts
- Archive completed reviews in appropriate release folders
- Multiple provider reviews recommended for major documentation updates

## Meta-Review for Documentation

After running multiple providers, combine and compare their recommendations:

```bash
# Combine all documentation review reports
"$PROJECT_ROOT/dev-tools/exe/llm-query" gpro \
  "$PROJECT_ROOT/dev-local/handbook/gds/review/_handbook.md" \
  --input "dr-report-*.md" \
  --timeout 300 \
  --output dr-meta-review.md
```
