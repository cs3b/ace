# Handbook Review Command

Comprehensive wrapper for reviewing dev-handbook changes using the unified review-code workflow with handbook-specific configuration.

### Parameters

- **target** (required): What to review in dev-handbook
  - `workflows` - Review workflow-instructions files → `dev-handbook/workflow-instructions/**/*`
  - `guides` - Review guide files → `dev-handbook/guides/**/*`
  - `templates` - Review template files → `dev-handbook/templates/**/*`
  - `all` - Review all handbook content → `dev-handbook/**/*`

- **git-range** (optional): Git range for diff-based review
  - `v.0.2.0..HEAD` - From tag to HEAD
  - `HEAD~5..HEAD` - Recent commits
  - `41a9da9f..HEAD` - From specific commit
  - If omitted, reviews working directory changes

## Pre-Configured Parameters

This command automatically sets:
- **Focus**: `docs` (uses documentation review approach)
- **Context**: `docs/**/*.md` (project documentation context)
- **System Prompt**: `dev-local/handbook/tpl/review/system.prompt.md` (handbook-specific)
- **Timeout**: `500` seconds (for processing large handbook content)
- **Output**: Direct file output with cost tracking enabled
- **Session Directory**: current release directory (run `bin/rc`) + `/code_review/YYYYMMDD-HHMMSS-handbook-[target]/`
- **Repository Context**: dev-handbook submodule only

## Command Execution

This command executes the `/code-review` workflow with pre-configured parameters. The system prompt is passed via the `--system` flag to ensure proper separation from user prompts:

```claude
/code-review docs [git-range]
  context: docs/**/*.md
  target: dev-handbook/[target-paths]
  system-prompt: dev-local/handbook/tpl/review/system.prompt.md
  session-dir: code_review/YYYYMMDD-HHMMSS-handbook-[target]/
  repository: dev-handbook
```

## Troubleshooting

### Common Issues

- **Invalid target**: Use one of: `workflows`, `guides`, `templates`, `all`
- **Missing git range**: Command will review working directory changes if git-range is omitted
- **Submodule not initialized**: Run `git submodule update --init --recursive` first
- **No changes found**: Ensure there are changes in the specified target paths

### Validation

The command validates:
- Target parameter is one of the supported values
- Git range syntax is valid (if provided)
- dev-handbook submodule is available
- System prompt file exists
