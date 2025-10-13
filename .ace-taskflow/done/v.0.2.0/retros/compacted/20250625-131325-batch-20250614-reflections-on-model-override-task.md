# Reflections Template

## Stop Doing

- **Guessing File Paths:** I incorrectly guessed the path for the VCR cassette when trying to delete it. I should have used `find_path` first to confirm its location before attempting a file operation.
- **Making Assumptions on Test Failures:** I jumped to the conclusion that the VCR cassette was the problem for the failing integration test, when the root cause was the use of an invalid model name in the test setup. Re-recording the cassette fixed it, but only after I had already corrected the model name. I need to analyze the complete context of a failure before attempting a fix.
- **Using Hardcoded Lists for Dynamic Data:** The initial implementation for listing models used a static, hardcoded list. It was a correct user suggestion to change this to a dynamic API call. I should default to fetching dynamic data from its source when possible.

## Continue Doing

- **Systematically Following Workflow Instructions:** I successfully followed the steps outlined in `create-reflection-note.wf.md`, which led to the correct creation of the reflection file.
- **Correcting Tool Usage Errors:** When the `bin/rc -p` command failed, I correctly interpreted the help output and used the right command (`bin/rc`) immediately after.
- **Refactoring to Better Data Structures:** Adopting the `Molecules::Model` class to represent model data was a significant improvement over using raw hashes. I should continue to embrace creating clear data structures.

## Start Doing

- **Verifying Paths Before Acting:** I will make it a priority to use `find_path` or `list_directory` to confirm a file's existence and exact path before attempting to modify or delete it, to avoid failed tool calls.
- **Deeper Root Cause Analysis:** When a test fails, I will focus more on identifying the fundamental reason (e.g., "Why did the API call fail?") rather than just fixing the immediate symptom (e.g., "The test failed").
- **Designing for Dynamism First:** When dealing with data that can change, like a list of API-provided models, my default approach should be to build a dynamic solution from the start, rather than beginning with a hardcoded one.