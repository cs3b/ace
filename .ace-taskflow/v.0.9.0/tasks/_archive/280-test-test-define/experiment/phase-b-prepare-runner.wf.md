# Phase B — Prepare Runner Input

## Purpose

Bundle all 8 standalone runner TC files into a single prompt file, plus a system prompt,
for the runner agent to execute.

## Steps

### 1. Create runner system prompt

Write `sandbox/.cache/ace-e2e/runner-system.md`:

```markdown
You are an E2E test executor working in a sandbox directory.

Rules:
- Execute each goal in order (1 through 8)
- Use only ace-b36ts, jq, and standard shell utilities
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal
```

### 2. Create runner prompt

Write `sandbox/.cache/ace-e2e/runner-prompt.md` by concatenating all 8 runner files:

```markdown
# E2E Test Runner: ace-b36ts Goal-Based Pilot

Tool under test: ace-b36ts
Required tools: ace-b36ts, jq
Workspace root: {{SANDBOX_DIR}}

Execute each goal sequentially. Goal 1 is discovery — all later goals
build on what you learn there. Do not re-run --help after Goal 1.

---

{{contents of TC-001-help-survey.runner.md}}

---

{{contents of TC-002-encode-today.runner.md}}

---

{{contents of TC-003-decode-token.runner.md}}

---

{{contents of TC-004-error-behavior.runner.md}}

---

{{contents of TC-005-output-routing.runner.md}}

---

{{contents of TC-006-structured-output.runner.md}}

---

{{contents of TC-007-roundtrip-pipeline.runner.md}}

---

{{contents of TC-008-batch-sort.runner.md}}
```

Where `{{SANDBOX_DIR}}` is replaced with the absolute path to the sandbox directory,
and each `{{contents of ...}}` is replaced with the full contents of the corresponding file
from `../e2e/TS-B36TS-001-pilot/`.

### 3. Implementation

The `runner.yml.md` file has `bundle:` frontmatter that lists all 8 runner TC files
and includes the header/rules. Use `ace-bundle` to generate the prompt in one step:

```bash
TASK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX_DIR="$TASK_DIR/experiment/sandbox"
TC_DIR="$TASK_DIR/e2e/TS-B36TS-001-pilot"

# System prompt (standalone — not part of runner.yml.md bundle)
cat > "$SANDBOX_DIR/.cache/ace-e2e/runner-system.md" << 'SYSTEM_EOF'
You are an E2E test executor working in a sandbox directory.

Rules:
- Execute each goal in order (1 through 8)
- Use only ace-b36ts, jq, and standard shell utilities
- Save all artifacts to results/tc/{NN}/ directories as specified
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal
SYSTEM_EOF

# Runner prompt — use ace-bundle to expand runner.yml.md (header + all 8 goals)
ace-bundle "$TC_DIR/runner.yml.md" > "$SANDBOX_DIR/.cache/ace-e2e/runner-prompt.md"
```

## Outputs

- `sandbox/.cache/ace-e2e/runner-system.md` — system prompt for the runner agent
- `sandbox/.cache/ace-e2e/runner-prompt.md` — concatenated prompt with all 8 goals
