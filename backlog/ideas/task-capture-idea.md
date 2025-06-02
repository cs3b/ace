## Tool for Capturing Task Ideas (bin/tci)

**Goal:** Create a command-line tool (`bin/tci`) to streamline the process of capturing new task ideas and documenting them in the project backlog.

**Details:**
- The tool should accept a command-line parameter representing the user's intention or the core idea.
- It should load the project environment context (potentially using a mechanism similar to the `context-hydration` idea).
- A new workflow instruction should be created specifically for the task idea capture process, guiding the tool on loading necessary context and interacting with the LLM.
- The tool will use an LLM (e.g., Google Flash Lite) to process the provided intention.
- The LLM should expand on the idea and format it according to a predefined simple template for idea files. The expansion should stay within the structural limits of the template.
- The output from the LLM, formatted by the template, should be saved as a new Markdown file in the `docs-project/backlog/ideas/` directory.
- A guide document (`docs-dev/guides/how-to-capture-ideas.guide.md`) should be created to explain the process and how to use the `bin/tci` tool.

**Missing Information / Clarification Needed:**
- What is the desired structure and content of the simple template for idea files?
- What specific instructions or prompt structure should be used when querying the LLM with the user's intention and the template?

**Next Steps:** Define the idea file template and LLM prompt strategy, then create a detailed task ticket for implementing the `bin/tci` tool and the guide.