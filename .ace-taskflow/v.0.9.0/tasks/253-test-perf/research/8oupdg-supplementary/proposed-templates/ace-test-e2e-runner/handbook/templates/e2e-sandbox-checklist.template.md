---
name: e2e-sandbox-checklist
description: Checklist for safe E2E sandbox and external API usage
doc-type: template
purpose: E2E sandbox safety
update:
  frequency: as-needed
  last-updated: '2026-01-31'
---

# E2E Sandbox Checklist: {{test_id}}

## Sandbox Setup
- [ ] Unique sandbox under .cache/ace-test-e2e
- [ ] Project root captured before chdir
- [ ] Repo state clean and isolated

## External API Safety
- [ ] Test account only (no production)
- [ ] Token scopes minimized
- [ ] No tokens printed to logs
- [ ] Cleanup steps documented

## Cleanup
- [ ] Sandbox directory removed or archived
- [ ] Test resources deleted
- [ ] Tokens revoked if needed
