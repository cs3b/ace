# Claude Integration Install Prompts

For each workflow instruction write a claude command

docs-dev/workflow-instructions
├── docs
│   ├── generate-adr.md
│   ├── generate-api-docs.md
│   ├── generate-release-overview.md
│   ├── generate-retro.md
│   ├── generate-review-checklist.md
│   ├── generate-test-cases.md
│   └── generate-user-docs.md
├── generate-blueprint.md
├── initialize-project-structure.md
├── lets-commit.md
├── lets-fix-tests.md
├── lets-release.md
├── lets-spec-from-diff.md
├── lets-spec-from-frd.md
├── lets-spec-from-pr
│   ├── fetch-comments-by-api.md
│   └── fetch-comments-by-mcp.md
├── lets-spec-from-pr-comments.md
├── lets-spec-from-prd.md
├── lets-spec-from-release-backlog.md
├── lets-start.md
├── lets-tests.md
├── load-env.md
├── log-session.md
├── review-tasks-board-status.md
└── self-reflect.md

.claude/commands

Below is a template for one commmand:

```md .claude/commands/lets-commit.md
READ and RUN INSTRUCTIONS in docs-dev/workflow-instructions/lets-commit.md
(also read internally linked other documents within this document)
```

## Instructions to Claude

- using cp & rm istead of git mv
