---
description: "E2E runner for installed durable inbox"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-installed-delivery.runner.md
    - ./TC-002-reconciliation.runner.md
    - ./TC-003-installed-pi.runner.md
---

# Installed inbox runner

Execute the three goals in order. Setup and fake native executables are provided
by `scenario.yml`. Run the installed `ace-herdr` executable, not a source
checkout binstub. Save stdout, stderr, and numeric exit codes in the declared
`results/tc/NN/` directories. Do not assign verdicts. Continue to the next goal
if an earlier one fails, preserving the failure evidence.
