# Test Review Workflow

Automated test review workflow using multiple LLM providers for comprehensive analysis of spec files.

**When providing a commit hash as argument**: The commit is used as the starting point (exclusive) - the review will include all commits from AFTER that commit up to HEAD.

## Prerequisites

- Ensure all changes are committed or stashed
- Available providers: `google:gemini-2.5-pro` (gpro), `anthropic:claude-4-0-sonnet-latest` (csonet), `openai:gpt-4o` (o4), `mistral:mistral-large-latest` (mistral)
- Scripts: `bin/test-review` (prompt generator), `dev-tools/dev-tools/exe/llm-query` (LLM interface)

## Default Configuration

**Default parameters for test reviews:**

- **Include documentation**: Use `--include-docs` to add documentation context
- **Timeout**: 300 seconds (5 minutes) for complex reviews
- **System prompt**: `dev-handbook/guides/code-review/_test-review-system.md`
- **Default provider**: `gpro` (Google Gemini 2.5 Pro)
- **Filtered paths**: Only include `spec/**` changes, exclude `spec/cassettes/**`
- **Context**: Test documentation and implementation files

## Quick Start (Staged/Uncommitted Changes)

```bash
# 1. Create timestamped review directory
mkdir -p dev-taskflow/current/v.0.2.0-synapse/test_review/uncommitted-changes-$(date +%Y%m%d-%H%M%S)
cd dev-taskflow/current/v.0.2.0-synapse/test_review/uncommitted-changes-*

# 2. Ensure all changes are staged
git add -A  # Stages all changes (new, modified, and deleted files)

# 3. Generate diff from tag to HEAD (spec only, excluding cassettes)
# For staged changes:
git diff --cached -- 'spec/**' ':!spec/cassettes/**' > input.diff
# For tag-based reviews:
git diff v.0.2.1+task.61..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff

# 4. Generate review prompt
bin/test-review -d input.diff -o tr-prompt.md

# 5. Run review with default provider (gpro)
dev-tools/dev-tools/exe/llm-query gpro tr-prompt.md \
  --system dev-handbook/guides/code-review/_test-review-system.md \
  --timeout 300 \
  --output tr-report-gpro.md
```

## Workflow Steps

### 1. Prepare Review Environment

```bash
# Create review directory with timestamp (default for uncommitted changes)
mkdir -p dev-taskflow/current/v.0.2.0-synapse/test_review/uncommitted-changes-$(date +%Y%m%d-%H%M%S)
cd dev-taskflow/current/v.0.2.0-synapse/test_review/uncommitted-changes-*

# Or use specific task/release naming
mkdir -p dev-taskflow/current/v.X.X.X-release/test_review/task-N/
cd dev-taskflow/current/v.X.X.X-release/test_review/task-N/
```

### 2. Generate Diff (spec directory only, no cassettes)

```bash
# Option A: From staged (uncommitted) changes (DEFAULT)
git add -A  # Ensure all changes are staged first
git diff --cached -- 'spec/**' ':!spec/cassettes/**' > input.diff

# Option B: From all uncommitted changes (staged + unstaged)
git diff HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff

# Option C: From specific commits/branches  
git diff HEAD~3..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff
git diff main..feature-branch -- 'spec/**' ':!spec/cassettes/**' > input.diff

# Option D: From tag/reference to HEAD (RECOMMENDED for releases)
git diff v.0.2.1+task.61..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff
git diff v.0.2.1..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff

# Option E: From commit hash to HEAD (exclusive of starting commit)
git diff <commit-hash>..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff

# Option F: From commit hash (single commit only - NOT recommended for reviews)
git show <commit-hash> -- 'spec/**' ':!spec/cassettes/**' > input.diff
```

### 3. Generate Review Prompt

```bash
# Default: Basic prompt generation
bin/test-review -d input.diff -o tr-prompt.md

# With documentation context (for comprehensive analysis)
bin/test-review -d input.diff -o tr-prompt.md --include-docs

# With implementation context (to verify test coverage)
bin/test-review -d input.diff -o tr-prompt.md --include-implementation
```

### 4. Run Test Review (DEFAULT: gpro)

