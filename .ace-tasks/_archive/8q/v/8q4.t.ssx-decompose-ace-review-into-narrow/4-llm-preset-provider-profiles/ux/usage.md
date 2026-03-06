# ace-llm preset-qualified model targets - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Reuse a named review runtime profile

**Goal**: Run a model with a reusable high-depth review profile without rewriting timeout or token options on each call

```bash
ace-llm query claude:sonnet@review-deep "Summarize likely correctness risks in this diff"

# Expected output:
# Provider/model resolves successfully and the named execution preset is applied.
```

### Scenario 2: Override one option while keeping the preset

**Goal**: Start from a reusable preset but override one runtime choice explicitly for a single run

```bash
ace-llm query gflash@review-fast --temperature 0.0 "List only blocking issues"

# Expected output:
# The review-fast preset is used, but explicit temperature overrides the preset default.
```

### Scenario 3: Invalid preset reference fails early

**Goal**: Get a clear setup error when a referenced preset does not exist

```bash
ace-llm query claude:sonnet@missing-preset "Summarize this diff"

# Expected output:
# An actionable error names the missing preset and no provider request is attempted.
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
