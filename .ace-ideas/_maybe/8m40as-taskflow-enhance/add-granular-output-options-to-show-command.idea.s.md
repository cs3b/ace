---
title: Enhance ace-taskflow show command with granular output options
filename_suggestion: feat-taskflow-output-options
enhanced_at: 2025-11-05 00:12:50.000000000 +00:00
location: active
llm_model: gflash
id: 8m40as
status: pending
tags: []
created_at: '2025-11-05 00:11:58'
---

# Enhance ace-taskflow show command with granular output options

## Problem
Currently, the `ace-taskflow show` command provides a single, comprehensive output format for task information. While useful for a general overview, this fixed output can be verbose and inefficient when only specific pieces of information are required. For both human developers and AI agents, programmatically extracting granular data like just the task's metadata, its file path, or its content requires additional parsing logic, which increases complexity and can be error-prone. This limitation hinders the efficiency of automated workflows and agent interactions with `ace-taskflow`.

## Solution
Introduce new output options to the `ace-taskflow show` command, allowing users to specify the exact components of a task they wish to retrieve. This would be implemented via a `--output` or `--format` flag, supporting values such as `meta`, `path`, `content`, and `default` (to retain the current behavior). Additionally, a `--json` option could provide machine-readable structured output, which is highly beneficial for AI agents.

**Examples:**
- `ace-taskflow show <task_id> --output=meta` (shows only frontmatter metadata)
- `ace-taskflow show <task_id> --output=path` (shows only the task file's absolute path)
- `ace-taskflow show <task_id> --output=content` (shows only the main content of the task file)
- `ace-taskflow show <task_id> --json` (outputs all task data in JSON format)

## Implementation Approach
Within the `ace-taskflow` gem, the `CLI` class (specifically the `show` command) would be updated to accept and validate the new `--output` and `--json` options. An `Organism` or `Molecule` (e.g., `lib/ace/taskflow/organisms/task_presenter.rb` or `lib/ace/taskflow/molecules/task_formatter.rb`) would be responsible for orchestrating the retrieval of task data and then formatting it according to the specified output option. This would leverage existing `Atoms` for parsing task frontmatter and content, ensuring a clean separation of concerns as per the ATOM architecture. The output for each option must be deterministic and easily parseable by other tools and AI agents.

## Considerations
- **Integration with existing ace-* gems**: This feature primarily enhances `ace-taskflow`'s standalone utility. However, `ace-llm` agents interacting with `ace-taskflow` would directly benefit from the ability to request precise data, reducing token usage and improving parsing accuracy.
- **Configuration cascade implications**: While not strictly necessary, default output preferences could potentially be configured in `.ace/taskflow/config.yml` using `Ace::Core.config.get('ace', 'taskflow')` for project-specific defaults.
- **CLI interface design**: The `--output` flag should be intuitive, with clear documentation for available options. The `--json` flag should provide a consistent, structured output for all task data, adhering to a defined schema.
- **Error handling**: Implement robust error handling for invalid or unsupported output options.

## Benefits
- **Improved AI Agent Efficiency**: Agents can request and parse only the specific task information they need, significantly reducing token consumption and processing overhead.
- **Enhanced Human Usability**: Developers can quickly extract targeted task details without sifting through verbose output, streamlining their workflow.
- **Increased Automation**: Provides a more robust and predictable interface for scripting and integrating `ace-taskflow` with other tools and systems.
- **Deterministic Output**: Ensures consistent and parseable output, which is crucial for reliable autonomous execution by AI agents.
- **Reduced Cognitive Load**: Both for humans and AI, by presenting only the most relevant information for a given context.

---

## Original Idea

```
ace-taskflow should have multiple otpions to output part of the info for the task, like meta, path, content, default (what we have now when we run show) - --ouput or --format
```