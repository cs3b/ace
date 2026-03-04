---
doc-type: guide
purpose: User guide for feedback-based review workflow
update:
  last-updated: '2026-02-03'
---

# Feedback-Based Review Workflow

## Overview

The feedback system extracts individual findings from code reviews into tracked items. Instead of monolithic synthesis reports that are difficult to action, each review finding becomes a discrete feedback item with its own lifecycle - from initial discovery through verification to resolution.

Key benefits:
- **Trackable**: Each finding has a unique ID and status
- **Verifiable**: Draft items can be validated before work begins
- **Actionable**: Clear state machine guides items to resolution
- **Organized**: Items are stored per-task with automatic archiving

## Quick Start

1. Run a review with feedback extraction:
   ```bash
   ace-review --preset code-pr --pr 123 --auto-execute
   ```

2. List feedback items:
   ```bash
   ace-review-feedback list
   ```

3. Process feedback:
   ```bash
   # Verify a draft item as valid
   ace-review-feedback verify abc123 --valid --research "Confirmed issue in production logs"

   # Verify as invalid (false positive)
   ace-review-feedback verify abc123 --invalid --research "False positive: validation exists"

   # Skip an item that's not applicable
   ace-review-feedback verify abc123 --skip --research "Out of scope for this PR"

   # Resolve a pending item
   ace-review-feedback resolve abc123 --resolution "Fixed in commit def456"
   ```

## Feedback Item Lifecycle

```
draft --> (verify --valid) --> pending --> (resolve) --> done [archived]
      \
       --> (verify --invalid) --------------> invalid [archived]
        \
         --> (verify --skip) ---------------> skip [archived]

pending --> (resolve) --> done [archived]
         \
          --> (verify --skip) -------------> skip [archived]
```

### Status Definitions

| Status | Description | Next States |
|--------|-------------|-------------|
| `draft` | Newly extracted, needs verification | `pending`, `invalid`, `skip` |
| `pending` | Verified valid, awaiting resolution | `done`, `skip` |
| `invalid` | False positive, no action needed | (terminal) |
| `skip` | Not applicable to current context | (terminal) |
| `done` | Resolved with documented fix | (terminal) |

Terminal states (`invalid`, `skip`, `done`) are automatically archived.

## CLI Commands

### `ace-review-feedback list`

Lists feedback items with optional filters.

```bash
# List all active items
ace-review-feedback list

# Filter by status
ace-review-feedback list --status pending

# Filter by priority
ace-review-feedback list --priority high

# Combine filters
ace-review-feedback list --status pending --priority critical

# Include archived items
ace-review-feedback list --archived

# Output as JSON
ace-review-feedback list --format json

# Use specific session
ace-review-feedback list --session .ace-local/ace-review/sessions/review-8p2h11
```

**Options:**
- `--status STATUS` - Filter by status (draft/pending/invalid/skip/done)
- `--priority PRIORITY` - Filter by priority (critical/high/medium/low)
- `--session PATH` - Session directory containing feedback
- `--archived` - Include archived items
- `--format FORMAT` - Output format (table/json)

### `ace-review-feedback show <id>`

Displays detailed information about a feedback item.

```bash
# Show by full ID
ace-review-feedback show abc123

# Show by partial ID (minimum 3 characters)
ace-review-feedback show abc

# Use specific session
ace-review-feedback show abc123 --session .ace-local/ace-review/sessions/review-8p2h11
```

**Output includes:**
- Title, status, priority, reviewer
- Creation and update timestamps
- File references
- Finding description
- Context (why it matters)
- Research notes (verification)
- Resolution (how it was fixed)

### `ace-review-feedback verify <id>`

Verifies a draft item as valid, invalid, or skipped.

```bash
# Mark as valid (moves to pending)
ace-review-feedback verify abc123 --valid

# Mark as invalid (archives the item)
ace-review-feedback verify abc123 --invalid

# Mark as skipped (archives the item)
ace-review-feedback verify abc123 --skip

# Add research notes
ace-review-feedback verify abc123 --valid --research "Confirmed: code path is reachable"
ace-review-feedback verify abc123 --invalid --research "False positive: handled elsewhere"
ace-review-feedback verify abc123 --skip --research "Design: using polling for simplicity"
```

**Options:**
- `--valid` - Mark as valid (moves to pending status)
- `--invalid` - Mark as invalid (archives the item)
- `--skip` - Mark as skipped (archives the item)
- `--research TEXT` - Add verification research notes (what we learned/decided)
- `--session PATH` - Session directory containing feedback

