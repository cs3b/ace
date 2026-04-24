---
id: 8rl.t.ks9.4
status: done
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [README.md, docs/quick-start.md, ace-support-config/lib/ace/support/config/organisms/config_initializer.rb, ace-support-config/test/feat/config_initializer_bootstrap_test.rb, ace-support-core/.ace-defaults/project-root/AGENTS.md, ace-support-core/.ace-defaults/project-root/CLAUDE.md, ace-support-core/.ace-defaults/README.md, ace-llm/test/e2e/TS-LLM-002-provider-discovery/TC-001-list-providers-public-surface.runner.md, ace-git-commit/test/e2e/TS-COMMIT-001-commit-workflow/TC-007-only-staged-contract.runner.md, .ace-tasks/8rl.t.ks9-clarify-ace-quick-start-first/ux-usage.md]
  commands: [ace-task show 8rl.t.ks9.4 --content]
tags: []
parent: 8rl.t.ks9
created_at: "2026-04-22 13:51:35"
needs_review: false
---

# Verify fresh-repo first-use walkthrough

## Behavioral Specification

### User Experience

- Input: A maintainer or agent validates the quick start from a clean repository perspective.
- Process: The verification follows the documented minimal setup path, confirms generated-file expectations, checks provider discovery/readiness guidance, and validates the deterministic setup commit guidance.
- Output: The first-use documentation is protected by a repeatable public-surface validation path.

### Expected Behavior

The first-use walkthrough should verify the user-observable setup contract rather than private internals. It should confirm docs mention generated file categories, generated guidance files identify ACE provenance and customization safety, repo-local commands use `bundle exec`, provider discovery and readiness are distinct, and the first setup commit can be completed deterministically.

### Interface Contract

```bash
bundle add --group "development, test" ...
bundle install
bundle exec ace-config init
bundle exec ace-handbook sync
bundle exec ace-llm --list-providers
bundle exec ace-config doctor
bundle exec ace-bundle project
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

Expected generated guidance-file behavior:

- `AGENTS.md` and `CLAUDE.md` identify ACE as the generator/source of starter guidance when ACE creates them.
- Generated guidance says it is safe to customize for repo-specific guidance.
- Generated guidance names the refresh/sync path through `ace-config init` and/or `ace-handbook sync` as appropriate.

Error Handling:

- Missing provider readiness is accepted only when docs and doctor guidance provide actionable next steps.
- Existing user-owned guidance files should not be overwritten; verification should confirm preservation behavior if that is part of the touched setup surface.

Edge Cases:

- Minimal setup with only Codex integration should not require Claude skill output.
- Full-stack setup docs should still show optional integration packages for non-Codex users.
- Fresh-repo verification should avoid depending on a specific user's live provider credentials.

## Success Criteria

- A fresh-repo validation scenario covers setup-mode selection, generated-file preview, `bundle exec` commands, provider discovery/readiness distinction, generated guidance provenance, and deterministic setup commit recovery.
- Generated `AGENTS.md` and `CLAUDE.md` starter content identifies ACE provenance and customization/refresh expectations where ACE creates those files.
- Verification uses public commands and observable file content.
- Failure-path validation does not require live provider account success.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: the quick-start first-use contract has durable acceptance coverage.
- Advisory size: medium.
- Context dependencies: quick-start docs, config initializer, provider discovery E2E, git-commit staged-only E2E, draft usage doc.

## Verification Plan

### Unit/Component Validation

- Config initializer coverage confirms generated guidance-file content includes provenance/customization guidance when starter files are created.
- Documentation checks confirm generated-file preview and command examples are present.

### Integration/E2E Validation

- Fresh-repo scenario follows the documented command sequence and records user-visible setup output.

### Failure/Invalid Path Validation

- Provider readiness absence and LLM-backed commit failure are valid only when the documented recovery path remains available.

### Verification Commands

- `ace-lint README.md docs/quick-start.md`
- `ace-test ace-support-config`
- `ace-test ace-llm all`
- `ace-test ace-git-commit all`
- `ace-test-e2e ace-llm`
- `ace-test-e2e ace-git-commit`

## Objective

Ensure future quick-start changes preserve the first-use experience described by GitHub issue #299.

## Scope of Work

- Public-surface validation of docs, generated guidance, setup readiness guidance, and deterministic setup commit flow.
- No dependence on live provider credentials for pass/fail correctness.

## Deliverables

### Behavioral Specifications

- Fresh-repo validation contract and generated guidance-file provenance expectations.

### Validation Artifacts

- E2E or equivalent scenario evidence for the first-use walkthrough.

## Out of Scope

- Live provider account entitlement checks.
- End-to-end validation of every optional agent integration.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/299
