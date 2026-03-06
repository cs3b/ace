## Practical prompt compressor architecture

Build it as a pipeline with explicit stages, not one “summarize” step.

```text
ingest
→ parse
→ classify
→ normalize
→ extract
→ deduplicate
→ compress
→ patch
→ validate
→ emit
```

---

## 1. Core modules

### A. Ingestor

Input:

* markdown files
* plain text files

Responsibilities:

* load file text
* detect encoding
* assign file ID
* record path, hash, timestamp

Output:

```text
RawFile{id,path,text,hash,mtime}
```

---

### B. Parser

Convert source into a structured AST-like form.

Extract:

* frontmatter
* headings
* paragraphs
* lists
* tables
* code blocks
* blockquotes
* links
* chart-like text blocks

Output:

```text
ParsedFile{
  meta,
  blocks:[...],
  sections:[...]
}
```

Do not compress raw text directly. This is one of the biggest implementation wins.

---

### C. File classifier

Classify each file before compression.

Suggested classes:

* vision
* overview
* guide
* architecture
* spec
* decision
* workflow
* policy
* reference
* changelog
* unknown

This determines compression mode.

Example policy:

```text
vision/guide/overview      → lossy
architecture/reference     → hybrid
spec/decision/policy       → lossless
workflow                   → near-lossless
```

---

### D. Normalizer

Normalize noisy formatting before semantic compression.

Operations:

* drop or compact frontmatter
* normalize headings
* collapse whitespace
* standardize bullets
* convert markdown tables to row objects
* normalize code fences
* canonicalize inline links
* rewrite dates to ISO when useful

Output should still preserve meaning, just in a cleaner shape.

---

### E. Semantic extractor

This is where the real value starts.

Extract into typed objects:

* entities
* facts
* rules
* relations
* examples
* commands
* config structures
* decisions
* constraints

Example:

```text
RULE|tests|must_use|flat_structure
FACT|config_cascade|priority|[cli,project,user,defaults]
ENTITY|ace-git-commit|type|cli_tool
REL|ace-git-commit|belongs_to|ace_gems
```

For charts in markdown/text files:

* extract source table if present
* if only textual description exists, encode chart as fact set
* if image reference only, mark as unresolved chart

---

### F. Deduplicator

Run dedup at two levels.

#### Exact dedup

Remove:

* repeated paragraphs
* identical command examples
* duplicated rule descriptions

#### Semantic dedup

Merge near-equivalent content:

* “CLI-first, agent-agnostic”
* “Any agent that can run CLI can use ACE”

Keep one canonical form plus provenance references.

Output:

```text
CanonicalUnit{
  id,
  type,
  content,
  provenance:[...]
}
```

---

### G. Compressor

This stage produces the final compact representation.

It should support 3 modes.

#### 1. Lossless

* preserve all extracted facts/rules/examples
* compress form, not meaning

#### 2. Hybrid

* preserve rules and facts exactly
* compress narrative and examples

#### 3. Lossy

* preserve only reasoning-critical content
* drop prose, compress examples to refs

---

### H. Patch generator

For updates, never recompress and resend everything if not needed.

Instead:

* compare stable IDs
* emit add/replace/delete ops

Example:

```text
R|id=rule:test_structure|value=tests must use flat structure
I|after=fact:config|id=fact:new_flag|value=...
D|id=example:legacy_cli
```

This is much more token-efficient than unified diff for agent consumption.

---

### I. Validator

Critical stage. Compression without validation will drift.

Validate:

* required rules preserved
* numeric values preserved
* important entities preserved
* section coverage acceptable
* unresolved items marked
* token budget met

For lossy mode, validate that:

* every section has a summary or extracted units
* no imperative rule was dropped
* no table vanished silently

---

### J. Emitter

Produce one standard output format.

Recommended:

```text
FILE
META
TYPE
SUMMARY
ENTITIES
RULES
FACTS
RELATIONS
TABLES
EXAMPLES
OPEN_ITEMS
PROVENANCE
```

This should be your canonical “ContextPack”.

---

## 2. Recommended internal data model

Use typed intermediate objects, not freeform strings.

```text
Document
  id
  path
  type
  meta
  sections[]

Section
  id
  title
  blocks[]
  summary

Entity
  id
  name
  type
  aliases[]

Fact
  id
  subject
  predicate
  object
  qualifiers{}
  provenance[]

Rule
  id
  subject
  modality   # must / should / may / never
  action
  provenance[]

Example
  id
  kind
  content
  reduced_ref

PatchOp
  op         # add / replace / delete
  target_id
  payload
```

This makes downstream compression deterministic.

---

## 3. Compression algorithm by content type

### Narrative paragraphs

Transform into:

* summary
* extracted facts
* relations

### Rules / decisions

Transform into:

* exact imperative DSL
* preserve modality words

Example:

```text
RULE|workflow|must_be|self_contained
RULE|paths|must_be|root_relative
RULE|cli_gems|must_use|dry-cli
```

### Lists

Transform into arrays:

```text
tools=[ace-search,ace-docs,ace-lint]
```

### Tables

Transform into:

```text
TABLE|id=tools|cols=[tool,purpose,key_commands]|rows=[...]
```

If too large:

* keep schema
* keep top rows or stats
* mark compression applied

### Code blocks

