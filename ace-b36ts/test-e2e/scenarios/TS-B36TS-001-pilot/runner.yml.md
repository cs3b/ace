---
description: "E2E runner input for ace-b36ts real-work scenario"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-notes-reorganization.runner.md
---

# E2E Test Runner: ace-b36ts Real-Work Scenario

Tool under test: ace-b36ts
Workspace root: (current directory)

Execute the scenario exactly once, producing concrete filesystem outcomes and one final reflection artifact.

Rules:
- Use `ace-b36ts` commands for timestamp IDs; do not fabricate IDs.
- Move all files from `notes/inbox/` into `notes/archive/{year}/{month}/{week}/`.
- Prefix each filename with a b36ts token generated from the note's date.
- Save your final reflection to `results/tc/01/final-reflection.txt`.
- Reflection must list: commands used, grouping strategy, and any assumptions.
