# Question: Context Hygiene (Worker Input Shaping)

## The Question

How do we define what context a worker sees for each step, and how do we keep it small and relevant?

## Context

Context pollution is a primary failure mode in long-running workflows. Passing full logs or entire chat history
causes retries to degrade. We need a predictable, step-scoped input model.

## Options

### Option A: Full History

Pass everything (spec, full logs, prior attempts, chat history).

**Pros:**
- Easiest to implement
- No selection logic

**Cons:**
- Largest prompts
- Increased confusion and drift
- Compounds failure context on retries

### Option B: Step-Scoped Bundle

Write a fresh context file per step with only:
- Task/spec
- Relevant files or diffs
- Latest error summary (if retry)

**Pros:**
- Predictable and small
- Keeps workers focused
- Aligns with ACE file-based interchange

**Cons:**
- Requires selection rules
- Might omit useful background unless explicitly included

### Option C: Template + Include List

Use a standard context template, plus an explicit include list per step.

**Pros:**
- Consistent structure
- Clear extensibility

**Cons:**
- More configuration surface

## Recommendation

**Option B** for Phase 1, with a path toward Option C:
- Always generate `.ace/overseer/context.json` per step.
- Include spec + last error summary by default.
- Allow optional `include:` paths in workflow for explicit additions.
- Enforce a size budget to avoid prompt bloat.

## Decision Status

- [x] Decided: **Option B - Step-scoped bundle**

Fresh context per step with only:
- Task/spec
- Last error summary (on retry)
- Step-specific includes (defined in workflow YAML per step)

Workflows are self-sufficient - taskflow stores everything needed. Each step config defines what additional context to pass (as per Q3 decision). Enforce size budget to avoid prompt bloat.
