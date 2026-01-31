---
workflow-id: wfi-e2e-sandbox-setup
name: E2E Sandbox Setup
description: Standardized sandbox setup for safe E2E tests and external API usage
version: "1.0"
source: ace-test-e2e-runner
---

# E2E Sandbox Setup Workflow

This workflow defines a safe, repeatable sandbox process for E2E tests, including third-party API usage.

## Steps

1. **Capture project root** before changing directories
2. **Generate timestamp ID** with `ace-timestamp`
3. **Create sandbox directory** under `.cache/ace-test-e2e/`
4. **Configure environment** (test tokens, limited scopes)
5. **Confirm isolation** (no operations in repo root)
6. **Run E2E test** using the sandbox
7. **Cleanup resources** (repos, API artifacts, tokens if required)

## Safety Rules

- Never use production credentials
- Minimize token scopes
- Do not print secrets to logs
- Use dedicated test accounts
- Prefer provider sandbox/test endpoints

## Output

Record the sandbox checklist for each test run.

<documents>
  <template path="ace-test-e2e-runner/handbook/templates/e2e-sandbox-checklist.template.md"># E2E Sandbox Checklist: {{test_id}}

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
</template>
</documents>
