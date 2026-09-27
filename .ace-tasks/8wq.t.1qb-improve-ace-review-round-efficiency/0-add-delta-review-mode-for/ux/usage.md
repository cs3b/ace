# Delta review mode - Draft Usage

## API Surface

- [x] CLI (user-facing commands): new `--delta` flag for PR review rounds
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Re-review a PR after a new push

**Goal**: Review only what changed since the last reviewed head instead of the whole PR.

```bash
ace-review --pr 171 --delta
```

**Expected output**: A session scoped "delta since <recorded head from the previous
round>", carrying forward prior findings as evidence, with a normal verdict.

### Scenario 2: No prior session exists

**Goal**: Refuse clearly rather than silently doing a full review.

```bash
ace-review --pr 171 --delta
```

**Expected output**: Refusal explaining that no prior session recorded a reference
head for this PR and no explicit head was given; suggests a full round or an explicit
`--delta <head>`.

## Behavioral Acceptance Contract

- The session records the reference head it used (explicit or auto-resolved).
- Unchanged files are not part of the reviewed subject; carried-forward findings appear
  in the report.
- Empty deltas complete as no-op rounds with a verdict and no model call.

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using
  `wfi://docs/update-usage`.
