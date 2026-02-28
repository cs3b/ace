---

title: Implement Prompt Buffer and Task Queuing in ace-prompt-prep
filename_suggestion: feat-prompt-prep-task-queue
enhanced_at: 2026-01-26 21:10:17
location: active
llm_model: gflash
source: "taskflow:v.0.9.0"
---


# Implement Prompt Buffer and Task Queuing in ace-prompt-prep

## Problem
When developers or agents are actively working within a specific context (e.g., an `ace-git-worktree` tied to a task), emergent observations, necessary follow-up actions, or complex multi-step instructions often arise. Capturing these requires breaking the flow to manually create a new `ace-taskflow` entry or save a prompt, leading to lost context and friction. We need a mechanism to quickly 'buffer' these emergent prompts/tasks.

## Solution
Enhance `ace-prompt-prep` to include a 'Prompt Buffer' or 'Queue' capability. This feature will allow immediate capture of text (observations, prompts, instructions) and automatically link them to the current working context (Git branch, worktree name, or active task ID).

New commands:
1. `ace-prompt-prep buffer [text]`: Enqueues the text into the context-specific buffer file.
2. `ace-prompt-prep flush`: Processes the buffer, either converting items into formal `ace-taskflow` ideas/tasks, or formatting them as a consolidated prompt for the next agent step.

## Implementation Approach
1. **Storage:** The buffer should be stored transparently in the project configuration space, perhaps `.ace/prompt-prep/buffers/<context_slug>.queue` (using `ace-support-core` for path resolution).
2. **Context Linking:** Use `ace-git` to automatically determine the current branch/worktree/task ID to name the context slug.
3. **Architecture:** The core queue management logic (read, write, context determination) will be implemented as **Organisms** within the `ace-prompt-prep` gem, relying on **Molecules** for file I/O and **Atoms** for text processing and context slug generation.
4. **Agent Integration:** Agents can use `ace-prompt-prep flush --output json` to retrieve structured follow-up instructions for autonomous execution.

## Considerations
- **Isolation:** The buffer must be strictly isolated per context (worktree/task) to prevent cross-contamination.
- **Configuration:** Configuration for the `flush` behavior (e.g., default target: `ace-taskflow` idea vs. raw prompt) should be managed via the Configuration Cascade (ADR-022) in `.ace/prompt-prep/config.yml`.
- **CLI Interface:** Ensure the CLI output for `buffer` and `flush` is deterministic and easily parseable by agents.

## Benefits
- **Improved Flow:** Reduces context switching for developers and agents by allowing immediate capture of emergent work.
- **Context Preservation:** Ensures follow-up actions are automatically linked to the source context.
- **Enhanced Agent Orchestration:** Provides a structured way for agents to manage multi-step workflows based on real-time observations.

---

## Original Idea

```
ace-prompt-prep - we should rethink it, or add soemthing new as que -> for each task / worktree wee need to be able to enque next tasks - or add them to the claude directly, what should be done next (not sure how, but sometimes obserwing whats going on, i want to add next work that need ba done - a prompt from the que - ace-promp-prep enque ... 

386fbcc4b
```