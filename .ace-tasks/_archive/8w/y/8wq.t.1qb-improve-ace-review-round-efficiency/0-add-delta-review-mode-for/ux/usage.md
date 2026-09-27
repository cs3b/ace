# Delta review mode - Usage

## API Surface

- [x] CLI (user-facing commands): `--delta` flag for PR review rounds
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Re-review a PR after a new push

**Goal**: Review only what changed since the last reviewed head instead of the whole PR.

```bash
ace-review --pr 171 --delta
```

**Expected output**: A session scoped "delta since <reference head>", where the
reference head is auto-resolved from the most recent prior session of this PR. The
reference session's findings are carried forward as evidence, and a non-empty delta is
reviewed normally at proportional cost.

### Scenario 2: Explicit reference head

```bash
ace-review --pr 171 --delta <head-sha>
```

**Expected output**: A round scoped to the diff `<head-sha>..<current head>`. Evidence
carry-forward from a matching prior session can be added with `--evidence-session`.

### Scenario 3: Nothing changed since the reference head

**Expected output**: The round completes as a recorded no-op session (`review.md`
with `noop_round: true`) — carried-forward findings plus a verdict, zero model calls.

### Scenario 4: No prior session exists

**Expected output**: Refusal explaining that no prior session recorded a reference head
for this PR and no explicit head was given; run a full round or pass `--delta <head>`.
The round never silently falls back to a full review.

### Scenario 5: Reference head is not an ancestor (force-push)

**Expected output**: Refusal citing rewritten history; re-run a full round.

## Behavioral Acceptance Contract

- The session metadata records `diff_manifest.head_sha`, `delta_reference_head` and
  `delta_reference_source` (explicit|session), so a later bare `--delta` chains from it.
- Unchanged files are not part of the reviewed subject; carried-forward findings appear
  in the report/evidence.
- Empty deltas and fully review-exempt deltas (8wq.t.1qb.1) complete as no-op rounds
  with a verdict and zero model calls.
- An oversized selected delta refuses with the token budget named, like full rounds.
