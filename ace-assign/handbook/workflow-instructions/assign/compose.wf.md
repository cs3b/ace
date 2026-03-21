---
doc-type: workflow
title: Compose Assignment Workflow
purpose: LLM-driven composition of assignments using canonical assign-capable skill metadata, phrase hints, and hard ordering rules
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# Compose Assignment Workflow

## Purpose

Compose a tailored assignment by selecting steps from assign-capable canonical skills, applying composition rules, and using recipes as optional starting points.

Boundary:
- Compose resolves intent from user input + assign-capable canonical step data.
- Compose is allowed to use step-level intent metadata (phrase hints) from canonicalized step entries.
- Compose keeps skill-backed steps high-level. Runtime `ace-assign create` performs `assign.source` sub-step expansion.

## Input Formats

### 1. Natural Description

```bash
/as-assign-compose "implement task 148 with PR and 2 reviews"
```

### 2. Explicit Step List

```bash
/as-assign-compose "run tests, reorganize commits, push to remote"
```

### 3. Recipe Reference

```bash
/as-assign-compose implement-with-pr --taskref 148
```

## Process

### 1. Load Canonical Assign-Capable Catalog

Load public skill-backed step entries from canonical skills:

```
Canonical source: skill://* (workflow/orchestration skills with explicit assign metadata)
Read: ace-assign/.ace-defaults/assign/catalog/composition-rules.yml
Glob: ace-assign/.ace-defaults/assign/catalog/recipes/*.recipe.yml
```

Internal helper step templates under `ace-assign/.ace-defaults/assign/catalog/steps/*.step.yml`
remain runtime support data for non-skill steps such as subtree orchestration helpers. They are not the
authoritative source for public skill-backed step composition.

For each step, read:
- `name`, `skill`, `description`
- `prerequisites`
- `context`
- `tags`
- `intent.phrases` (if present)

### 2. Understand Intent

Extract from user input:
- Goal and requested actions
- Explicit requested order
- Task refs (`--taskref`, `--taskrefs`, or inline text)
- Constraints (include/exclude specific steps)

Classify request shape:
- **Explicit-step mode**: user lists concrete steps (comma-separated or sequenced)
- **Goal mode**: user states high-level outcome

### 3. Resolve Explicit Phrases to Steps

Apply deterministic matching per explicit phrase in order:

1. Exact step-name match (`push-to-remote`)
2. Exact/contains match against `intent.phrases`
3. Token overlap against step `name` + `description` + `intent.phrases`

Normalization rules:
- Lowercase and trim punctuation before matching
- Normalize duplicates to one step unless repetition is explicitly requested
- Keep first match as canonical step selection

Unmatched phrase handling:
- Stop composition
- Return unmatched phrase and closest candidates (step name + matching hint)

### 4. Optional Recipe Match

Recipe matching is optional and advisory:

- If user provides an exact recipe name, use it as starting scaffold.
- If request is explicit-step mode, explicit steps are primary and recipe steps are secondary defaults.
- If both conflict, explicit user steps win unless hard ordering/prerequisite rules require correction.

### 5. Compose Step Sequence

Precedence policy:

1. **Explicit user steps** (primary)
2. **Required prerequisites** from selected steps
3. **Hard ordering rules** from `composition-rules.yml`
4. **Recommended conditionals/defaults** as suggestions (advisory)

Hard-rule corrections must be explainable by rule name.

Skill-backed steps (for example `work-on-task`) remain high-level in composed YAML.
Do not manually inline sub-steps from external skill/workflow files in compose.

### 6. Validate

Validate composed sequence:

- Hard ordering satisfied (`before/after` rules)
- Required prerequisites present
- Pair constraints honored where applicable
- No unresolved placeholders in rendered instructions

If reordering occurred, record:
- original explicit order
- final order
- rule name(s) causing adjustment

### 7. Present Plan

Show user the composed assignment:

```
Proposed: <assignment-name>

Steps:
  010: verify-test-suite
  020: reorganize-commits
  030: push-to-remote

Ordering adjustments:
  - none

Suggestions (advisory):
  [optional] add update-pr-desc
```

Include:
- Step number + name + brief description
- Fork context markers where applicable
- Hard-rule reorder explanations
- Advisory suggestions (clearly labeled optional)

### 8. Refine (Optional)

Use AskUserQuestion when needed:
- Accept as-is
- Add/remove step
- Adjust review cycles
- Provide custom changes

Re-validate after edits.

### 9. Generate job.yaml

Generate job configuration compatible with `ace-assign create`:

```yaml
session:
  name: <assignment-name>
  description: <composed description>

steps:
  - name: verify-test-suite
    workflow: wfi://test/verify-suite
    instructions:
      - Run package test verification.
```

Step mapping source of truth:
- `name` from canonicalized step catalog entry
- `workflow` from canonicalized step catalog entry
- `context` from canonicalized step catalog entry (if set)
- `instructions` as assignment overlay from catalog description + request-specific context

### 10. Output Result

Write job.yaml to task jobs directory (or custom `--output`) and report:

```
Assignment composed: <assignment-name>
Job configuration: <path-to-job.yaml>

Steps: N total
  010: ...

Composition validated: no ordering violations
```

## Error Handling

| Scenario | Action |
|----------|--------|
| No matching recipe | Compose directly from steps |
| Unmatched explicit phrase | Fail with unmatched phrase + closest candidates |
| Missing required prerequisite | Insert required prerequisite and report why |
| Ordering violation | Reorder by hard rule and report rule name |
| Missing required parameter | Prompt user |
| Empty step selection | Suggest minimum viable assignment |

## Examples

### Example 1: Explicit Steps

```bash
/as-assign-compose "run tests, reorganize commits, push to remote"
```

Expected core steps:
- `verify-test-suite`, `reorganize-commits`, `push-to-remote`

### Example 2: Explicit + Mainline Maintenance

```bash
/as-assign-compose "squash changelog, rebase with origin main, update pr description"
```

Expected core steps:
- `squash-changelog`, `rebase-with-main`, `update-pr-desc`

### Example 3: High-level Task Intent

```bash
/as-assign-compose "work on task 123 and create a PR"
```

Expected composed steps include high-level `work-on-task` and `create-pr`; runtime create expands task sub-steps via `assign.source`.

## Success Criteria

- [ ] Canonical assign-capable phrase hints are used for explicit-step matching
- [ ] Common explicit requests resolve to stable steps
- [ ] Explicit ordering is preserved unless hard rules require changes
- [ ] Any reorder is explainable by named rule
- [ ] Skill-backed step expansion remains runtime responsibility
- [ ] Output job.yaml stays compatible with `ace-assign create`

## Next Steps

After job.yaml is created:

```bash
/as-assign-create <job.yaml>
# or
/as-assign-create "...intent..." --run
```