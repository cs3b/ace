---
description: "E2E verifier input for ace-git-worktree task-aware goal-based tests"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-help-survey.verify.md
    - ./TC-002-create-task-worktree.verify.md
    - ./TC-003-list-and-filter.verify.md
    - ./TC-004-switch-by-task.verify.md
    - ./TC-005-multi-task.verify.md
    - ./TC-006-json-metadata.verify.md
    - ./TC-007-remove-and-cleanup.verify.md
---

# E2E Verification: ace-git-worktree (Task-Aware)

You are an E2E test verifier. You inspect artifacts and render PASS/FAIL verdicts.

## Rules

- Use impact-first verification order:
  1. sandbox/project state impact
  2. explicit artifacts under `results/tc/{NN}/`
  3. debug captures (`stdout`, `stderr`, `.exit`) only as fallback
- Evaluate each goal independently based solely on the artifacts provided
- Do not speculate about what the runner did — only judge what exists
- For each goal, cite specific evidence (filenames, content snippets)
- Follow the output format exactly

## Output Format

For each goal output:

### Goal N — <title>
- **Verdict**: PASS | FAIL
- **Evidence**: <specific file/content citations>

Final line: **Results: X/7 passed**
