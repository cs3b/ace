# Actionable Insights for Implementing a Prompt Compressor

## 1. Structure Beats Natural Language

LLMs handle **structured compact formats** better than verbose Markdown.

**Recommendation**

Convert Markdown into a structured intermediate representation before compression.

Example transformation:

Markdown:

```markdown
## Core Principles
1. CLI-first
2. Transparent
3. Same tools for humans and agents
```

Compressed representation:

```
PRINCIPLES:
- cli_first
- transparent
- shared_tools
```

Benefits:

* fewer tokens
* easier parsing for the model
* less ambiguity

---

# 2. Separate Lossless vs Lossy Compression Modes

You need **two compression modes**.

### Lossless Mode

Use when:

* policies
* decisions
* specs
* workflows

Rules:

* preserve all semantics
* compress formatting
* normalize structure

Expected reduction:

```
40–60%
```

### Lossy Mode

Use when:

* vision
* guides
* README
* architecture summaries

Rules:

* remove narrative
* keep concepts
* drop examples

Expected reduction:

```
70–90%
```

---

# 3. File Type Determines Compression Strategy

Different document types compress differently.

### Highly compressible

* vision documents
* conceptual architecture
* guides
* documentation narratives

Compression potential:

```
80–90%
```

### Moderately compressible

* technical docs
* architecture specs
* API docs

Compression potential:

```
50–70%
```

### Sensitive to compression

* rules
* ADR decisions
* policies
* procedures

Compression potential:

```
30–60%
```

But semantics must be preserved.

---

# 4. Drop Frontmatter by Default

Frontmatter adds many tokens with low reasoning value.

Typical YAML:

```yaml
---
update_frequency: weekly
max_lines: 150
required_sections:
  - overview
---
```

Better representation:

```
META|updated=2026-01-12
```

Policy:

```
default: drop
optional: keep_compact
```

Keep only:

* version
* last_updated
* status
* breaking
* deprecated

Everything else should be removed.

---

# 5. Normalize Repeated Patterns

Many repos repeat the same patterns.

Example patterns found:

* CLI flags
* architecture patterns
* testing pyramids
* configuration cascades

Instead of repeating full text, encode once.

Example:

```
PATTERN atom_architecture
layers=[atoms,molecules,organisms,models]
```

Then reference:

```
ARCHITECTURE|pattern=atom_architecture
```

This significantly reduces tokens.

---

# 6. Replace Long Lists With Encoded Arrays

Markdown lists are verbose.

Example:

```
- ace-search
- ace-docs
- ace-lint
- ace-taskflow
```

Compressed:

```
tools=[ace-search,ace-docs,ace-lint,ace-taskflow]
```

Savings become significant across large repos.

---

# 7. Convert Code Blocks to Tagged Blocks

Markdown code fences waste tokens.

Example:

````markdown
```ruby
resolver = Ace::Support::Config.create
```
````

Better:

```
CODE[ruby]:
resolver = Ace::Support::Config.create
```

Even better (lossy):

```
CODE_REF|config_resolution_example
```

---

# 8. Extract Facts Instead of Sentences

LLMs reason better over **facts than paragraphs**.

Example paragraph:

> ACE uses a configuration cascade where CLI flags override project configuration, which overrides user configuration.

Compressed:

```
CONFIG_CASCADE:
1 CLI
2 project
3 user
4 defaults
```

This reduces tokens while preserving meaning.

---

# 9. Chunk Documents by Semantic Units

Do not compress entire documents blindly.

Split into chunks:

```
META
SUMMARY
RULES
FACTS
EXAMPLES
REFERENCES
```

This improves:

* retrieval
* patch updates
* agent reasoning

---

# 10. Deduplicate Across Files

Repositories contain heavy cross-file duplication.

Example duplicates:

* architecture descriptions
* CLI flag explanations
* testing guidelines

Create a deduplication layer:

```
ENTITY|ATOM_ARCH
ENTITY|CONFIG_CASCADE
ENTITY|TEST_PYRAMID
```

Then reference them.

This can reduce repository context by **30–50%**.

---

# 11. Use Stable IDs for Sections

Assign IDs to sections so they can be patched later.

Example:

```
SEC|id=arch_config
CONFIG_CASCADE:
1 CLI
2 project
3 user
4 defaults
```

This enables efficient updates.

---

# 12. Implement Diff-Based Updates

Instead of sending the entire compressed document again, send patches.

Example patch:

```
PATCH
R|id=arch_config|replace|value=[cli,project,user,defaults,env]
```

Typical savings:

```
3k tokens → 30–200 tokens
```

This is critical for long-running agents.

---

# 13. Avoid Markdown in Final Representation

Markdown introduces:

* formatting noise
* punctuation tokens
* inconsistent structures

Better formats:

```
key=value
ENTITY
RULE
FACT
ARRAY
```

This produces cleaner tokenization.

---

# 14. Encode Meaningful Entities

Represent important project elements as entities.

Example:

```
ENTITY ace_gems
type=ruby_packages
pattern=ATOM
```

Benefits:

* consistent referencing
* smaller prompts
* easier reasoning

---

# 15. Preserve Imperative Rules Exactly

Never summarize rules that contain:

```
must
must not
never
required
only
```

Example rule:

```
RULE:
tests must use flat structure
```

Do **not** compress to:

```
tests use flat structure
```

The imperative semantics matter.

---

# 16. Compress Examples Aggressively

Examples are useful for humans but expensive for prompts.

Strategy:

```
example → example_ref
```

Example:

```
EXAMPLE_REF|ace_git_commit_usage
```

Only include examples when agents must generate similar output.

---

# 17. Preserve Relationships Between Concepts

When compressing, ensure relationships remain explicit.

Example:

```
ace-gems → follow → ATOM architecture
```

Compressed:

```
REL|ace_gems|pattern|ATOM
```

Relationships are often more important than descriptions.

---

# 18. Compression Works Best After Parsing

Do not compress raw Markdown text.

Pipeline should be:

```
Markdown
↓
AST parser
↓
semantic extraction
↓
compression
↓
structured context pack
```

This avoids losing structure.

---

# 19. Use a Consistent Output Schema

All compressed files should follow a predictable schema.

Recommended schema:

```
FILE
META
TYPE
SUMMARY
ENTITIES
RULES
FACTS
RELATIONS
EXAMPLES
```

Consistency improves agent comprehension.

---

# 20. Realistic Compression Targets

Based on experiments:

| document type  | compression |
| -------------- | ----------- |
| vision docs    | 80–90%      |
| architecture   | 60–80%      |
| technical docs | 50–70%      |
| rules / ADRs   | 40–60%      |

Across a repository you can expect:

```
60–85% total reduction
```

---

# Most Important Implementation Takeaways

If you only implement five things:

1. **Structured DSL representation**
2. **Frontmatter removal**
3. **Lossy vs lossless modes**
4. **Entity deduplication**
5. **Diff-based updates**

These deliver the majority of the gains.
