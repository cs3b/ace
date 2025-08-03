# Goal

Ensure all changes made in the current session or workflow are properly committed to git.

# Implementation

Use the git-commit-manager agent to handle the commit process.

# Usage

When called from a workflow command, determine the context automatically:
- Check what workflow was just executed
- Use git-status to see what changed
- Create appropriate commit with workflow context

When called directly, use the session context:
- Review all changes made in current session
- Group related changes appropriately
- Commit with clear intention

## Agent Invocation

```
Use the git-commit-manager agent to commit changes.
Context: [Brief description of what was done]
Files modified: [File paths or globs like ".claude/commands/*.md" OR "Check git-status" if unknown]
Intention: [Purpose and goal of these changes]
```

Example with specific files:
```
Use the git-commit-manager agent to commit changes.
Context: Created git-commit-manager agent and updated command files
Files modified: .claude/agents/git-commit-manager.md, .claude/commands/*.md, dev-handbook/.integrations/claude/install-prompts.md
Intention: Centralize git commit management through specialized agent and update all commands to reference /commit instead of duplicating logic
```

Example without files (agent will check git-status):
```
Use the git-commit-manager agent to commit changes.
Context: Completed work-on-task workflow
Files modified: Check git-status
Intention: Implement task requirements as specified in the workflow
```

The agent will analyze the changes and create appropriate commits.