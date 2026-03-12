---
workflow-id: wfi-rewrite-e2e-tests
name: e2e/rewrite
description: Execute a change plan — delete, create, modify, and consolidate E2E test scenarios
version: "1.0"
source: ace-test-runner-e2e
---

# Rewrite E2E Tests Workflow

This workflow executes an approved change plan by deleting old scenarios, creating new ones, modifying existing ones, and consolidating overlapping TCs.

**Pipeline position:** Stage 3 of 3 (Execute)

```text
ace-bundle wfi://e2e/review  →  ace-bundle wfi://e2e/plan-changes  →  ace-bundle wfi://e2e/rewrite
     (explore)                           (decide)                           ▶ (execute) ◀
```

**Difference from `ace-bundle wfi://e2e/create`:** `create-e2e-test` is for standalone creation — "I need a new E2E test for feature X" with no prior analysis. `rewrite-e2e-tests` is plan-driven — it operates from a structured change plan, handles deletions and modifications, and can replace entire suites.

## Arguments

- `PACKAGE` (required) - The package to rewrite tests for (e.g., `ace-lint`)
- `--plan <path>` (optional) - Path to change plan from Stage 2. If omitted, runs Stages 1+2 first.
- `--dry-run` (optional) - Show what would change without writing files.

## Canonical Conventions

- Keep scenario IDs in `TS-<PACKAGE_SHORT>-<NNN>[-slug]`
- Keep standalone pairs as `TC-*.runner.md` + `TC-*.verify.md`
- Keep TC artifact outputs under `results/tc/{NN}/`
- Keep summary report fields as `tcs-passed`, `tcs-failed`, `tcs-total`, `failed[].tc`
- CLI split reminder:
  - `ace-test-e2e` runs single-package tests
  - `ace-test-e2e-suite` runs suite-level tests

## Rewrite Contract

- Normalize runner files to execution-only language.
- Normalize verifier files to verdict-only, impact-first validation.
- Keep setup concerns in `scenario.yml` and fixtures, not in TC runner setup sections.

## Workflow Steps

### 1. Load Change Plan

**If `--plan` provided:**
Read the file at the given path. Verify it contains the expected sections: REMOVE, KEEP, MODIFY, CONSOLIDATE, ADD, and Proposed Scenario Structure.

**If no plan:**
Run the full pipeline:
1. Load `ace-bundle wfi://e2e/review` → capture review report
2. Load `ace-bundle wfi://e2e/plan-changes` → capture change plan
3. Present the plan to the user for confirmation before proceeding

Parse the plan into structured actions:
- List of TCs to REMOVE (with file paths)
- List of TCs to KEEP (no action needed)
- List of TCs to MODIFY (with change descriptions)
- List of CONSOLIDATE groups (source TCs → target TC)
- List of new TCs to ADD (with scenario assignments)
- Proposed scenario structure

**If `--dry-run`:** After loading the plan, skip to step 6 (Verify Result) and report what would change without writing files.

### 2. Delete Removed Scenarios/TCs

For each TC classified as REMOVE:

**Entire scenario removal** (all TCs in a scenario are REMOVE):
```bash
rm -rf {PACKAGE}/test/e2e/{scenario-dir}/
```

**Individual TC removal** (some TCs in a scenario survive):
```bash
rm {PACKAGE}/test/e2e/{scenario-dir}/{tc-file}.runner.md
rm {PACKAGE}/test/e2e/{scenario-dir}/{tc-file}.verify.md
```

After all deletions, check if any scenario directories are now empty:
```bash
# Find scenarios with no remaining TC files
find {PACKAGE}/test/e2e/TS-* -maxdepth 1 -name "TC-*.runner.md" 2>/dev/null | sort
```

Remove empty scenario directories (no TCs left):
```bash
rm -rf {PACKAGE}/test/e2e/{empty-scenario-dir}/
```

Stage the deletions:
```bash
git add {PACKAGE}/test/e2e/
```

### 3. Create New Scenarios and TCs

For each ADD group in the proposed scenario structure:

**Create scenario directory:**
```bash
mkdir -p {PACKAGE}/test/e2e/TS-{AREA}-{NNN}-{slug}
```

**Write `scenario.yml`:**
Include metadata, setup directives, tags, and fixture requirements. Follow the existing scenario.yml format from other scenarios in the package. Preserve existing `tags` when modifying scenarios; add `tags: [{cost-tier}, "use-case:{area}"]` to new scenarios.

**Write fixture files** (if needed):
Create test data files in the scenario's `fixtures/` directory.

**Write TC files:**
For each TC in the scenario, create paired files:
- `TC-{NNN}-{slug}.runner.md`
- `TC-{NNN}-{slug}.verify.md`

Follow the E2E test writing rules:

