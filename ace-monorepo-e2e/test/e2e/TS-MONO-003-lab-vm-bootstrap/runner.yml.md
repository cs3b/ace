---
description: "Autonomous bootstrap and ordered Forgejo integration: runner"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-bootstrap.runner.md
    - ./TC-002-forgejo-delivery.runner.md
    - ./TC-003-idle.runner.md
---

# Autonomous bootstrap and ordered Forgejo integration

Read `results/setup/fixture.json` for this exact VM/run and source path. The
source's `ace-monorepo-e2e/lab-vm/README.md` documents host instrumentation.
This is a disposable UTM fixture using only local Forgejo.

Execute cases in order. Setup belongs to scenario.yml. Supply user goals and
controlled faults; never implement, assign, review or merge for the Overseer.
Record actual CLI stdout, stderr and numeric exit status as `commands.stdout`,
`commands.stderr`, `commands.exit` within each declared case directory. Preserve
owner/native state in `state.json` and redacted model-turn/tool-action evidence
in `sessions.json`; these must be actual captured records, never synthesized
success summaries. Raw session records and secrets remain in private VM evidence.
Do not print credential files. On failure preserve/export evidence and stop the
owned VM through its helper; do not reset, silently repair or continue dependent
cases. Runner observations are harness-managed; do not assign verdicts.
