# Frontmatter-Free README.md Support - Draft Usage

## API Surface

- [x] CLI (user-facing commands) — `ace-docs status`, `ace-docs discover`, `ace-docs update`
- [x] Developer API (modules, classes) — DocumentLoader, TypeInferrer, ReadmeMetadataInferrer, GitDateResolver
- [ ] Agent API (workflows, protocols, slash commands) — no changes
- [x] Configuration (config keys, env vars) — new `user` document type in config

## Usage Scenarios

### Scenario 1: README Without Frontmatter Appears in Status

**Goal**: README.md files are automatically discovered and tracked without frontmatter

```bash
ace-docs status
```

### Expected Output

```
ace-bundle/README.md    user    current    User-facing introduction for ace-bundle
ace-docs/README.md      user    current    User-facing introduction for ace-docs
ace-lint/README.md      user    current    User-facing introduction for ace-lint
...
```

### Scenario 2: Lint Passes on README Without Frontmatter

**Goal**: ace-lint does not require frontmatter for README.md files

```bash
ace-lint ace-bundle/README.md
```

### Expected Output

```
ace-bundle/README.md: OK
```

(No "Missing required field: 'doc-type'" or "Missing required field: 'purpose'" errors)

### Scenario 3: README With Explicit Frontmatter Still Works

**Goal**: Backward compatibility — frontmatter values override inferred values

```bash
# README.md with explicit frontmatter:
# ---
# doc-type: reference
# purpose: Custom purpose override
# ---
ace-docs status
```

### Expected Output

```
my-package/README.md    reference    ...    Custom purpose override
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
