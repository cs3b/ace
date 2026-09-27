# Exempt-path scopes - Usage

## API Surface

- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars): `exempt_paths` review config key

## Usage Scenarios

### Scenario 1: Docs-only delta accepted without a model call

**Goal**: A delta round (`--delta`) whose changed files all match declared-exempt paths
completes free.

```yaml
# .ace/review/config.yml (project) or preset
exempt_paths:
  - "CHANGELOG.md"
  - "**/*.golden"
```

```bash
ace-review --pr 171 --delta
```

**Expected output**: A recorded no-op session — `review.md` states the delta is
review-exempt, lists the exempt paths and the patterns that matched them, and carries
prior findings forward as evidence. Zero model calls; `metadata.yml` has
`noop_round: true`, `noop_reason: exempt_delta`.

### Scenario 2: Mixed delta (exempt + non-exempt paths)

**Expected output**: The round reviews only the non-exempt paths; the exempt paths are
enumerated in the diff manifest (`exempt_files`, `exempt_patterns`) and in the report.
The non-exempt part is never silently skipped.

### Scenario 3: Full round touching exempt paths

**Expected output**: Exempt paths are excluded from the subject and listed, but the
round is never converted into a no-op (full rounds are explicit operator intent). If
every changed file is exempt, the round refuses — an empty subject cannot be reviewed.

### Scenario 4: Overly broad pattern refused at config load

```yaml
exempt_paths:
  - "**"
```

**Expected output**: Config-load refusal naming the offending pattern, e.g.
`Invalid exempt_paths ... pattern '**' matches every path; refusing to exempt the
world`. Non-string or empty pattern values are refused the same way.

## Behavioral Acceptance Contract

- Pattern validation happens at config load, before any fetch or model call.
- Matching uses destination (b/) paths, consistent with the diff manifest, via the same
  glob semantics as file_patterns (`SubjectFilter`).
- Exemption decisions are visible in the session report (which paths, which patterns).
