---
update:
  update_frequency: on-change
  auto_generate:
  - template-refs: from-embedded
  frequency: on-change
  last-updated: '2025-09-24'
---

# Capture Idea Workflow Instruction

## Goal

Use the ace-taskflow idea tool to capture and enhance raw ideas within project context, transforming informal thoughts into structured, contextual ideas ready for future specification phases.

## Prerequisites

* `ace-taskflow idea` tool available (from dev-tools Ruby gem)
* Raw idea text or concept to capture
* LLM provider configured (Google Gemini recommended)
* Write access to `.ace-taskflow/backlog/ideas/` directory

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
     ace-taskflow idea create "your raw idea text here"
     ```

   * **From clipboard**:
     ```bash
     ace-taskflow idea create --clipboard
     # OR combine with context:
     ace-taskflow idea create "Main context" --clipboard
     ```

   * **With explicit note text**:
     ```bash
     ace-taskflow idea create --note "Explicit idea text here"
     ```

   * **Scoped ideas**:
     ```bash
     # For active release (default):
     ace-taskflow idea create "New feature idea"

     # For backlog:
     ace-taskflow idea create "Future feature" --backlog

     # For specific release:
     ace-taskflow idea create "Bug fix" --release v.0.9.1

     # For uncertain ideas (maybe/ scope):
     ace-taskflow idea create "Uncertain idea" --maybe

     # For low priority (anyday/ scope):
     ace-taskflow idea create "Low priority enhancement" --anyday
     ```

   * **With Git commit**:
     ```bash
     ace-taskflow idea create "New feature" --git-commit
     ```

   * **With LLM enhancement**:
     ```bash
     ace-taskflow idea create "Complex idea" --llm-enhance
     ```

3. **Execute Idea Capture:**
   * Run the selected `ace-taskflow idea create` command
   * The tool will automatically:
     * Create structured idea file with frontmatter metadata
     * Generate timestamp-based subdirectory and filename
     * Optionally enhance with LLM (if `--llm-enhance` or configured)
     * Optionally commit to git (if `--git-commit` or configured)
     * Store in appropriate scope directory based on flags
   * Monitor the output for the created file path

4. **Verify Idea Creation:**
   * Check that the command completed successfully
   * Note the output file path showing:
     - Release/backlog directory
     - Scope subdirectory (if using --maybe or --anyday)
     - Timestamp-based subdirectory (format: `YYYYMMDD-HHMMSS-slug/`)
     - Idea file (format: `YYYYMMDD-HHMMSS-slug.s.md`)
   * Verify the file exists and contains:
     - Frontmatter with `title`, `filename_suggestion`, `enhanced_at`, `location`, `llm_model` (if enhanced)
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

* **Active release ideas** (default): Immediately actionable, relevant to current release
* **Backlog ideas** (`--backlog`): Future work not tied to specific release
* **Maybe scope** (`--maybe`): Uncertain if we should do it, needs evaluation
* **Anyday scope** (`--anyday`): Good ideas but not urgent, low priority
* **Done scope**: Completed or skipped ideas (moved via `ace-taskflow idea done`)

## Common Usage Patterns

### Pattern 1: Quick Idea Capture (Active Release)
```bash
# Capture a brief concept immediately for current release
ace-taskflow idea create "Add real-time notifications to the dashboard"
# => Created: .ace-taskflow/v.0.9.0/ideas/20251116-143000-real-time-notifications/20251116-143000-real-time-notifications.s.md
```

### Pattern 2: Backlog Idea
```bash
# Capture future idea not tied to current release
ace-taskflow idea create "Migrate to PostgreSQL" --backlog
# => Created: .ace-taskflow/backlog/ideas/20251116-143200-migrate-postgresql/20251116-143200-migrate-postgresql.s.md
```

### Pattern 3: Clipboard Integration
```bash
# Copy idea text to clipboard first, then:
ace-taskflow idea create --clipboard
# OR combine with main context:
ace-taskflow idea create "Dashboard improvements" --clipboard
# => Created: .ace-taskflow/v.0.9.0/ideas/20251116-143400-dashboard-improvements/20251116-143400-dashboard-improvements.s.md
```

### Pattern 4: Enhanced Idea with Git Commit
```bash
# Create enhanced idea and automatically commit
ace-taskflow idea create "Complex refactoring task" --llm-enhance --git-commit
# => LLM enhances idea, creates file, commits to git
# => Created: .ace-taskflow/v.0.9.0/ideas/20251116-143600-complex-refactoring/20251116-143600-complex-refactoring.s.md
```

### Pattern 5: Scoped Ideas (GTD Organization)
```bash
# Uncertain idea (maybe/ scope)
ace-taskflow idea create "Consider switching to TypeScript" --maybe

# Low priority idea (anyday/ scope)
ace-taskflow idea create "Add dark mode theme" --anyday

# Specific release
ace-taskflow idea create "Critical bug fix" --release v.0.9.1
```

## Error Handling

### Common Issues and Solutions

**"No content provided" Error:**
* **Cause**: Missing idea text argument and no clipboard/note specified
* **Solution**: Provide idea text: `ace-taskflow idea create "your idea"`
* **Alternative**: Use `--clipboard` or `--note "text"` flag

**"Could not read from clipboard" Error:**
* **Cause**: Clipboard tools not available on system (pbpaste/pbcopy on macOS)
* **Solution**: Use direct text input or ensure clipboard tools are available
* **Note**: Clipboard functionality requires `ace-support-mac-clipboard` gem

**"Release not found" Error:**
* **Cause**: Specified release doesn't exist
* **Solution**: Check available releases with `ace-taskflow release list` or use `--backlog`

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

* Idea successfully captured in `.ace-taskflow/backlog/ideas/` directory
* Generated file contains enhanced idea with project context
* File includes relevant questions for future specification
* Timestamp-based filename created for easy organization
* Tool returns created file path for reference
* No errors during capture process

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
ace-taskflow idea "Users report difficulties with mobile interface - want better responsive design and touch interactions"
# Output: Creates enhanced idea with mobile UX questions and project-specific considerations
```

### Example 2: Technical Improvement Ideas
```bash
# During code review, note performance concerns
ace-taskflow idea "Database queries in user dashboard are slow - consider caching layer and query optimization"
# Output: Creates idea with technical questions about architecture and performance impact
```

### Example 3: Feature Brainstorming Session
```bash
# Capture multiple ideas from team meeting
ace-taskflow idea --file team-brainstorm-2025-01-30.txt --big-user-input-allowed
# Output: Creates comprehensive idea file with context-aware enhancement questions
```

---

This workflow enables efficient capture and enhancement of raw ideas, ensuring they're preserved with proper project context and structured for future development consideration. The ace-taskflow idea tool handles the complexity of context loading and enhancement, providing a simple interface for idea preservation.
