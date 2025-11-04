# ace-review Context.md Enhancement - Usage Documentation

## Overview

The enhanced ace-review provides transparent, reproducible review sessions by adopting ace-docs' proven context.md pattern. Every review session now creates a context.md file that captures the complete configuration, enabling exact session reproduction.

## Key Features

- **Context.md Creation**: Automatic generation of context.md with YAML frontmatter for every review session
- **Full ace-context Integration**: Leverages ace-context for all content loading (files, presets, diffs, commands)
- **Session Reproducibility**: Re-run any review by loading the saved context.md file from cache
- **Cache-First Storage**: Working files in `.cache/ace-review/`, final reports in release folder (same location as current)
- **Fail-Fast Error Handling**: Clear error messages when ace-context is unavailable or fails
- **Transparent Configuration**: All context sources visible in a single human-readable file
- **Backward Compatible**: ace-review returns release folder path (unchanged from current behavior)

## Command Structure

### Basic Review Commands (Unchanged)

```bash
# Review PR changes against main branch
ace-review --preset pr --auto-execute

# Security review with specific files
ace-review --preset security --subject 'files: ["lib/**/*.rb"]' --context 'presets: [project]'

# Review recent commits with Ruby ATOM pattern checks
ace-review --preset ruby-atom --subject 'recent-commits: 5'

# Review staged changes
ace-review --preset code --subject staged --auto-execute
```


## Usage Scenarios

### Scenario 1: Standard PR Review with Reproducibility

**Goal**: Review changes in your feature branch and save the session for team reference

```bash
# Step 1: Run the review
ace-review --preset pr --auto-execute

# Output shows release folder location (same as current):
# Review saved to .ace-taskflow/v.0.9.0/reviews/review-20251101-153000/review-report-gpro.md

# Step 2: Reproduce the exact review later (from cache)
ace-context .cache/ace-review/sessions/review-20251101-153000/context.md

# Step 3: Share context.md from cache for identical reviews
cat .cache/ace-review/sessions/review-20251101-153000/context.md
```

**Cache Structure** (Working Files - `.cache/ace-review/sessions/review-20251101-153000/`):
```
├── context.md              # Complete session configuration
├── prompt-system.md        # System prompt
├── prompt-user.md          # Embedded content from ace-context
├── subject.md              # Extracted diffs
├── review-report-gpro.md   # LLM-generated review
└── metadata.yml            # Session metadata
```

**Release Structure** (Final Reports - `.ace-taskflow/v.0.9.0/reviews/review-20251101-153000/`):
```
├── review-report-gpro.md   # Final report (copied from cache)
└── metadata.yml            # Session metadata (copied from cache)
```

**Note**: ace-review returns the release folder path (backward compatible)

### Scenario 2: Custom Context Loading

**Goal**: Review with specific project documentation loaded

```bash
# Create a custom context configuration
cat > review-context.yml <<EOF
context:
  params:
    format: markdown-xml
  presets: [project, testing]
  files:
    - docs/api.md
    - docs/security.md
  commands:
    - git log --oneline -10
EOF

# Run review with custom context
ace-review --preset security \
  --subject 'diff: {ranges: ["origin/main...HEAD"]}' \
  --context "$(cat review-context.yml)" \
  --auto-execute
```

### Scenario 3: Debugging a Failed Review

**Goal**: Understand why a review session failed or produced unexpected results

```bash
# Step 1: Locate the failed session in cache
cache_dir=".cache/ace-review/sessions/review-20251101-160000"

# Step 2: Examine the context.md to see what was loaded
cat "$cache_dir/context.md"

# Step 3: Check what ace-context actually embedded
cat "$cache_dir/prompt-user.md" | head -100

# Step 4: Verify the subject diff
cat "$cache_dir/subject.md" | head -50

# Step 5: Re-run with debugging
ace-context "$cache_dir/context.md" --debug
```

## Command Reference

### Review Session Artifacts

Every review session creates files in two locations:

**Cache Location** (`.cache/ace-review/sessions/` - All working files):

| File | Purpose | Format |
|------|---------|--------|
| `context.md` | Session configuration with YAML frontmatter | Markdown with YAML frontmatter |
| `prompt-system.md` | System prompt instructions | Markdown |
| `prompt-user.md` | Embedded content from ace-context | XML-embedded markdown |
| `subject.md` | Git diff content (if applicable) | Unified diff format |
| `review-report-{model}.md` | LLM-generated review output | Markdown with frontmatter |
| `metadata.yml` | Session metadata and statistics | YAML |

**Release Location** (`.ace-taskflow/v.0.9.0/reviews/` - Final reports only):

