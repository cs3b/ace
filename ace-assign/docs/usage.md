# ace-assign Usage Guide

Comprehensive guide to ace-assign commands and features.

## Hierarchical Phase Structure

ace-assign supports nested phases to model complex workflows with parent-child relationships.

### Numbering System

```
010              # Top-level phase (depth 0)
010.01           # First child of 010 (depth 1)
010.02           # Second child of 010 (depth 1)
010.01.01        # First grandchild of 010.01 (depth 2)
010.01.02        # Second grandchild of 010.01 (depth 2)
```

**Constraints**:
- Top-level: 3-digit format (`%03d`), max 999 phases (001-999)
- Children: 2-digit format (`%02d`), max 99 siblings per parent (01-99)
- Maximum nesting depth: 3 levels (e.g., `010.01.01` is max)

### Creating Hierarchical Phases

#### Child Phases

Use `--after` with `--child` to create nested phases:

```bash
# Create first child of phase 010
ace-assign add setup-db --after 010 --child -i "Set up database"
# Creates: 010.01-setup-db.ph.md

# Create second child of phase 010
ace-assign add setup-cache --after 010 --child -i "Set up cache"
# Creates: 010.02-setup-cache.ph.md

# Create grandchild (child of 010.01)
ace-assign add create-tables --after 010.01 --child -i "Create tables"
# Creates: 010.01.01-create-tables.ph.md
```

#### Sibling Phases

Use `--after` without `--child` to insert siblings:

```bash
# Insert after phase 010 (as sibling 011)
ace-assign add hotfix --after 010 -i "Apply hotfix"
# Creates: 011-hotfix.ph.md
# If 011 existed, it gets renumbered to 012, etc.
```

### Starting Work

After an assignment is created, the first workable phase is started automatically. In sequential workflows, `finish` auto-advances to the next phase — no `start` call is needed between phases:

```bash
# Normal sequential flow
ace-assign finish --message done.md   # completes 010, auto-starts 020
ace-assign finish --message done.md   # completes 020, auto-starts 030
```

Use `ace-assign start` explicitly for recovery or subtree entry:

```bash
ace-assign start            # start next workable phase (after fail/retry)
ace-assign start 030        # start a specific pending phase
```

Providing report content via piped stdin avoids creating temporary files:

```bash
printf "Done: implemented feature\n" | ace-assign finish
cat report.md | ace-assign finish
```

When both `--message` and stdin are provided, `--message` takes precedence.

### Completion Semantics

1. **Leaf phases** (no children): Complete via `ace-assign finish --message <string|file>` or piped stdin
2. **Parent phases**: Auto-complete when ALL children are done
3. **Multi-level**: Completion cascades up the tree

Example workflow:
```
010 (pending) - parent
├── 010.01 (done)
└── 010.02 (pending)
```

When 010.02 completes → 010 auto-completes.

### Work Order (next_workable)

The queue follows these rules for determining the next phase:

1. Skip parents that have incomplete children (work the children first)
2. Within siblings, work in numerical order
3. After completing a child, check if siblings remain before returning to parent

Example:
```
010 (in_progress) - has children, so...
├── 010.01 (done)
└── 010.02 (pending) ← THIS is current
020 (pending)
```

### Renumbering

When inserting siblings that conflict with existing numbers, ace-assign automatically renumbers:

```bash
# Before: 010, 011, 012
ace-assign add urgent --after 010
# After: 010, 011-urgent (NEW), 012 (was 011), 013 (was 012)
```

**Cascade behavior**: Children are renumbered with their parents:
```
# Before: 010, 010.01, 011
ace-assign add fix --after 010
# After: 010, 010.01, 011-fix (NEW), 012 (was 011), 012.01 (was 011.01 if it existed)
```

Frontmatter tracks renumbering history:
```yaml
---
status: pending
renumbered_from: "011"
renumbered_at: "2026-01-30T12:00:00Z"
parent: "012"  # Updated if parent was also renumbered
---
```

## Creating Assignments

### From Job File

```bash
ace-assign create path/to/job.yaml
```

Output shows the assignment ID, cache directory, and first phase instructions.

### Hidden Spec Provenance

When an assignment is created from a hidden spec (rendered under `.ace-local/assign/jobs/`), the create output includes a provenance line:

```
Assignment: work-on-task-123 (abc123)
Created: .ace-local/assign/abc123/
Created from hidden spec: .ace-local/assign/jobs/1741234567-work-on-task-123.yml
```

The hidden spec is retained after creation for traceability. Assignment metadata references the spec location for status and debug flows.

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Assignment not found |
| 4 | No current phase |
| 130 | Interrupted (SIGINT) |

See [exit-codes.md](exit-codes.md) for details.

## Advanced Features

### Fork Context

Phases with `context: fork` run in isolated agent contexts. See README.md for details.

### Status Display Modes

```bash
# Hierarchical view (default)
ace-assign status

# Flat view (no tree structure)
ace-assign status --flat
```

### Quiet Mode

Suppress output for scripting:

```bash
ace-assign add task -i "..." --quiet
ace-assign finish --message report.md --quiet
```

## Workflow Patterns

### Verification Pattern

Parent phase with verification children:

```yaml
phases:
  - name: implement
    instructions: |
      Implement the feature.
      When done, run: ace-assign finish --message impl.md
```

Then dynamically add verification:
```bash
ace-assign add verify --after 010 --child -i "Run tests and verify"
ace-assign add review --after 010 --child -i "Code review"
```

### Hotfix Pattern

Insert urgent work without disrupting order:

```bash
# Insert after current, renumber rest
ace-assign add hotfix --after $(ace-assign current --number) -i "Critical fix"
```
