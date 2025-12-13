# Advanced LLM Intelligence Features - Usage Guide

## Overview

The advanced LLM intelligence features provide AI-powered assistance for maintaining documentation:

- **Content Recommendations**: Get specific suggestions for updating documents based on code changes
- **Smart Suggestions**: Analyze document quality (clarity, completeness, consistency)
- **Cross-Document Analysis**: Find inconsistencies across documentation sets
- **Relevance Learning**: Train the system to prioritize recommendations based on your feedback

## Available Commands

| Command | Purpose | Primary Use Case |
|---------|---------|------------------|
| `recommend` | Content update suggestions | After code changes, suggest where to update docs |
| `suggest` | Quality improvement feedback | Review document quality, find gaps |
| `analyze-consistency` | Cross-document validation | Find terminology conflicts, duplicates |
| `feedback` | Relevance training | Teach system what matters for each document |

## Command Types

**Claude Code Commands** (run within Claude Code):
```
/ace:docs recommend architecture.md
/ace:docs suggest guide.md --clarity
```

**Bash CLI Commands** (run in terminal):
```bash
ace-docs recommend docs/architecture.md
ace-docs suggest docs/guide.md --clarity
```

## Command Structure

### Content Recommendations

```bash
ace-docs recommend FILE [OPTIONS]
  --since DATE          # Analyze changes since date (default: doc last-updated)
  --priority LEVEL      # Filter by priority (high/medium/low)
  --format FORMAT       # Output format (text/json)
  --apply               # Interactive mode to apply suggestions
```

**Output Format:**
```
Content Recommendations for docs/architecture.md
Based on changes since 2025-10-14

HIGH PRIORITY (2):
┌─────────────────────────────────────────────────────────┐
│ Add new component to architecture                       │
│ Location: ## Component Architecture (line 45)           │
│ Suggestion: Add ace-docs entry:                         │
│   - ace-docs: Documentation management with LLM         │
│ Reason: New gem added to ecosystem (commit abc123)      │
│ Confidence: 0.85                                        │
└─────────────────────────────────────────────────────────┘

MEDIUM PRIORITY (3):
[... more recommendations ...]

LOW PRIORITY (1):
[... more recommendations ...]
```

### Smart Suggestions

```bash
ace-docs suggest FILE [OPTIONS]
  --clarity             # Check readability and clarity
  --completeness        # Check for missing content
  --consistency         # Check internal consistency
  --all                 # All checks (default)
  --model MODEL         # LLM model to use
  --format FORMAT       # Output format (text/json)
```

**Output Format:**
```
Smart Suggestions for docs/guide.md

CLARITY ISSUES (2):
  HIGH: Section "Installation" uses inconsistent terminology
    → Inconsistent: "gem install", "bundle add", "add to Gemfile"
    → Suggestion: Standardize on one approach or explain differences

  MEDIUM: Complex explanation in "Configuration" section
    → Location: Lines 45-60
    → Suggestion: Break into subsections or add examples

COMPLETENESS GAPS (1):
  HIGH: Missing troubleshooting section
    → Suggestion: Add section with common issues and solutions
    → Expected location: After "Usage Examples"

CONSISTENCY (0):
  ✓ No consistency issues found
```

### Cross-Document Analysis

```bash
ace-docs analyze-consistency [PATTERN] [OPTIONS]
  --type TYPE           # Analysis type (terminology/duplicates/versions/all)
  --fix-terminology     # Suggest terminology standardization
  --detect-duplicates   # Find duplicate content
  --check-versions      # Verify version consistency
```

**Output Format:**
```
Cross-Document Consistency Analysis
Analyzed 12 documents in docs/

TERMINOLOGY CONFLICTS (3):
  "gem" vs "package" (5 documents)
    - docs/architecture.md uses "gem" (15 occurrences)
    - docs/guide.md uses "package" (8 occurrences)
    - Recommendation: Standardize on "gem" (Ruby ecosystem convention)

DUPLICATE CONTENT (2):
  Installation steps duplicated:
    - README.md (lines 42-58)
    - docs/guide.md (lines 10-28)
    - Consolidation: Keep in guide.md, link from README

VERSION INCONSISTENCIES (1):
  README shows v0.3.0, CHANGELOG shows v0.3.2
    - Files: README.md line 12, CHANGELOG.md line 5
    - Recommendation: Update README to v0.3.2

CONSOLIDATION OPPORTUNITIES (1):
  3 documents explain same workflow:
    - docs/workflow-a.md, docs/workflow-b.md, docs/guide.md
    - Recommendation: Create single workflow doc, link from others
```

