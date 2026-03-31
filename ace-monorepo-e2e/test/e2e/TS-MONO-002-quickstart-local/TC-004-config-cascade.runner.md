# Goal 4 — Configuration Cascade

## Goal

Follow quick-start section 7 ("Customization") and verify that project-level overrides take precedence over gem defaults.

## Workspace

Save all output to `results/tc/04/`.

## Steps

1. Create a project-level config override as documented:
   ```bash
   mkdir -p .ace/git
   ```
   Write a file `.ace/git/commit.yml` containing:
   ```yaml
   max_subject_length: 72
   body_wrap: 80
   ```
2. Save the created file path to `results/tc/04/override-path.txt`.
3. Verify the override file exists and has the expected content. Save the file content to `results/tc/04/override-content.txt`.
4. Create a project-level prompt override as documented:
   ```bash
   mkdir -p .ace-handbook/prompts
   ```
   Write a file `.ace-handbook/prompts/git-commit.system.md` with custom content.
5. Save the prompt file path to `results/tc/04/prompt-path.txt`.
6. Verify both override paths exist. Write a summary to `results/tc/04/cascade-check.txt` confirming the project-level files are in place.

## Constraints

- Follow the exact directory structure from quick-start.md.
- These are filesystem operations — the goal is that the documented override paths are valid and writable.
