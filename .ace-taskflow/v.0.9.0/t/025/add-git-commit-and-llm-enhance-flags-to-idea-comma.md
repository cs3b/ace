---
id: v.0.9.0+task.025
status: pending
priority: medium
estimate: 2h
dependencies: []
---

# Add git-commit and llm-enhance flags to idea command

## Description

Add two new flags to the `ace-taskflow idea create` command:
1. `--git-commit` / `-gc`: Automatically commit the created idea file
2. `--llm-enhance` / `-llm`: Use LLM to enhance the idea description with implementation details

## Planning Steps

* [ ] Review current idea_command.rb implementation
* [ ] Study git integration patterns in dev-tools
* [ ] Design LLM enhancement architecture (stub for now)

## Execution Steps

- [ ] Modify `ace-taskflow/lib/ace/taskflow/commands/idea_command.rb`
  - [ ] Add `--git-commit` and `-gc` option parsing
  - [ ] Add `--llm-enhance` and `-llm` option parsing
  - [ ] Pass flags to idea_writer
- [ ] Update `ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb`
  - [ ] Add git_commit parameter
  - [ ] Execute git add and commit after file creation
  - [ ] Use descriptive commit message: "Capture idea: [title]"
- [ ] Create `ace-taskflow/lib/ace/taskflow/molecules/idea_enhancer.rb`
  - [ ] Load project context
  - [ ] Create enhancement prompt
  - [ ] Stub LLM call for future implementation
- [ ] Update command help text
- [ ] Add tests for new flags

## Acceptance Criteria

- [ ] `ace-taskflow idea create "text" --git-commit` commits the idea automatically
- [ ] `ace-taskflow idea create "text" -gc` works as short form
- [ ] `ace-taskflow idea create "text" --llm-enhance` enhances description (stubbed)
- [ ] `ace-taskflow idea create "text" -llm` works as short form
- [ ] Both flags can be used together
- [ ] Help text documents new options

## Implementation Notes

Based on old capture-it tool behavior, the git-commit flag should run after file creation.
LLM enhancement is a new feature to be stubbed initially for future implementation.
