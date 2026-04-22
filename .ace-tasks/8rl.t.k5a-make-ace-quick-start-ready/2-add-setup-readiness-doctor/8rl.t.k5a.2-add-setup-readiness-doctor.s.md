---
id: 8rl.t.k5a.2
status: draft
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: ["project"]
  files:
    - ace-support-config/lib/ace/support/config/cli.rb
    - ace-support-config/lib/ace/support/config/organisms/config_initializer.rb
    - ace-support-config/test/feat/config_initializer_bootstrap_test.rb
    - ace-llm/docs/usage.md
    - .ace-tasks/8rl.t.k5a-make-ace-quick-start-ready/ux-usage.md
  commands:
    - ace-task show 8rl.t.k5a.2
tags: []
parent: 8rl.t.k5a
created_at: "2026-04-22 13:26:05"
---

# Add setup readiness doctor

## Behavioral Specification

### User Experience

- Input: A developer runs `ace-config doctor` after `ace-config init` and `ace-handbook sync`.
- Process: ACE performs non-mutating checks for local setup readiness and prints a concise status report.
- Output: The developer sees pass/fail/warn rows with exact next actions for ignored artifacts, provider package availability, provider discovery, configured aliases, and optional tiny provider probes.

### Expected Behavior

`ace-config doctor` should be a safe readiness check for fresh setup. It should not edit config, install gems, mutate git state, or write tracked files. It should identify setup blockers and warnings that affect the quick-start path, especially CLI providers and `ace-git-commit` readiness.

### Interface Contract

```bash
ace-config doctor
ace-config doctor --json
ace-config doctor --no-probe
```

Default human output should include sections for:

- Project artifact hygiene: whether `.ace-local/` is ignored.
- Provider package availability: whether packages required by configured providers are installed.
- Provider discovery: whether `ace-llm --list-providers` can enumerate configured providers.
- Alias readiness: whether configured aliases resolve to declared models.
- Probe readiness: whether enabled providers can complete a tiny non-mutating prompt when probes are allowed.

Exit behavior:

- Exit `0` when no blockers are found.
- Exit non-zero when one or more blockers prevent the documented quick-start path.
- Warnings do not fail the command unless they also block the quick-start contract.

Error Handling:

- Missing `ace-llm-providers-cli`: print the exact gem name and install guidance.
- `.ace-local/` not ignored: recommend adding `.ace-local/` to the repo root `.gitignore`.
- Unsupported alias: print provider, alias, resolved model, and expected configured models.
- Probe cannot run because credentials or local CLI account are missing: mark as actionable setup guidance, not an internal error.

Edge Cases:

- `--no-probe` skips live prompts and still checks local config shape.
- `--json` returns machine-readable statuses while preserving equivalent facts.
- API-only users can pass doctor if their configured API provider is ready even when unrelated CLI providers are inactive.

## Success Criteria

- `ace-config --help` lists `doctor`.
- `ace-config doctor` produces non-mutating readiness output.
- `ace-config doctor --json` reports the same checks in structured form.
- `ace-config doctor --no-probe` avoids tiny live provider prompts.
- Missing `.ace-local/`, missing CLI provider gem, stale aliases, and failed provider probes are covered by tests.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: users can diagnose fresh setup readiness before trying their first LLM-backed workflow.
- Advisory size: medium.
- Context dependencies: ace-support-config CLI, config initializer behavior, ace-llm provider discovery contract, draft usage doc.

## Verification Plan

### Unit/Component Validation

- Doctor status classification covers pass, warn, and blocker outcomes.
- JSON and text output include equivalent check names and statuses.

### Integration/E2E Validation

- Fresh temporary repo with missing provider gem reports the missing dependency.
- Fresh temporary repo with no `.ace-local/` ignore rule reports the expected remediation.

### Failure/Invalid Path Validation

- Stale Codex alias and failed tiny prompt produce actionable diagnostics without stack traces.

### Verification Commands

- `ace-test ace-support-config`
- `ace-test ace-llm`

## Objective

Give fresh users a single safe command that answers whether ACE setup is ready and what to fix next.

## Scope of Work

- Public CLI readiness interface for setup diagnostics.
- Read-only checks and user-facing output.
- No automatic repair in this subtask.

## Deliverables

### Behavioral Specifications

- Text and JSON doctor output contracts.
- Probe opt-out behavior.

### Validation Artifacts

- `ux-usage.md` scenarios for primary readiness, missing dependency, and no-probe usage.

## Out of Scope

- Installing missing gems.
- Editing `.gitignore`.
- Authenticating provider accounts.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/298
- Draft usage: `.ace-tasks/8rl.t.k5a-make-ace-quick-start-ready/ux-usage.md`
