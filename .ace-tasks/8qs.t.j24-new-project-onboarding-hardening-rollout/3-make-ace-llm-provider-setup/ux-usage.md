# ace-llm provider setup - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (provider config and env vars)

## Usage Scenarios

### Scenario 1: Discover supported providers
**Goal**: See which providers are available and how to start configuring them.

```bash
ace-llm --list-providers
```

#### Expected Output

The command lists available providers and serves as the canonical next step referenced by runtime errors and docs.

### Scenario 2: Unsupported provider configuration
**Goal**: Understand what to fix when provider config is invalid.

```bash
ace-llm nonexistent "hello"
```

#### Expected Output

The error names supported providers, points to `ace-llm --list-providers`, and gives enough context to correct the config without a stacktrace.

## Notes for Implementer

Full usage documentation to be completed during work-on-task using `wfi://docs/update-usage`.
