# Create Reflection Note Workflow Instruction

## Goal

To capture individual or team observations, learnings, and ideas for improvement using the standard
reflection template. These notes are intended for later synthesis, primarily as input for the
`create-retrospective-document.md` workflow.

## Prerequisites

- The reflection template is available at `docs-dev/guides/prepare-release/v.x.x.x/reflections/_template.md`.
- Understanding of the proposed naming convention
  and location for reflection notes:
  - **Location:** Within a specific release directory, e.g.,
    (e.g., `docs-project/current/{release_dir}/reflections/\\` or
    `docs-project/backlog/{release_dir}/reflections/\\`)
  - **Filename:** `YYYYMMDD-brief-description.md` (e.g., `20231027-thoughts-on-task-123.md`).
  - The `reflections/` subdirectory should be created within the target release directory if it doesn't exist.

## Process Steps

1. **Initiation:**
    - The user requests to create a reflection note.
    - The user provides a brief topic, task ID, or description for the note (e.g., "reflections on
      component X refactor", "learnings from bug Y").
    - The user specifies the target release (e.g., "current release", or the name/path of a specific
      release in `docs-project/backlog/`). If not specified, the agent should assume the "current" release.

2. **Prepare File:**
    - The agent determines the path to the target release directory.
        - For "current release": This usually involves identifying the symbolic link or directory at
          `docs-project/current/`. The agent might need to list contents or use a helper
          script/tool if available to resolve this to a concrete path
          (e.g., `docs-project/current/vX.Y.Z-release-name`).
        - For a backlog release: The user should provide the path or name (e.g., `docs-project/backlog/vA.B.C-future-release`).
    - The agent constructs the full path for the reflection note:
      `TARGET_RELEASE_PATH/reflections/YYYYMMDD-user-provided-description.md`.
        - Example for current release:
          `docs-project/current/{resolved_release_dir}/reflections/`
          `YYYYMMDD-user-provided-description.md`.
    - The agent ensures the `TARGET_RELEASE_PATH/reflections/` directory exists. If not, it should be
      created. (Note: `edit_file` tool with `create_or_overwrite = True` typically handles parent directory
      creation for the file itself).

3. **Populate from Template:**
    - The agent reads the content of the standard reflection template:
      `docs-dev/guides/prepare-release/v.x.x.x/reflections/_template.md`.
    - The agent creates the new reflection note file (using the full path determined in Step 2) and
      populates it with the template's content (which includes level 1 headings for sections).

4. **User Fills Reflection:**
    - The agent informs the user that the reflection note file has been created with the template
      and is ready to be filled (providing the path to the new file).
    - The agent prompts the user to provide their thoughts for the "Stop Doing", "Continue Doing", and
      "Start Doing" sections, indicating that they will be added as bullet points.
    - The user provides the content for these sections.
    - The agent assists the user by editing the newly created reflection note file to insert
      the user's content as bullet points under the appropriate level 1 headings. Empty
      sections (those for which the user provided no content) are skipped.

5. **Save & Confirm:**
    - The agent ensures the reflection note file is saved with the user's input.
    - The agent confirms to the user that the note has been saved (providing the full path again).
    - The agent reminds the user that this note can be used as input for the
      [`create-retrospective-document.md`](./create-retrospective-document.md) workflow.

## Input

- User request to create a reflection note.
- Target release for the reflection note (e.g., "current", or path/name of a backlog release).
- A brief topic, task ID, or description for the reflection note (used for filename generation).
- Content for the "Stop Doing", "Continue Doing", and "Start Doing" sections (provided by the
  user during Step 4).

## Output / Success Criteria

- [ ] A new Markdown file is created within the `reflections/` subdirectory of the target release
  (e.g., `docs-project/current/{release_dir}/reflections/\` or `docs-project/backlog/{release_dir}/reflections/\`)
  with a name following the `YYYYMMDD-brief-description.md` convention.
- [ ] The `reflections/` subdirectory within the target release directory is created if it did not previously exist.
- [ ] The new file is populated with user-provided reflections.
- [ ] Only sections (Stop Doing, Continue Doing, Start Doing) for which the user provided content are included in the file.
- [ ] User reflections within included sections are formatted as bullet points under their respective level 1 headings.
- [ ] The user is informed that the reflection note has been successfully saved and its intended use for future retrospectives.

## Reference Documentation

- [Reflection Template (`_template.md`)](docs-dev/guides/prepare-release/v.x.x.x/reflections/_template.md)
- [`create-retrospective-document.md` Workflow Instruction](./create-retrospective-document.md)
- [Writing Workflow Instructions Guide](docs-dev/guides/.meta/writing-workflow-instructions-guide.md)
