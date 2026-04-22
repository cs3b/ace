---
id: 8rl.t.k5a.0
status: pending
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [README.md, docs/quick-start.md, ace-llm/docs/getting-started.md, ace-llm/docs/usage.md]
  commands: [ace-task show 8rl.t.k5a.0]
tags: []
parent: 8rl.t.k5a
created_at: "2026-04-22 13:25:58"
needs_review: false
---

# Align quick-start install guidance with CLI providers

## Behavioral Specification

### User Experience

- Input: A developer reads the README or `docs/quick-start.md` to set up ACE in a fresh repo.
- Process: The developer copies the full-stack install command and runs the setup sequence.
- Output: The installed bundle includes the package needed for CLI-backed providers, and the docs set expectations about generated setup files before the first large diff appears.

### Expected Behavior

The full-stack quick-start path should include `ace-llm-providers-cli` wherever it promises CLI-backed provider support through Codex, Claude, Gemini, OpenCode, or pi. The docs should distinguish this from API-only provider setup and should tell users that `ace-config init` and `ace-handbook sync` intentionally generate a large tracked file set under `.ace/`, provider skill directories, guidance files, and Bundler files.

### Interface Contract

```bash
bundle add --group "development, test" ... ace-llm ace-llm-providers-cli ...
bundle install
ace-config init
ace-handbook sync
ace-llm --list-providers
```

Error Handling:

- If CLI providers are listed as unavailable because `ace-llm-providers-cli` is missing, docs point back to the full-stack install command.
- If users want API providers only, docs state that local CLI provider probes may remain unavailable without blocking API-backed ACE usage.

Edge Cases:

- README and quick-start examples remain consistent.
- Optional handbook integration packages remain optional and are not confused with `ace-llm-providers-cli`.

## Success Criteria

- README full-stack install command includes `ace-llm-providers-cli`.
- `docs/quick-start.md` full-stack install command includes `ace-llm-providers-cli`.
- Quick-start docs explain that setup can generate hundreds of tracked setup files and list the main generated locations.
- Provider verification guidance says `ace-llm --list-providers` is the canonical provider availability check.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: users copy a complete install command and are not surprised by generated setup artifacts.
- Advisory size: small.
- Context dependencies: README, quick-start docs, ace-llm provider docs.

## Verification Plan

### Unit/Component Validation

- Documentation check confirms both quick-start install examples include `ace-llm-providers-cli`.

### Integration/E2E Validation

- Fresh-repo quick-start scenario uses the documented install list and sees CLI providers discovered after bundle install when local CLIs are present.

### Failure/Invalid Path Validation

- Missing provider package scenario results in guidance that names `ace-llm-providers-cli`.

### Verification Commands

- `ace-lint README.md docs/quick-start.md`

## Objective

Remove first-use friction caused by incomplete install guidance and undisclosed generated file volume.

## Scope of Work

- Include public install and setup guidance only.
- Do not change provider runtime behavior in this subtask.

## Deliverables

### Behavioral Specifications

- Docs state what users install, how they verify providers, and what generated files to expect.

### Validation Artifacts

- Documentation validation for quick-start consistency.

## Out of Scope

- Provider model aliases.
- Setup doctor behavior.
- Commit generation failures.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/298
