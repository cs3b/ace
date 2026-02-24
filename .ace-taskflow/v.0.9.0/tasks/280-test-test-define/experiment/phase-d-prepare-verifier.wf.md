# Phase D — Prepare Verifier Input

## Purpose

Collect all sandbox artifacts produced by the runner and bundle them with
all 8 verify.md files into a single verifier prompt.

## Prerequisites

- Phase C completed (runner artifacts exist in `results/tc/{01..08}/`)

## Steps

### 1. Create verifier system prompt

Write `sandbox/.cache/ace-e2e/verifier-system.md`:

```markdown
You are an E2E test verifier. You inspect artifacts and render PASS/FAIL verdicts.

Rules:
- Evaluate each goal independently based solely on the artifacts provided
- Do not speculate about what the runner did — only judge what exists
- For each goal, cite specific evidence (filenames, content snippets)
- Follow the output format exactly
```

### 2. Create verifier prompt

Write `sandbox/.cache/ace-e2e/verifier-prompt.md` with this structure:

```markdown
# E2E Verification: ace-b36ts Goal-Based Pilot

## Sandbox Artifacts

### Directory tree
{{output of: tree sandbox/results/}}

### File contents
{{for each file in results/: path + content}}

---

## Verification Criteria

{{contents of TC-001-help-survey.verify.md}}

---

{{contents of TC-002-encode-today.verify.md}}

---

{{contents of TC-003-decode-token.verify.md}}

---

{{contents of TC-004-error-behavior.verify.md}}

---

{{contents of TC-005-output-routing.verify.md}}

---

{{contents of TC-006-structured-output.verify.md}}

---

{{contents of TC-007-roundtrip-pipeline.verify.md}}

---

{{contents of TC-008-batch-sort.verify.md}}

---

## Output Format

For each goal output:

### Goal N — <title>
- **Verdict**: PASS | FAIL
- **Evidence**: <specific file/content citations>

Final line: **Results: X/8 passed**
```

### 3. Implementation

The `verifier.yml.md` file has `bundle:` frontmatter listing all 8 verify TC files
with the header/rules. Use `ace-bundle` for the verification criteria, then prepend
the sandbox artifacts (which ace-bundle can't collect since they're runtime output).

```bash
TASK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SANDBOX_DIR="$TASK_DIR/experiment/sandbox"
TC_DIR="$TASK_DIR/e2e/TS-B36TS-001-pilot"

# System prompt
cat > "$SANDBOX_DIR/.cache/ace-e2e/verifier-system.md" << 'SYSTEM_EOF'
You are an E2E test verifier. You inspect artifacts and render PASS/FAIL verdicts.

Rules:
- Evaluate each goal independently based solely on the artifacts provided
- Do not speculate about what the runner did — only judge what exists
- For each goal, cite specific evidence (filenames, content snippets)
- Follow the output format exactly
SYSTEM_EOF

# Verifier prompt — artifacts (manual) + verification criteria (ace-bundle)
{
  # Part 1: Sandbox artifacts (collected at runtime, not bundleable)
  echo "## Sandbox Artifacts"
  echo ""
  echo "### Directory tree"
  echo '```'
  tree "$SANDBOX_DIR/results/" 2>/dev/null || find "$SANDBOX_DIR/results/" -type f | sort
  echo '```'
  echo ""
  echo "### File contents"
  echo ""
  find "$SANDBOX_DIR/results/" -type f | sort | while read -r f; do
    echo "#### \`${f#$SANDBOX_DIR/}\`"
    echo '```'
    cat "$f"
    echo '```'
    echo ""
  done
  echo "---"
  echo ""

  # Part 2: Verification criteria from verifier.yml.md (header + all 8 verify TCs)
  ace-bundle "$TC_DIR/verifier.yml.md"
} > "$SANDBOX_DIR/.cache/ace-e2e/verifier-prompt.md"
```

## Outputs

- `sandbox/.cache/ace-e2e/verifier-system.md` — system prompt for the verifier agent
- `sandbox/.cache/ace-e2e/verifier-prompt.md` — artifacts + verification criteria
