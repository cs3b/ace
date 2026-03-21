# Getting Started with ace-task

Use `ace-task` to capture behavioral specs, track progress, and generate implementation plans.

## Prerequisites

- Ruby installed
- `ace-task` installed

Run:


```bash
gem install ace-task
```

## 1) Create your first task

Run:


```bash
ace-task create "Rewrite onboarding docs"
```

This creates a new task spec in your configured task directory and returns a task reference.

## 2) View and update the task

Run:


```bash
ace-task show <task-ref>
ace-task update <task-ref> --set status=in-progress
```

Use `show` to inspect the full spec and `update` to move through your workflow states.

## 3) Create a subtask

Run:


```bash
ace-task create "Draft quick-start outline" --child-of <task-ref>
ace-task show <task-ref> --tree
```

Subtasks let you split larger goals into smaller slices while keeping parent context visible.

## 4) Generate an implementation plan

Run:


```bash
ace-task plan <task-ref>
```

`ace-task plan` converts the behavioral specification into a concrete implementation checklist.

## 5) Keep task health in check

Run:


```bash
ace-task doctor --check
```

Use doctor checks to detect structure issues early, especially in long-lived branches.

## What to try next

- Explore pending work: `ace-task list --status pending`
- Refresh a stale plan: `ace-task plan <task-ref> --refresh`
- Resolve task quality issues automatically: `ace-task doctor --auto-fix`
