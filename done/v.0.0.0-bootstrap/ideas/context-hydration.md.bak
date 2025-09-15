## tools - bin/context

**Goal:** Create a tool (`bin/context`) to generate a single, comprehensive context document for a specific task or prompt, incorporating relevant documentation, workflow instructions, and potentially tool call responses.

**Details:**
- Leverage the existing prototype script in `dev-taskflow/backlog/research/sample-context-hydration.rb` as a starting point.
- The tool should scan "wiki-style" files (Markdown documents), follow internal links, and gather related information.
- It should also search for and include relevant tool calling examples.
- The output should be a single Markdown file.
- The Markdown file should contain a summary at the top, followed by the embedded content of the gathered documents and tool call responses.
- Embedded documents should include links back to their original source files, potentially with line numbers (implementation TBD).
- An LLM (e.g., Gemini Flash Lite) should be used to compact or summarize key information, especially for the summary section.

**Missing Information / Clarification Needed:**
- How should the tool identify and include "relevant tool calling" examples? Should it search for specific patterns (e.g., `tool_code` blocks), look in designated directories, or rely on metadata?
- How should relevance be determined when gathering tool calling examples?

**Next Steps:** Refine the scope based on the clarification regarding relevant tool calling, then create a detailed task ticket outlining implementation phases (similar to `git-aliases-ticket.md`).