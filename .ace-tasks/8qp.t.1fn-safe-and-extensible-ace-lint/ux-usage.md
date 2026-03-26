# Safe and Extensible ace-lint Fix System - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Fix markdown safely (surgical edits)

**Goal**: Fix typography and whitespace violations without altering file structure

```bash
ace-lint --fix docs/**/*.md
```

#### Expected Output

```
Fixed: docs/guide.md (2 violations fixed: em-dash, smart quote)
Clean: docs/api.md (no violations)
============================================================
Validated: 2 files, 2 violations fixed, 0 remaining
```

### Scenario 2: Preview fixes before applying

**Goal**: See what would change without modifying files

```bash
ace-lint --fix --dry-run README.md
```

#### Expected Output

```
Would fix: README.md:15: Em-dash character -> double hyphens
Would fix: README.md:23: Smart double quote -> ASCII quote
2 fixes would be applied in 1 file
```

### Scenario 3: Format with guardrails detects structural damage

**Goal**: Kramdown normalization skips files where it would cause damage

```bash
ace-lint --format README.md
```

#### Expected Output

```
Skipped: README.md (structural change detected: frontmatter would be altered)
0 files formatted, 1 file skipped
```

### Scenario 4: Agent-assisted fix for remaining violations

**Goal**: Fix what can be fixed deterministically, then delegate remaining to LLM agent

```bash
ace-lint --auto-fix-with-agent docs/**/*.md --model gemini:flash-latest
```

#### Expected Output

```
Fixed 3 violations in 2 files.
1 violation remains (launching agent)...
[Agent session output]
All violations resolved.
```

### Scenario 5: Error — agent unavailable

**Goal**: Clear error when ace-llm is not installed

```bash
ace-lint --auto-fix-with-agent README.md
```

#### Expected Output

```
Error: --auto-fix-with-agent requires ace-llm gem. Install with: gem install ace-llm
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
- `--fix` and `--auto-fix` are aliases (single behavior: fix + re-lint + report)
- `-f` alias maps to `--auto-fix`
- `--format` is a separate flag (Kramdown rewrite with guardrails)
