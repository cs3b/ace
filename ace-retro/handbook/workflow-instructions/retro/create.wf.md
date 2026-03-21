---
doc-type: workflow
title: Create Retro Workflow Instruction
purpose: Documentation for ace-retro/handbook/workflow-instructions/retro/create.wf.md
ace-docs:
  last-updated: 2026-03-01
  last-checked: 2026-03-21
---

# Create Retro Workflow Instruction

## Goal

Capture observations, learnings, and improvement ideas from development work. Retros document insights that help improve future processes and outcomes.

## Prerequisites

- Understanding of what to capture (learnings, challenges, improvements)
- Current working session or specific context to reflect upon

## Process Steps

### 1. Determine Retro Context

Identify the scope and subject of the retro:

- **User-provided topic**: Use the specific topic, task, or time period given
- **Current session**: Self-review the working session for patterns and learnings
- **Task completion**: Reflect on a completed task or feature

### 2. Generate a Slug

Create a concise, descriptive slug from the topic:

- Use lowercase with hyphens: `oauth-integration-challenges`
- Keep it short but descriptive: `sprint-23-learnings`
- Include relevant context: `ace-test-runner-fixes`

### 3. Create the Retro File

```bash
# Basic creation
ace-retro create "topic-slug"

# With type and tags
ace-retro create "topic-slug" --type standard --tags sprint,team

# With task reference
ace-retro create "topic-slug" --task-ref 148
```

Read the created file path from the command output.

### 4. Populate the Retro

Use the template format from `tmpl://retro/retro` to structure content. Fill each section with meaningful insights from the retro context.

**Core sections to populate:**

- **What Went Well** — successful approaches, effective patterns, good decisions
- **What Could Be Improved** — challenges, inefficiencies, areas needing attention
- **Key Learnings** — insights gained, new understanding, valuable lessons
- **Action Items** — stop/continue/start doing items

**Optional enhancement sections** (use when relevant):

- Automation Insights
- Tool Proposals
- Workflow Proposals

### 5. Gather Content via Reflection

**Reflection Prompts:**

- What was the main goal of this work?
- What obstacles were encountered?
- How were problems solved?
- What would you do differently?
- What patterns emerged?
- What knowledge was gained?

**For session-based retros**, review:

- Recent git commits and changes
- Challenges faced and how they were resolved
- Successful approaches worth repeating

### 6. Finalize

- Ensure populated sections have meaningful content
- Remove empty optional sections
- Verify with `ace-retro list` to confirm the retro appears

## Best Practices

**DO:**

- Be honest about challenges and failures
- Focus on actionable improvements
- Include specific examples
- Keep entries concise but complete
- Date and contextualize retros

**DON'T:**

- Make it a blame session
- Be vague or generic
- Skip the action items
- Leave sections empty without removing them
- Write novels — keep it focused

## Success Criteria

- Retro created via `ace-retro create` with appropriate slug
- Key sections populated with meaningful content
- Action items clearly defined
- Insights captured for future reference
