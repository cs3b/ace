# Capture Idea Workflow Instruction

## Goal

Use the ideas-manager tool to capture and enhance raw ideas within project context, transforming informal thoughts into structured, contextual ideas ready for future specification phases.

## Prerequisites

* `ideas-manager` tool available (from dev-tools Ruby gem)
* Raw idea text or concept to capture
* LLM provider configured (Google Gemini recommended)
* Write access to `dev-taskflow/backlog/ideas/` directory

## Project Context Loading

* Load project objectives: `docs/what-do-we-build.md`
* Load architecture overview: `docs/architecture.md`
* Load project structure: `docs/blueprint.md`
* Load tools documentation: `docs/tools.md`

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
     ideas-manager capture "your raw idea text here"
     ```
   
   * **From clipboard**:
     ```bash
     ideas-manager capture --clipboard
     ```
   
   * **From file**:
     ```bash
     ideas-manager capture --file path/to/idea-notes.txt
     ```
   
   * **For long ideas** (over 1000 words):
     ```bash
     ideas-manager capture "long idea text..." --big-user-input-allowed
     ```
   
   * **With debug information**:
     ```bash
     ideas-manager capture "idea text" --debug
     ```

3. **Execute Idea Capture:**
   * Run the selected ideas-manager command
   * The tool will automatically:
     * Load current project context from all `docs/*.md` files
     * Generate project-specific enhancement questions
     * Create structured idea file with timestamp naming
     * Store in `dev-taskflow/backlog/ideas/` directory
   * Monitor the output for the created file path

4. **Verify Idea Creation:**
   * Check that the command completed successfully
   * Note the output file path (format: `dev-taskflow/backlog/ideas/YYYYMMDD-HHMM-idea-slug.md`)
   * Verify the file exists and contains enhanced content
   * Review the generated questions and context for quality

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
* You already have well-structured requirements (use create-task instead)
* The idea is just a quick note (simple text file may suffice)
* You need immediate implementation (use work-on-task workflow)

### Input Size Considerations

* **Small ideas** (< 100 words): Perfect for basic capture
* **Medium ideas** (100-1000 words): Standard usage, ideal size
* **Large ideas** (> 1000 words): Use `--big-user-input-allowed` flag
* **Very large content**: Consider breaking into multiple ideas

## Common Usage Patterns

### Pattern 1: Quick Idea Capture
```bash
# Capture a brief concept immediately
ideas-manager capture "Add real-time notifications to the dashboard"
# => Created: dev-taskflow/backlog/ideas/20250730-1430-real-time-dashboard-notifications.md
```

### Pattern 2: Detailed Idea from Notes
```bash
# Capture from prepared notes file
ideas-manager capture --file brainstorm-session-notes.txt
# => Created: dev-taskflow/backlog/ideas/20250730-1432-brainstorm-session-insights.md
```

### Pattern 3: Clipboard Integration
```bash
# Copy idea text to clipboard first, then:
ideas-manager capture --clipboard
# => Created: dev-taskflow/backlog/ideas/20250730-1434-clipboard-captured-idea.md
```

### Pattern 4: Long-form Idea Processing
```bash
# For comprehensive ideas or requirements documents
ideas-manager capture --file detailed-requirements.md --big-user-input-allowed
# => Created: dev-taskflow/backlog/ideas/20250730-1436-detailed-requirements-analysis.md
```

## Error Handling

### Common Issues and Solutions

**"No input provided" Error:**
* **Cause**: Missing idea text argument and no clipboard/file specified
* **Solution**: Provide idea text: `ideas-manager capture "your idea"`

**"Input too large" Error:**
* **Cause**: Idea text exceeds 1000 words without permission flag
* **Solution**: Add `--big-user-input-allowed` flag to command

**"Could not read from clipboard" Error:**
* **Cause**: Clipboard tools not available on system
* **Solution**: Use direct text input or install required clipboard tools (pbpaste/xclip/xsel)

**"File not found" Error:**
* **Cause**: Specified file path doesn't exist or isn't readable
* **Solution**: Verify file path and permissions

**LLM Enhancement Failures:**
* **Cause**: API issues or model unavailability
* **Result**: Tool saves raw idea without enhancement (degraded functionality)
* **Action**: Check network/API keys, or proceed with raw idea file

## Success Criteria

* Idea successfully captured in `dev-taskflow/backlog/ideas/` directory
* Generated file contains enhanced idea with project context
* File includes relevant questions for future specification
* Timestamp-based filename created for easy organization
* Tool returns created file path for reference
* No errors during capture process

## Integration with Other Workflows

### Natural Follow-up Workflows

**After capturing ideas:**
* **create-task**: When ready to turn idea into actionable task
* **draft-release**: During release planning to review captured ideas
* **create-reflection-note**: To document patterns from multiple ideas

**Preparation workflows:**
* **load-project-context**: If project context files are missing
* **update-blueprint**: If project structure has changed significantly

## Usage Examples

### Example 1: User Feedback Integration
```bash
# After receiving user feedback: "Users want better mobile experience"
ideas-manager capture "Users report difficulties with mobile interface - want better responsive design and touch interactions"
# Output: Creates enhanced idea with mobile UX questions and project-specific considerations
```

### Example 2: Technical Improvement Ideas
```bash
# During code review, note performance concerns
ideas-manager capture "Database queries in user dashboard are slow - consider caching layer and query optimization"
# Output: Creates idea with technical questions about architecture and performance impact
```

### Example 3: Feature Brainstorming Session
```bash
# Capture multiple ideas from team meeting
ideas-manager capture --file team-brainstorm-2025-01-30.txt --big-user-input-allowed
# Output: Creates comprehensive idea file with context-aware enhancement questions
```

---

This workflow enables efficient capture and enhancement of raw ideas, ensuring they're preserved with proper project context and structured for future development consideration. The ideas-manager tool handles the complexity of context loading and enhancement, providing a simple interface for idea preservation.