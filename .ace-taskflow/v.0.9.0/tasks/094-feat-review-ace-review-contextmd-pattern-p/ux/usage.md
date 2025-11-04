# ace-review Context.md Enhancement - Usage Documentation

## Overview

The enhanced ace-review provides transparent, reproducible review sessions by adopting ace-docs' proven context.md pattern. Every review session now creates a context.md file that captures the complete configuration, enabling exact session reproduction. Additionally, a new PR workflow guides users through generating pull request descriptions.

## Key Features

- **Context.md Creation**: Automatic generation of context.md with YAML frontmatter for every review session
- **Full ace-context Integration**: Leverages ace-context for all content loading (files, presets, diffs, commands)
- **Session Reproducibility**: Re-run any review by loading the saved context.md file
- **PR Description Generation**: New preset and workflow for creating GitHub pull request descriptions
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

### PR Description Generation

```bash
# Generate PR description for current branch
ace-review --preset pr-description --auto-execute

# Generate with custom diff range
ace-review --preset pr-description --subject 'diff: {ranges: ["develop...HEAD"]}' --auto-execute

# Generate with additional context
ace-review --preset pr-description \
  --subject 'diff: {ranges: ["origin/main...HEAD"]}' \
  --context 'presets: [project, architecture]' \
  --auto-execute
```

## Usage Scenarios

### Scenario 1: Standard PR Review with Reproducibility

**Goal**: Review changes in your feature branch and save the session for team reference

```bash
# Step 1: Run the review
ace-review --preset pr --auto-execute

# Output shows session location:
# Review saved to .ace-taskflow/v.0.9.0/reviews/review-20251101-153000/review-report.md

# Step 2: Reproduce the exact review later
ace-context .ace-taskflow/v.0.9.0/reviews/review-20251101-153000/context.md

# Step 3: Share context.md with team for identical reviews
cat .ace-taskflow/v.0.9.0/reviews/review-20251101-153000/context.md
```

**Expected Output Structure**:
```
.ace-taskflow/v.0.9.0/reviews/review-20251101-153000/
├── context.md              # Complete session configuration
├── prompt-system.md        # System prompt
├── prompt-user.md          # Embedded content from ace-context
├── subject.diff            # Extracted diffs
├── review-report.md        # LLM-generated review
└── metadata.yml            # Session metadata
```

### Scenario 2: Creating a GitHub Pull Request

**Goal**: Generate a PR description and create a pull request

```bash
# Step 1: Generate PR description
ace-review --preset pr-description --auto-execute

# Step 2: Extract the generated description
review_dir=$(ls -d .ace-taskflow/v.0.9.0/reviews/review-* | tail -1)
review_file="$review_dir/review-report.md"

# Step 3: Extract title (first heading after frontmatter)
title=$(grep -m1 "^# " "$review_file" | sed 's/^# //')

# Step 4: Extract body (everything after title)
body=$(sed '1,/^# /d' "$review_file")

# Step 5: Create the PR
gh pr create --title "$title" --body "$body"

# Output: PR URL
# https://github.com/user/repo/pull/123
```

### Scenario 3: Custom Context Loading

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

### Scenario 4: Debugging a Failed Review

**Goal**: Understand why a review session failed or produced unexpected results

```bash
# Step 1: Locate the failed session
session_dir=".ace-taskflow/v.0.9.0/reviews/review-20251101-160000"

# Step 2: Examine the context.md to see what was loaded
cat "$session_dir/context.md"

# Step 3: Check what ace-context actually embedded
cat "$session_dir/prompt-user.md" | head -100

# Step 4: Verify the subject diff
cat "$session_dir/subject.diff" | head -50

# Step 5: Re-run with debugging
ace-context "$session_dir/context.md" --debug
```

## Command Reference

### Review Session Artifacts

Every review session creates these files:

| File | Purpose | Format |
|------|---------|--------|
| `context.md` | Session configuration with YAML frontmatter | Markdown with YAML frontmatter |
| `prompt-system.md` | System prompt instructions | Markdown |
| `prompt-user.md` | Embedded content from ace-context | XML-embedded markdown |
| `subject.diff` | Git diff content (if applicable) | Unified diff format |
| `review-report.md` | LLM-generated review output | Markdown with frontmatter |
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

### PR Description Preset Configuration

Location: `.ace/review/presets/pr-description.yml`

```yaml
composition:
  base: "prompt://base/pr-description"
  format: "prompt://format/pr-description"
  focus:
    - "prompt://focus/changes-summary"
    - "prompt://focus/impact-analysis"
  guidelines:
    - "prompt://guidelines/pr-best-practices"

subject:
  diff:
    ranges: ["origin/main...HEAD"]

context:
  presets: [project]

options:
  auto_execute: true
  model: gpt-4  # Or your preferred model
```

## Tips and Best Practices

1. **Session Organization**: Review sessions are timestamped and stored in `.ace-taskflow/v.0.9.0/reviews/`. Clean old sessions periodically.

2. **Context Optimization**: Use specific presets rather than loading all project files to reduce token usage.

3. **Reproducibility**: Share the context.md file with team members for consistent review perspective.

4. **PR Workflow**: Customize the pr-description preset to match your team's PR template requirements.

5. **Debugging**: If reviews fail, check:
   - ace-context availability: `which ace-context`
   - Context preset exists: `ace-context --list`
   - Git range is valid: `git log origin/main...HEAD --oneline`

## Migration from Previous Versions

The CLI interface remains unchanged - existing commands work identically. The key differences are:

| Aspect | Before | After |
|--------|--------|-------|
| Context extraction | Internal ContextExtractor | Delegates to ace-context |
| Session files | context.md.tmp | context.md with frontmatter |
| Reproducibility | Not supported | Full reproduction via context.md |
| PR creation | Manual process | Documented workflow with preset |

## Troubleshooting

**ace-context not found**:
```bash
# Install ace-context gem
gem install ace-context
# Or add to Gemfile
bundle add ace-context
```

**Context preset not loading**:
```bash
# List available presets
ace-context --list

# Test preset loading
ace-context project --output stdio
```

**PR creation fails**:
```bash
# Ensure gh CLI is installed
which gh || brew install gh

# Authenticate with GitHub
gh auth login

# Verify current branch has upstream
git push -u origin feature-branch
```

**Large diffs causing timeouts**:
```bash
# Use path filters to reduce diff size
ace-review --preset pr \
  --subject 'diff: {ranges: ["origin/main...HEAD"], paths: ["lib/**/*.rb"]}' \
  --auto-execute
```

## Internal Implementation Notes

The enhanced ace-review uses:
- `Ace::Context.load_file_as_preset()` for loading context.md files
- YAML frontmatter in context.md for configuration
- ace-context's markdown-xml format for embedding
- Delegates all file reading, git operations, and command execution to ace-context
- Preserves backward compatibility with existing CLI interface