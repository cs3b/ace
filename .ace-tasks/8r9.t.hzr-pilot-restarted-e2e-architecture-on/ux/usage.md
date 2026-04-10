# Restarted testing structure - draft usage

## API Surface
- [x] CLI
- [ ] Developer API
- [ ] Agent API
- [ ] Configuration

## Usage Scenarios

### Scenario 1: Run deterministic sandboxed package coverage
Goal: Run the package’s deterministic sandboxed E2E-style tests through ordinary ace-test.

Command:
ace-test ace-b36ts e2e

Expected output:
- runs only ace-b36ts/test/e2e/**/*_test.rb
- executes from sandboxed package copies, not the developer worktree
- reports ordinary Minitest results through ace-test

### Scenario 2: Run deterministic coverage across the monorepo
Goal: Run all package test/e2e suites explicitly.

Command:
ace-test-suite --target e2e

Expected output:
- passes e2e to each package-level ace-test
- leaves default ace-test-suite behavior unchanged when --target is omitted

### Scenario 3: Run one package’s agent scenario
Goal: Validate the package’s real agent experience without mixing in deterministic Minitest.

Command:
ace-test-e2e ace-b36ts

Expected output:
- runs only package scenarios from test-e2e/scenarios
- saves the final response as the scenario-owned text output
- verifies the result from the final response plus sandbox state