### Relevance Feedback

```bash
ace-docs feedback --relevant PATTERN [OPTIONS]
ace-docs feedback --irrelevant PATTERN [OPTIONS]
ace-docs feedback --critical PATTERN [OPTIONS]
ace-docs feedback --ignore PATTERN [OPTIONS]
  --document FILE       # Apply to specific document
  --global              # Apply to all documents
```

## Usage Scenarios

### Scenario 1: Update Documentation After Code Changes

**Goal**: Update architecture.md after adding new ace-docs gem

**Steps**:
```bash
# 1. Get recommendations
ace-docs recommend docs/architecture.md

# Output shows:
# HIGH: Add ace-docs to component list
# MEDIUM: Update tool table with ace-docs commands
# LOW: Consider mentioning LLM integration patterns

# 2. Apply recommendations interactively
ace-docs recommend docs/architecture.md --apply

# Interactive prompts:
# Recommendation 1/3 (HIGH): Add ace-docs to component list
# Location: ## ACE Components (line 42)
# Suggestion: Add line:
#   - ace-docs: Documentation management with frontmatter tracking
# Apply this recommendation? (y)es, (n)o, (s)kip, (q)uit: y
# ✓ Applied

# Recommendation 2/3 (MEDIUM): Update tool table
# [... continue through recommendations ...]

# Summary: Applied 2, skipped 1, total 3
```

**Alternative - Review Only**:
```bash
# Just see recommendations without applying
ace-docs recommend docs/architecture.md --format text > recommendations.txt
# Review offline, apply manually
```

### Scenario 2: Improve Document Quality

**Goal**: Improve clarity of installation guide

**Steps**:
```bash
# 1. Check clarity
ace-docs suggest docs/installation.md --clarity

# Output shows:
# HIGH: Inconsistent terminology for "installing gems"
# MEDIUM: Complex explanation of dependency management
# LOW: Missing examples for Gemfile approach

# 2. Check completeness
ace-docs suggest docs/installation.md --completeness

# Output shows:
# HIGH: Missing troubleshooting section
# MEDIUM: No mention of Windows-specific considerations

# 3. Run full analysis
ace-docs suggest docs/installation.md --all

# Combines all suggestions with priorities
```

### Scenario 3: Standardize Documentation Set

**Goal**: Fix terminology inconsistencies across all docs

**Steps**:
```bash
# 1. Analyze terminology
ace-docs analyze-consistency docs/ --type terminology

# Output shows:
# "gem" vs "package": 5 documents affected
# "install" vs "add": 3 documents affected

# 2. Get standardization suggestions
ace-docs analyze-consistency docs/ --fix-terminology

# Output includes recommendations:
# Standardize on "gem" (Ruby convention)
# Standardize on "install" (bundler convention)

# 3. Apply changes manually or via recommendations
ace-docs recommend docs/*.md --priority high
```

### Scenario 4: Train Relevance System

**Goal**: Teach system that test file changes don't affect architecture docs

**Steps**:
```bash
# 1. Mark pattern as irrelevant for architecture docs
ace-docs feedback --irrelevant "test file changes" \
  --document docs/architecture.md

# Output: Feedback stored. Future recommendations will adjust scores.

# 2. Mark pattern as relevant for testing docs
ace-docs feedback --relevant "test file changes" \
  --document docs/testing.md

# 3. Verify learning
ace-docs recommend docs/architecture.md
# Test changes now have lower priority or filtered out

ace-docs recommend docs/testing.md
# Test changes now prioritized higher
```

### Scenario 5: Complex Multi-Document Update

**Goal**: Update all guides after major refactoring

**Steps**:
```bash
# 1. Get recommendations for all guides
for file in docs/guides/*.md; do
  echo "=== $file ==="
  ace-docs recommend "$file" --priority high
done

# 2. Analyze consistency before updates
ace-docs analyze-consistency docs/guides/ --type all

# 3. Apply high-priority recommendations
ace-docs recommend docs/guides/*.md --priority high --apply

# 4. Re-check consistency after updates
ace-docs analyze-consistency docs/guides/ --type all

# 5. Mark common patterns for future learning
ace-docs feedback --relevant "CLI command changes" --document docs/guides/cli.md
ace-docs feedback --relevant "API changes" --document docs/guides/api.md
```

