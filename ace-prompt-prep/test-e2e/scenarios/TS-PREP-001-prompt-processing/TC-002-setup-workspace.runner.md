# Goal 2 — Setup Workspace

## Goal

Using the setup subcommand discovered in Goal 1, create the prompt workspace. Verify that the expected directory structure and template file are created by capturing a directory listing and the template file content.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `setup.stdout`, `setup.stderr`, `setup.exit` from the setup invocation
- `workspace-tree.txt` listing the prompt workspace structure
- `template.md` containing the created prompt template content

## Constraints

- Use only `ace-prompt-prep` to perform the setup. Do not manually create directories or files.
- Using what you learned from Goal 1, invoke the setup operation. Do not assume syntax beyond what Goal 1 revealed.
- All artifacts must come from real tool execution, not fabricated.
