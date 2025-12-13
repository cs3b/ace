# Task 025: Git-Commit and LLM-Enhance Flags Usage

## Q: How do I configure default behavior for git-commit and llm-enhance?

**A:** Configure defaults in `.ace/taskflow.yml` to automatically apply these behaviors:

```yaml
# .ace/taskflow.yml
taskflow:
  idea:
    defaults:
      git_commit: true      # Auto-commit all ideas by default
      llm_enhance: true     # Auto-enhance all ideas by default
```

With these defaults set:
```bash
# Automatically commits AND enhances (based on config)
ace-taskflow idea create "New feature"

# Disable for a specific idea
ace-taskflow idea create "Quick note" --no-git-commit --no-llm-enhance
```

## Q: How do I capture an idea and automatically commit it to git?

**A:** Use the `--git-commit` or `-gc` flag when creating an idea:

```bash
ace-taskflow idea create "Add caching layer to improve API performance" --git-commit
```

Expected behavior:
- Creates idea file in the appropriate directory
- Automatically runs `git add` on the new file
- Commits with message: "Capture idea: Add caching layer to improve API performance"

## Q: How do I enhance an idea description using LLM?

**A:** Use the `--llm-enhance` or `-llm` flag to enrich the idea with implementation details:

```bash
ace-taskflow idea create "Implement rate limiting" --llm-enhance
```

Expected behavior:
- Creates initial idea from your text
- Loads project context
- Enhances description with implementation suggestions (initially stubbed)
- Saves enhanced version to file

## Q: Can I use both flags together?

**A:** Yes, you can combine both flags to enhance and commit in one operation:

```bash
ace-taskflow idea create "Add user authentication" --llm-enhance --git-commit
```

Or using short forms:
```bash
ace-taskflow idea create "Add user authentication" -llm -gc
```

Execution order:
1. Create initial idea
2. Enhance with LLM
3. Save enhanced version
4. Commit to git

## Q: What if I want to commit to a specific release?

**A:** Combine with release targeting:

```bash
ace-taskflow idea create "Fix memory leak" --release v.0.10.0 --git-commit
```

This will:
- Create idea in v.0.10.0 release directory
- Commit with release context in message

## Q: How does the git commit message format work?

**A:** The commit message follows this pattern:

- Short title: "Capture idea: [first 50 chars of idea]"
- If in specific release: "Capture idea in v.0.10.0: [title]"
- If in backlog: "Capture idea in backlog: [title]"

## Q: What happens if git commit fails?

**A:** The idea file is still created successfully. Error scenarios:

```bash
# Not in a git repository
ace-taskflow idea create "New feature" --git-commit
# Output: Idea created at [path]
# Warning: Git commit failed: not a git repository

# Uncommitted changes blocking
ace-taskflow idea create "New feature" --git-commit
# Output: Idea created at [path]
# Warning: Git commit failed: uncommitted changes in repository
```

## Q: How does LLM enhancement work with existing project context?

**A:** The enhancement process:

1. Loads project context (via ace-context)
2. Creates enhancement prompt with:
   - Original idea text
   - Project architecture understanding
   - Relevant code patterns
3. Returns enhanced description with:
   - Implementation approach
   - Technical considerations
   - Dependencies and impacts

Example enhanced output:
```markdown
# Original
Implement rate limiting

# Enhanced
Implement rate limiting

## Implementation Approach
- Add middleware for request throttling
- Use Redis for distributed rate limit tracking
- Configure per-endpoint and per-user limits

## Technical Considerations
- Integrate with existing auth middleware
- Consider burst allowances for API clients
- Add monitoring and alerting

## Dependencies
- Redis connection required
- Update API documentation
- Add rate limit headers to responses
```

## Q: Can I customize the enhancement prompt?

**A:** Not directly via command line, but the enhancement uses configuration:

```yaml
# .ace/taskflow.yml
taskflow:
  idea:
    defaults:
      git_commit: false     # Default: don't auto-commit
      llm_enhance: false    # Default: don't auto-enhance
    enhancement:
      include_context: true
      max_context_size: 4000
      prompt_template: "Enhance this idea with implementation details..."
```

## Q: What's the configuration priority order?

**A:** Configuration is resolved in this priority order (highest to lowest):

1. **Command-line flags** (explicit user intent)
   ```bash
   ace-taskflow idea create "Test" --git-commit  # Overrides all configs
   ```

2. **Project-level config** (`.ace/taskflow.yml`)
   ```yaml
   taskflow:
     idea:
       defaults:
         git_commit: true    # Project wants auto-commit
   ```

3. **User-level config** (`~/.ace/taskflow.yml`)
   ```yaml
   taskflow:
     idea:
       defaults:
         llm_enhance: true   # User prefers enhancement
   ```

4. **Built-in defaults** (both false)

## Q: How do I test these features during development?

**A:** Use dry-run or debug modes:

```bash
# Test without actual git operations
ace-taskflow idea create "Test idea" --git-commit --dry-run

# See enhancement prompt without LLM call
ace-taskflow idea create "Test idea" --llm-enhance --debug
```

## Common Usage Patterns

### With defaults configured (git_commit: true, llm_enhance: true)
```bash
# Uses both defaults
ace-taskflow idea create "New feature"

# Quick note without enhancements
ace-taskflow idea create "Remember to check logs" --no-llm-enhance

# Private idea not for commit
ace-taskflow idea create "Personal todo" --no-git-commit

# Completely manual
ace-taskflow idea create "Draft idea" --no-git-commit --no-llm-enhance
```

### Without defaults configured
```bash
# Quick capture with commit
ace-taskflow idea create "Bug: Login fails with special chars" -gc

# Detailed feature with enhancement
ace-taskflow idea create "Multi-tenant database architecture" -llm

# Full workflow for important ideas
ace-taskflow idea create "Microservices migration strategy" -llm -gc --release v.1.0.0
```

### Team configuration example
```yaml
# Team prefers auto-commit for traceability
# .ace/taskflow.yml (checked into repo)
taskflow:
  idea:
    defaults:
      git_commit: true      # All ideas tracked in git
      llm_enhance: false    # Enhancement opt-in per developer

# Individual developer can override
# ~/.ace/taskflow.yml (personal preference)
taskflow:
  idea:
    defaults:
      llm_enhance: true     # This dev wants enhancement by default
```