### Scenario 6: Find Duplicate Content

**Goal**: Identify and consolidate duplicate installation instructions

**Steps**:
```bash
# 1. Detect duplicates
ace-docs analyze-consistency docs/ --detect-duplicates

# Output shows:
# Installation steps duplicated in:
#   - README.md (lines 42-58)
#   - docs/quick-start.md (lines 10-28)
#   - docs/installation.md (lines 5-25)

# 2. Review consolidation recommendations
# Output includes:
# Recommendation: Keep comprehensive instructions in docs/installation.md
#                 Use brief version in README.md
#                 Link from quick-start.md to installation.md

# 3. Apply consolidation manually
# (No automatic consolidation in v1)
```

## Command Reference

### recommend

**Syntax**:
```bash
ace-docs recommend FILE [--since DATE] [--priority LEVEL] [--format FORMAT] [--apply]
```

**Parameters**:
- `FILE`: Document to analyze (required)
- `--since DATE`: Analyze changes since date (default: doc's last-updated)
- `--priority LEVEL`: Filter by priority (high, medium, low)
- `--format FORMAT`: Output format (text, json)
- `--apply`: Interactive mode to apply recommendations

**Examples**:
```bash
# Basic recommendations
ace-docs recommend docs/architecture.md

# With custom time range
ace-docs recommend docs/architecture.md --since "1 month ago"

# Only high-priority
ace-docs recommend docs/architecture.md --priority high

# Interactive application
ace-docs recommend docs/architecture.md --apply

# JSON output for processing
ace-docs recommend docs/architecture.md --format json > recommendations.json
```

**Internal Implementation**:
- Uses `git diff` to analyze code changes
- Calls `ace-llm-query` with recommendation prompt
- Applies feedback-based scoring
- Returns prioritized recommendations

### suggest

**Syntax**:
```bash
ace-docs suggest FILE [--clarity] [--completeness] [--consistency] [--all] [--model MODEL] [--format FORMAT]
```

**Parameters**:
- `FILE`: Document to analyze (required)
- `--clarity`: Check readability and clarity
- `--completeness`: Check for missing content
- `--consistency`: Check internal consistency
- `--all`: All checks (default)
- `--model MODEL`: LLM model to use
- `--format FORMAT`: Output format (text, json)

**Examples**:
```bash
# All suggestions
ace-docs suggest docs/guide.md

# Clarity only
ace-docs suggest docs/guide.md --clarity

# Multiple modes
ace-docs suggest docs/guide.md --clarity --completeness

# Use specific model
ace-docs suggest docs/guide.md --model gpt-4 --all

# JSON output
ace-docs suggest docs/guide.md --format json
```

**Internal Implementation**:
- Loads document content
- Calls `ace-llm-query` with mode-specific prompt (temperature 0.7)
- Parses suggestions into structured format
- Groups by severity (HIGH/MEDIUM/LOW)

### analyze-consistency

**Syntax**:
```bash
ace-docs analyze-consistency [PATTERN] [--type TYPE] [--fix-terminology] [--detect-duplicates] [--check-versions]
```

**Parameters**:
- `PATTERN`: Document pattern to analyze (default: all managed docs)
- `--type TYPE`: Analysis type (terminology, duplicates, versions, all)
- `--fix-terminology`: Suggest terminology standardization
- `--detect-duplicates`: Find duplicate content
- `--check-versions`: Verify version consistency

**Examples**:
```bash
# Analyze all docs
ace-docs analyze-consistency

# Specific directory
ace-docs analyze-consistency docs/guides/

# Terminology only
ace-docs analyze-consistency docs/ --type terminology

# All analysis types
ace-docs analyze-consistency docs/ --type all

# With terminology fix suggestions
ace-docs analyze-consistency docs/ --fix-terminology
```

**Internal Implementation**:
- Loads document set matching pattern
- Pre-analysis with TerminologyExtractor (local, fast)
- Calls `ace-llm-query` for deep semantic analysis (temperature 0.3)
- Combines results into ConsistencyReport
- Caches report in `.cache/ace-docs/consistency-{timestamp}.md`

### feedback

**Syntax**:
```bash
ace-docs feedback {--relevant|--irrelevant|--critical|--ignore} PATTERN [--document FILE] [--global]
```

**Parameters**:
- `PATTERN`: Change pattern to mark (required)
- `--relevant`: Increase weight for similar changes (+0.2)
- `--irrelevant`: Decrease weight for similar changes (-0.2)
- `--critical`: Mark pattern as always relevant (+0.5)
- `--ignore`: Mark pattern as always irrelevant (filter out)
- `--document FILE`: Apply to specific document
- `--global`: Apply to all documents

**Examples**:
```bash
# Mark relevant for specific doc
ace-docs feedback --relevant "test changes" --document docs/testing.md

# Mark irrelevant globally
ace-docs feedback --irrelevant "formatting changes" --global

# Critical pattern
ace-docs feedback --critical "API breaking changes" --global

# Ignore pattern
ace-docs feedback --ignore "whitespace changes" --global
```

**Internal Implementation**:
- Validates pattern (must be valid regex)
- Stores in `.ace/docs/feedback.yml`
- Format: `{pattern, type, scope, timestamp}`
- Applied automatically in future `recommend` calls
- Affects confidence scoring and filtering

## Tips and Best Practices

### Recommendations

**Getting Quality Recommendations**:
- Keep documents up-to-date with `last-updated` frontmatter
- Use `--since` flag to focus on recent changes
- Start with `--priority high` to avoid noise
- Use feedback to tune recommendations over time

**Interactive Mode**:
- Review all HIGH priority first: `--priority high --apply`
- Use (s)kip for recommendations to review later
- Use (q)uit to stop and save progress
- Track applied count in output summary

**Avoiding Noise**:
- Mark irrelevant patterns with `feedback --irrelevant`
- Use `feedback --ignore` for consistently irrelevant changes
- Focus recommendations with `--since` time ranges

### Suggestions

**Best Analysis Modes**:
- Start with `--all` for comprehensive view
- Use `--clarity` for user-facing docs (guides, README)
- Use `--completeness` for reference docs (API, architecture)
- Use `--consistency` for multi-section docs (design, workflows)

**Interpreting Results**:
- HIGH severity: Address immediately
- MEDIUM severity: Plan for next update cycle
- LOW severity: Nice-to-have improvements

**Iterative Improvement**:
- Run suggestions periodically (weekly/monthly)
- Track improvements over time
- Focus on one type per session

### Cross-Document Analysis

**When to Run**:
- Before major releases (terminology alignment)
- After large refactors (version consistency)
- Periodically (monthly) for documentation health

**Large Document Sets**:
- Use `--type` to focus analysis (faster, clearer results)
- Start with `--type terminology` (most common issue)
- Run `--type duplicates` when consolidating docs
- Use `--type versions` before releases

**Performance Optimization**:
- Analyze specific directories: `docs/guides/` not `docs/`
- Use glob patterns: `docs/**/*.md` to filter
- Batch large sets (>20 docs) automatically handled

### Relevance Learning

**Training Strategy**:
- Mark patterns immediately when noticed
- Use `--document` for document-specific patterns
- Use `--global` for universal patterns
- Balance: relevant (+0.2) and irrelevant (-0.2) conservatively

**Pattern Types**:
- File patterns: "test file changes", "markdown formatting"
- Commit patterns: "refactoring", "bug fixes"
- Content patterns: "dependency updates", "config changes"

**Resetting Learning**:
- Edit `.ace/docs/feedback.yml` manually
- Delete file to reset all feedback
- Future: `--reset-feedback` flag (v0.5.0)

## Troubleshooting

### ace-llm-query Not Found

**Error**:
```
Error: Semantic validation unavailable (ace-llm-query not found)
Install ace-llm gem to enable semantic validation.
```

**Solution**:
```bash
# Install ace-llm gem
gem install ace-llm

# Or add to Gemfile
bundle add ace-llm

# Verify installation
ace-llm-query --version
```

### LLM API Timeout

**Error**:
```
Error: LLM API timeout after 30s
Suggestion: Try again in a few minutes or use --model with faster model
```

**Solutions**:
1. Wait and retry (rate limiting)
2. Use faster model: `--model gflash`
3. Reduce document set size
4. Check internet connection

### No Recommendations Generated

**Issue**: `ace-docs recommend` returns "No recommendations at this time"

**Possible Causes**:
1. Document is up-to-date (no changes since last-updated)
   - Solution: Check `git log --since <last-updated>`
2. Feedback has marked all patterns as irrelevant
   - Solution: Review `.ace/docs/feedback.yml`
3. LLM found no significant changes
   - Solution: Use `--since` to expand time range

### Parsing Failures

**Error**:
```
Warning: Could not parse LLM response
Showing raw output:
[... raw LLM response ...]
```

**Solutions**:
1. Check if LLM response is valid (manual review)
2. Retry command (LLM responses vary)
3. Report issue if persistent

### Interactive Mode Issues

**Issue**: Interactive prompts not working correctly

**Solutions**:
1. Check terminal supports interactive input
2. Verify stdin is not redirected
3. Use non-interactive mode: remove `--apply`
4. Update ace-docs to latest version

### Large Document Sets Slow

**Issue**: `analyze-consistency` takes >5 minutes on 50+ docs

**Solutions**:
1. Use `--type` to focus: `--type terminology`
2. Analyze subdirectories separately
3. Use glob patterns to filter
4. Batch processing automatic (wait for progress)
5. Results cached - subsequent runs faster

### Feedback Not Affecting Recommendations

**Issue**: Marked patterns as irrelevant but still appear

**Possible Causes**:
1. Pattern doesn't match exactly
   - Solution: Review pattern syntax in `.ace/docs/feedback.yml`
2. Document scope incorrect
   - Solution: Check `document_scope` field
3. Confidence override (pattern marked critical elsewhere)
   - Solution: Review global patterns

**Debug**:
```bash
# Check feedback file
cat .ace/docs/feedback.yml

# Verify pattern matching
ace-docs recommend docs/test.md --format json | jq '.confidence_scores'

# Clear and retry
rm .ace/docs/feedback.yml
ace-docs feedback --irrelevant "pattern" --document docs/test.md
ace-docs recommend docs/test.md
```

## Migration Notes

### From analyze Command

**Before (task.071)**:
```bash
ace-docs analyze --needs-update
```

**Now (task.074)**:
```bash
# Batch analysis still available
ace-docs analyze --needs-update

# Plus new recommendation system
ace-docs recommend docs/architecture.md
```

**Key Differences**:
- `analyze`: Batch diff compaction for multiple documents
- `recommend`: Specific actionable suggestions for single document
- Both use LLM but different prompts and outputs

### From validate --semantic

**Before (task.073)**:
```bash
ace-docs validate docs/file.md --semantic
```

**Now (task.074)**:
```bash
# Semantic validation still available
ace-docs validate docs/file.md --semantic

# Plus new suggestion system
ace-docs suggest docs/file.md --all
```

**Key Differences**:
- `validate --semantic`: Pass/fail validation
- `suggest`: Detailed improvement suggestions
- Suggestions more actionable and specific

## Example Workflows

### Weekly Documentation Maintenance

```bash
#!/bin/bash
# weekly-docs-update.sh

# 1. Check which docs need updating
ace-docs status --needs-update

# 2. Get recommendations for stale docs
ace-docs recommend docs/architecture.md --priority high
ace-docs recommend docs/tools.md --priority high

# 3. Run quality checks
ace-docs suggest docs/README.md --completeness
ace-docs suggest docs/guide.md --clarity

# 4. Check cross-document consistency
ace-docs analyze-consistency docs/ --type terminology

# 5. Apply critical updates interactively
ace-docs recommend docs/architecture.md --priority high --apply
```

### Pre-Release Documentation Review

```bash
#!/bin/bash
# pre-release-docs-review.sh

# 1. Check version consistency
ace-docs analyze-consistency docs/ --check-versions

# 2. Find duplicate content to consolidate
ace-docs analyze-consistency docs/ --detect-duplicates

# 3. Standardize terminology
ace-docs analyze-consistency docs/ --fix-terminology

# 4. Get all high-priority recommendations
for file in docs/*.md; do
  ace-docs recommend "$file" --priority high
done

# 5. Final quality check
for file in docs/*.md; do
  ace-docs suggest "$file" --all
done
```

### New Developer Documentation Audit

```bash
#!/bin/bash
# new-dev-docs-audit.sh

# 1. Check completeness of getting-started docs
ace-docs suggest docs/quick-start.md --completeness
ace-docs suggest docs/installation.md --completeness

# 2. Check clarity of guides
ace-docs suggest docs/guides/*.md --clarity

# 3. Find missing sections
ace-docs suggest docs/architecture.md --completeness

# 4. Cross-reference consistency
ace-docs analyze-consistency docs/ --type all
```
