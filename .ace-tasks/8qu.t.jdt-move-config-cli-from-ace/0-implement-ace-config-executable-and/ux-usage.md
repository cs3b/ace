# ace-config — Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Initialize all gem configs

**Goal**: Set up `.ace/` directory with default configuration for all installed ace-* gems

```bash
$ ace-config init
```

### Expected Output

```
Initializing all ace-* gem configurations...
  Copied: .ace/bundle/config.yml
  Copied: .ace/handbook/config.yml
  ...
Configuration initialization complete:
  Files copied: 12
  Files skipped: 0
```

### Scenario 2: Initialize a specific gem

**Goal**: Initialize config for just one gem

```bash
$ ace-config init ace-bundle --dry-run
```

### Expected Output

```
  Would copy: /path/to/.ace-defaults/bundle/config.yml -> .ace/bundle/config.yml
```

### Scenario 3: Diff configs against defaults

**Goal**: See which configs have drifted from their shipped defaults

```bash
$ ace-config diff --one-line
```

### Expected Output

```
MISSING: .ace/review/config.yml
CHANGED: .ace/bundle/config.yml
SAME:    .ace/handbook/config.yml

Summary:
  Missing: 1
  Changed: 1
  Same: 1
```

### Scenario 4: List available gems

**Goal**: See which ace-* gems provide configuration

```bash
$ ace-config list
```

### Expected Output

```
Available ace-* gems with example configurations:

  ace-bundle [local+gem]
  ace-handbook [local+gem]
  ...

Use 'ace-config init [GEM]' to initialize a specific gem's configuration
Use 'ace-config init' to initialize all configurations
```

### Scenario 5: Unknown command (error path)

**Goal**: Confirm error handling for invalid input

```bash
$ ace-config bogus
```

### Expected Output

```
Unknown command: bogus

NAME
  ace-config - Configuration management for ace-* gems
...
```

(exit code 1)

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
