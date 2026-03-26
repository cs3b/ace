# Dynamic Task Subtree Insertion - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Add a work-on-task child to a running batch

**Goal**: Insert a new task implementation subtree into an active assignment's batch parent

```bash
# Skill invocation (agent context)
/as-assign-add-task t.xyz

# Equivalent manual CLI flow:
cat > /tmp/add-task-xyz.yml << 'EOF'
steps:
  - name: work-on-t.xyz
    context: fork
    workflow: wfi://task/work
    instructions: |
      Implement task t.xyz following project conventions.
      When complete, mark the task as done.
    sub_steps:
      - onboard
      - plan-task
      - work-on-task
      - pre-commit-review
      - verify-test
EOF

ace-assign add --from /tmp/add-task-xyz.yml --after 010 --child
```

### Expected Output

```
Added 6 step(s) from add-task-xyz.yml
  010.03: work-on-t.xyz [pending]
  010.03.01: onboard [pending]
  010.03.02: plan-task [pending]
  010.03.03: work-on-task [pending]
  010.03.04: pre-commit-review [pending]
  010.03.05: verify-test [pending]
```

### Scenario 2: Batch-add flat steps after a specific step

**Goal**: Insert multiple sequential steps into an assignment without parent/child nesting

```bash
cat > /tmp/review-steps.yml << 'EOF'
steps:
  - name: review-security
    instructions: "Run security review on authentication changes."
  - name: review-performance
    instructions: "Profile API endpoints for latency regressions."
EOF

ace-assign add --from /tmp/review-steps.yml --after 030
```

### Expected Output

```
Added 2 step(s) from review-steps.yml
  031: review-security [pending]
  032: review-performance [pending]

Renumbered steps:
  031 -> 033
```

### Scenario 3: Invalid input — mutually exclusive flags

**Goal**: Clear error when both `name` and `--from` are provided

```bash
ace-assign add fix-bug --from steps.yml -i "Fix the bug"
```

### Expected Output

```
Error: --from and name argument are mutually exclusive
```

## Notes for Implementer

- Full usage documentation to be completed during work-on-task step using `wfi://docs/update-usage`
