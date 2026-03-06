# ace-compressor compact mode - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Compact Policy Action Tokens

`POLICY|...|action=<token>` must use one of the following values:
- `aggressive_compact`: aggressive narrative/example reduction for clearly safe sources.
- `compact_with_table_guards`: compact narrative while preserving table schema/key-row guarantees.
- `compact_with_exact_rule_sections`: compact mixed content while preserving rule-bearing sections exactly.
- `conservative_compact`: minimal-safe compaction used when `class=unknown`.
- `refuse`: compaction denied because fidelity checks failed; caller should retry with `--mode exact`.

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

### Scenario 2: Apply conservative fallback for unknown class

**Goal**: Avoid unsafe aggressive reduction when the classifier cannot determine a safe class.

```bash
mise exec -- ace-compressor compress docs/custom-notes.md --mode compact --verbose

# Expected output:
POLICY|source=docs/custom-notes.md|class=unknown|action=conservative_compact
NOTE|source=docs/custom-notes.md|reason=classification_ambiguous
```

### Scenario 3: Keep safe-source output on mixed refusal

**Goal**: Compact safe docs while refusing unsafe rule-heavy docs.

```bash
mise exec -- ace-compressor compress docs/vision.md docs/decisions.md --mode compact --verbose

# Expected output:
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
SUMMARY|source=docs/vision.md|ACE is a CLI-first toolkit for human+agent workflows
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
REFUSAL|source=docs/decisions.md|reason=fidelity_check_failed|failed_checks=[imperative_rules]
GUIDANCE|retry_with=--mode exact
```

**Exit behavior contract**:
- Mixed-outcome runs return a non-zero process exit when any source refuses.
- Compact output lines for safe sources are emitted before the process exits.
- `class=unknown` with `action=conservative_compact` is non-blocking by itself; only `action=refuse` triggers failure exit.

### Scenario 4: Mixed single-source success with exact policy preservation

**Goal**: Permit compact output for mixed content only when critical policy sections are preserved exactly.

```bash
mise exec -- ace-compressor compress docs/blueprint.md --mode compact --verbose

# Expected output:
POLICY|source=docs/blueprint.md|class=mixed|action=compact_with_exact_rule_sections
FIDELITY|source=docs/blueprint.md|checks=[imperative_rules,numeric_facts,table_structure]|status=pass
SECTION|source=docs/blueprint.md|id=read_only_paths|mode=exact_preserve
SUMMARY|source=docs/blueprint.md|mode=compact_for_narrative_sections
```

### Scenario 5: Compact tables with explicit loss metadata

**Goal**: Reduce structured docs without hiding row elision.

```bash
mise exec -- ace-compressor compress docs/ace-gems.g.md --mode compact --verbose

# Expected output:
POLICY|source=docs/ace-gems.g.md|class=mixed|action=compact_with_table_guards
TABLE|id=tbl:gem-naming|mode=schema_plus_key_rows
LOSS|target=tbl:gem-naming|type=row_elision|retained_rows=3|original_rows=4
```

**Loss counting note**: `retained_rows` and `original_rows` count data rows only; the header row is excluded from both counts.

### Scenario 6: Collapse repeated examples to one reference

**Goal**: Deduplicate repeated examples across sources while preserving provenance.

```bash
mise exec -- ace-compressor compress README.md docs/vision.md --mode compact --verbose

# Expected output:
POLICY|source=README.md|class=narrative-heavy|action=aggressive_compact
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
EXAMPLE_REF|id=ace_git_commit_usage|sources=[README.md,docs/vision.md]
```

### Scenario 7: Quiet mode still surfaces refusal outcomes

**Goal**: Keep quiet mode terse without hiding safety failures.

```bash
mise exec -- ace-compressor compress docs/decisions.md --mode compact --quiet

# Expected output:
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
Error: compact mode cannot safely compress rule-heavy input; retry with --mode exact
```

## Notes for Implementer
- `compact` is the user-facing lossy mode.
- `POLICY|`, `REFUSAL|`, `GUIDANCE|`, `LOSS|`, and `FIDELITY|` are runtime outputs, not doc-only annotations.
- The supported classes are `narrative-heavy`, `mixed`, `rule-heavy`, and `unknown`.
- The supported fidelity checks are `imperative_rules`, `numeric_facts`, and `table_structure`.
- `--verbose` should expose class and policy decisions per source.
- `--quiet` should suppress verbose detail but never hide refusal outcomes.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
