---
title: Add Demo Section to PR Description Template
filename_suggestion: feat-taskflow-pr-demo-section
enhanced_at: 2026-02-26 16:53:34.000000000 +00:00
location: active
llm_model: pi:glm
id: 8pppc7
status: pending
tags: []
created_at: '2026-02-26 16:53:32'
---

# Add Demo Section to PR Description Template

## What I Hope to Accomplish
Standardize PR descriptions to include a "Demo / Testing" section immediately after the summary, providing a short tutorial that enables reviewers and users to quickly test what has been implemented. This addresses a common pain point where PR reviewers must ask "how do I test this?" and reduces onboarding friction for new features.

## What "Complete" Looks Like

PR description template (`.github/PULL_REQUEST_TEMPLATE.md` or similar) includes a structured "## Demo / Testing" section positioned directly after the Summary section. The section includes clear subsections for:
- Quick Start: One-liner command or steps to see the feature in action
- Example Output: Expected result of running the demo
- Edge Cases: Optional section for showing alternative scenarios

Existing PRs are updated with demo sections during merge cleanup, and the `.claude/` integration workflow (ace-git-commit/ace-review agents) is updated to prompt authors for demo content when drafting PR descriptions.

## What "Complete" Looks Like

Success Criteria
- PR template includes "## Demo / Testing" section immediately after Summary
- Demo section has Quick Start + Example Output subsections
- ace-review agent prompts for demo content when analyzing changes
- PR reviewers can execute provided commands to verify implementation
- Demo content is concise (under 10 lines, CLI-focused where possible)

---

## Original Idea

```
pr description needs to have demo section - how can i test what have been implmeented, short tutorial (should be right after the summary part)
```