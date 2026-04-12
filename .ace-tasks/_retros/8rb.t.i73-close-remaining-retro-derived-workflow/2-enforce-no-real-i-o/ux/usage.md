# Test Discipline and Profiling - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (CI or verification policy)

## Usage Scenarios

### Scenario 1: Profile without breaking command-integrity rules
**Goal**: A maintainer profiles tests and reviews the slow cases without piping or redirecting `ace-test`.

`ace-test --profile 10`

**Expected Output**: The workflow treats the tool’s native output or referenced artifacts as the source of truth and does not instruct shell post-processing that violates repo policy.

### Scenario 2: Detect policy violation in unit tests
**Goal**: A new unit test performs subprocess, filesystem, network, or sleep behavior.

`ace-test --profile 10`

**Expected Output**: The verification or CI policy surfaces the violation as a test-discipline problem rather than silently relying on manual reviewer memory.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
