# ACE Dual Change Analysis — User Instructions

You are analyzing a combined git diff containing both code and documentation updates.

## Your Tasks

1. **Classify each file** by type (code / config / docs / examples).
2. Produce two distinct analyses:
   - **Code Change Analysis** → core logic, architecture, tests
   - **Documentation & Config Change Analysis** → everything else
3. Apply coverage tracking and evidence referencing for both analyses.

---

## Analysis Context

**Diff source:** {repo or project}
**Time range:** {commit window}
**Included paths:**
- `**/*.rb` (code)
- `**/*.yaml`, `**/*.yml`, `**/*.json` (config)
- `**/*.md`, `**/*.wf.md`, `**/*.ag.md` (documentation)

---

## Output Expectations

- **Separate sections** for Code and Docs analyses.
- Each section contains:
  - Summary
  - Changes Detected (HIGH/MEDIUM/LOW)
  - Patterns / Trends (optional)
  - Self-check block

**Do not merge them into one generic list.**

---

## Coverage Tracking
Each section must report:

```yaml
hunks_total: [N]
hunks_mapped: [M]
hunks_ambiguous: [K]
coverage_ratio: [M/N]
```

---

## Quality Rules

✅ Be specific — reference exact hunks or files.
✅ Keep each change ≤ 2 lines.
✅ Detect and group repeated patterns.
✅ Avoid repetition across analyses.
✅ If uncertain, mark as ambiguous with reason.

---

## Example Output Structure (abbreviated)

### 🧩 1. Code Change Analysis
**Summary:**
Refactored `analyze` command into modular pipeline and added `--file` input flag to `ace-bundle`.

**HIGH**
- `lib/ace/docs/analyze_command.rb` — Added diff summarization pipeline. *Impact:* Enables LLM-driven diff analysis.
- `lib/ace/context/cli.rb` — Added `--file` option. *Impact:* Supports YAML-based preset loading.

**Self-Check**
```yaml
hunks_total: 12
hunks_mapped: 11
hunks_ambiguous: 1
```

### 📚 2. Documentation & Configuration Change Analysis
**Summary:**
Added a 598-line usage guide for `ace-docs` and expanded configuration schema for `ace-bundle`.

**MEDIUM**
- `ace-docs/docs/usage.md` — New guide with examples. *Impact:* Improves onboarding.
- `.ace/docs/config.yml` — Added `max_diff_lines_warning` parameter.

**Self-Check**
```yaml
hunks_total: 7
hunks_mapped: 6
hunks_ambiguous: 1
```

---

**Prompt version:** v3.0 — 2025-10-18
