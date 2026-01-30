# ace-coworker Usage Guide

Comprehensive guide to ace-coworker commands and features.

## Hierarchical Job Structure

ace-coworker supports nested jobs to model complex workflows with parent-child relationships.

### Numbering System

```
010              # Top-level job (depth 0)
010.01           # First child of 010 (depth 1)
010.02           # Second child of 010 (depth 1)
010.01.01        # First grandchild of 010.01 (depth 2)
010.01.02        # Second grandchild of 010.01 (depth 2)
```

**Constraints**:
- Top-level: 3-digit format (`%03d`), max 999 jobs (001-999)
- Children: 2-digit format (`%02d`), max 99 siblings per parent (01-99)
- Maximum nesting depth: 3 levels (e.g., `010.01.01` is max)

### Creating Hierarchical Jobs

#### Child Jobs

Use `--after` with `--child` to create nested jobs:

```bash
# Create first child of job 010
ace-coworker add setup-db --after 010 --child -i "Set up database"
# Creates: 010.01-setup-db.j.md

# Create second child of job 010
ace-coworker add setup-cache --after 010 --child -i "Set up cache"
# Creates: 010.02-setup-cache.j.md

# Create grandchild (child of 010.01)
ace-coworker add create-tables --after 010.01 --child -i "Create tables"
# Creates: 010.01.01-create-tables.j.md
```

#### Sibling Jobs

Use `--after` without `--child` to insert siblings:

```bash
# Insert after job 010 (as sibling 011)
ace-coworker add hotfix --after 010 -i "Apply hotfix"
# Creates: 011-hotfix.j.md
# If 011 existed, it gets renumbered to 012, etc.
```

### Completion Semantics

1. **Leaf jobs** (no children): Complete via `ace-coworker report`
2. **Parent jobs**: Auto-complete when ALL children are done
3. **Multi-level**: Completion cascades up the tree

Example workflow:
```
010 (pending) - parent
├── 010.01 (done)
└── 010.02 (pending)
```

When 010.02 completes → 010 auto-completes.

### Work Order (next_workable)

The queue follows these rules for determining the next job:

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

When inserting siblings that conflict with existing numbers, ace-coworker automatically renumbers:

```bash
# Before: 010, 011, 012
ace-coworker add urgent --after 010
# After: 010, 011-urgent (NEW), 012 (was 011), 013 (was 012)
```

**Cascade behavior**: Children are renumbered with their parents:
```
# Before: 010, 010.01, 011
ace-coworker add fix --after 010
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

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Configuration error |
| 3 | Session not found |
| 4 | No current step |
| 130 | Interrupted (SIGINT) |

See [exit-codes.md](exit-codes.md) for details.

## Advanced Features

### Fork Context

Jobs with `context: fork` run in isolated agent contexts. See README.md for details.

### Status Display Modes

```bash
# Hierarchical view (default)
ace-coworker status

# Flat view (no tree structure)
ace-coworker status --flat
```

### Quiet Mode

Suppress output for scripting:

```bash
ace-coworker add task -i "..." --quiet
ace-coworker report report.md --quiet
```

## Workflow Patterns

### Verification Pattern

Parent job with verification children:

```yaml
steps:
  - name: implement
    instructions: |
      Implement the feature.
      When done, run: ace-coworker report impl.md
```

Then dynamically add verification:
```bash
ace-coworker add verify --after 010 --child -i "Run tests and verify"
ace-coworker add review --after 010 --child -i "Code review"
```

### Hotfix Pattern

Insert urgent work without disrupting order:

```bash
# Insert after current, renumber rest
ace-coworker add hotfix --after $(ace-coworker current --number) -i "Critical fix"
```
