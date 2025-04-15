# Structured Code Edits Guide

This guide describes a standardized XML format for describing specific code changes. This format is primarily intended for use in AI-assisted development workflows, allowing AI agents to propose or apply precise edits to the codebase in a structured and reviewable manner.

## XML Format Specification

The user of a code editor wants to make a change to their codebase.
You must describe the change using the following XML structure:

- &lt;patch&gt; - A group of related code changes.
  Child tags:
    - &lt;title&gt; (required) - A high-level description of the changes. This should be as short
      as possible, possibly using common abbreviations.
    - &lt;edit&gt; (1 or more) - An edit to make at a particular range within a file.
      Includes the following child tags:
        - &lt;path&gt; (required) - The path to the file that will be changed.
        - &lt;description&gt; (optional) - An arbitrarily-long comment that describes the purpose
          of this edit.
        - &lt;old_text&gt; (optional) - An excerpt from the file's current contents that uniquely
          identifies a range within the file where the edit should occur. Required for all operations
          except `create`.
        - &lt;new_text&gt; (required) - The new text to insert into the file.
        - &lt;operation&gt; (required) - The type of change that should occur at the given range
          of the file. Must be one of the following values:
            - `update`: Replaces the entire range with the new text.
            - `insert_before`: Inserts the new text before the range.
            - `insert_after`: Inserts new text after the range.
            - `create`: Creates or overwrites a file with the given path and the new text.
            - `delete`: Deletes the specified range from the file.

## Guidelines for Generating Edits

- Never provide multiple edits whose ranges intersect each other. Instead, merge them into one edit.
- Prefer multiple edits to smaller, disjoint ranges, rather than one edit to a larger range.
- There's no need to escape angle brackets within XML tags.
- Always ensure imports are added if you're referencing symbols that are not in scope.

## Example

*(See the example provided in the original task description, showing updates to Rectangle and Circle structs in Rust)*

## Integration into Workflow

This format can be used in various ways:

1.  **AI Output:** An AI coding agent generates code changes described using this XML format. The developer can then review the structured patch before applying it.
2.  **AI Input:** A developer could potentially write an XML patch to provide very specific instructions to an AI agent, although this is less common for general development.
3.  **Tooling:** Code editors or specialized tools could consume this format to apply changes automatically.

Refer to the [Project Management Guide](project-management.md) and the [Unified Workflow Guide](../project/current/v.0.2.0/docs/unified-workflow-guide.md) to see where this format fits within the overall development process, particularly during the Task Implementation phase.