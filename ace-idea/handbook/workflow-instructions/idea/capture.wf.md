---
doc-type: workflow
title: Capture Idea Workflow Instruction
purpose: Documentation for ace-idea/handbook/workflow-instructions/idea/capture.wf.md
ace-docs:
  last-updated: 2026-03-01
  last-checked: 2026-03-21
---

# Capture Idea Workflow Instruction

## Goal

Use the ace-idea tool to capture and enhance raw ideas within project context, transforming informal thoughts into structured, contextual ideas ready for future specification phases.

## Prerequisites

* `ace-idea` tool available (from dev-tools Ruby gem)
* Raw idea text or concept to capture
* LLM provider configured (Google Gemini recommended)
* Write access to the configured ideas directory (default: `.ace-ideas/`)

## Process Steps

1. **Identify the Idea Source:**
   * Determine the input method for your raw idea:
     * **Direct text**: You have the idea ready as text
     * **Clipboard**: Idea is copied to clipboard
     * **File content**: Idea is stored in a text file
   * Prepare the idea text - can be informal, unstructured, or just a brief concept

2. **Choose Appropriate Command Options:**
   * **Basic usage** (most common):
     ```bash
     ace-idea create "your raw idea text here"
     ```

   * **From clipboard**:
     ```bash
     ace-idea create --clipboard
     # OR combine with context:
     ace-idea create "Main context" --clipboard
     ```

   * **With explicit title and tags**:
     ```bash
     ace-idea create "Explicit idea text here" --title "Refined title" --tags ux,ideas
     ```

   * **With folder placement**:
     ```bash
     # Park uncertain work in _maybe
     ace-idea create "Future experiment" --move-to maybe

     # Keep low-priority work in _anytime
     ace-idea create "Nice-to-have polish" --move-to anytime

     # Fresh captures go to root by default (no --move-to needed)
     ace-idea create "New feature idea"
     ```

   * **With Git commit**:
     ```bash
     ace-idea create "New feature" --git-commit
     ```

   * **With LLM enhancement**:
     ```bash
     ace-idea create "Complex idea" --llm-enhance
     ```

3. **Execute Idea Capture:**
   * Run the selected `ace-idea create` command
   * The tool will automatically:
     * Create a structured idea file with frontmatter metadata
     * Generate a folder and spec filename using the raw ID and slug
     * Optionally enhance with LLM (if `--llm-enhance` or configured)
     * Optionally commit to git (if `--git-commit` or configured)
     * Store the idea in `.ace-ideas/` or the configured root, with optional folder placement (e.g., `_maybe`, `_anytime`)
   * Monitor the output for the created file path

4. **Verify Idea Creation:**
   * Check that the command completed successfully
   * Note the output file path showing:
     - The configured ideas root (default: `.ace-ideas/`)
     - Optional special folder such as `_maybe`, `_anytime`, or `_archive`
     - Idea directory (format: `{id}-{slug}/`)
     - Idea file (format: `{id}-{slug}.idea.s.md`)
   * Verify the file exists and contains:
     - Frontmatter with `id`, `status`, `title`, `tags`, and `created_at`
     - Content body with your idea details
   * Review the generated content for quality

5. **Document the Captured Idea:**
   * Record the path to the created idea file for future reference
   * Note any follow-up actions or related ideas
   * Consider whether immediate specification work is needed

## Decision Guidance

### When to Use This Workflow

**Use capture-idea when:**
* You have a raw, unstructured idea that needs project context
* Ideas come from brainstorming, user feedback, or informal discussions
* You want to preserve ideas for future development cycles
* Ideas need contextual questions for proper specification later

**Don't use capture-idea when:**
* You already have well-structured requirements (use draft-task instead)
* The idea is just a quick note (simple text file may suffice)
* You need immediate implementation (use work-on-task workflow)

### Scope Considerations

* **Root ideas** (default): Fresh captures — no `--move-to` needed
* **Maybe queue** (`--move-to maybe`): Ideas worth revisiting later
* **Anytime queue** (`--move-to anytime`): Low-priority work with no immediate deadline
* **Archive** (`--move-to archive`): Completed or retired ideas

## Common Usage Patterns

### Pattern 1: Quick Idea Capture
```bash
# Capture a brief concept immediately
ace-idea create "Add real-time notifications to the dashboard"
# => Created: .ace-ideas/8ppq7w-real-time-notifications/8ppq7w-real-time-notifications.idea.s.md
```

### Pattern 2: Place an Idea in _maybe
```bash
# Park an idea for later evaluation
ace-idea create "Migrate to PostgreSQL" --move-to maybe
# => Created: .ace-ideas/_maybe/8ppq7w-migrate-to-postgresql/8ppq7w-migrate-to-postgresql.idea.s.md
```

### Pattern 3: Clipboard Integration
```bash
# Copy idea text to clipboard first, then:
ace-idea create --clipboard
# OR combine with main context:
ace-idea create "Dashboard improvements" --clipboard
# => Created: .ace-ideas/8ppq7w-dashboard-improvements/8ppq7w-dashboard-improvements.idea.s.md
```

