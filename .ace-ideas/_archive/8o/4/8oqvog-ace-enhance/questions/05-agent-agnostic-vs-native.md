# Question: Agent-Agnostic vs Native Tools

## The Question

Should we build agent-agnostic CLI tools, or leverage Claude Code's native capabilities (like Task tool)?

## Context

From the notes:
> "would like to avoid it and keep it general - but inabiquity [ubiquity]"

The 8-step workflow was designed around Claude Code's native Task tool. But ACE philosophy is "same tools for developers and agents."

## Options

### Option A: Pure CLI (Agent-Agnostic)

`ace-overseer` is a Ruby gem like all others. State in files. Any agent that can run bash works.

```bash
ace-overseer run workflow.yml
ace-overseer status
ace-overseer resume
```

**Pros:**
- Works with Claude Code, Codex, Gemini CLI, humans
- Follows ACE philosophy
- Testable, debuggable, inspectable
- No vendor lock-in

**Cons:**
- Agents lose native conveniences
- Reinventing what agents already have
- Context switching between file state and agent memory

### Option B: Native Integration (Claude Code First)

Use Claude Code's Task tool for tracking. Skill-based orchestration.

```markdown
# Workflow as skill
/ace:work-on-task 228

# Uses native Task tool internally
TaskCreate: "Implement feature"
TaskUpdate: status=in_progress
...
TaskUpdate: status=completed
```

**Pros:**
- Rich agent experience
- Uses built-in progress tracking
- Tighter context management
- Less file I/O

**Cons:**
- Claude Code only
- Can't inspect state externally
- Different agents need different integrations

### Option C: CLI Core + Agent Adapters (Recommended)

Core orchestration in CLI (`ace-overseer`). Agent-specific adapters wrap it.

```
ace-overseer (core)
    ├── Claude Code skill (reads/writes state, uses native tasks)
    ├── Codex adapter (different prompting style)
    └── CLI direct (for humans/scripts)
```

**Pros:**
- Agent-agnostic foundation
- Best experience per agent
- State is always file-based (inspectable)
- Adapters are thin wrappers

**Cons:**
- More code paths
- Adapter maintenance

## Recommendation

**Option C: CLI Core + Agent Adapters**

The overseer is a CLI tool. State is files. This is inspectable and universal.

For Claude Code: a skill that wraps the CLI, optionally uses native Task tool for display, but relies on file state for persistence.

```markdown
# /ace:overseer-continue skill

1. Read .ace/overseer/state.json
2. Show progress using native Task tool (visual only)
3. Execute current step
4. Write outcome to state file
5. Call ace-overseer advance
```

This way:
- `ace-overseer status` works from terminal
- Claude Code shows pretty progress
- State is always recoverable from files

## Decision Status

- [x] Decided: **Option C - CLI Core, independent from agents**

ace-overseer follows the established ace-* pattern:
- CLI tool (`exe/ace-overseer`)
- handbook/ (workflows, agents, templates, guides)
- config (`.ace-defaults/`, `.ace/` cascade)
- Works standalone without any agent

**Philosophy:** Don't optimize FOR Claude Code → make sure it WORKS WITH Claude Code.

Integration is separate and thin (ace-integration-claude or .claude/skills/). Core gem has zero Claude Code dependencies. Any agent that can run CLI + read files can use it.