```bash
# Default: Run with gpro only
dev-tools/dev-tools/exe/llm-query gpro tr-prompt.md \
  --system dev-handbook/guides/code-review/_test-review-system.md \
  --timeout 300 \
  --output tr-report-gpro.md

# Multiple providers (for critical test suites)
for provider in gpro csonet; do
  dev-tools/dev-tools/exe/llm-query $provider tr-prompt.md \
    --system dev-handbook/guides/code-review/_test-review-system.md \
    --timeout 300 \
    --output "tr-report-${provider}.md"
done

# All providers
providers=(gpro csonet o4 mistral)
for provider in "${providers[@]}"; do
  dev-tools/dev-tools/exe/llm-query $provider tr-prompt.md \
    --system dev-handbook/guides/code-review/_test-review-system.md \
    --timeout 300 \
    --output "tr-report-${provider}.md"
done
```

## Example Usage

### Basic Review

```bash
# Quick review of current spec changes
mkdir -p dev-taskflow/current/v.0.2.0-synapse/test_review/task-42/
cd dev-taskflow/current/v.0.2.0-synapse/test_review/task-42/
git diff -- 'spec/**' ':!spec/cassettes/**' > input.diff
bin/test-review -d input.diff -o tr-prompt.md
dev-tools/dev-tools/exe/llm-query gpro tr-prompt.md --system dev-handbook/guides/code-review/_test-review-system.md --timeout 300 -o tr-report-gpro.md
```

### Comprehensive Review

```bash
# Full context review with multiple providers
mkdir -p dev-taskflow/current/v.0.2.0-synapse/test_review/task-42/
cd dev-taskflow/current/v.0.2.0-synapse/test_review/task-42/
git diff v.0.2.1+task.61..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff
bin/test-review -d input.diff -o tr-prompt.md --include-implementation

# Run multiple providers
for provider in gpro csonet; do
  dev-tools/dev-tools/exe/llm-query $provider tr-prompt.md \
    --system dev-handbook/guides/code-review/_test-review-system.md \
    --timeout 300 \
    --output "tr-report-${provider}.md"
done
```

### Review PR Test Changes

```bash
# Review specific PR test changes
gh pr checkout 123
git diff main..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff
bin/test-review -d input.diff -o tr-prompt.md
dev-tools/dev-tools/exe/llm-query csonet tr-prompt.md --system dev-handbook/guides/code-review/_test-review-system.md --timeout 300 -o tr-report-csonet.md

# Or review from last release tag to current branch
git diff v.0.2.1+task.61..HEAD -- 'spec/**' ':!spec/cassettes/**' > input.diff
```

## Provider Selection Guide

- **google:gemini-2.5-pro (gpro)**: Excellent at RSpec best practices and test patterns
- **anthropic:claude-4-0-sonnet-latest (csonet)**: Strong at identifying missing test cases  
- **openai:gpt-4o (o4)**: Good at test optimization and performance
- **mistral:mistral-large-latest (mistral)**: Fast reviews for quick test checks

## Output Files Structure

```
dev-taskflow/current/v.X.X.X-release/test_review/task-N/
├── input.diff              # Git diff of spec changes
├── tr-prompt.md            # Generated review prompt  
├── tr-report-gpro.md       # Google Gemini review
├── tr-report-csonet.md     # Claude Sonnet review
├── tr-report-o4.md         # OpenAI GPT-4o review
└── tr-report-mistral.md    # Mistral review
```

## Important Notes

- **Focus**: Only reviews changes in `spec/**` directory (excluding cassettes)
- **Context**: Can include implementation files to verify coverage
- **Exclusions**: Automatically excludes `spec/cassettes/**` VCR recordings
- Use `--include-implementation` flag to verify test coverage completeness
- Use `--timeout 300` for complex test suites to avoid timeouts
- Archive completed reviews in appropriate release folders
- Multiple provider reviews recommended for critical test suites

## Meta-Review for Tests

After running multiple providers, combine and compare their recommendations:

```bash
# Combine all test review reports
dev-tools/dev-tools/exe/llm-query gpro dev-handbook/guides/code-review/_meta-test-review-combine.md \
  --input "tr-report-*.md" \
  --timeout 300 \
  --output tr-meta-review.md
```

## Test Review Focus Areas

The test review specifically analyzes:

1. **RSpec Best Practices**
   - Proper use of contexts and describes
   - Clear test descriptions
   - DRY principle application
   - Appropriate use of let, before, and subject

2. **Test Coverage**
   - Missing edge cases
   - Error condition testing
   - Happy path completeness
   - Integration points

3. **Test Performance**
   - Slow test identification
   - Unnecessary database hits
   - Over-mocking concerns
   - Test isolation issues

4. **Test Maintainability**
   - Brittle test patterns
   - Clear assertions
   - Proper test data setup
   - Readable test structure
