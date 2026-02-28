# Question: Worker Interface

## The Question

What exactly IS a worker? How do workers receive context and report outcomes?

## Context

The original spec defines workers as "roles" that can be filled by:
- CLI tools (ace-test, ace-lint)
- AI agents (Claude Code, Codex)
- Humans (for review gates)

But the field notes reveal confusion between skills and actions.

## The "Skill vs Action" Problem

From the notes:
> When skill says "Run: /ace:commit" - I literally load another skill, instead of just DOING the commit.

**Root cause:** Ambiguity in instruction language.

**Solution:** Clear semantic distinction:
- `action:` = run this exact command
- `worker:` = delegate to agent with reasoning

## Options for Worker Interface

### Option A: Exit Code Only (Simplest)

Workers are commands. Success = exit 0. Failure = exit non-zero.

```yaml
- action: ace-test
```

Overseer captures:
- Exit code
- stdout/stderr (for logging)

**Pros:**
- Works with any CLI tool
- No special adaptation needed
- Unix philosophy

**Cons:**
- No structured outcome data
- Can't communicate partial results
- No metadata (coverage %, test count, etc.)

### Option B: Report File Contract

Workers write structured report to known location.

```yaml
- action: ace-test
  report: .ace/overseer/report.json
```

Worker writes:
```json
{
  "outcome": "partial",
  "summary": "15/18 tests passed",
  "details": { "failed": ["test_a", "test_b", "test_c"] }
}
```

**Pros:**
- Rich outcome data
- Extensible
- Aggregatable

**Cons:**
- Workers must be "overseer-aware"
- Extra file I/O
- Need to handle missing report

### Option C: Environment + Report (Hybrid)

Context IN via environment variables.
Outcome OUT via exit code + optional report.

```
# Context (input)
ACE_TASK=228
ACE_SESSION=abc123
ACE_STEP=test
ACE_CONTEXT_FILE=.ace/overseer/context.json

# Outcome (output)
Exit code: 0|1
Optional: .ace/overseer/step-report.json
```

**Pros:**
- Environment is universal
- Exit code is always available
- Report is optional enrichment
- Existing tools work (just ignore context)

**Cons:**
- Two mechanisms (env + file)
- Tools that want rich context need to read file

## Recommendation

**Option C: Environment + Report**

1. **All workers** get environment variables (universal context)
2. **All workers** must return exit code (universal outcome)
3. **Smart workers** can read context file for rich input
4. **Smart workers** can write report file for rich output

This means:
- `ace-test` works as-is (exit code based)
- Claude Code skill can read/write for full context
- Humans just signal "approved" (exit 0)

## Worker Type Taxonomy

| Worker Type | Context | Outcome | Example |
|-------------|---------|---------|---------|
| CLI tool | Env vars | Exit code | `ace-test` |
| Enhanced CLI | Env + context file | Exit + report | `ace-review` |
| Agent | Full context | Report file | Claude Code |
| Human | Prompt display | Approval signal | Review gate |

## Open Prompts

- Do we standardize optional input/output directories (instruction.md, context/, artifacts/)?
- Do we define required report fields or allow free-form reports?
- Are any exit codes reserved (timeout, invalid report, gate rejected)?
- Do workers have full filesystem access or a sandboxed subset?
- Do we need streaming logs to overseer or only post-run logs?

## Decision Status

- [x] Decided: **Skill-based workers with simple context**

**Worker model:**
- Worker = skill run as agent (Claude Code / Codex / OpenCode)
- Agent invokes `/ace:overseer <job, task-ids>` first → overseer CLI manages state
- Triggered from agent (simpler), CLI manages hard data

**Step configuration (YAML):**
```yaml
steps:
  - name: implement
    context: "Task 228 - implement feature X"
    instructions: ace-bundle wfi://work-on-task 228
    report: summary of changes made
    verifications:
      - ace-test passes
      - no lint errors
```

**Communication:**
- Plain concise English between overseer ↔ agents
- JSONL only for hard data (one JSON per line, easy parsing)
- Markdown files for human-readable logs

**Observability (optional module for later):**
- Log all events (hooks or explicit instrumentation)
- JSONL + markdown for debugging by humans and agents
