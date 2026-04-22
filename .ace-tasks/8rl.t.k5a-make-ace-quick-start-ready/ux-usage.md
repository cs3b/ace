# ACE Setup Readiness Doctor - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Fresh Setup Readiness

**Goal**: A developer verifies whether a fresh ACE setup is ready before using LLM-backed workflows.

```bash
ace-config doctor
```

## Expected Output

```text
ACE setup doctor
PASS .ace-local/ is ignored
PASS CLI provider package ace-llm-providers-cli is available
PASS Provider discovery completed
PASS Configured model aliases resolve
WARN Some providers require credentials or local account access
```

The command exits `0` when no blocking setup failures are found.

### Scenario 2: Missing CLI Provider Package

**Goal**: A developer sees why CLI providers are unavailable after following an incomplete install command.

```bash
ace-config doctor
```

## Expected Output

```text
ACE setup doctor
BLOCKER CLI provider package missing: ace-llm-providers-cli
Install it with your ACE development/test bundle, then run bundle install.
Run ace-llm --list-providers to confirm provider discovery.
```

The command exits non-zero because the documented CLI-provider quick-start path is blocked.

### Scenario 3: Read-Only Alias Check Without Live Probes

**Goal**: A developer or CI job checks local config shape without sending prompts to any provider.

```bash
ace-config doctor --no-probe
```

## Expected Output

```text
ACE setup doctor
PASS .ace-local/ is ignored
PASS Provider discovery completed
PASS Configured model aliases resolve
SKIP Live provider probes disabled by --no-probe
```

The command does not mutate config, install gems, edit `.gitignore`, or contact providers for prompt completion.

## Notes for Implementer

Full usage documentation should be completed during the work-on-task step using `wfi://docs/update-usage`.
