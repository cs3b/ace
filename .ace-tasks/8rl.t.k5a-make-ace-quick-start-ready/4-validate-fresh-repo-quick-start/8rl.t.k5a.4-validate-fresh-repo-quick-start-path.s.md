---
id: 8rl.t.k5a.4
status: draft
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: ["project"]
  files:
    - README.md
    - docs/quick-start.md
    - ace-llm/test/e2e/TS-LLM-002-provider-discovery/scenario.yml
    - ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/scenario.yml
    - ace-support-config/test/feat/config_initializer_bootstrap_test.rb
  commands:
    - ace-task show 8rl.t.k5a.4
tags: []
parent: 8rl.t.k5a
created_at: "2026-04-22 13:26:14"
---

# Validate fresh-repo quick-start path

## Behavioral Specification

### User Experience

- Input: A developer starts from an empty git repository with no Gemfile and follows the documented ACE quick start.
- Process: The setup path installs gems, initializes config, syncs handbook assets, verifies providers, runs doctor, and attempts the first setup commit.
- Output: The documented path is verified as a user-facing workflow, including the expected success path and the actionable failure path.

### Expected Behavior

The fresh-repo quick-start path should be validated end-to-end enough to catch regressions in install guidance, generated defaults, `.ace-local/` ignore behavior, provider discovery, and first setup commit guidance. The scenario should focus on public commands and observable outputs, not private implementation details.

### Interface Contract

```bash
bundle add --group "development, test" ...
bundle install
ace-config init
ace-handbook sync
ace-llm --list-providers
ace-config doctor
ace-git-commit -i "set up ace tooling"
ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

Error Handling:

- If provider credentials or local CLI account access are absent, the workflow verifies that diagnostic output is actionable.
- If `ace-git-commit` cannot generate an LLM message, the workflow verifies the direct-message fallback remains usable.

Edge Cases:

- Existing `.gitignore` should be preserved while adding the required `.ace-local/` ignore rule.
- Generated file volume should be documented and therefore not treated as unexpected.
- Provider discovery may report unavailable providers without failing the whole setup if doctor classifies them as non-blocking for the configured path.

## Success Criteria

- A fresh-repo scenario validates the quick-start command sequence.
- The scenario asserts `.ace-local/` is ignored after initialization.
- The scenario asserts Codex aliases generated for fresh setup do not reference `gpt-5-mini`.
- The scenario asserts provider discovery and doctor output are useful for setup diagnosis.
- The scenario asserts first setup commit failure guidance includes deterministic `-m` fallback.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: public quick-start workflow protects the first-use contract from regressions.
- Advisory size: medium.
- Context dependencies: quick-start docs, LLM provider discovery E2E, git-commit E2E, config initializer tests.

## Verification Plan

### Unit/Component Validation

- Reuse focused package tests from subtasks 0-3.

### Integration/E2E Validation

- Fresh-repo scenario executes public commands in a temporary sandbox and captures user-visible outputs.

### Failure/Invalid Path Validation

- Missing provider readiness and failed LLM-backed commit are accepted only when actionable setup guidance is present.

### Verification Commands

- `ace-test ace-support-config`
- `ace-test ace-llm all`
- `ace-test ace-llm-providers-cli all`
- `ace-test ace-git-commit all`
- `ace-test-e2e ace-llm`
- `ace-test-e2e ace-git-commit`

## Objective

Make the issue #298 fresh-repo reproduction path a durable acceptance check for the full fix.

## Scope of Work

- Public-surface verification of the quick-start workflow.
- Do not depend on a specific user's provider credentials or account entitlements.

## Deliverables

### Behavioral Specifications

- Fresh-repo acceptance workflow with success and failure-path expectations.

### Validation Artifacts

- E2E or equivalent scenario evidence for the complete setup path.

## Out of Scope

- Real credential provisioning.
- Live provider billing or account entitlement assertions.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/298