| File | Purpose | Format |
|------|---------|--------|
| `review-report-{model}.md` | Final review report (copied from cache) | Markdown with frontmatter |
| `metadata.yml` | Session metadata (copied from cache) | YAML |

### Context.md Structure

```markdown
---
context:
  params:
    format: markdown-xml
  presets: [project]
  files:
    - /absolute/path/to/subject.diff
  diffs:
    - range: origin/main...HEAD
---

# Review Instructions

[Base instructions from preset]

## Review Scope

**Context files** (for understanding the codebase):
- Loaded from preset: `project`

**Subject of review** (git diff filtered to):
- All changes in current branch
```

## Tips and Best Practices

1. **Session Organization**:
   - Working files stored in `.cache/ace-review/sessions/` (automatically gitignored)
   - Final reports in `.ace-taskflow/v.0.9.0/reviews/` (user can commit for history)
   - Clean old cache sessions periodically: `rm -rf .cache/ace-review/sessions/review-2024*`

2. **Cache-First Benefits**:
   - Working files never clutter release folder
   - Only final reports need git tracking
   - Simpler gitignore (just `.cache`)

3. **Context Optimization**: Use specific presets rather than loading all project files to reduce token usage.

4. **Reproducibility**: Share the context.md file from cache for consistent reviews:
   ```bash
   ace-context .cache/ace-review/sessions/review-*/context.md
   ```

5. **Fail-Fast Philosophy**: If ace-context is unavailable or fails, ace-review will error immediately with clear guidance. This prevents silent degradation and ensures reviews are complete.

6. **Debugging**: If reviews fail, check:
   - ace-context availability: `which ace-context`
   - Context preset exists: `ace-context --list`
   - Git range is valid: `git log origin/main...HEAD --oneline`
   - Cache files for details: `cat .cache/ace-review/sessions/review-*/metadata.yml`

## Migration from Previous Versions

The CLI interface remains unchanged - existing commands work identically. The key differences are:

| Aspect | Before | After |
|--------|--------|-------|
| Context extraction | Internal ContextExtractor | Delegates to ace-context via ContextComposer |
| Session location | Release folder only | Cache for working files, release for final reports |
| Working files | Stored with .tmp in release | Stored in `.cache/ace-review/` (no .tmp needed) |
| Final reports | review.md in release | review-report-{model}.md in release (copied from cache) |
| Output path | Release folder path | Release folder path (unchanged - backward compatible) |
| Reproducibility | Not supported | Full reproduction via cache context.md |
| Error handling | Fallback to empty | Fail-fast with clear error messages |
| Gitignore | **/*.tmp pattern | .cache directory |

## Troubleshooting

**ace-context not found**:
```bash
# Install ace-context gem
gem install ace-context
# Or add to Gemfile
bundle add ace-context

# Verify installation
which ace-context
ace-context --version
```

**Context preset not loading**:
```bash
# List available presets
ace-context --list

# Test preset loading
ace-context project --output stdio

# Debug preset loading
ace-context project --debug
```

**Review fails with ace-context error**:
ace-review now fails fast with clear error messages. Check:
- ace-context is installed and in PATH
- Preset exists: `ace-context --list | grep project`
- YAML syntax in cache context.md is valid
- Files referenced in context exist and are readable

**Large diffs causing timeouts**:
```bash
# Use path filters to reduce diff size
ace-review --preset pr \
  --subject 'diff: {ranges: ["origin/main...HEAD"], paths: ["lib/**/*.rb"]}' \
  --auto-execute
```

**Cache directory issues**:
If cache directory cannot be created:
- Check permissions on project root
- Ensure `.cache` is not a file
- Manually create: `mkdir -p .cache/ace-review/sessions`

**Release folder unavailable**:
If ace-taskflow is not available or release path cannot be determined:
- Reports saved to cache only
- ace-review will warn but continue
- Access reports from `.cache/ace-review/sessions/review-*/`

## Internal Implementation Notes

The enhanced ace-review uses:
- **ContextComposer** molecule for generating context.md files with YAML frontmatter in cache
- **ContextExtractor** delegates to ContextComposer for composition
- `Ace::Context.load_file_as_preset()` for loading and embedding context
- ace-context's markdown-xml format for content embedding
- **Cache-first storage**: All working files in `.cache/ace-review/sessions/`
- **Report copying**: Final reports copied to release folder (if available)
- **Fail-fast error handling**: Errors immediately if ace-context unavailable or fails
- Delegates all file reading, git operations, and command execution to ace-context
- Preserves backward compatibility: Returns release folder path (same as current)
- **Review output naming**: Appends model slug to review-report (e.g., review-report-gpro.md)