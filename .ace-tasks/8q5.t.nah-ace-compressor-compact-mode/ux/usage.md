# ace-compressor compact mode - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compact a narrative-heavy document

**Goal**: Produce smaller output than exact mode on safe narrative input.

```bash
mise exec -- ace-compressor compress docs/vision.md --mode compact

# Expected output:
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
SUMMARY|source=docs/vision.md|ACE is a CLI-first toolkit for human+agent workflows
EXAMPLE_REF|id=ace_git_commit_usage
```

### Scenario 2: Keep safe-source output on mixed refusal

**Goal**: Compact safe docs while refusing unsafe rule-heavy docs.

```bash
mise exec -- ace-compressor compress docs/vision.md docs/decisions.md --mode compact --verbose

# Expected output:
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
SUMMARY|source=docs/vision.md|ACE is a CLI-first toolkit for human+agent workflows
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
REFUSAL|source=docs/decisions.md|reason=fidelity_check_failed
GUIDANCE|retry_with=--mode exact
```

### Scenario 3: Compact tables with explicit loss metadata

**Goal**: Reduce structured docs without hiding row elision.

```bash
mise exec -- ace-compressor compress docs/ace-gems.g.md --mode compact --verbose

# Expected output:
POLICY|source=docs/ace-gems.g.md|class=mixed|action=compact_with_table_guards
TABLE|id=tbl:gem-naming|mode=schema_plus_key_rows
LOSS|target=tbl:gem-naming|type=row_elision|retained_rows=3|original_rows=4
```

## Notes for Implementer
- `compact` is the user-facing lossy mode.
- `POLICY|`, `REFUSAL|`, `GUIDANCE|`, and `LOSS|` are runtime outputs, not doc-only annotations.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