### Pattern 4: Enhanced Idea with Git Commit
```bash
# Create enhanced idea and automatically commit
ace-idea create "Complex refactoring task" --llm-enhance --git-commit
# => LLM enhances idea, creates file, commits to git
# => Created: .ace-ideas/8ppq7w-complex-refactoring-task/8ppq7w-complex-refactoring-task.idea.s.md
```

### Pattern 5: GTD-Style Folder Organization
```bash
# Uncertain idea
ace-idea create "Consider switching to TypeScript" --move-to maybe

# Low priority idea
ace-idea create "Add dark mode theme" --move-to anytime

# Archive an old idea later
ace-idea update q7w --move-to archive
```

## Error Handling

### Common Issues and Solutions

**"No content provided" Error:**
* **Cause**: Missing idea text argument and no clipboard input
* **Solution**: Provide idea text: `ace-idea create "your idea"`
* **Alternative**: Use `--clipboard`

**"Could not read from clipboard" Error:**
* **Cause**: Clipboard tools not available on system (pbpaste/pbcopy on macOS)
* **Solution**: Use direct text input or ensure clipboard tools are available
* **Note**: Clipboard functionality requires `ace-support-mac-clipboard` gem

**"Invalid target folder" Error:**
* **Cause**: `--move-to` was given a virtual filter (e.g., `next`) instead of a physical folder
* **Solution**: Use a physical folder: `maybe`, `anytime`, `archive`, or any custom name. Note: `next` is a virtual filter for listing, not a physical folder — omit `--move-to` to place ideas in root

**LLM Enhancement Failures:**
* **Cause**: API issues, model unavailability, or `--no-llm-enhance` flag
* **Result**: Tool saves raw idea without LLM enhancement
* **Action**: Check LLM configuration, network/API keys, or accept basic idea file
* **Note**: Enhancement is optional; ideas work fine without it

**Git Commit Failures:**
* **Cause**: Git repository issues or `--no-git-commit` flag
* **Result**: Idea file created but not committed
* **Action**: Manually commit later or fix git configuration

## Success Criteria

* Idea successfully captured in appropriate directory:
  - Root: `.ace-ideas/`
  - Special folder: `.ace-ideas/_maybe/`, `.ace-ideas/_anytime/`, or `.ace-ideas/_archive/`
* Generated file structure includes:
  - Idea directory (e.g., `8ppq7w-dark-mode/`)
  - Idea file with frontmatter (e.g., `8ppq7w-dark-mode.idea.s.md`)
* Frontmatter contains required metadata:
  - `id`: Raw idea identifier
  - `status`: Initial status
  - `title`: Human-readable title
  - `tags`: Array of tags
  - `created_at`: Creation timestamp
* File content includes idea description and details
* Tool returns created file path for reference
* No errors during capture process
* Optional: Git commit created (if configured or requested)
* Optional: LLM enhancement applied (if configured or requested)

## Integration with Other Workflows

### Natural Follow-up Workflows

**After capturing ideas:**
* **draft-task**: When ready to turn idea into actionable task
* **draft-release**: During release planning to review captured ideas
* **create-reflection-note**: To document patterns from multiple ideas

**Preparation workflows:**
* **load-project-context**: If project context files are missing
* **update-blueprint**: If project structure has changed significantly

## Usage Examples

### Example 1: User Feedback Integration
```bash
# After receiving user feedback: "Users want better mobile experience"
ace-idea create "Users report difficulties with mobile interface - want better responsive design and touch interactions" --llm-enhance
# Output: Creates enhanced idea with mobile UX questions and project-specific considerations
# => .ace-ideas/8ppq7w-mobile-interface-improvements/...
```

### Example 2: Technical Improvement Ideas
```bash
# During code review, note performance concerns
ace-idea create "Database queries in user dashboard are slow - consider caching layer and query optimization" --git-commit
# Output: Creates idea and commits to git automatically
# => .ace-ideas/8ppq7w-database-query-optimization/...
```

### Example 3: Maybe-Later Feature Ideas
```bash
# Capture future feature for later evaluation
ace-idea create "Add GraphQL API alongside REST" --move-to maybe
# Output: Creates idea in the maybe queue for later evaluation
# => .ace-ideas/_maybe/8ppq7w-graphql-api-alongside-rest/...
```

### Example 4: Configuration for Automatic Enhancement
```yaml
# ~/.ace/idea/config.yml
idea:
  defaults:
    git_commit: true     # Always commit new ideas
    llm_enhance: true    # Always enhance new captures
```
```bash
# Now simple command does both
ace-idea create "New feature concept"
# => Automatically enhanced and committed
```

---

This workflow enables efficient capture and enhancement of raw ideas, ensuring they're preserved with proper project context and structured for future development consideration. The ace-idea tool handles the complexity of context loading and enhancement, providing a simple interface for idea preservation.
