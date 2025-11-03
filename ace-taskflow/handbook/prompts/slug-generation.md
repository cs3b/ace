---
description: LLM prompt for generating hierarchical task and idea slugs
context:
  presets:
    - project-base
  params:
    format: markdown
    max_size: 102400
---

# Slug Generation Instructions

You are generating hierarchical slugs for organizing tasks and ideas in a project management system.

## Context Understanding

Review the provided project context to understand:
- The main systems/components in the project
- Common terminology and naming patterns
- Project structure and architecture

## Folder Slugs (2-4 words)

Format: `{system/area}-{goal/action}`

The folder slug should:
- Identify the main system or area being affected (from project context)
- Add the goal type or action category
- Be 2-4 words separated by hyphens

### Common Goal Types:
- **feat/add** - New features or functionality
- **fix** - Bug fixes and corrections
- **enhance/improve** - Improvements to existing features
- **refactor** - Code restructuring without behavior change
- **docs** - Documentation changes
- **test** - Test additions or modifications
- **perf** - Performance improvements
- **chore** - Maintenance tasks
- **build** - Build system changes
- **ci** - CI/CD pipeline changes

### Examples:
- `search-fix` - Fixing search functionality
- `taskflow-enhance` - Enhancing task management
- `llm-add` - Adding LLM features
- `git-commit-refactor` - Refactoring git commit logic
- `docs-update` - Updating documentation

## File Slugs (3-5+ words)

Format: `{specific-action-description}`

The file slug should:
- Describe the specific change or action precisely
- Be 3-5+ words that clearly explain what's being done
- Avoid redundancy with the folder slug
- Focus on the "what" not the "how"

### Examples:
- `implement-update-command`
- `always-use-project-root`
- `add-provider-support`
- `fix-memory-leak-issue`
- `improve-error-handling`
- `add-timestamp-to-output`

## Important Rules

1. **All lowercase** with hyphens between words
2. **No numbers** or timestamps in slugs (those are handled separately)
3. **Be concise** but descriptive
4. **Use project terminology** from the provided context
5. **Folder = general** (what system + why type)
6. **File = specific** (precise action/change)

## Response Format

You must respond with ONLY valid JSON in this exact format:

```json
{
  "folder_slug": "system-goal",
  "file_slug": "specific-action-description"
}
```

Do not include any explanation or additional text outside the JSON.
