# Phase B — Prepare Runner Input

## Purpose

Bundle all 8 runner.md goal files into a single prompt file, plus a system prompt,
for the runner agent to execute.

## Steps

### 1. Create runner system prompt

Write `sandbox/.cache/ace-e2e/runner-system.md`:

```markdown
You are an E2E test executor working in a sandbox directory.

Rules:
- Execute each goal in order (1 through 8)
- Use only ace-b36ts, jq, and standard shell utilities
- Save all artifacts to results/{N}/ directories as specified
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

{{contents of goal-1-help-survey.runner.md}}

---

{{contents of goal-2-encode-today.runner.md}}

---

{{contents of goal-3-decode-token.runner.md}}

---

{{contents of goal-4-error-behavior.runner.md}}

---

{{contents of goal-5-output-routing.runner.md}}

---

{{contents of goal-6-structured-output.runner.md}}

---

{{contents of goal-7-roundtrip-pipeline.runner.md}}

---

{{contents of goal-8-batch-sort.runner.md}}
```

Where `{{SANDBOX_DIR}}` is replaced with the absolute path to the sandbox directory,
and each `{{contents of ...}}` is replaced with the full contents of the corresponding file
from `../e2e/TS-B36TS-001-goal-pilot/`.

### 3. Implementation

```bash
TASK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX_DIR="$TASK_DIR/experiment/sandbox"
GOAL_DIR="$TASK_DIR/e2e/TS-B36TS-001-goal-pilot"

# System prompt
cat > "$SANDBOX_DIR/.cache/ace-e2e/runner-system.md" << 'SYSTEM_EOF'
You are an E2E test executor working in a sandbox directory.

Rules:
- Execute each goal in order (1 through 8)
- Use only ace-b36ts, jq, and standard shell utilities
- Save all artifacts to results/{N}/ directories as specified
- Do not fabricate output — all artifacts must come from real tool execution
- If a goal fails, note the failure and continue to the next goal
- After all goals, output a brief summary of what you produced for each goal
SYSTEM_EOF

# Runner prompt — header + all 8 goals
cat > "$SANDBOX_DIR/.cache/ace-e2e/runner-prompt.md" << HEADER_EOF
# E2E Test Runner: ace-b36ts Goal-Based Pilot

Tool under test: ace-b36ts
Required tools: ace-b36ts, jq
Workspace root: $SANDBOX_DIR

Execute each goal sequentially. Goal 1 is discovery — all later goals
build on what you learn there. Do not re-run --help after Goal 1.
HEADER_EOF

for i in 1 2 3 4 5 6 7 8; do
  name=$(ls "$GOAL_DIR"/goal-${i}-*.runner.md)
  echo -e "\n---\n" >> "$SANDBOX_DIR/.cache/ace-e2e/runner-prompt.md"
  cat "$name" >> "$SANDBOX_DIR/.cache/ace-e2e/runner-prompt.md"
done
```

## Outputs

- `sandbox/.cache/ace-e2e/runner-system.md` — system prompt for the runner agent
- `sandbox/.cache/ace-e2e/runner-prompt.md` — concatenated prompt with all 8 goals
