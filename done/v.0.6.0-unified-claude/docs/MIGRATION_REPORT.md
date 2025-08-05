# Command Migration Report - 2025-08-05

## Summary
- Commands migrated in dev-handbook: 0 (already migrated)
- Commands migrated in .claude: 32
- Commands skipped (already migrated): 0

## dev-handbook Migration
### Custom Commands Moved
The dev-handbook commands were already migrated to the new structure:
- dev-handbook/.integrations/claude/commands/_custom/ (6 files)
- dev-handbook/.integrations/claude/commands/_generated/ (24 files)

## .claude Migration  
### Custom Commands
Files moved to _custom/:
- commit.md
- draft-tasks.md
- load-project-context.md
- plan-tasks.md
- review-tasks.md
- work-on-tasks.md

### Generated Commands
Files moved to _generated/:
- capture-idea.md
- create-adr.md
- create-api-docs.md
- create-reflection-note.md
- create-test-cases.md
- create-user-docs.md
- draft-release.md
- draft-task.md
- fix-linting-issue-from.md
- fix-tests.md
- handbook-review.md
- improve-code-coverage.md
- initialize-project-structure.md
- plan-task.md
- publish-release.md
- rebase-against.md
- replan-cascade-task.md
- review-code.md
- review-synthesizer.md
- review-task.md
- save-session-context.md
- synthesize-reflection-notes.md
- synthesize-reviews.md
- update-blueprint.md
- update-roadmap.md
- work-on-task.md

## Verification
- Git history preserved: Yes (used git mv for all moves)
- All files accounted for: Yes
- Non-command files preserved: Yes (commands.json and commands.json.backup remain in root)