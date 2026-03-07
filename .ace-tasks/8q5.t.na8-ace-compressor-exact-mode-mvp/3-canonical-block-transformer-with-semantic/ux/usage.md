# ace-compressor exact mode ContextPack/3 - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Single markdown file with prose, lists, and code

**Goal**: Demonstrate all 8 transformations on a representative document.

**Input** (`docs/vision.md` excerpt):

```markdown
# ACE Vision

ACE bridges the gap between developer workflows and agent capabilities by providing
CLI tools that developers use directly and agents can invoke through bash and filesystem.

## Why ACE Exists

Agents can run CLI commands and read files. But current workflows suffer from:

- **Context bloat** -- prompts grow without bounds
- **No isolation boundary** -- agents share raw context
- **Prompt fragility** -- minor changes break behavior
- **Lost flow** -- developers lose track of agent state

ACE's approach combines:
1. Unix philosophy
2. Files as interchange format
3. Composable workflows

## Core Principles

### 1. CLI-First, Agent-Agnostic

Agents with bash and filesystem access can use ACE tools. Examples include
[Claude Code](https://claude.com), Codex CLI, OpenCode, and Gemini CLI.

You **must** use the CLI interface for all operations. Never bypass the CLI
to call internal APIs directly.

---

### 2. Transparent & Inspectable

Sessions serialize to files. Every workflow supports `--dry-run`.
Configuration is readable YAML. All operations are traceable.
```

**Command**:
```bash
ace-compressor compress docs/vision.md --mode exact --format stdio
```

**Expected output**:
```
H|ContextPack/3|exact
FILE|docs/vision.md
SEC|ace_vision
SUMMARY|ACE bridges developer-agent workflow gaps with CLI tools for developers usable by agents
SEC|why_ace_exists
FACT|agents_can|run_cli+read_files
PROBLEMS|[context_bloat,isolation_boundary,prompt_fragility,lost_flow]
FACT|ACE_approach|unix_philosophy+files_as_interchange+composable_workflows
SEC|core_principles
SEC|cli_first_agent_agnostic
FACT|agents_with_bash+filesystem|examples=[ClaudeCode,CodexCLI,OpenCode,GeminiCLI]
RULE|must_use_cli_for_all_operations|never_bypass_cli_to_call_internal_apis
SEC|transparent_inspectable
FACT|sessions_to_files|dry_run_support|readable_yaml|traceable
```

**What changed vs ContextPack/2**:
- `H|ContextPack/3|exact` header (was `H|ContextPack/2|exact`)
- `SEC|snake_case` headings (was `M|1|1|### 1. CLI-First, Agent-Agnostic`)
- `SUMMARY|` for overview prose (was `F|1|ACE bridges the gap...` verbatim)
- `PROBLEMS|[...]` array for bullet list (was multiple `F|1|` lines with raw markdown)
- `RULE|` for imperative statements (was `F|1|` with `**must**` preserved)
- `---` separator dropped entirely
- No `**bold**`, backticks, or `[link](url)` in output
- No `S|1|`, `F|1|`, `B|1|` source ID prefixes

### Scenario 2: File with code fences and shell commands

**Input** (`docs/howto.md` excerpt):

```markdown
## How It Works

### Example: ace-git-commit

Run the tool:

\`\`\`bash
ace-git-commit -i "fix auth bug"
\`\`\`

The tool uses these files:

\`\`\`
.ace-defaults/git/commit.yml
handbook/prompts/git-commit.system.md
exe/ace-git-commit
\`\`\`
```

**Command**:
```bash
ace-compressor compress docs/howto.md --mode exact --format stdio
```

**Expected output**:
```
H|ContextPack/3|exact
FILE|docs/howto.md
SEC|how_it_works
EXAMPLE|tool=ace-git-commit
CMD|ace-git-commit -i "fix auth bug"
FILES|ace-git-commit|[.ace-defaults/git/commit.yml,handbook/prompts/git-commit.system.md,exe/ace-git-commit]
```

**What changed**: Code fences become typed records (`CMD|` for bash, `FILES|` for file listings) instead of generic `B|1|fenced-code|` wrappers.

### Scenario 3: Stats format showing real compression

**Command**:
```bash
ace-compressor compress docs/vision.md --mode exact --format stats
```

**Expected output**:
```
Source: docs/vision.md
Input:  3,245 bytes / 87 lines
Output: 1,890 bytes / 24 lines
Change: -41.8% bytes / -72.4% lines
Format: ContextPack/3|exact
```

**Key point**: Both byte and line counts must show negative change. If output is larger than input, the transformer is not compressing -- it's relabeling.

## Notes for Implementer
- `exact` remains the user-facing mode name.
- ContextPack/3 replaces ContextPack/2 -- no backward compatibility needed.
- Semantic classification uses keyword signals (must/never/required -> RULE), not LLM inference.
- The canonical block transformer sits between MarkdownParser output and ContextPack encoding.
- Stats format should report both byte and line reduction percentages.
