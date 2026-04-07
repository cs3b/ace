# Soft GitHub Issue Integration for `ace-task` - Draft Usage

## API Surface

- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (task frontmatter metadata)

## Usage Scenarios

### Scenario 1: Create a task linked to a GitHub issue

**Goal**: Start ACE work from a GitHub issue and have GitHub track the ACE task automatically.

```bash
ace-task create "Add soft GitHub issue integration" --github-issue 276
```

## Expected Output

- A draft or pending ACE task is created with machine-readable GitHub issue metadata.
- The linked GitHub issue gets the `ace:tracked` label.
- The linked GitHub issue gets one ACE-managed sticky comment using this format:

```md
Tracked in ace-task: [8r4.t.ilo](https://github.com/cs3b/ace/blob/main/.ace-tasks/8r4.t.ilo-add-soft-github-issue-integration/8r4.t.ilo-add-soft-github-issue-integration-for-ace.s.md)
```

### Scenario 2: Complete or reopen a linked task

**Goal**: Let ACE task state drive the linked GitHub issue lifecycle.

```bash
ace-task update ilo --set status=done
ace-task update ilo --set status=pending
```

## Expected Output

- When the ACE task becomes terminal, the linked GitHub issue closes.
- When the ACE task returns to a non-terminal state, the linked GitHub issue reopens.
- The same ACE-managed one-line sticky comment is updated rather than duplicated.

### Scenario 3: Repair or backfill GitHub issue tracking

**Goal**: Reconcile GitHub issue tracking for one linked task or for all linked tasks.

```bash
ace-task github-sync t.ilo
ace-task github-sync --all
```

## Expected Output

- ACE reuses existing sticky comments where present.
- Missing ACE comments, labels, or issue state mismatches are reconciled for linked tasks.

## Notes for Implementer

- Full usage documentation should be completed during work-on-task using `wfi://docs/update-usage`.
