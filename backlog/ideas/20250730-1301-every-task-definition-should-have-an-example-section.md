every task definition should have an example section

it should be part of drafting tasks (dev-handbook/workflow-instructions/draft-release.wf.md)

analyze the current draft task workflow instructions and ensure we have this section as part of this workflow

example should focus on the


## Example

how it example could look like ;-) can look like in context of: dev-taskflow/current/v.0.4.0-replanning/tasks/v.0.4.0+task.001-create-ideas-manager-tool.md

### How we run it:

#### from simple text

```bash
ideas-manager capture "in context of task-manager - lets print a status on top (when doing any listing how many tasks are in certain state - in one line: draft: 2, panding: 5, done: 20, total: 27"
```

##### producing output

```bash
# => Created: dev-taskflow/backlog/ideas/20250730-1430-add-status-to-task-manager.md
```


#### from file

```bash
ideas-manager capture --file dev-taskflow/backlog/ideas/wf-create-reflection-note-feedback.md --commit
```

##### producing output

```bash
# => Created: dev-taskflow/backlog/ideas/20250730-1430-improve-reflection-note.md
```

#### from clipboad

```bash
ideas-manager capture -clipboard
```
##### producing output

```bash
# => Created: dev-taskflow/backlog/ideas/20250730-1430-task-example-section.md
```
