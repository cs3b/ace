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
- `conservative_compact`: minimal-safe compaction used when class confidence is low (`class=unknown`).
- `refuse`: compaction denied because fidelity checks failed; caller should retry with `--mode exact`.

## Usage Scenarios

### Scenario 1: Compact a narrative-heavy document

**Goal**: Reduce token footprint aggressively while keeping key concepts and rules.
**Class rationale**: `docs/vision.md` is `narrative-heavy` because it is primarily explanatory prose with few imperative constraints.

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
**Class rationale**: `README.md` and `docs/vision.md` are `narrative-heavy` because repeated examples appear in prose-oriented explanatory sections.

```bash
mise exec -- ace-compressor compress README.md docs/vision.md --mode compact --verbose

# Expected output:
POLICY|source=README.md|class=narrative-heavy|action=aggressive_compact
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
EXAMPLE_REF|id=ace_git_commit_usage|sources=[README.md,docs/vision.md]
```

### Scenario 3: Compact a table with explicit loss declaration

**Goal**: Keep table structure explicit even when row-level detail is reduced.
**Class rationale**: `docs/ace-gems.g.md` is `mixed` because it combines narrative guidance with structured tables.

```bash
mise exec -- ace-compressor compress docs/ace-gems.g.md --mode compact --verbose

# Expected output:
POLICY|source=docs/ace-gems.g.md|class=mixed|action=compact_with_table_guards
TABLE|id=tbl:gem-naming-conventions|mode=schema_plus_key_rows|cols=[pattern,purpose,examples]
LOSS|target=tbl:gem-naming-conventions|type=row_elision|retained_rows=3|original_rows=4
```

**Loss counting note**: `retained_rows` and `original_rows` count data rows only; the header row is excluded from both counts.

### Scenario 4: Refuse unsafe compaction

**Goal**: Stop before a rule-heavy source loses required semantics.
**Class rationale**: `docs/decisions.md` is `rule-heavy` because it records normative ADR decisions and required implementation impacts.

```bash
mise exec -- ace-compressor compress docs/decisions.md --mode compact

# Expected output:
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
REFUSAL|source=docs/decisions.md|reason=fidelity_check_failed|failed_checks=[imperative_rules]
GUIDANCE|retry_with=--mode exact
Error: compact mode cannot safely compress rule-heavy input; retry with --mode exact
```

### Scenario 5: Apply conservative fallback for unknown class

**Goal**: Avoid unsafe aggressive reduction when the classifier cannot determine a safe class.
**Class rationale**: `docs/custom-notes.md` remains `unknown` when classification confidence is insufficient for any narrower safe class.

```bash
mise exec -- ace-compressor compress docs/custom-notes.md --mode compact --verbose

# Expected output:
POLICY|source=docs/custom-notes.md|class=unknown|action=conservative_compact
NOTE|source=docs/custom-notes.md|reason=classification_ambiguous
```

### Scenario 6: Mixed input with per-source policy divergence

**Goal**: Allow one run to produce different policy outcomes per source.
**Class rationale**:
- `docs/vision.md` is `narrative-heavy` because it is mostly explanatory narrative.
- `docs/decisions.md` is `rule-heavy` because imperative requirements must remain exact.

```bash
mise exec -- ace-compressor compress docs/vision.md docs/decisions.md --mode compact --verbose

# Expected output:
POLICY|source=docs/vision.md|class=narrative-heavy|action=aggressive_compact
SUMMARY|source=docs/vision.md|ACE is a CLI-first toolkit for human+agent workflows
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
REFUSAL|source=docs/decisions.md|reason=fidelity_check_failed|failed_checks=[imperative_rules]
GUIDANCE|retry_with=--mode exact
Error: compact mode cannot safely compress rule-heavy input; retry with --mode exact
```

**Exit behavior contract**:
- Mixed-outcome runs return a non-zero process exit when any source refuses.
- Compact output lines for safe sources are emitted before the process exits.
- `class=unknown` with `action=conservative_compact` is non-blocking by itself; only `action=refuse` triggers failure exit.

**Contract assertions (mixed-input refusal + success)**:
- Process exit is non-zero (`1` expected for refusal path).
- Output includes `SUMMARY|source=docs/vision.md|...` for the safe source.
- Output includes `REFUSAL|source=docs/decisions.md|...` for the refusing source.
- Output includes `GUIDANCE|retry_with=--mode exact` retry guidance.

### Scenario 7: Mixed single-source success with exact policy preservation

**Goal**: Permit compact output for mixed content only when critical policy sections are preserved exactly.
**Class rationale**: `docs/blueprint.md` is `mixed` because it blends narrative explanation with constraint-oriented lists.

```bash
mise exec -- ace-compressor compress docs/blueprint.md --mode compact --verbose

# Expected output:
POLICY|source=docs/blueprint.md|class=mixed|action=compact_with_exact_rule_sections
FIDELITY|source=docs/blueprint.md|checks=[imperative_rules,numeric_facts,table_structure]|status=pass
SECTION|source=docs/blueprint.md|id=read_only_paths|mode=exact_preserve
SUMMARY|source=docs/blueprint.md|mode=compact_for_narrative_sections
```

### Scenario 8: Quiet mode still surfaces refusal outcomes

**Goal**: Keep quiet mode terse without hiding safety failures.
**Class rationale**: `docs/decisions.md` stays `rule-heavy` in quiet mode because its imperative decision records still require strict fidelity.

```bash
mise exec -- ace-compressor compress docs/decisions.md --mode compact --quiet

# Expected output:
POLICY|source=docs/decisions.md|class=rule-heavy|action=refuse
Error: compact mode cannot safely compress rule-heavy input; retry with --mode exact
```

## Notes for Implementer
- `compact` is the user-facing name for the lossy mode.
- `--verbose` should expose class and policy decisions per source.
- `--quiet` should suppress verbose detail but never hide refusal/fallback outcomes.
- Refusal output should identify failed fidelity checks when available (rules, facts, table structure).
- When tables are summarized, emit explicit loss metadata instead of silently eliding rows.
- `--dry-run` and `--force` are not defined by this slice and must not bypass refusal safety.
- Full usage documentation gets completed during work-on-task using `wfi://docs/update-usage`.
