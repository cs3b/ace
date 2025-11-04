# ace-review Context.md Enhancement - Usage Documentation

## Overview

The enhanced ace-review provides transparent, reproducible review sessions by adopting ace-docs' proven context.md pattern. Every review session now creates a context.md file that captures the complete configuration, enabling exact session reproduction.

## Key Features

- **Context.md Creation**: Automatic generation of context.md with YAML frontmatter for every review session
- **Full ace-context Integration**: Leverages ace-context for all content loading (files, presets, diffs, commands)
- **Session Reproducibility**: Re-run any review by loading the saved context.md file
- **Location-Based Naming**: Cache folders use clean filenames, release folders use .tmp extensions
- **Fail-Fast Error Handling**: Clear error messages when ace-context is unavailable or fails
- **Transparent Configuration**: All context sources visible in a single human-readable file

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

# Output shows session location:
# Review saved to .ace-taskflow/v.0.9.0/reviews/review-20251101-153000/review-report-gpro.md

# Step 2: Reproduce the exact review later
ace-context .ace-taskflow/v.0.9.0/reviews/review-20251101-153000/context.md.tmp

# Step 3: Share context.md.tmp with team for identical reviews
cat .ace-taskflow/v.0.9.0/reviews/review-20251101-153000/context.md.tmp
```

**Expected Output Structure (Release Folder)**:
```
.ace-taskflow/v.0.9.0/reviews/review-20251101-153000/
├── context.md.tmp          # Complete session configuration
├── prompt-system.md.tmp    # System prompt
├── prompt-user.md.tmp      # Embedded content from ace-context
├── subject.md.tmp          # Extracted diffs
├── review-report-gpro.md   # LLM-generated review (model: gpro)
└── metadata.yml            # Session metadata
```

**Expected Output Structure (Cache Folder)**:
```
.cache/ace-review/review-20251101-153000/
├── context.md              # Complete session configuration (no .tmp)
├── prompt-system.md        # System prompt (no .tmp)
├── prompt-user.md          # Embedded content from ace-context (no .tmp)
├── subject.md              # Extracted diffs (no .tmp)
├── review-report-gpro.md   # LLM-generated review (model: gpro)
└── metadata.yml            # Session metadata
```

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
# Step 1: Locate the failed session
session_dir=".ace-taskflow/v.0.9.0/reviews/review-20251101-160000"

# Step 2: Examine the context.md.tmp to see what was loaded
cat "$session_dir/context.md.tmp"

# Step 3: Check what ace-context actually embedded
cat "$session_dir/prompt-user.md.tmp" | head -100

# Step 4: Verify the subject diff
cat "$session_dir/subject.md.tmp" | head -50

# Step 5: Re-run with debugging
ace-context "$session_dir/context.md.tmp" --debug
```

## Command Reference

### Review Session Artifacts

Every review session creates these files:

**In Release Folders** (e.g., `.ace-taskflow/v.0.9.0/reviews/`):

| File | Purpose | Format |
|------|---------|--------|
| `context.md.tmp` | Session configuration with YAML frontmatter | Markdown with YAML frontmatter |
| `prompt-system.md.tmp` | System prompt instructions | Markdown |
| `prompt-user.md.tmp` | Embedded content from ace-context | XML-embedded markdown |
| `subject.md.tmp` | Git diff content (if applicable) | Unified diff format |
| `review-report-{model}.md` | LLM-generated review output (model slug appended) | Markdown with frontmatter |
| `metadata.yml` | Session metadata and statistics | YAML |

**In Cache Folders** (e.g., `.cache/ace-review/`):

| File | Purpose | Format |
|------|---------|--------|
| `context.md` | Session configuration (no .tmp extension) | Markdown with YAML frontmatter |
| `prompt-system.md` | System prompt instructions (no .tmp) | Markdown |
| `prompt-user.md` | Embedded content from ace-context (no .tmp) | XML-embedded markdown |
| `subject.md` | Git diff content (no .tmp) | Unified diff format |
| `review-report-{model}.md` | LLM-generated review output | Markdown with frontmatter |
| `metadata.yml` | Session metadata and statistics | YAML |

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

1. **Session Organization**: Review sessions are timestamped and stored in `.ace-taskflow/v.0.9.0/reviews/` (release) or `.cache/ace-review/` (cache). Clean old sessions periodically.

2. **Location-Based Naming**: Release folders use .tmp extensions for session files, cache folders use clean names. This follows the ace-docs pattern consistently.

3. **Context Optimization**: Use specific presets rather than loading all project files to reduce token usage.

4. **Reproducibility**: Share the context.md.tmp file with team members for consistent review perspective. They can load it with `ace-context path/to/context.md.tmp`.

5. **Fail-Fast Philosophy**: If ace-context is unavailable or fails, ace-review will error immediately with clear guidance. This prevents silent degradation and ensures reviews are complete.

6. **Debugging**: If reviews fail, check:
   - ace-context availability: `which ace-context`
   - Context preset exists: `ace-context --list`
   - Git range is valid: `git log origin/main...HEAD --oneline`
   - Session files for error details: `cat .ace-taskflow/v.0.9.0/reviews/review-*/metadata.yml`

## Migration from Previous Versions

The CLI interface remains unchanged - existing commands work identically. The key differences are:

| Aspect | Before | After |
|--------|--------|-------|
| Context extraction | Internal ContextExtractor | Delegates to ace-context via ContextComposer |
| Session files | prompt.md.tmp, context.md.tmp | context.md.tmp, prompt-system.md.tmp, prompt-user.md.tmp, subject.md.tmp |
| File naming | Single .tmp pattern | Location-based: .tmp (release), clean (cache) |
| Review output | review.md | review-report-{model-slug}.md |
| Reproducibility | Not supported | Full reproduction via context.md.tmp |
| Error handling | Fallback to empty | Fail-fast with clear error messages |

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
- YAML syntax in context.md.tmp is valid
- Files referenced in context exist and are readable

**Large diffs causing timeouts**:
```bash
# Use path filters to reduce diff size
ace-review --preset pr \
  --subject 'diff: {ranges: ["origin/main...HEAD"], paths: ["lib/**/*.rb"]}' \
  --auto-execute
```

**Location detection issues**:
If files are created with wrong extensions (.tmp vs clean):
- Release folders (.ace-taskflow/, project folders): Should have .tmp
- Cache folders (.cache/): Should have clean names
- Check session creation location in debug output

## Internal Implementation Notes

The enhanced ace-review uses:
- **ContextComposer** molecule for generating context.md files with YAML frontmatter
- **ContextExtractor** delegates to ContextComposer for composition
- `Ace::Context.load_file_as_preset()` for loading and embedding context
- ace-context's markdown-xml format for content embedding
- **Location-based naming**: Detects cache vs release folders, applies appropriate extensions
- **Fail-fast error handling**: Errors immediately if ace-context unavailable or fails
- Delegates all file reading, git operations, and command execution to ace-context
- Preserves backward compatibility with existing CLI interface
- **Review output naming**: Appends model slug to review-report (e.g., review-report-gpro.md)