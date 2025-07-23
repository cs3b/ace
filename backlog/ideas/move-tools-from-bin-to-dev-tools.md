1. We should move code from bin/ to dev-tools/exe-old and keep only scripts that point to this tools:

- lint-security
- lint-cassetes

2. and for bin/ names consistency we should rename:

bin/cr -> bin/review-code
bin/cr-docs -> bin/review-docs
bin/test-review -> bin/review-test


and update refereces in:

- .claude
- bin
- dev-handbook
- dev-tools
- docs

3. Ensure we properly documented new directory strcutre responsibility:

dev-handbook/           # Guides, workflows, integrations, usage patterns
dev-tools/              # AI utilities, scripts, CLI helpers
dev-taskflow/           # Release lifecycle, tasks, reviews, decisions

Inside the documents:
- docs/architecture.md
- docs/blueprint.md
