---
description: "E2E verifier for installed durable inbox"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-installed-delivery.verify.md
    - ./TC-002-reconciliation.verify.md
    - ./TC-003-installed-pi.verify.md
---

# Installed inbox verifier

Judge the sandbox state first, then the declared `results/tc/NN/` artifacts,
and use raw stdout/stderr/exit captures to diagnose failures. Give each goal
a PASS or FAIL with specific evidence. Finish with `Results: X/3 passed`.