- **Run the tool first** to verify actual behavior before writing assertions
- Apply the E2E Value Gate — every TC must require real CLI binary + external tools + filesystem I/O
- Use `&& echo "PASS" || echo "FAIL"` patterns for every verification step
- Follow TC ordering: error paths first, happy path, structure verification, lifecycle, end state
- Consolidate assertions sharing the same CLI invocation into a single TC
- Target 2-5 TCs per scenario
- Test through the CLI interface, not library imports

**Load the TC template for reference:**
```bash
ace-bundle tmpl://test-e2e
```

### 4. Modify Existing TCs

For each TC classified as MODIFY:

1. Read the current TC runner/verifier pair
2. Apply the changes specified in the plan:
   - **Update assertions** — if source code changed, run the tool to observe new behavior, then update expected output
   - **Narrow scope** — remove assertions that unit tests cover, keep only E2E-exclusive checks
   - **Broaden scope** — add assertions for related behavior tested by the same CLI invocation
   - **Fix structure** — add missing sections, fix formatting issues
3. Update the `last-verified` field if the TC was re-run during modification
4. Write the updated TC runner/verifier files

### 5. Consolidate TCs

For each CONSOLIDATE group:

1. Read all source TC runner/verifier pairs in the group
2. Identify the target TC (the one that survives)
3. Merge assertion steps from source TCs into the target TC:
   - Combine verification steps under the shared CLI invocation
   - Preserve all unique assertions
   - Remove duplicate assertions
   - Maintain the PASS/FAIL pattern for each verification
4. Write the updated target TC
5. Delete source TC runner/verifier files (except the target pair)
6. Verify the consolidated TC count stays within 2-5 per scenario

### 6. Verify Result

After all changes are applied (or in `--dry-run` mode, report what would happen):

**List all remaining E2E test files:**
```bash
find {PACKAGE}/test/e2e -name "scenario.yml" -o -name "runner.yml.md" -o -name "verifier.yml.md" -o -name "TC-*.runner.md" -o -name "TC-*.verify.md" 2>/dev/null | sort
```

**Verify counts match the plan:**
- Scenario count matches proposed scenario structure
- TC count per scenario matches plan
- Total TC count matches plan's "Proposed" column

**Check for stale references:**
- Grep for references to deleted TC IDs in remaining files
- Verify no broken cross-references between TCs

**Check scenario health:**
- Each scenario has 2-5 TCs
- Each scenario has a valid `scenario.yml`
- No empty scenario directories

### 7. Report Summary

Present the execution summary:

```markdown
## E2E Rewrite Summary: {package}

**Executed:** {timestamp}
**Plan:** {plan path or "inline"}
**Mode:** {execute or dry-run}

### Changes Applied

| Action | Count | Details |
|--------|-------|---------|
| Deleted | {n} TCs | {list of removed TC IDs} |
| Created | {n} TCs | {list of new TC IDs} |
| Modified | {n} TCs | {list of modified TC IDs} |
| Consolidated | {n} → {n} TCs | {consolidation summary} |
| Kept | {n} TCs | (unchanged) |

### Files Changed

**Created:**
- {file path}
- {file path}

**Modified:**
- {file path}

**Deleted:**
- {file path}

### Final State

| Metric | Before | After |
|--------|--------|-------|
| Scenarios | {n} | {n} |
| Test Cases | {n} | {n} |

### Verification

- [ ] Scenario count matches plan: {yes/no}
- [ ] TC count matches plan: {yes/no}
- [ ] No stale references: {yes/no}
- [ ] All scenarios have 2-5 TCs: {yes/no}

### Next Steps

1. Review the created/modified TC files
2. Run `ace-test-e2e {PACKAGE} {TEST_ID}` for the scenarios you want to verify
3. Commit changes with `ace-git-commit`
```

## Example Invocations

**Execute a pre-approved plan:**
```bash
ace-bundle wfi://e2e/rewrite
```

**Run full pipeline (review → plan → rewrite):**
```bash
ace-bundle wfi://e2e/rewrite
```

**Dry-run to preview changes:**
```bash
ace-bundle wfi://e2e/rewrite
```

## Error Handling

### Invalid Plan Format

If the plan file is missing required sections:
```
Plan file is missing required sections: {missing sections}

Expected sections: REMOVE, KEEP, MODIFY, CONSOLIDATE, ADD, Proposed Scenario Structure
Re-run `ace-bundle wfi://e2e/plan-changes` to generate a valid plan.
```

### File Conflicts

If a file to be created already exists:
1. Compare the existing file with the planned content
2. If different: warn the user and ask whether to overwrite
3. If identical: skip (already applied)

### Partial Execution

If execution fails partway through:
1. Report which actions completed and which failed
2. Do not attempt to roll back completed actions
3. Show the state of `{PACKAGE}/test/e2e/` after partial execution
4. Suggest re-running with the remaining actions
