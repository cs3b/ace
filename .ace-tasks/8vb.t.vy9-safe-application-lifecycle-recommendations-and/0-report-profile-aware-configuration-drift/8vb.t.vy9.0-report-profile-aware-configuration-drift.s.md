---
id: 8vb.t.vy9.0
status: done
priority: high
created_at: "2026-08-12 21:18:14"
estimate: TBD
dependencies: []
tags: [config, doctor, recommendations, json]
parent: 8vb.t.vy9
bundle:
  presets: [project]
  files: [ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb, ace-support-config/lib/ace/support/config/molecules/setup_doctor_reporter.rb, ace-support-config/lib/ace/support/config/cli.rb, ace-support-config/.ace-defaults/config/config.yml, ace-support-config/test/fast/organisms/setup_doctor_test.rb, ace-support-config/test/feat/cli_test.rb]
  commands: [ace-config doctor --no-probe, ace-config doctor --no-probe --json]
needs_review: false
---

# Report profile-aware configuration drift

## Behavioral Specification

### User Experience

- **Input:** A developer runs doctor recommendations with an optional profile, output format, strictness, or update check.
- **Process:** ACE resolves the selected profile and evaluates offline, versioned recommendations shipped by installed packages.
- **Output:** Human and JSON reports explain each finding, its owner, current state, desired state, and next action without modifying the project.

### Expected Behavior

Recommendation mode supports `minimal`, `application`, and `ace-development`. Selection precedence is CLI profile, project profile, then `minimal`. The existing setup-health mode remains available and unchanged.

Each finding exposes a stable ID, severity (`blocker`, `warning`, `recommendation`, or `info`), profile, evidence, resolved source, current value, recommended value, rationale, next action, and recommendation/package version. Package-owned defaults are attributed to their package rather than blamed on project overrides.

### Interface Contract

```bash
ace-config doctor --recommendations
ace-config doctor --recommendations --profile application
ace-config doctor --recommendations --json
ace-config doctor --recommendations --strict
ace-config doctor --recommendations --check-updates
```

Error Handling:

- An unknown profile exits nonzero and lists the accepted values.
- Normal recommendation mode remains successful even when findings exist; strict mode exits nonzero for blocker or warning findings.
- A requested update check that cannot reach its source reports an explicit informational failure without corrupting offline findings.

Edge Cases:

- A project with no profile uses `minimal` and is not warned about absent full-stack capabilities.
- Normal recommendations make no network calls; only `--check-updates` may do so.
- Human and JSON views represent the same ordered finding set.

## Success Criteria

- Profile selection follows CLI > project > `minimal` and is visible in output.
- Finding records expose every required field with stable IDs and deterministic JSON.
- Existing doctor behavior remains unchanged when `--recommendations` is absent.
- Normal mode is read-only and non-failing for recommendation findings; strict mode fails on blocker/warning findings.
- Package default drift identifies the owning package and source layer.

## Validation Questions

- None open. The approved unconfigured fallback is `minimal`; network discovery is opt-in only.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Users can obtain a versioned, profile-aware drift report through doctor
- **Advisory size:** Medium
- **Context dependencies:** Current setup doctor, reporter, CLI options, config cascade, and doctor tests

## Verification Plan

### Unit/Component Validation

- Verify profile precedence, finding normalization, severity handling, source attribution, and deterministic serialization.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Exercise human/JSON equivalence for minimal and application fixtures through the public CLI.

### Failure/Invalid Path Validation

- Invalid profiles fail clearly; unavailable opt-in update checks do not erase offline results; recommendation mode writes no project files.

### Verification Commands

- `ace-test ace-support-config all`
- `ace-config doctor --recommendations --profile minimal --json`

## Objective

Extend first-install health into a stable lifecycle recommendation surface that projects and CI can run repeatedly as ACE evolves.

## Scope of Work

- Profile selection and versioned finding contract
- Human/JSON output and strict exit semantics
- Offline default behavior and explicit update discovery
- Package/source attribution

## Deliverables

### Behavioral Specifications

- CLI, profile, finding, and exit contracts in this task

### Validation Artifacts

- Profile, output, attribution, strictness, and read-only scenarios

## Out of Scope

- The semantic workflow checks themselves (`8vb.t.vy9.1`)
- Automatically applying recommendations
- Update installation or dependency mutation

## References

- https://github.com/cs3b/ace/issues/311
- Parent `8vb.t.vy9`
- `../ux-usage.md`
