# Getting Started with ace-review

Use `ace-review` to run repeatable, preset-driven code reviews from CLI or Claude Code.

## Prerequisites

- Ruby installed
- `ace-review` installed
- Optional for PR reviews: GitHub CLI (`gh`) authenticated via `gh auth login`

Run:

```bash
gem install ace-review
```

## 1) Run your first review

Run:

```bash
ace-review --preset code --subject diff:origin/main..HEAD --auto-execute
```

This runs a code-focused review against your current branch diff and writes session artifacts under `.ace-local/review/`.

## 2) Review a GitHub PR

Run:

```bash
ace-review --pr 123 --preset code-pr --auto-execute
```

Use `--post-comment` when you want to publish the review back to GitHub.

## 3) Try different presets

Run:

```bash
ace-review --list-presets
ace-review --preset security --subject diff:origin/main..HEAD --auto-execute
```

Pick a preset that matches the review goal (general quality, docs, security, PR).

## 4) Create a custom preset

Create `.ace/review/presets/team-review.yml`:

```yaml
description: Team review baseline
presets:
  - code
instructions:
  bundle:
    sections:
      team_focus:
        files:
          - "prompt://focus/quality/security"
          - "prompt://focus/languages/ruby"
```

Then run:

```bash
ace-review --preset team-review --subject diff:origin/main..HEAD --auto-execute
```

## What to try next

- Review a PR with developer feedback: `ace-review --pr 123 --pr-comments --auto-execute`
- Post review results directly to GitHub: `ace-review --pr 123 --post-comment --auto-execute`
- Read [Feedback Workflow](feedback-workflow.md) to operationalize findings
