# Generate Project Blueprint Command

## Goal
Create or update the `docs-dev/project/blueprint.md` file with a summary of the current project structure and links to core project documents.

## Process (Initial - Manual/Semi-Automated)

1.  **Identify Core Project Documents:** Ensure `docs-dev/project/what-do-we-build.md` and `docs-dev/project/architecture.md` are up-to-date.
2.  **Capture Directory Structure:**
    *   Run `tree -L 2` (or adjust depth as needed) from the project root.
    *   Copy the relevant output into the `blueprint.md` code block.
3.  **Identify Key Files:** List important project-specific files (like `version.rb`, `Gemfile`, `.gemspec`, main entry points, core test helpers) in the designated section.
4.  **Update Links:** Ensure links to core documents are correct.
5.  **Save:** Save the updated `docs-dev/project/blueprint.md`.

## Future Enhancements
- A script could automate steps 2 and potentially 3 by scanning the project for standard files.
- Could be integrated into `load-env` to automatically refresh if changes are detected (potentially complex).

## Usage
Run this process manually whenever significant structural changes occur or before starting a major planning phase to ensure the context loaded by `load-env` is accurate.