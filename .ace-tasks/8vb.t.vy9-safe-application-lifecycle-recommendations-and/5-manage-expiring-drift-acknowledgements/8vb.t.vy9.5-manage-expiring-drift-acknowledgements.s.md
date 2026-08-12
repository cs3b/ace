---
id: 8vb.t.vy9.5
status: draft
priority: high
created_at: "2026-08-12 21:18:29"
estimate: TBD
dependencies: [8vb.t.vy9.0]
tags: [config, recommendations, acknowledgements, updates]
parent: 8vb.t.vy9
bundle:
  presets: [project]
  files: [ace-support-config/lib/ace/support/config/cli.rb, ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb, ace-support-config/lib/ace/support/config/molecules/setup_doctor_reporter.rb, ace-support-config/lib/ace/support/config/organisms/config_resolver.rb, ace-support-config/.ace-defaults/config/config.yml, ace-support-config/test/fast/organisms/setup_doctor_test.rb, ace-support-config/test/feat/cli_test.rb]
  commands: [ace-config doctor --recommendations --json, ace-config doctor --recommendations --check-updates --json, ace-test ace-support-config all]
---

# Manage expiring drift acknowledgements

## Behavioral Specification

### User Experience

- **Input:** A project owner records a temporary acknowledgement for one stable doctor finding and later reruns `ace-config doctor`.
- **Process:** ACE validates project-local acknowledgement metadata, suppresses only the matching current finding while valid, and rechecks it at the declared time boundary.
- **Output:** Active acknowledgements remain auditable; expired or invalid acknowledgements cannot permanently hide configuration drift.

### Expected Behavior

- Acknowledgements are project-local and address a stable recommendation identifier, with required rationale plus actor and recorded-time metadata.
- Every acknowledgement includes an absolute expiry or `recheck_after`; an entry with neither is invalid and suppresses nothing.
- An acknowledgement applies only to the selected profile and matching recommendation/package version constraints declared by the contract.
- Expired acknowledgements cause the finding to reappear in human and structured doctor output with the prior acknowledgement context.
- Normal doctor execution is network-free. Update discovery occurs only when the caller explicitly supplies `--check-updates`.

### Interface Contract

Project configuration represents an acknowledgement as:

```yaml
recommendation_acknowledgements:
  <stable-finding-id>:
    rationale: <non-empty text>
    actor: <identity>
    acknowledged_at: <timestamp>
    expires_at: <timestamp>       # or recheck_after
    profile: <profile>
    recommendation_version: <version constraint>
```

```text
ace-config doctor [--profile <name>] [--check-updates] [--format json]
```

Error Handling:

- Malformed timestamps, empty rationale, unknown finding identifiers, or missing time boundaries are reported and never suppress a finding.
- Network or registry failure under `--check-updates` is reported separately and does not corrupt local recommendations or acknowledgements.
- Clock or version ambiguity resolves conservatively by showing the finding.

Edge Cases:

- An acknowledgement for a finding outside the selected profile has no effect and creates no warning for that package.
- A no-longer-applicable acknowledgement may be reported as unused but does not create a false finding.
- Expiry at the current instant is expired.

## Success Criteria

- Valid acknowledgements record stable ID, rationale, actor/time metadata, profile/version scope, and a finite recheck boundary.
- Active matching entries suppress only their exact finding while remaining visible in structured output.
- Expired, malformed, unknown, ambiguous, or version-mismatched entries never suppress drift.
- Running doctor without `--check-updates` performs no network update discovery.
- Update-check failure leaves local results deterministic and usable.

## Validation Questions

- None open. Project-local storage, finite acknowledgement lifetime, and explicit network opt-in are fixed by issue #311.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Teams can temporarily acknowledge known drift without creating permanent or hidden exceptions
- **Advisory size:** Medium
- **Context dependencies:** Stable recommendation contract, setup configuration cascade, doctor reporting

## Verification Plan

### Unit/Component Validation

- Verify acknowledgement parsing, matching, expiry, version/profile scope, and network opt-in.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Exercise config cascade plus doctor output before acknowledgement, while active, after expiry, and during explicit update discovery.

### Failure/Invalid Path Validation

- Invalid metadata, unknown IDs, clock ambiguity, and update-service failure must expose findings rather than suppress them.

### Verification Commands

- `ace-test ace-support-config all`
- `ace-test-suite --target fast`

## Objective

Provide auditable, self-expiring exceptions for recommendation drift while keeping routine diagnosis offline.

## Scope of Work

- Project-local acknowledgement schema and validation
- Finding/profile/version matching and expiration
- Doctor output for active, expired, invalid, and unused entries
- Explicit `--check-updates` network boundary

## Deliverables

### Behavioral Specifications

- Acknowledgement lifecycle and update-discovery contract

### Validation Artifacts

- Matching, expiry, malformed-state, profile, version, and network-failure scenarios

## Out of Scope

- The base recommendations schema (`8vb.t.vy9.0`)
- Workflow policy checks (`8vb.t.vy9.1`)
- Automatic remote update checks

## References

- https://github.com/cs3b/ace/issues/311
- Parent `8vb.t.vy9`
- Dependency `8vb.t.vy9.0`
- `../ux-usage.md`
