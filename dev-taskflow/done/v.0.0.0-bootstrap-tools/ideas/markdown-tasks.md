## Markdown Document Linting and Improvements

**Goal:** Enhance the project's capabilities for linting Markdown documents, specifically focusing on link validation and improving the output of the linting tool.

**Details:**
- Build upon existing sample tools like `docs-dev/tools/lint-md-links.rb` and `docs-dev/tools/lint-task-metadata`.
- Implement checks for specific Markdown link formats and path issues (e.g., broken file links, incorrect relative paths).
- The linter should report errors and warnings by default.
- Add an `--autofix` option to attempt to automatically correct certain types of link or formatting issues.
- Improve the output of the `bin/lint` tool:
    - Include a summary at the very end, breaking down the number of errors and warnings per linting part (e.g., link errors, metadata errors).
    - By default, show detailed error/warning information for only the first few files encountered (e.g., up to the first 5) to keep the output manageable.
    - Present a comprehensive list of all files containing errors or warnings in the final summary.

**Missing Information / Clarification Needed:**
- How should the comprehensive list of all files with issues be presented in the final summary? (e.g., just a list of paths, or paths with a count of issues per file).
- What specific link formats/path issues should be prioritized for checking and potential autofixing?

**Next Steps:** Refine the output format and specific checks based on clarification, then create a detailed task ticket for implementation.