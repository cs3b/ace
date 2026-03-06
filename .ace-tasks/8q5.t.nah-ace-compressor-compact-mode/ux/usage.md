# ace-compressor compact mode - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Compact a narrative-heavy document

**Goal**: Reduce token footprint aggressively while keeping key concepts and rules.

```bash
mise exec -- ace-compressor compress docs/vision.md --mode compact

# Expected output:
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
SUMMARY|ACE is a CLI-first toolkit for human+agent workflows
FACT|id=fact:ace:approach|value=[cli_tools,file_interchange,composable_workflows]
EXAMPLE_REF|id=ace_git_commit_usage
```

### Scenario 2: Collapse repeated examples to one reference

**Goal**: Deduplicate repeated examples across sources while preserving provenance.

```bash
mise exec -- ace-compressor compress README.md docs/vision.md --mode compact --verbose

# Expected output:
POLICY|source=README.md|class=narrative-heavy|action=aggressive_compact
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
EXAMPLE_REF|id=ace_git_commit_usage|sources=[README.md,docs/vision.md]
```

### Scenario 3: Compact a table with explicit loss declaration

**Goal**: Keep table structure explicit even when row-level detail is reduced.

```bash
mise exec -- ace-compressor compress docs/ace-gems.g.md --mode compact --verbose

# Expected output:
POLICY|source=docs/ace-gems.g.md|class=mixed|action=compact_with_table_guards
TABLE|id=tbl:gem-naming-conventions|mode=schema_plus_key_rows|cols=[pattern,purpose,examples]
LOSS|target=tbl:gem-naming-conventions|type=row_elision|retained_rows=3|original_rows=4
```

### Scenario 4: Refuse unsafe compaction

**Goal**: Stop before a rule-heavy source loses required semantics.

```bash
mise exec -- ace-compressor compress docs/decisions.md --mode compact

# Expected output:
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
Error: compact mode cannot safely compress rule-heavy input; retry with --mode exact
```

### Scenario 5: Apply conservative fallback for unknown class

**Goal**: Avoid unsafe aggressive reduction when the classifier cannot determine a safe class.

```bash
mise exec -- ace-compressor compress docs/custom-notes.md --mode compact --verbose

# Expected output:
POLICY|source=docs/custom-notes.md|class=unknown|action=conservative_compact
NOTE|source=docs/custom-notes.md|reason=classification_ambiguous
```

### Scenario 6: Mixed input with per-source policy divergence

**Goal**: Allow one run to produce different policy outcomes per source.

```bash
mise exec -- ace-compressor compress docs/vision.md docs/decisions.md --mode compact --verbose

# Expected output:
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
Error: compact mode cannot safely compress rule-heavy input; retry with --mode exact
```

## Notes for Implementer
- `compact` is the user-facing name for the lossy mode.
- `--verbose` should expose class and policy decisions per source.
- `--quiet` should suppress verbose detail but never hide refusal/fallback outcomes.
- When tables are summarized, emit explicit loss metadata instead of silently eliding rows.
- `--dry-run` and `--force` are not defined by this slice and must not bypass refusal safety.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
