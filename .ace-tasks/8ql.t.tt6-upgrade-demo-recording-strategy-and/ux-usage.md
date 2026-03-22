# Upgrade Demo Recording — Draft Usage

## API Surface

- [x] CLI (user-facing commands) — `ace-demo record`, `create`, `list`, `show`
- [ ] Developer API (modules, classes) — new atoms/molecules
- [ ] Agent API (workflows, protocols, slash commands) — no changes
- [x] Configuration (config keys, env vars) — `sandbox_dir` in config

## Usage Scenarios

### Scenario 1: Record a Demo from YAML

**Goal**: Record a demo with controlled sandbox data from a `.tape.yml` source

```bash
ace-demo record ace-task-getting-started.tape.yml
```

**Expected output**:
```
Recording ace-task-getting-started.tape.yml...
  → Creating sandbox: .ace-local/demo/sandbox/tt6a3b/
  → Running setup (4 directives)...
  → Compiling VHS tape (3 scenes)...
  → Recording with VHS...
  → Teardown: sandbox removed
Output: .ace-local/demo/ace-task-getting-started.gif
```

### Scenario 2: Record an Old .tape File (Backward Compat)

**Goal**: Existing `.tape` files still work during migration

```bash
ace-demo record hello.tape
```

**Expected output**:
```
Recording hello.tape...
  → Recording with VHS...
Output: .ace-local/demo/hello.gif
```

### Scenario 3: Create a New YAML Demo

**Goal**: Generate a `.tape.yml` template for a new demo

```bash
ace-demo create my-feature
```

**Expected output**:
```
Created docs/demo/my-feature-getting-started.tape.yml
```

### Scenario 4: Setup Command Fails

**Goal**: Sandbox is cleaned up even when setup fails

```bash
ace-demo record broken-setup.tape.yml
```

**Expected output**:
```
Recording broken-setup.tape.yml...
  → Creating sandbox: .ace-local/demo/sandbox/tt6x9z/
  → Running setup (3 directives)...
  ✗ Setup failed at directive 3: "run: nonexistent-command"
  → Teardown: sandbox removed
Error: Setup command failed: nonexistent-command: command not found
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
