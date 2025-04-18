# Generate Retrospective Template Workflow Instruction

## Goal
Create a retrospective document for a completed release cycle using the standard template, facilitating analysis of what went well, what didn't, and identifying actionable improvements.

## Prerequisites
- A release has been completed and its directory moved to `docs-project/done/`.
- Access to the completed release's tasks, commits, and potentially reflection logs (`reflections/`).

## Process Steps

1.  **Identify Target Release:** Confirm the path to the completed release directory in `docs-project/done/`.
2.  **Create Retro File:** Create a new file within the completed release directory, e.g., `docs-project/done/{release_dir}/retrospective.md`.
3.  **Apply Template:** Copy the content from the standard retrospective template (`guides/prepare-release/v.x.x.x/reflections/_template.md`) into the new file.
4.  **Gather Context:** Review the release overview (`README.md`), completed tasks (`tasks/*.md`), reflection logs (`reflections/*.md`), and commit history for the release.
5.  **Facilitate Retrospective:** Guide the user/team through filling out the template sections based on the gathered context:
    *   **Stop Doing:** Identify ineffective practices.
    *   **Continue Doing:** Highlight successful practices.
    *   **Start Doing:** Propose new practices or improvements.
6.  **Identify Action Items:** Extract concrete, actionable improvements from the "Start Doing" section. Consider creating new tasks in the main `docs-project/backlog/` for these items.
7.  **Save:** Save the completed retrospective document.

## Input
- Path to the completed release directory.
- Optional: User/team input during the retrospective process.

## Output / Success Criteria
- [x] A `retrospective.md` file is created within the completed release directory.
- [x] The file uses the standard retrospective template structure.
- [x] Key insights (Stop/Continue/Start) are captured based on the release cycle.
- [x] Actionable improvements are identified.

## Reference Documentation
- [Writing Workflow Instructions Guide](../../guides/writing-workflow-instructions.md)
- [Retrospective Template](../../guides/prepare-release/v.x.x.x/reflections/_template.md)
- [Self-Reflect Workflow Instruction](../self-reflect.md) (Input for retrospectives)