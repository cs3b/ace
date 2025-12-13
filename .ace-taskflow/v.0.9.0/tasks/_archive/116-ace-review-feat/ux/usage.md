# GitHub Pull Request Review Mode - Usage Guide

## Overview

The PR review mode enables ace-review to directly analyze GitHub Pull Requests by integrating with the GitHub CLI (`gh`). This eliminates manual diff extraction and enables automated PR review workflows.

**Available Features:**
- Fetch PR diffs automatically using `gh` CLI
- Review PRs using standard ace-review presets
- Post review feedback as PR comments
- Support for multiple PR identifier formats
- Local caching of review results

**Key Benefits:**
- Seamless integration with existing GitHub workflows
- Automated PR reviews for AI agents
- Consistent review quality using presets
- Offline review capability via cached diffs

## Command Types

**Bash CLI Commands** (executed in terminal):
```bash
ace-review --pr <identifier> [options]
```

These commands execute in your shell and interact with GitHub via the `gh` CLI tool.

## Command Structure

### Basic Invocation

```bash
# Review a pull request by number
ace-review --pr <PR_NUMBER>

# Review using specific preset
ace-review --pr <PR_NUMBER> --preset <PRESET_NAME>

# Review and post comment to GitHub
ace-review --pr <PR_NUMBER> --post-comment

# Dry run (show what would be posted without posting)
ace-review --pr <PR_NUMBER> --post-comment --dry-run
```

### PR Identifier Formats

The `--pr` flag accepts multiple identifier formats:

```bash
# PR number (uses current repository context)
ace-review --pr 123

# Full GitHub URL
ace-review --pr https://github.com/owner/repo/pull/123

# Owner/repo#number format
ace-review --pr owner/repo#123
```

### Options and Flags