## Choosing Between Verification Modes

All three modes archive feedback items, but they mean different things:

```
┌─────────────────────────────────────────────────────────────────┐
│  Is the feedback claim factually correct?                        │
├─────────────────┬───────────────────────────────────────────────┤
│  NO             │  YES                                          │
│  → verify --invalid  │  → Are you fixing it?                      │
│  (False positive)  │     ├─ YES → verify --valid (then resolve)  │
│                    │     └─ NO → verify --skip "..."            │
│                    │           (Not applicable)                  │
└────────────────────┴─────────────────────────────────────────────┘
```

| Question | `verify --invalid` | `verify --skip` |
|----------|-------------------|-----------------|
| Is the claim factually wrong? | ✅ Yes | ❌ No |
| Is the finding correct but not fixed? | ❌ No | ✅ Yes |
| Does it archive the item? | ✅ Yes | ✅ Yes |
| `--research` meaning | Why it's incorrect | Why we're skipping |

### Concrete Examples

**Use `verify --invalid` for false positives (incorrect findings):**

```bash
# Claimed code doesn't exist, but it does
ace-review-feedback verify abc123 --invalid --research "Class exists at lib/extractor.rb:42"

# Claimed missing validation, but it exists elsewhere
ace-review-feedback verify abc124 --invalid --research "Validation exists in AuthMiddleware:23"

# Claimed issue in CI, but code doesn't run in CI
ace-review-feedback verify abc125 --invalid --research "E2E tests are agent-executed, not in CI"
```

**Use `verify --skip` for correct findings that won't be fixed:**

```bash
# Design decision - intentionally choosing this approach
ace-review-feedback verify abc126 --skip --research "Design: using polling for simplicity"

# Deferred - correct issue, but tracking separately
ace-review-feedback verify abc127 --skip --research "Tracked in task 253"

# Duplicate - already covered by another item
ace-review-feedback verify abc128 --skip --research "Duplicate of abc120"
```

### `ace-review-feedback resolve <id>`

Resolves a pending item with resolution text.

```bash
ace-review-feedback resolve abc123 --resolution "Fixed in commit def456"
ace-review-feedback resolve abc123 --resolution "Added input validation in UserController"
ace-review-feedback resolve abc123 --resolution "Refactored to use parameterized queries"
```

**Options:**
- `--resolution TEXT` - (required) How the issue was resolved
- `--session PATH` - Session directory containing feedback

## Configuration

### Enabling/Disabling Feedback

Feedback extraction is enabled by default. Configure in `.ace/review/config.yml`:

```yaml
# .ace/review/config.yml
feedback:
  enabled: true                        # default
  synthesis_model: google:gemini-2.5-flash  # model for synthesis
```

### CLI Flags

- `--no-feedback` - Disable feedback extraction for this review
- `--feedback-model MODEL` - Specify extraction model for this review

### Example Workflow Configuration

```yaml
# .ace/review/presets/code-pr.yml
presets:
  - code

# Feedback settings for PR reviews
feedback:
  enabled: true
  synthesis_model: google:gemini-2.5-flash
```

## Session Context

Feedback is stored within session directories and discovered via:

1. **`--session` flag** (explicit): `ace-review-feedback list --session .ace-local/ace-review/sessions/review-8p2h11`
2. **`.ace-review-session` cache file**: Auto-created after reviews, remembers the latest session
3. **Current working directory**: Fallback to pwd

Session directories are automatically symlinked to task directories for organization.

## File Format

Feedback items are stored as markdown files with YAML frontmatter:

```yaml
---
id: 8o7abc
title: SQL Injection in User Input Handler
files:
  - src/handlers/user.rb:42-55
reviewer: google:gemini-2.5-flash
status: draft
priority: high
created: 2026-01-22T19:00:00Z
updated: 2026-01-22T19:00:00Z
---

## Finding
The user input handler passes unsanitized input directly to SQL queries,
creating a potential SQL injection vulnerability.

## Context
This code path is reached when processing user registration forms.
An attacker could exploit this to access or modify database records.

## Research
Confirmed by code review: the `params[:name]` value is interpolated
directly into the query string without escaping.

## Resolution
Refactored to use parameterized queries in commit abc123.
Added input validation in commit def456.
```

### Filename Convention

Files are named: `{id}-{slug}.s.md`

