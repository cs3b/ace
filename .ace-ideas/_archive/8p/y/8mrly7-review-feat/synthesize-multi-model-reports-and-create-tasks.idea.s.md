---
title: Multi-Model Review Report Synthesis and Task Creation
filename_suggestion: feat-review-multi-report-synthesis
enhanced_at: 2025-11-28 14:38:29.000000000 +00:00
llm_model: gflash
status: done
completed_at: 2025-12-01 18:26:44.000000000 +00:00
id: 8mrly7
tags: []
created_at: '2025-11-28 14:37:59'
---

# Multi-Model Review Report Synthesis and Task Creation

## Problem

Currently, `ace-review` generates individual review reports, often from different LLM providers or presets, storing them temporarily in `.cache/ace-review/sessions/`. There is no integrated mechanism within ACE to automatically consolidate these multiple reports into a single, cohesive summary of recommendations. Manually aggregating feedback from several distinct review reports for a given subject (e.g., a pull request or a task) and then translating that into a structured development plan or a new `ace-taskflow` subtask is a time-consuming and error-prone process. This leads to fragmented feedback and a lack of clear, actionable next steps derived from comprehensive analysis.

## Solution

Introduce a new `ace-review` command, `ace-review synthesize-reports`, designed to automate the aggregation and synthesis of multiple review reports. This command will take a directory containing individual review reports (e.g., from a specific `ace-taskflow` task's `.cache` directory or a designated `review/` folder) as input. It will leverage `ace-llm` to process the content of these reports, identify common themes, reconcile conflicting suggestions, and prioritize actionable recommendations. The output will be a consolidated report, structured to provide a clear overview of findings, key recommendations, and proposed action items.

Furthermore, this command will integrate directly with `ace-taskflow` to automatically create a new subtask. This subtask will be populated with the synthesized report and a prompt for developing a detailed implementation plan based on the consolidated feedback. The raw review reports will also be organized and moved from their temporary `.cache` locations to a permanent, structured directory within the `ace-taskflow` task context (e.g., `ace-task.121.01/.ace-taskflow/v.0.9.0/tasks/121-ace-prompt/review/task.121.01-01/`), ensuring traceability and easy access.

## Implementation Approach

1. **`ace-review` CLI Extension**: Add a new `synthesize-reports` command to `ace-review/lib/ace/review/commands/cli.rb` using Thor. This command will accept arguments for the input directory of reports and an optional `task-id` for `ace-taskflow` integration.
2. **Report Parsing & Aggregation (Molecules)**: Develop `Molecules` within `ace-review` to read and parse the individual markdown review reports. These molecules will extract relevant sections (e.g., recommendations, issues, praise) from each report.
3. **LLM-Powered Synthesis (Organism)**: Create a new `Organism`, e.g., `Ace::Review::Organisms::ReportSynthesizer`, responsible for orchestrating the synthesis. This organism will:
    * Utilize `ace-llm` to send the aggregated content of the individual reports to a configured LLM (via `Ace::Llm::Molecules::LlmCaller`).
    * Employ a carefully crafted system prompt (managed by `Ace::Core::Molecules::PromptCacheManager`) to guide the LLM in identifying commonalities, resolving conflicts, prioritizing, and structuring the synthesized output.
    * Generate the consolidated report in markdown format.
4. **File Organization (Molecule/Organism)**: Implement a `Molecule` or `Organism` to manage the movement and organization of the original review reports from the `.cache` directory to a permanent, versioned location within the `ace-taskflow` task structure, as demonstrated in the idea (e.g., `/.ace-taskflow/v.X.Y.Z/tasks/TASK_ID/review/SUBTASK_ID/`).
5. **`ace-taskflow` Integration (Molecule)**: Develop a `Molecule` that interfaces with `ace-taskflow`'s internal APIs (or CLI commands) to create a new subtask. The subtask's description will include the synthesized report and a template for planning the implementation.
6. **Configuration**: Leverage `ace-support-core` for configuration management, allowing users to specify the LLM model for synthesis, output format preferences, and default parameters for subtask creation.

## Considerations
* **LLM Prompt Engineering**: The effectiveness of the synthesis relies heavily on the quality and specificity of the LLM prompt. It must guide the LLM to produce actionable, concise, and conflict-aware summaries.
* **Report Structure Consistency**: While the synthesis should be robust, a more standardized structure for `ace-review`'s individual reports would improve synthesis quality.
* **User Control**: Provide CLI options for users to select specific reports for synthesis, choose the synthesis LLM, and customize the generated subtask's title or description.
* **Idempotency**: Ensure that repeated execution of the synthesis command for the same set of reports does not create redundant tasks or reports without explicit user intent.
* **Error Handling**: Implement robust error handling for file I/O, LLM API calls, and `ace-taskflow` interactions.

## Benefits
* **Automated Feedback Consolidation**: Drastically reduces manual effort in aggregating and summarizing feedback from multiple review sources.
* **Improved Actionability**: Transforms raw, potentially disparate review comments into a structured, prioritized, and actionable development plan within `ace-taskflow`.
* **Enhanced Traceability**: Ensures all review reports, both individual and synthesized, are permanently organized and linked to the relevant `ace-taskflow` task.
* **Consistent Workflow**: Establishes a standardized and repeatable workflow for managing and acting upon code review feedback across the ACE ecosystem.
* **Leverages AI for Analysis**: Utilizes LLMs to intelligently synthesize complex information, improving the quality and speed of feedback processing.
* **Boosts `ace-taskflow` Utility**: Further integrates `ace-review` with `ace-taskflow`, making the entire AI-assisted development workflow more seamless and efficient.

---

## Original Idea

```
ace-review should allow workflow like this - we run multiple review for subject (pr) and we synthezie the result as subtask

we have gather feedback for task 121.01, below are reports

/Users/mc/Ps/ace-task.121.01/.cache/ace-review/sessions/review-20251128-143014/review-report-gpt-5.1.md
/Users/mc/Ps/ace-task.121.01/.cache/ace-review/sessions/review-20251128-143031/review-report-gpro.md
/Users/mc/Ps/ace-task.121.01/.cache/ace-review/sessions/review-20251128-143223/review-report-zai-org/GLM-4.6.md
/Users/mc/Ps/ace-task.121.01/.cache/ace-review/sessions/review-20251128-143126/review-report-moonshotai/Kimi-K2-T
hinking.md

0. Organize all the reporst in the folder
/Users/mc/Ps/ace-task.121.01/.ace-taskflow/v.0.9.0/tasks/121-ace-prompt/review/task.121.01-01/

1. Read all of them carefuly
2. Synthezie recomendations
3. Plan how to implement it

4. /ace:create task as a subtask fro 121 with plan for all the feedback for task 121.01
```

---

⏺ Changes Committed: Review reports, synthesis, and subtask 121.07 for addressing ace-prompt review feedback
  Commit Message: feat(ace-prompt): Add task to address review feedback for prompt generation
  Files Modified: 6 files (+740 lines)

* 121.07-address-review-feedback-for-prompt-generation.s.md (subtask)
* review/task.121.01-01/review-gpt-5.1.md
* review/task.121.01-01/review-gpro.md
* review/task.121.01-01/review-glm-4.6.md
* review/task.121.01-01/review-kimi-k2-thinking.md (empty)
* review/task.121.01-01/synthesis.md

  Status: ✓ Complete

---

ace-task.121.01 on  121.01-12101-basic-archive-output-to-stdout [$] via 💎 v3.4.6
❯ ace-review --preset code-pr --pr 50  --model gpro --auto-execute
✓ Review saved: /Users/mc/Ps/ace-task.121.01/.cache/ace-review/sessions/review-20251128-143031/review-report-gpro.md

ace-task.121.01 on  121.01-12101-basic-archive-output-to-stdout [$] via 💎 v3.4.6 took 46s
❯ ace-review --preset code-pr --pr 50  --model togetherai:zai-org/GLM-4.6 --auto-execute
✓ Review saved: /Users/mc/Ps/ace-task.121.01/.cache/ace-review/sessions/review-20251128-143223/review-report-zai-org/GLM-4.6.md