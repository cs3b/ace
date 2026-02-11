# E2E Test Migration Pattern Reference

## Overview

This document defines the standard migration pattern for converting `.mt.md` monolithic E2E test files to the new directory-based per-TC format (`TS-*/scenario.yml` + `fixtures/` + `TC-*.tc.md`).

## Source Format (`.mt.md`)

```
{package}/test/e2e/MT-{AREA}-{NNN}-{slug}.mt.md
```

Single monolithic markdown file containing:
- YAML frontmatter (test-id, title, area, package, priority, requires, etc.)
- Environment Setup section (bash heredocs for sandbox creation)
- Test Data section (bash heredocs creating fixture files)
- Test Cases sections (`### TC-NNN: Title`)
- Success Criteria and Observations sections

## Target Format (per-TC directory)

```
{package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
├── scenario.yml          # Metadata + declarative setup steps
├── fixtures/             # Real test data files (extracted from heredocs)
│   ├── file1.rb
│   └── subdir/
│       └── file2.rb
├── TC-001-{slug}.tc.md   # Independent test case
├── TC-002-{slug}.tc.md
└── TC-NNN-{slug}.tc.md
```

## Phase 0: Pre-Migration Pipeline

Before applying the migration algorithm, run the 3-stage E2E pipeline to determine which TCs have genuine E2E value:

1. **Review:** `/ace:review-e2e-tests {PACKAGE}` — produces coverage matrix (functionality × unit tests × E2E)
2. **Plan:** `/ace:plan-e2e-changes {PACKAGE}` — classifies each existing MT TC as REMOVE / KEEP / MODIFY / CONSOLIDATE / ADD
3. **Approve plan** before proceeding to migration

The ace-lint migration (262.01) demonstrated that ~60% of TCs duplicate unit test coverage. A faithful 1:1 migration of 31 TCs was immediately followed by restructuring down to 9 TCs (~71% reduction). The pipeline avoids this wasted intermediate step.

### Migration scope is determined by the plan:
- **KEEP TCs** → migrate to TS format as-is (Steps 1–6 below)
- **MODIFY TCs** → migrate to TS format with changes applied
- **CONSOLIDATE TCs** → merge during migration (single TS TC from multiple MT TCs)
- **REMOVE TCs** → skip (don't create TS files, delete MT files)
- **ADD TCs** → create new TS TCs for uncovered features (if any)

The 6-step migration algorithm below applies only to TCs approved through the Value Gate.

## Migration Algorithm (Per File)

### Step 1: Create Directory Structure

```
MT-{AREA}-{NNN}-{slug}.mt.md → TS-{AREA}-{NNN}-{slug}/
```

Naming: Replace `MT-` prefix with `TS-`, drop `.mt.md` extension, create directory.

### Step 2: Extract `scenario.yml`

Map frontmatter fields:

| .mt.md field | scenario.yml field | Notes |
|---|---|---|
| `test-id: MT-LINT-001` | `test-id: TS-LINT-001` | Change MT- to TS- prefix |
| `title` | `title` | Direct copy |
| `area` | `area` | Direct copy |
| `package` | `package` | Direct copy |
| `priority` | `priority` | Direct copy |
| `requires` | `requires` | Direct copy (tools, ruby) |
| `duration` | _(omit)_ | Not needed in new format |
| `automation-candidate` | _(omit)_ | All are automation now |
| `last-verified` | _(omit)_ | Reset on migration |
| `verified-by` | _(omit)_ | Reset on migration |

Add `setup:` section based on analysis of Environment Setup + Test Data sections:

```yaml
setup:
  - git-init                    # If setup creates a git repo
  - copy-fixtures               # If fixtures/ directory has files
  - run: <command>              # For post-copy setup commands
  - write-file:                 # For dynamic content not suitable as fixtures
      path: relative/path.ext
      content: |
        inline content
  - env:                        # For environment variables
      PROJECT_ROOT_PATH: .
```

### Step 3: Extract Fixture Files

Parse the Test Data section's bash heredocs and create real files:

```bash
# Source (in .mt.md):
cat > valid.rb << 'EOF'
# frozen_string_literal: true
class Greeter
  def greet(name)
    "Hello, #{name}!"
  end
end
EOF

# Target: fixtures/valid.rb (real file)
```

**Rules:**
- Each `cat > {path} << 'EOF' ... EOF` block → `fixtures/{path}`
- Preserve directory structure (`mkdir -p batch` → `fixtures/batch/`)
- Preserve file content exactly (no modifications)
- Files created via `echo` or other commands → also extract to fixtures/

### Step 4: Extract Test Cases

Each `### TC-NNN: Title` section → individual `TC-{NNN}-{slug}.tc.md` file.

**TC filename:** Derive slug from title: lowercase, spaces→hyphens, remove punctuation.
Example: `### TC-001: StandardRB Available - Valid File` → `TC-001-standardrb-available-valid-file.tc.md`

**TC content structure:**

```markdown
---
tc-id: TC-001
title: StandardRB Available - Valid File
---

## Objective

[From **Objective:** field in original TC section]

## Steps

[From **Steps:** section — preserve bash code blocks]

## Expected

[From **Expected:** section — preserve bullet points]
```

**Omit from TC files:**
- `**Actual:**` fields (filled during execution)
- `**Status:**` checkboxes (tracked by runner)
- Horizontal rule separators (`---` between TCs)
- `**Note:**` addenda (incorporate into Steps or Expected as appropriate)

### Step 5: Validate

```bash
ace-test-e2e setup {package} TS-{AREA}-{NNN}
```

Must exit 0 and print sandbox path. Inspect sandbox to verify fixtures are in place.

### Step 6: Remove Original

Delete the `.mt.md` file after successful validation.

## Special Cases

### Variant Naming (e.g., 004a/b/c/d)

Preserve variant suffixes in directory names:
- `MT-COMMIT-004a-auto-split-basics.mt.md` → `TS-COMMIT-004a-auto-split-basics/`

### Sequential Test Dependencies

When TCs have sequential dependencies (each TC depends on state from the previous):
- **Merge** the sequential chain into a single composite TC
- Include all verification points within the merged TC
- Name: `TC-001-full-{workflow-name}.tc.md`

### Files with No Heredoc Test Data

Some scenarios may not have inline file creation. In that case:
- `fixtures/` directory may be empty or omitted
- Remove `copy-fixtures` from setup steps
- Setup may only contain `env:` and `run:` steps

### Environment Variable Patterns

Common env vars to translate to `env:` setup step:
- `PROJECT_ROOT_PATH` → `env: { PROJECT_ROOT_PATH: "." }`
- Tool-specific env vars → include in `env:` step

### ace-test-e2e-sh References

The `.mt.md` format uses `ace-test-e2e-sh "$TEST_DIR"` wrapper for sandbox isolation.
In the new format, `SetupExecutor` handles sandbox creation automatically — these wrappers are no longer needed in TC steps. Strip the wrapper and keep only the command:

```bash
# Old (in .mt.md):
ace-test-e2e-sh "$TEST_DIR" ace-lint lint valid.rb

# New (in TC-*.tc.md):
ace-lint lint valid.rb
```

## Estimation Formula

Per file: ~15 min (simple) to ~30 min (complex with many TCs or fixtures)
Per TC: ~2-3 min extraction time
Validation: ~5 min per scenario
