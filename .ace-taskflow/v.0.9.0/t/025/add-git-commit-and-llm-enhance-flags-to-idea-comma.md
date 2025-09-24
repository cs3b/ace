---
id: v.0.9.0+task.025
status: completed
priority: medium
estimate: 2h
dependencies: []
completed_at: 2025-09-24
---

# Add git-commit and llm-enhance flags to idea command

## Description

Add two new flags to the `ace-taskflow idea create` command:
1. `--git-commit` / `-gc`: Automatically commit the created idea file
2. `--llm-enhance` / `-llm`: Use LLM to enhance the idea description with implementation details

## Planning Steps

* [x] Review current idea_command.rb implementation
* [x] Study git integration patterns in dev-tools
* [x] Design LLM enhancement architecture (stub for now)

## Execution Steps

- [x] Modify `ace-taskflow/lib/ace/taskflow/commands/idea_command.rb`
  - [x] Add `--git-commit` and `-gc` option parsing
  - [x] Add `--llm-enhance` and `-llm` option parsing
  - [x] Add `--no-git-commit` to override config default
  - [x] Add `--no-llm-enhance` to override config default
  - [x] Read defaults from configuration
  - [x] Pass flags to idea_writer
- [x] Update `ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb`
  - [x] Add git_commit parameter
  - [x] Execute git add and commit after file creation
  - [x] Use descriptive commit message: "Capture idea: [title]"
- [x] Create `ace-taskflow/lib/ace/taskflow/molecules/idea_enhancer.rb`
  - [x] Load project context
  - [x] Create enhancement prompt
  - [x] Stub LLM call for future implementation
- [x] Update configuration handling
  - [x] Add `idea.defaults.git_commit` config option (default: false)
  - [x] Add `idea.defaults.llm_enhance` config option (default: false)
  - [x] Support user-level and project-level configuration
- [x] Update command help text
- [x] Add tests for new flags and configuration

## Acceptance Criteria

- [x] `ace-taskflow idea create "text" --git-commit` commits the idea automatically
- [x] `ace-taskflow idea create "text" -gc` works as short form
- [x] `ace-taskflow idea create "text" --llm-enhance` enhances description (stubbed)
- [x] `ace-taskflow idea create "text" -llm` works as short form
- [x] Both flags can be used together
- [x] Configuration defaults are respected when flags not specified
- [x] `--no-git-commit` overrides config default of true
- [x] `--no-llm-enhance` overrides config default of true
- [x] Help text documents new options and configuration

## Implementation Notes

Based on old capture-it tool behavior, the git-commit flag should run after file creation.
LLM enhancement is a new feature to be stubbed initially for future implementation.

Configuration priority order:
1. Command-line flags (highest priority)
2. Project-level config (.ace/taskflow.yml)
3. User-level config (~/.ace/taskflow.yml)
4. Built-in defaults (git_commit: false, llm_enhance: false)