Modes:

* exact keep
* reduce to essential lines
* replace with symbolic ref

Example:

```text
CODE[ruby]|resolver=Ace::Support::Config.create
```

### Examples

Compress aggressively unless generative mimicry is needed.

```text
EXAMPLE_REF|git_commit_usage
```

---

## 4. Compression policy engine

Create an explicit policy layer.

Example:

```text
policy:
  frontmatter: drop
  examples: compress
  code_blocks: compact
  tables: keep_schema
  decisions: exact_rules
  workflows: preserve_steps
  provenance: minimal
```

Then vary by mode:

### Lossless

```text
frontmatter=compact
examples=keep
code_blocks=keep_compact
tables=full_or_compact
rules=exact
```

### Hybrid

```text
frontmatter=minimal
examples=compress
code_blocks=compact
tables=schema_plus_key_rows
rules=exact
```

### Lossy

```text
frontmatter=drop
examples=drop_or_ref
code_blocks=ref
tables=summary
rules=exact
```

---

## 5. Stable ID strategy

This matters a lot for patching.

Use IDs derived from:

* file path
* section path
* unit type
* normalized content hash

Example:

```text
file:docs/vision.md
sec:core_principles
rule:cli_first
fact:config_cascade
```

Good stable IDs should survive:

* whitespace edits
* heading punctuation edits
* frontmatter changes

Do not use line numbers as primary identity.

---

## 6. Provenance strategy

Keep provenance compact but present.

Example:

```text
P|rule:cli_framework|src=docs/decisions.md#ADR-023
P|fact:config_cascade|src=docs/architecture.md#configuration-cascade
```

For agent use, provenance helps with:

* trust
* traceability
* selective refresh
* conflict resolution

Keep it lightweight.

---

## 7. Token-efficiency heuristics

These heuristics gave the best practical results:

### Good

* short field names
* arrays instead of bullets
* DSL instead of prose
* canonical entity references
* exact rules, compressed narrative

### Bad

* raw markdown
* raw YAML frontmatter
* repeated examples
* repeated explanatory prose
* large unified diffs in prompt context

---

## 8. Suggested output format: `ContextPack/1`

Example:

```text
FILE|id=docs/vision.md|type=vision
META|updated=2026-01-17

SUMMARY|ACE is a CLI-first toolkit for human+agent development workflows

ENTITY|ace|type=toolkit
ENTITY|ace-git-commit|type=cli_tool

FACT|ace|solves|[context_bloat,isolation_boundary,prompt_fragility,lost_flow]
FACT|ace|approach|[cli_tools,file_interchange,composable_workflows]

RULE|tools|should_be|developer_friendly
RULE|agent_api|must_not_exist_as_separate_surface

REL|ace-git-commit|belongs_to|ace
REL|user_override|path|~/.ace/
REL|project_override|path|.ace/

EXAMPLE_REF|ace_git_commit_usage
P|fact:ace:approach|src=docs/vision.md#how-it-works
```

This is much better than sending raw markdown.

---

## 9. Suggested patch format: `PatchPack/1`

Example:

```text
PATCH|base=sha256:abc123
R|id=rule:cli_framework|value=cli gems must use dry-cli
I|after=fact:config_cascade|id=fact:config_reset|value=gems should provide reset_config!
D|id=example:legacy_thor_usage
```

This is simple, compact, and agent-friendly.

---

## 10. Recommended implementation order

Build in this order:

### Phase 1

* parser
* normalizer
* frontmatter drop
* section chunking
* token counting

### Phase 2

* file classifier
* semantic extraction
* rule/fact/entity schema
* ContextPack emitter

### Phase 3

* deduplication
* hybrid/lossy policies
* example compression
* code block compression

### Phase 4

* stable IDs
* patch generation
* validation suite
* incremental update workflow

This avoids overengineering early.

---

## 11. Minimal viable compressor

If you want an MVP that already gives strong gains, implement only:

* markdown parser
* frontmatter drop
* heading/section extraction
* rule/fact extraction
* compact DSL output
* exact-rule preservation
* stable section IDs

That alone can already cut many contexts by 3× to 8×.

---

## 12. Failure modes to guard against

### 1. Compressing prose without extracting rules

You lose “must/never/required”.

### 2. Using raw summarization only

Too nondeterministic and hard to patch.

### 3. No stable IDs

Updates become expensive.

### 4. Keeping examples verbatim

They bloat the prompt.

### 5. Treating all files equally

A vision doc and a policy doc should not use the same strategy.

### 6. Dropping provenance entirely

Harder to debug and refresh.

---

## 13. Best practical target

For implementation, aim for:

* **lossless**: 1.7× to 2.5× reduction
* **hybrid**: 3× to 6× reduction
* **lossy**: 6× to 12× reduction
* **incremental patches**: 20× to 100× smaller than full resend

Those are realistic and useful.

---

## 14. Final recommended architecture

```text
Raw Markdown/Text
  ↓
Parser
  ↓
Typed IR
  ↓
Classifier
  ↓
Normalizer
  ↓
Extractor (rules/facts/entities/examples/tables)
  ↓
Deduplicator
  ↓
Policy Engine (lossless/hybrid/lossy)
  ↓
ContextPack Emitter
  ↓
PatchPack Generator
  ↓
Validator
```