- `id`: 8-character Base36 identifier (millisecond-precision timestamp)
- `slug`: URL-safe version of title (max 40 characters)
- `.s.md`: Suffix indicating structured markdown

Examples:
- `8o7abc12-sql-injection-user-input.s.md`
- `8o7abc13-missing-error-handling.s.md`

## Directory Structure

Review sessions are stored in a cache directory and symlinked into task directories:

```
# Cache directory (gitignored)
.ace-local/ace-review/sessions/
  review-8p2h11/              # Session directory
    review.md                  # Review output
    review-report-*.md         # Multi-model outputs
    synthesis.md               # Synthesis report (if multi-model)
    feedback/                  # Feedback items
      8o7abc-sql-injection.s.md
      _archived/
        8o7abf-resolved.s.md
    system.prompt.md           # Prompts
    user.prompt.md
    metadata.yml
    llm_metadata.yml
    pr-diff.patch              # If PR review
  review-8p2fo1/
    ...

# Task directory (tracked in git)
task-dir/
  reviews/
    review-8p2h11 → ../../../../../.ace-local/ace-review/sessions/review-8p2h11
    review-8p2fo1 → ../../../../../.ace-local/ace-review/sessions/review-8p2fo1
```

Multiple review sessions can be linked to the same task, allowing for iterative reviews across PR cycles.

Within `.ace-taskflow` task directories:

```
.ace-taskflow/
  v.0.36.0/
    tasks/
      227-feedback-architecture/
        227.s.md                    # Task spec
        reviews/                    # Symlinks to session directories
          review-8p2h11 → ../../../../../../.ace-local/ace-review/sessions/review-8p2h11
          review-8p2fo1 → ../../../../../../.ace-local/ace-review/sessions/review-8p2fo1
```

Each symlinked session contains:
- Review outputs (`review.md`, `review-report-*.md`, `synthesis.md`)
- Feedback items in `feedback/` subdirectory
- Prompts and metadata for reproducibility

## Integration with Review Pipeline

Feedback extraction happens automatically after reviews complete:

1. Review reports are generated by LLM
2. Extraction model analyzes reports for actionable findings
3. Findings are deduplicated across multiple reports
4. Each finding becomes a `draft` feedback item
5. Items are saved to the task's `feedback/` directory

### Deduplication

When multiple LLM reviewers identify the same issue:
- Titles are compared for similarity
- File references are matched
- Only unique findings are saved
- Duplicate count is reported

## Troubleshooting

### No feedback items extracted

Possible causes:
- Review contains no actionable findings (praise-only, or general observations)
- Extraction model unavailable or rate-limited
- `--no-feedback` flag was set
- Review report is empty or malformed

Solutions:
- Check that review reports contain specific, actionable issues
- Verify extraction model is configured correctly
- Remove `--no-feedback` if set
- Check review session directory for report content

### Feedback not saved to task

Feedback is stored within session directories, which are symlinked to task directories.

Possible causes:
- No review session found in cache
- Session directory doesn't exist
- Permission issues accessing session

Solutions:
- Run a review first to create a session
- Specify session explicitly with `--session .ace-local/ace-review/sessions/review-xyz`
- Ensure .ace-local/ace-review/sessions/ exists and is writable

Note: Feedback is stored in each session's `feedback/` directory.

### Partial ID matching fails

The minimum ID length for matching is 3 characters. If multiple items match:
- Provide more characters of the ID
- Use full 8-character ID from `feedback list`

### Cannot transition status

Each status has specific allowed transitions:
- `draft` can go to: `pending`, `invalid`, `skip`
- `pending` can go to: `done`, `skip`
- Terminal states (`done`, `invalid`, `skip`) cannot transition

To fix items stuck in wrong state, manually edit the YAML frontmatter.

### Archived items not visible

By default, `list` shows only active items. Use `--archived` to include:

```bash
ace-review-feedback list --archived
```

Archived items are in `feedback/_archived/` subdirectory within each session.

### Multiple sessions for the same task

Each review execution creates a new session:

```bash
# First review
ace-review --pr 189 --preset code-pr

# Second review (different PR or updated code)
ace-review --pr 190 --preset code-pr

# List all sessions
ls -la .ace-local/ace-review/sessions/
# review-8p2h11/
# review-8p2xyz/

# Work with a specific session
ace-review-feedback list --session .ace-local/ace-review/sessions/review-8p2h11
```

This enables:
- Historical record of all reviews
- Separate feedback tracking per review cycle
- Iterative refinement based on multiple review passes
