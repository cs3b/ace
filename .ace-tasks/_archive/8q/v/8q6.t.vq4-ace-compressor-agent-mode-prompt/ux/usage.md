# ace-compressor agent mode - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (prompt composition and ace-llm selection come from existing ACE config patterns)

## Agent Mode Contract

`agent` is a quality-first compression mode for agents.

- It must not behave like a broad summary generator.
- It should minify, simplify, canonicalize, and deduplicate while preserving nearly all instructions and reasoning-critical content.
- It uses prompt-composed `ace-llm` flow rather than hardcoded inline prompt strings.
- If agent compression cannot produce a valid result, the CLI degrades to `exact` and emits explicit fallback metadata.

## Usage Scenarios

### Scenario 1: Compress a narrative doc with near-lossless minification

**Goal**: Remove repeated framing and boilerplate from a narrative source without losing core instructions, facts, or examples.

```bash
mise exec -- ace-compressor docs/vision.md --mode agent --format stdio
```

**Expected output** (excerpt):

```text
H|ContextPack/3|agent
FILE|docs/vision.md
POLICY|class=narrative-heavy|action=agent_minify
SEC|ace_vision
FACT|Any agent that can run CLI commands and access the filesystem can use ACE.
EXAMPLE_REF|tool=ace-git-commit|source=docs/vision.md|reason=duplicate_example
```

### Scenario 2: Compress a dense technical document without compact-mode underperformance

**Goal**: Reduce boilerplate and repeated explanation from a technical reference doc while preserving technical facts, rules, and configuration details.

```bash
mise exec -- ace-compressor docs/architecture.md --mode agent --format stats
```

**Expected output** (excerpt):

```text
Cache:    miss
Output:   /.../.ace-local/compressor/agent/docs/architecture.<hash>.agent.pack
Sources:  1 file
Mode:     agent
Original: ...
Packed:   ...
Change:   ...
```

### Scenario 3: Degrade to exact when agent compression is unavailable or invalid

**Goal**: Keep the run usable when `ace-llm` cannot produce a valid agent result.

```bash
mise exec -- ace-compressor docs/decisions.md --mode agent --verbose
```

**Expected output** (excerpt):

```text
H|ContextPack/3|exact
FILE|docs/decisions.md
FALLBACK|source=docs/decisions.md|from=agent|to=exact|reason=validation_failed
RULE|workflow|must_be|self_contained
```

**Exit behavior contract**:
- Fallback-to-exact exits `0`.
- The degraded path is explicit in runtime output.
- Hidden fallback is not allowed.

## Notes for Implementer
- Use `ace-bundle` resource composition and existing `ace-llm` behavior for prompt flow.
- Do not add new compressor-specific provider/model flags in this phase.
- Keep corpus-level multi-file agent compression out of this task.