- `--pr <identifier>` - PR identifier (number, URL, or owner/repo#number)
- `--preset <name>` - Review preset to use (default: pr)
- `--post-comment` - Post review as PR comment
- `--dry-run` - Prepare review without executing/posting
- `--auto-execute` - Execute LLM analysis automatically
- `--model <model>` - Override LLM model
- `--verbose` - Enable detailed output

## Usage Scenarios

### Scenario 1: Quick PR Review (Local Only)

**Goal**: Review a PR and save results locally for inspection

```bash
# Navigate to repository
cd /path/to/project

# Review PR #123 using default preset
ace-review --pr 123

# Expected output:
# Fetching PR #123 diff...
# ✓ PR diff retrieved (245 lines, 3 files changed)
# Analyzing code with preset 'pr'...
# ✓ Review completed. Results saved to .cache/ace-review/sessions/pr-review-20251116-140530/
#   System prompt: .cache/ace-review/sessions/pr-review-20251116-140530/system.prompt.md
#   User prompt: .cache/ace-review/sessions/pr-review-20251116-140530/user.prompt.md
#
# To execute with LLM:
#   ace-llm query --file .cache/ace-review/sessions/pr-review-20251116-140530/user.prompt.md --context .cache/ace-review/sessions/pr-review-20251116-140530/system.prompt.md
```

### Scenario 2: Security-Focused PR Review

**Goal**: Review PR for security vulnerabilities using security preset

```bash
# Review with security preset
ace-review --pr 456 --preset security --auto-execute

# Expected output:
# Fetching PR #456 diff...
# ✓ PR diff retrieved (89 lines, 2 files changed)
# Analyzing code with preset 'security'...
# Executing LLM review with model 'google:gemini-2.5-flash'...
# ✓ Review completed and saved to .cache/ace-review/sessions/pr-review-20251116-141203/review-report-gemini-2.5-flash.md
#
# Security Review Summary:
# - Authentication: 1 issue found
# - Input validation: 2 recommendations
# - Dependencies: All clear
```

### Scenario 3: Review and Post Comment

**Goal**: Review PR and automatically post feedback as GitHub comment

```bash
# Review and post comment
ace-review --pr 789 --preset architecture --post-comment --auto-execute

# Expected output:
# Fetching PR #789 diff...
# ✓ PR diff retrieved (512 lines, 8 files changed)
# Analyzing code with preset 'architecture'...
# Executing LLM review...
# ✓ Review completed
# Posting comment to PR #789...
# ✓ Review posted to PR #789: https://github.com/owner/repo/pull/789#issuecomment-123456
```

### Scenario 4: Cross-Repository PR Review

**Goal**: Review a PR from a different repository

```bash
# Review PR from external repository
ace-review --pr external-org/external-repo#42 --auto-execute

# Expected output:
# Fetching PR external-org/external-repo#42 diff...
# ✓ PR diff retrieved (178 lines, 5 files changed)
# Analyzing code with preset 'pr'...
# ✓ Review completed. Results saved to .cache/ace-review/sessions/pr-review-20251116-142045/
```

### Scenario 5: Dry Run Before Posting

**Goal**: Preview what would be posted without actually posting

```bash
# Dry run to preview comment
ace-review --pr 123 --post-comment --dry-run --auto-execute

# Expected output:
# Fetching PR #123 diff...
# ✓ PR diff retrieved (67 lines, 2 files changed)
# Analyzing code with preset 'pr'...
# ✓ Review completed
#
# [DRY RUN] Would post the following comment to PR #123:
# ----------------------------------------
# ## Code Review - ace-review
#
# **Preset**: pr
# **Model**: google:gemini-2.5-flash
# **Generated**: 2025-11-16 14:25:30
#
# ### Summary
# [Review content here...]
# ----------------------------------------
#
# To post this comment, run without --dry-run
```

### Scenario 6: Error Handling - Not Authenticated

**Goal**: Understand authentication requirements

```bash
# Attempt to review without GitHub authentication
ace-review --pr 123

# Expected output:
# Fetching PR #123 diff...
# ✗ Failed to fetch PR: GitHub authentication required
#
# Run 'gh auth login' to authenticate with GitHub
# Or check authentication status: gh auth status
```

## Command Reference

### ace-review --pr

**Syntax**:
```bash
ace-review --pr <identifier> [--preset <name>] [--post-comment] [--dry-run] [options]
```

**Parameters**:
- `<identifier>` (required) - PR number, URL, or owner/repo#number
- `--preset <name>` (optional) - Review preset (default: pr)
- `--post-comment` (optional) - Post review as PR comment
- `--dry-run` (optional) - Prepare without executing/posting
- `--auto-execute` (optional) - Execute LLM automatically
- `--model <model>` (optional) - Override LLM model
- `--verbose` (optional) - Enable detailed output

**Input Formats**:
- PR number: `123`
- Full URL: `https://github.com/owner/repo/pull/123`
- Qualified reference: `owner/repo#123`

**Output**:
- Success: Session directory path and review file locations
- Success with comment: GitHub comment URL
- Error: Clear error message with resolution steps

**Internal Implementation**:
The command uses:
1. `gh pr diff <identifier>` to fetch PR diff
2. `gh pr view <identifier> --json` to fetch PR metadata
3. `gh pr comment <identifier> --body-file` to post comments
4. Standard ace-review pipeline for LLM analysis
5. ace-context for content aggregation

**Exit Codes**:
- `0` - Success
- `1` - Error (authentication, network, invalid PR, etc.)

## Tips and Best Practices

### Authentication Setup

Ensure `gh` CLI is authenticated before using PR review mode:

```bash
# Check authentication status
gh auth status

# Login if needed
gh auth login

# Verify access to target repository
gh repo view owner/repo
```

### Performance Optimization

For large PRs, consider reviewing specific files:

```bash
# Review only Ruby files in a large PR
ace-review --pr 123 --subject 'files: ["lib/**/*.rb"]'
```

### Preset Selection

Choose appropriate presets for different review types:

- `pr` - General PR review (default)
- `security` - Security-focused review
- `architecture` - Architecture and design review
- `docs` - Documentation review
- Custom presets in `.ace/review/presets/`

### Caching and Offline Review

Reviews are cached in `.cache/ace-review/sessions/pr-review-*/`:

```bash
# Initial review (fetches from GitHub)
ace-review --pr 123 --auto-execute

# Later inspection (uses cached files)
cat .cache/ace-review/sessions/pr-review-*/review-report-*.md
```

### Error Recovery

Common issues and solutions:

**Issue**: `gh: command not found`
```bash
# Install GitHub CLI
brew install gh  # macOS
# See https://cli.github.com/manual/installation for other platforms
```

**Issue**: `PR #999 not found`
```bash
# Verify PR exists and you have access
gh pr view 999
```

**Issue**: `Rate limit exceeded`
```bash
# Check rate limit status
gh api rate_limit

# Wait for reset or use authentication token with higher limits
```

## Troubleshooting

### Debugging Failed Requests

Enable verbose output to see detailed execution:

```bash
ace-review --pr 123 --verbose
```

### Validating gh CLI Integration

Test `gh` CLI commands independently:

```bash
# Test diff fetching
gh pr diff 123

# Test PR metadata retrieval
gh pr view 123 --json number,state,isDraft,title

# Test comment posting (dry run)
echo "Test comment" | gh pr comment 123 --body-file -
```

### Network Issues

For network failures, the tool retries with exponential backoff (3 attempts). If persistent:

```bash
# Check GitHub API status
curl -I https://api.github.com/

# Verify network connectivity
gh api /user
```

## Migration Notes

This feature adds new functionality without replacing existing ace-review capabilities:

**Existing Workflows** (still work):
```bash
ace-review --preset pr  # Reviews local changes
ace-review --subject 'diff: {ranges: ["HEAD~5..HEAD"]}'  # Reviews git range
```

**New PR Workflow**:
```bash
ace-review --pr 123  # Reviews GitHub PR
```

**Key Differences**:
- `--pr` mode fetches diff from GitHub, not local git
- Requires `gh` CLI authentication
- Supports `--post-comment` for GitHub integration
- PR metadata (state, draft status) included in review context
