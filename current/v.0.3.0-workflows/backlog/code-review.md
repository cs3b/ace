# Review my Changes / Project

Reviewing changes is important, we should use models that works on large context (agent usually cannot do this on scale).

In the end we should have

# System Prompt

- review code
- review tests
- review docs

# What we Review

- diff (or filtered diff)
- files (tree, part of tree )

# Context Project

- we load project review (usually what we have in dev-handbook/workflow-instructions/load-project-context.wf.md -> docs/**/*.md)

# Examples

- review my diff from recent tag to HEAD use mixed prompt (review code / tests / docs ) and add context of project
- review my whole lib/**/* using review code prompt
- review my docs against recent changes in diff, and point me to what documentation should we update, what adr create

We have currently:

Tools:

######

- dev-tools/exe/llm-query
- dev-tools/exe-old/filter-diff.rb
- dev-tools/exe-old/generate-code-review-prompt
- dev-tools/exe-old/generate-doc-review-prompt
- dev-tools/exe-old/generate-test-review-prompt
- dev-tools/exe-old/diff-list-modified-files.rb

Prompts / Templates:
####################

- dev-handbook/templates/review-code/*.md
- dev-handbook/templates/review-docs/*.md
- dev-handbook/templates/review-test/*.md
- dev-handbook/templates/review-synthesizer/*.md

Guides:
#######

- dev-handbook/guides/code-review-diff-for-docs-update.g.md

Probably Trash:
###############

- dev-handbook/guides/code-review/*.md

Claude Code Commands:
#####################

- dev-taskflow/current/v.0.3.0-workflows/backlog/claude-commands/code-review.md
- .claude/commands/handbook-review.md
