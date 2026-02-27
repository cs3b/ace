# Goal 2 Verification: Preset and Step Config Contract

PASS when:
- `results/tc/02/presets.ls` contains `validate-idea.yml`
- `results/tc/02/steps.ls` contains `draft.md`, `plan.md`, and `work.md`
- `results/tc/02/validate-idea.yml` contains `steps:` with `draft`, `plan`, and `work`
- each step file snapshot contains `embed_document_source: true`
- each step file snapshot contains `./input.md`
