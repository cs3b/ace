---
description: Context for draft stage simulation
bundle:
  params:
    output: cache
    format: markdown-xml
  sections:
    system:
      title: "System Context"
      description: "Project context and workflow instruction for draft stage"
      presets:
        - project
      files:
        - ace-taskflow/handbook/workflow-instructions/task/simulate-next-phase-draft.wf.md
    user:
      title: "User Input"
      description: "The source content to process"
      content: |
        Source Reference: {{source_reference}}
        Source Type: {{source_type}}

        --- Source Content ---
        {{source_content}}

        --- Previous Stage Output ---
        {{previous_artifact}}
---

# Draft Stage Simulation

This preset provides project context and workflow instruction for generating draft task specs.
