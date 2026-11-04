---
description: "Autonomous bootstrap and ordered Forgejo integration: verifier"
bundle:
  embed_document_source: true
  params:
    output: cache
    max_size: 81920
  files:
    - ./TC-001-bootstrap.verify.md
    - ./TC-002-forgejo-delivery.verify.md
    - ./TC-003-idle.verify.md
---

# Autonomous bootstrap and ordered Forgejo integration

Read `results/setup/fixture.json` for this exact VM/run and source path. The
source's `ace-monorepo-e2e/lab-vm/README.md` documents host instrumentation.
This is a disposable UTM fixture using only local Forgejo.

Inspect final VM/Forgejo/project state first, then owner/native records and
actual command captures. A test is not passed by a model statement, a launch,
a synthetic component probe or a task marked done alone. Missing evidence is
FAIL. Never infer acceptance from artifact existence. Check source SHA, manifest
hash and native artifact provenance against the setup receipt. Render a verdict
and cite concrete evidence for each case, then the passed/total count.
